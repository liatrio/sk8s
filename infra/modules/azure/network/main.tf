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
