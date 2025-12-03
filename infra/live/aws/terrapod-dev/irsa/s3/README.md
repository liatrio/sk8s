# IRSA for Terrapod S3

This Terragrunt configuration creates an IAM Role for Service Account (IRSA) that allows the Terrapod API service account to access the S3 bucket.

## What it creates

- **IAM Policy**: `terrapod-s3-policy` with permissions to:
  - `s3:GetObject` - Read objects from the bucket
  - `s3:PutObject` - Upload objects to the bucket
  - `s3:ListBucket` - List bucket contents
  - `s3:DeleteObject` - Delete objects from the bucket

- **IAM Role**: `terrapod-s3-role` that can be assumed by:
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

```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/terrapod-s3-role
  name: terrapod-api
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

Test S3 access from a pod:
```bash
kubectl run -it --rm debug --image=amazon/aws-cli --serviceaccount=terrapod-api -n terrapod-dev -- s3 ls s3://terrapod-graph-dev/
```
