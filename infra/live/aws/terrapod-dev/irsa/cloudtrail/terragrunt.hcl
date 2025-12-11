terraform {
  source = "../../../../../modules/aws/irsa-policy-only"
}

remote_state {
  backend = "s3"
  config  = {
    bucket = "terrapod-api-dev-tfstate"
    key    = "irsa/cloudtrail/terraform.tfstate"
    region = "us-east-1"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

dependency "s3_irsa" {
  config_path = "../s3"
}

inputs = {
  existing_role_name   = "terrapod-s3-role"
  policy_name          = "terrapod-cloudtrail-policy"
  policy_description   = "IAM policy for Terrapod CloudTrail access"

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudtrail:LookupEvents",
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    "Project"     = "Terrapod"
    "Environment" = "Development"
    "ManagedBy"   = "Terragrunt"
    "Component"   = "IRSA-CloudTrail"
  }
}