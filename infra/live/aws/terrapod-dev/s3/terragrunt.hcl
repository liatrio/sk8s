terraform {
  source = "../../../../modules/aws/s3"
}

remote_state {
  backend = "s3"
  config  = {
    bucket = "terrapod-api-dev-tfstate"
    key    = "s3/terraform.tfstate"
    region = "us-east-1"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  bucket_name          = "terrapod-graph-dev"
  versioning_enabled   = true
  block_public_access  = true

  tags = {
    "Project"     = "Terrapod"
    "Environment" = "Development"
    "ManagedBy"   = "Terragrunt"
  }
}
