# Deployment Guide: IRSA for S3

## Step 1: Deploy the IRSA Infrastructure

```bash
cd sk8s/infra/live/aws/terrapod-dev/irsa/s3
terragrunt init
terragrunt plan
terragrunt apply
```

## Step 2: Get the IAM Role ARN

```bash
terragrunt output role_arn
```

Example output:
```
arn:aws:iam::123456789012:role/terrapod-s3-role
```

## Step 3: Update Helm Values

Edit `terrapod-frontend/helm/terrapod-api/values-dev.yaml`:

```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::YOUR_ACCOUNT_ID:role/terrapod-s3-role
  name: terrapod-api
```

## Step 4: Deploy/Upgrade Helm Chart

```bash
cd terrapod-frontend/helm/terrapod-api
helm upgrade --install terrapod-api . \
  -f values-dev.yaml \
  -n terrapod-dev \
  --create-namespace
```

## Step 5: Verify

Check the service account annotation:
```bash
kubectl get sa terrapod-api -n terrapod-dev -o yaml | grep eks.amazonaws.com/role-arn
```

Check pod environment variables (AWS SDK will auto-detect these):
```bash
kubectl get pod -n terrapod-dev -l app.kubernetes.io/name=terrapod-api -o yaml | grep -A 5 AWS_
```

You should see:
- `AWS_ROLE_ARN`: The IAM role ARN
- `AWS_WEB_IDENTITY_TOKEN_FILE`: Path to the token file

## Step 6: Test S3 Access

Test from command line:
```bash
kubectl run -it --rm aws-cli \
  --image=amazon/aws-cli \
  --serviceaccount=terrapod-api \
  -n terrapod-dev \
  -- s3 ls s3://terrapod-graph-dev/
```

## Troubleshooting

### Permission Denied

Check if the role exists:
```bash
aws iam get-role --role-name terrapod-s3-role
```

Check if the policy is attached:
```bash
aws iam list-attached-role-policies --role-name terrapod-s3-role
```

### Service Account Not Annotated

Re-deploy the Helm chart or manually annotate:
```bash
kubectl annotate serviceaccount terrapod-api \
  -n terrapod-dev \
  eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT_ID:role/terrapod-s3-role
```

### Pod Can't Assume Role

Check pod logs for AWS SDK errors:
```bash
kubectl logs -n terrapod-dev -l app.kubernetes.io/name=terrapod-api
```

Verify the OIDC provider is configured:
```bash
aws eks describe-cluster --name terrapod-dev --query "cluster.identity.oidc.issuer"
```
