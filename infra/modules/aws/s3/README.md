# AWS S3 Bucket Module

This module creates an S3 bucket with security best practices enabled by default.

## Features

- Server-side encryption (AES256)
- Versioning support
- Public access blocking
- Customizable tags

## Usage

```hcl
module "s3_bucket" {
  source = "../../../modules/aws/s3"

  bucket_name          = "my-bucket-name"
  versioning_enabled   = true
  block_public_access  = true

  tags = {
    Environment = "dev"
    Project     = "terrapod"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket_name | Name of the S3 bucket | string | - | yes |
| versioning_enabled | Enable versioning | bool | true | no |
| block_public_access | Block public access | bool | true | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| bucket_arn | The ARN of the bucket |
| bucket_domain_name | The bucket domain name |
| bucket_regional_domain_name | The bucket region-specific domain name |
