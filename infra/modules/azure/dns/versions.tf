terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.51.0"
    }
  }

  required_version = ">= 1.3.1, <= 1.4.6"
}

provider "azurerm" {
  features {}
}
