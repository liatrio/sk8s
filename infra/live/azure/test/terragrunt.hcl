terraform {
  source = "../../..//src/azure"
}

remote_state {
  backend = "azurerm"
  config  = {
    resource_group_name  = "sk8s"
    storage_account_name = "sk8sinfrastate"
    container_name       = "tfstate"
    key                  = "test.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  resource_group_name = "sk8s-cluster"
  network_name        = "sk8s-cluster-vnet"
  address_space       = "10.1.0.0/16"
  subnets             = [
    {
      name           = "nodes"
      address_prefix = "10.1.0.0/18"
    },
    {
      name           = "aci"
      address_prefix = "10.1.128.0/18"
    }
  ]
  tags = {
    project = "Sk8s"
    owner   = "GitHub Practice"
  }
}
