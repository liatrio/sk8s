terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.26.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0.1"
    }
  }

  required_version = "~> 1.2.7"
}
