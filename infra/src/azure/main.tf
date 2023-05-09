module "network" {
  source = "../../modules/azure/network"

  resource_group_name = var.resource_group_name
  network_name        = var.network_name
  address_space       = var.address_space
  subnets             = var.subnets
  peering_connection  = var.peering_connection
  firewall            = var.firewall
  tags                = var.tags
}

module "dns" {
  source = "../../modules/azure/dns"

  domain_name         = "sk8s.internal.liatr.io"
  resource_group_name = var.resource_group_name
  is_public           = false
}

module "acr" {
  source     = "../../modules/azure/acr"

  container_registry_name = "sk8simgs"
  resource_group_name     = var.resource_group_name
  private_zone_id         = module.dns.zone_id
  network                 = {
    virtual_network_name = var.peering_connection.virtual_network_name
    subnet_name          = var.peering_connection.subnet_name
    resource_group       = var.peering_connection.resource_group
  }
}

module "aks" {
  source     = "../../modules/azure/aks"

  cluster_name         = "sk8s"
  resource_group_name  = var.resource_group_name
  private_zone_id      = module.dns.zone_id
  peering_connection   = var.peering_connection

  network = {
    virtual_network_name = module.network.virtual_network_name
    subnet_id            = module.network.subnets["nodes"].id
    peering_connection   = var.peering_connection.virtual_network_name
    user_defined_routing = true
    dns_service_ip       = "10.1.64.4"
    docker_bridge_cidr   = "172.17.0.1/16"
    plugin               = "azure"
    service_cidr         = "10.1.64.0/18"
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
