module "network" {
  source = "../../modules/azure/network"

  resource_group_name = var.resource_group_name
  network_name        = var.network_name
  address_space       = var.address_space
  subnets             = var.subnets
  tags                = var.tags
}

module "dns" {
  source = "../../modules/azure/dns"

  domain_name         = "sk8s.internal.liatr.io"
  resource_group_name = var.resource_group_name
  is_public           = false
}

data "azurerm_subnet" "self" {
  name                 = "nodes"
  virtual_network_name = var.network_name
  resource_group_name  = var.resource_group_name
}

module "acr" {
  source = "../../modules/azure/acr"

  container_registry_name = "sk8simgs"
  resource_group_name     = var.resource_group_name
  subnet_id               = data.azurerm_subnet.self.id
  private_zone_id         = module.dns.zone_id
}

module "aks" {
  source = "../../modules/azure/aks"

  cluster_name         = "sk8s"
  resource_group_name  = var.resource_group_name
  private_zone_id      = module.dns.zone_id

  network = {
    dns_service_ip       = "10.1.64.4"
    docker_bridge_cidr   = "172.17.0.1/16"
    plugin               = "azure"
    service_cidr         = "10.1.64.0/18"
    subnet_name          = "nodes"
    virtual_network_name = "sk8s-cluster-vnet"
  }

  default_node_pool = {
    auto_scaler_profile = {
      enabled        = true
      max_node_count = 9
      min_node_count = 3
    }
    node_size  = "Standard_D2s_v3"
    zones      = ["1", "2", "3"]
  }

  node_pools = {
    spot = {
      auto_scaler_profile = {
        enabled        = true
        max_node_count = 3
        min_node_count = 1
      }
      node_size  = "Standard_D2s_v3"
      zones      = ["1", "2", "3"]
      priority   = {
        spot_enabled = true
        spot_price   = -1
      }
    }
  }

  identity = {
    assignment = "SystemAssigned"
  }

  virtual_nodes = {
    enabled     = true
    subnet_name = "aci"
  }
}
