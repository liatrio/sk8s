# Terrapod Development Environment

This directory contains Terragrunt configurations for the Terrapod development environment infrastructure.

## Structure

```
terrapod-dev/
├── terragrunt.hcl          # Parent config with shared settings
├── ecr/                    # Elastic Container Registry
│   └── terragrunt.hcl
└── s3/                     # S3 bucket for data storage
    └── terragrunt.hcl
```

## Usage

### Deploy All Resources

```bash
cd sk8s/infra/live/aws/terrapod-dev
terragrunt run-all plan
terragrunt run-all apply
```

### Deploy Individual Resources

**ECR (Container Registry):**
```bash
cd sk8s/infra/live/aws/terrapod-dev/ecr
terragrunt init
terragrunt plan
terragrunt apply
```

**S3 Bucket:**
```bash
cd sk8s/infra/live/aws/terrapod-dev/s3
terragrunt init
terragrunt plan
terragrunt apply
```

### Destroy Resources

```bash
# Destroy all
terragrunt run-all destroy

# Destroy individual
cd ecr && terragrunt destroy
cd s3 && terragrunt destroy
```

## Configuration

The parent `terragrunt.hcl` file contains:
- Common remote state configuration (S3 backend)
- Shared locals (environment, project, region)

Each subdirectory inherits these settings and adds resource-specific inputs.
