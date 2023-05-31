data "azurerm_resource_group" "self" {
  name = var.resource_group_name
}

resource "azurerm_network_security_group" "self" {
  name                = "${var.network_name}-nsg"
  location            = data.azurerm_resource_group.self.location
  resource_group_name = data.azurerm_resource_group.self.name
}

resource "azurerm_virtual_network" "self" {
  name                = var.network_name
  resource_group_name = data.azurerm_resource_group.self.name
  location            = data.azurerm_resource_group.self.location
  address_space       = [var.address_space]
  dns_servers         = []
  tags                = var.tags
}

resource "azurerm_subnet" "self" {
  count = length(var.subnets)

  name                 = var.subnets[count.index].name
  resource_group_name  = data.azurerm_resource_group.self.name
  virtual_network_name = azurerm_virtual_network.self.name
  address_prefixes     = [var.subnets[count.index].address_prefix]
}

resource "azurerm_subnet_network_security_group_association" "self" {
  count = length(var.subnets)

  subnet_id                 = azurerm_subnet.self[count.index].id
  network_security_group_id = azurerm_network_security_group.self.id
}

data "azurerm_virtual_network" "self" {
  count = var.peering_connection != null ? 1 : 0

  name                = var.peering_connection.virtual_network_name
  resource_group_name = var.peering_connection.resource_group
}

resource "azurerm_virtual_network_peering" "peer_aks_to_hub" {
  count = var.peering_connection != null ? 1 : 0

  name                         = "${var.network_name}-to-${var.peering_connection.virtual_network_name}"
  resource_group_name          = data.azurerm_resource_group.self.name
  virtual_network_name         = azurerm_virtual_network.self.name
  remote_virtual_network_id    = data.azurerm_virtual_network.self[0].id
}

resource "azurerm_virtual_network_peering" "peer_hub_to_aks" {
  count = var.peering_connection != null ? 1 : 0

  name                         = "${var.peering_connection.virtual_network_name}-to-${var.network_name}"
  resource_group_name          = var.peering_connection.resource_group
  virtual_network_name         = var.peering_connection.virtual_network_name
  remote_virtual_network_id    = azurerm_virtual_network.self.id
}

data "azurerm_firewall" "self" {
  count = var.firewall != null ? 1 : 0

  name                = var.firewall.name
  resource_group_name = var.firewall.resource_group
}

resource "azurerm_route_table" "self" {
  count = var.firewall != null ? 1 : 0

  name                = "${var.network_name}-rt"
  resource_group_name = data.azurerm_resource_group.self.name
  location            = data.azurerm_resource_group.self.location

  route {
    name                   = "aks_outbound"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = data.azurerm_firewall.self[0].ip_configuration[0].private_ip_address
  }
}
 
locals {
  subnets = [for subnet in var.subnets : subnet if subnet.tags.routing == "external"]
}

resource "azurerm_subnet_route_table_association" "self" {
  count = (var.firewall != null && length(local.subnets) > 0) ? 1 : 0

  subnet_id      = local.subnets[0].id
  route_table_id = azurerm_route_table.self[0].id
}