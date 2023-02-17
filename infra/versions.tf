terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.26.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
  }

  required_version = "~> 1.2.7"
}
