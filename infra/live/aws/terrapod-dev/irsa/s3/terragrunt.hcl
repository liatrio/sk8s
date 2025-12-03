terraform {
  source = "../../../../../modules/aws/irsa"
}

remote_state {
  backend = "s3"
  config  = {
    bucket = "terrapod-api-dev-tfstate"
    key    = "irsa/s3/terraform.tfstate"
    region = "us-east-1"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

dependency "s3" {
  config_path = "../../s3"
}

inputs = {
  cluster_name         = "terrapod-dev"
  namespace            = "terrapod-dev"
  service_account_name = "terrapod-api"
  role_name            = "terrapod-s3-role"
  policy_name          = "terrapod-s3-policy"
  policy_description   = "IAM policy for Terrapod S3 access"

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          dependency.s3.outputs.bucket_arn,
          "${dependency.s3.outputs.bucket_arn}/*"
        ]
      }
    ]
  })

  tags = {
    "Project"     = "Terrapod"
    "Environment" = "Development"
    "ManagedBy"   = "Terragrunt"
    "Component"   = "IRSA-S3-Viewer"
  }
}
