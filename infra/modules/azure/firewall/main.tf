data "azurerm_resource_group" "self" {
  name = var.resource_group_name
}

data "azurerm_subnet" "self"{
  count = var.firewall != null && var.network.managed ? 1 : 0

  name                 = var.network.subnet_name
  virtual_network_name = var.network.virtual_network_name
  resource_group_name  = var.resource_group_name
}

data "azurerm_firewall" "self" {
  count = var.firewall != null && var.network.managed ? 1 : 0

  name                = var.firewall.name
  resource_group_name = var.firewall.resource_group
}

resource "azurerm_public_ip" "self" {
  count = var.firewall != null ? 1 : 0
  name                = "${var.firewall.name}-pip"
  resource_group_name = data.azurerm_resource_group.self.name
  location            = data.azurerm_resource_group.self.location 
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall_policy" "self" {
  count = var.firewall != null ? 1 : 0

  name                = "${var.firewall.name}-policy"
  resource_group_name = data.azurerm_resource_group.self.name 
  location            = data.azurerm_resource_group.self.location 
}

resource "azurerm_firewall_policy_rule_collection_group" "self" {
  count = var.firewall != null ? 1 : 0

  name               = "${azurerm_firewall_policy.self[0].name}-rcg"
  firewall_policy_id = azurerm_firewall_policy.self[0].id
  priority           = 101

  network_rule_collection {
    name     = "sk8s-network-rules"
    priority = 100
    action   = "Allow"

    dynamic "rule" {
      for_each = var.network_rules
      
      content {
        name                  = rule.value.name
        protocols             = rule.value.protocols
        source_addresses      = rule.value.source_addresses
        destination_addresses = rule.value.destination_addresses
        destination_ports     = rule.value.destination_ports
      }
    }
  }

  application_rule_collection {
    name     = "sk8s-app-rules"
    priority = 101
    action   = "Allow"

    dynamic "rule" {
      for_each = var.application_rules

      content {
        name              = rule.value.name
        source_addresses  = rule.value.source_addresses
        destination_fqdns = rule.value.destination_fqdns
        protocols { 
          type = rule.value.protocols.type
          port = rule.value.protocols.port
        }
      }
    }
  }
}

resource "azurerm_firewall" "self" {
  count = var.firewall != null && !var.network.managed ? 1 : 0 

  name                = var.firewall.name
  resource_group_name = data.azurerm_resource_group.self.name
  location            = data.azurerm_resource_group.self.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id = azurerm_firewall_policy.self[0].id

  ip_configuration {
    name                 = "${var.firewall.name}-ipconfig"
    subnet_id            = var.network.subnet_id
    public_ip_address_id = azurerm_public_ip.self[0].id
  }
}

resource "azurerm_route_table" "self" {
  count = var.firewall != null ? 1 : 0

  name                = "${var.network.virtual_network_name}-rt"
  resource_group_name = data.azurerm_resource_group.self.name
  location            = data.azurerm_resource_group.self.location

  route {
    name                   = "aks_outbound"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.network.managed ? data.azurerm_firewall.self[0].ip_configuration[0].private_ip_address : azurerm_firewall.self[0].ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "self" {
  count = var.firewall != null ? 1 : 0

  subnet_id      = var.association_subnet_id
  route_table_id = azurerm_route_table.self[0].id
}