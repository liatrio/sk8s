# Terrapod API IRSA Deployment Guide

This guide walks through deploying the combined IRSA configuration that provides both S3 and CloudTrail access for the Terrapod API.

## Overview

This IRSA configuration creates a single IAM role with permissions for:
- **S3 Access**: Read/write to the Terrapod S3 bucket for graph storage and spillover
- **CloudTrail Access**: Read CloudTrail events for IAM policy generation

## Quick Deployment

### 1. Deploy IRSA Role

```bash
# Navigate to the IRSA directory
cd sk8s/infra/live/aws/terrapod-dev/irsa/s3

# Deploy the combined role
terragrunt apply

# Get the role ARN
ROLE_ARN=$(terragrunt output -raw role_arn)
echo "Role ARN: $ROLE_ARN"
```

### 2. Deploy Application

```bash
# Navigate to Helm chart
cd ../../../../../../terrapod-frontend

# Deploy with IRSA
helm upgrade --install terrapod-api ./helm/terrapod-api \
  -f ./helm/terrapod-api/values-dev.yaml \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ROLE_ARN" \
  --namespace terrapod-dev \
  --create-namespace

# Wait for deployment
kubectl rollout status deployment/terrapod-api -n terrapod-dev
```

### 3. Test Both S3 and CloudTrail Access

```bash
# Port-forward to the API
kubectl port-forward -n terrapod-dev svc/terrapod-api 8000:80 &

# Test CloudTrail health
curl http://localhost:8000/api/v1/cloudtrail/health

# Test CloudTrail fetch
curl -X POST http://localhost:8000/api/v1/cloudtrail/fetch \
  -H "Content-Type: application/json" \
  -d '{
    "start_time": "2025-12-11T00:00:00Z",
    "end_time": "2025-12-11T23:59:59Z",
    "max_items": 5,
    "confidence_threshold": 50.0
  }'

# Stop port-forward
pkill -f "kubectl port-forward"
```

## What Gets Created

### IAM Role: `terrapod-api-role`
- **Trust Policy**: Allows `terrapod-api` service account in `terrapod-dev` namespace
- **Permissions**: Combined S3 and CloudTrail access

### IAM Policy: `terrapod-api-policy`
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket", 
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::terrapod-graph-dev",
        "arn:aws:s3:::terrapod-graph-dev/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudtrail:LookupEvents",
        "cloudtrail:DescribeTrails",
        "cloudtrail:GetTrailStatus"
      ],
      "Resource": "*"
    }
  ]
}
```

## Verification

### Check Service Account
```bash
kubectl get serviceaccount terrapod-api -n terrapod-dev -o yaml
```

### Test AWS Identity
```bash
kubectl exec -n terrapod-dev deployment/terrapod-api -- aws sts get-caller-identity
```

### Test S3 Access
```bash
kubectl exec -n terrapod-dev deployment/terrapod-api -- aws s3 ls s3://terrapod-graph-dev/
```

### Test CloudTrail Access
```bash
kubectl exec -n terrapod-dev deployment/terrapod-api -- \
  aws cloudtrail lookup-events --start-time 2025-12-11T00:00:00Z --max-results 1
```

## Expected Results

### Successful IRSA Setup
- **Service Account**: Has role ARN annotation
- **Pod Environment**: Contains `AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE`
- **AWS Identity**: Shows assumed role ARN
- **API Health**: Returns "IAM role/IRSA" auth method

### Sample Health Response
```json
{
  "status": "healthy",
  "cloudtrail_api": "connected",
  "region": "us-east-1",
  "auth_method": "IAM role/IRSA (region: us-east-1)",
  "test_events_found": 3,
  "message": "CloudTrail service is operational"
}
```

## Troubleshooting

### Role Not Found
```bash
aws iam get-role --role-name terrapod-api-role
```

### Permission Issues
```bash
# Check attached policies
aws iam list-attached-role-policies --role-name terrapod-api-role

# Check policy content
aws iam get-policy-version \
  --policy-arn $(aws iam list-attached-role-policies --role-name terrapod-api-role --query 'AttachedPolicies[0].PolicyArn' --output text) \
  --version-id v1
```

### Service Account Issues
```bash
# Check annotation
kubectl get sa terrapod-api -n terrapod-dev -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'

# Check pod environment
kubectl exec -n terrapod-dev deployment/terrapod-api -- env | grep AWS
```

## Cleanup

```bash
# Remove application
helm uninstall terrapod-api -n terrapod-dev

# Remove IRSA role
terragrunt destroy
```

This combined approach provides all necessary permissions for the Terrapod API while maintaining security best practices with a single, well-scoped IAM role.