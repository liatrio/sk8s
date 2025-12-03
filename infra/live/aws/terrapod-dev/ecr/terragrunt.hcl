terraform {
  source = "../../../../modules/aws/registry"
}

remote_state {
  backend = "s3"
  config  = {
    bucket = "terrapod-api-dev-tfstate"
    key    = "ecr/terraform.tfstate"
    region = "us-east-1"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  name = "terrapod-api"

  tags = {
    "Project"     = "Terrapod"
    "Environment" = "Development"
  }
}
