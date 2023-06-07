locals {
  create_subnets = [for subnet in var.subnets : subnet if !subnet.attributes.managed]
}

module "network" {
  source = "../../modules/azure/network"

  resource_group_name = var.resource_group_name
  network_name        = var.network_name
  address_space       = var.address_space
  subnets             = local.create_subnets
  peering_connection  = var.peering_connection
  firewall            = var.firewall
  tags                = var.tags
}

module "dns" {
  source = "../../modules/azure/dns"

  domain_name         = "sk8s.internal.liatr.io"
  resource_group_name = var.resource_group_name
  is_public           = false
  system_managed_dns = var.system_managed_dns
}

locals {
  subnets = [for subnet in var.subnets : subnet if contains(subnet.attributes.services, "acr")]
}

module "acr" {
  source = "../../modules/azure/acr"

  container_registry_name = "sk8simgs"
  resource_group_name     = var.resource_group_name
  private_zone_id         = module.dns.zone_id == null ? "System" : module.dns.zone_id
  network                 = {
    virtual_network_name = module.network.virtual_network_name
    resource_group       = var.resource_group_name
    subnet_id            = module.network.subnets[local.subnets[0].name].id
  }
}

locals{
  managed_subnets = [for subnet in var.subnets : subnet if subnet.attributes.managed]
}

module "aks" {
  source = "../../modules/azure/aks"

  cluster_name        = "sk8s"
  resource_group_name = var.resource_group_name
  private_zone_id     = module.dns.zone_id == null ? "System" : module.dns.zone_id

  network = {
    virtual_network_name = module.network.virtual_network_name
    subnet_id            = module.network.subnets["nodes"].id
    peering_connection   = (var.peering_connection != null) ? var.peering_connection.virtual_network_name : null
    user_defined_routing = var.firewall == null ? false : true
    dns_service_ip       = cidrhost(local.managed_subnets[0].address_prefix, 4)
    docker_bridge_cidr   = "172.17.0.1/16"
    plugin               = "azure"
    service_cidr         = local.managed_subnets[0].address_prefix
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

  # node_pools = {
  #   spot = {
  #     auto_scaler_profile = {
  #       enabled        = true
  #       max_node_count = 3
  #       min_node_count = 1
  #     }
  #     node_size  = "Standard_D2s_v3"
  #     zones      = ["1", "2", "3"]
  #     priority   = {
  #       spot_enabled = true
  #       spot_price   = -1
  #     }
  #   }
  # }

  identity = {
    assignment = "SystemAssigned"
  }

  virtual_nodes = {
    enabled     = true
    subnet_name = "aci"
  }
}
