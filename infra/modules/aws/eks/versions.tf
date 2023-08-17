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

  required_version = ">= 1.3.1, <= 1.4.6"
}
