# Terrapod Development Environment
# This directory contains infrastructure for the terrapod-dev environment
#
# Subdirectories:
# - ecr/  : Elastic Container Registry for Docker images
# - s3/   : S3 bucket for data storage
#
# To deploy all resources:
#   terragrunt run-all plan
#   terragrunt run-all apply
#
# To deploy individual resources:
#   cd ecr && terragrunt apply
#   cd s3 && terragrunt apply

locals {
  environment = "Development"
  project     = "Terrapod"
  region      = "us-east-1"
}

# Common remote state configuration
remote_state {
  backend = "s3"
  config = {
    bucket = "terrapod-api-dev-tfstate"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = local.region
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
