terraform {
  source = "../../infra/src/aws"
}

remote_state {
  backend = "s3"
  config  = {
    bucket = "sk8s-tfstate-prod"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  network_name = "ghest-prod"

  // The subnet range must generate at least twice the number of subnets as the number of availability zones specified.
  // So, for 3 AZs, we need 6 subnets (3 public + 3 private).
  cidr_block   = "172.27.0.0/18"
  subnet_range = 21

  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]

  cluster_name = "ghest-prod"

  instance_type = "m6i.2xlarge"
  disk_size     = 200

  // The Project tag is required; we use it to generate unique IAM roles for the EKS cluster being created.
  tags = {
    "Project"        = "GHESTProd"
    "Environment"    = "Production"
  }
}
