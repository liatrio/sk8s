# IRSA for Terrapod API

This Terragrunt configuration creates an IAM Role for Service Account (IRSA) that allows the Terrapod API service account to access AWS services including S3 and CloudTrail.

## What it creates

- **IAM Policy**: `terrapod-api-policy` with permissions to:
  
  **S3 Permissions:**
  - `s3:GetObject` - Read objects from the bucket
  - `s3:PutObject` - Upload objects to the bucket (for large graph spillover)
  - `s3:ListBucket` - List bucket contents
  - `s3:DeleteObject` - Delete objects from the bucket
  
  **CloudTrail Permissions:**
  - `cloudtrail:LookupEvents` - Fetch CloudTrail events for policy generation
  - `cloudtrail:DescribeTrails` - Get information about CloudTrail configurations
  - `cloudtrail:GetTrailStatus` - Check CloudTrail status

- **IAM Role**: `terrapod-api-role` that can be assumed by:
  - Kubernetes service account: `terrapod-api`
  - In namespace: `terrapod-dev`
  - Via EKS OIDC provider

## Prerequisites

- EKS cluster `terrapod-dev` must exist with OIDC provider enabled
- S3 bucket must be deployed (dependency on `../s3`)

## Deploy

```bash
cd sk8s/infra/live/aws/terrapod-dev/irsa/s3
terragrunt plan
terragrunt apply
```

## Usage in Helm

After deploying, add the IAM role annotation to your Helm values:

```bash
# Get the role ARN from terragrunt
ROLE_ARN=$(terragrunt output -raw role_arn)

# Deploy with the role ARN
helm upgrade --install terrapod-api ./helm/terrapod-api \
  -f ./helm/terrapod-api/values-dev.yaml \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ROLE_ARN" \
  --namespace terrapod-dev \
  --create-namespace
```

Get the role ARN:
```bash
terragrunt output role_arn
```

## Verify

Check if the service account has the annotation:
```bash
kubectl get sa terrapod-api -n terrapod-dev -o yaml
```

Test S3 and CloudTrail access from a pod:
```bash
# Test S3 access
kubectl run -it --rm debug --image=amazon/aws-cli --serviceaccount=terrapod-api -n terrapod-dev -- s3 ls s3://terrapod-graph-dev/

# Test CloudTrail access
kubectl run -it --rm debug --image=amazon/aws-cli --serviceaccount=terrapod-api -n terrapod-dev -- cloudtrail lookup-events --start-time 2025-12-11T00:00:00Z --max-results 1

# Test via API health endpoint
kubectl port-forward -n terrapod-dev svc/terrapod-api 8000:80 &
curl http://localhost:8000/api/v1/cloudtrail/health
pkill -f "kubectl port-forward"
```
