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

locals{ #ignore firewall and gateway security group association
  subnets = [for subnet in azurerm_subnet.self : subnet if (subnet.name != "GatewaySubnet" && subnet.name != "AzureFirewallSubnet")]
}

resource "azurerm_subnet_network_security_group_association" "self" {
  count = length(local.subnets)

  subnet_id                 = local.subnets[count.index].id
  network_security_group_id = azurerm_network_security_group.self.id
}

data "azurerm_virtual_network" "self" {
  count = var.peering_connection != null ? 1 : 0

  name                = var.peering_connection.virtual_network_name
  resource_group_name = var.peering_connection.resource_group
}

resource "azurerm_virtual_network_peering" "peer_aks_to_hub" {
  count = var.peering_connection != null ? 1 : 0

  name                       = "${var.network_name}-to-${var.peering_connection.virtual_network_name}"
  resource_group_name        = data.azurerm_resource_group.self.name
  virtual_network_name       = azurerm_virtual_network.self.name
  remote_virtual_network_id  = data.azurerm_virtual_network.self[0].id
}

resource "azurerm_virtual_network_peering" "peer_hub_to_aks" {
  count = var.peering_connection != null ? 1 : 0

  name                         = "${var.peering_connection.virtual_network_name}-to-${var.network_name}"
  resource_group_name          = var.peering_connection.resource_group
  virtual_network_name         = var.peering_connection.virtual_network_name
  remote_virtual_network_id    = azurerm_virtual_network.self.id
}
