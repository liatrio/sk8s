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

  dynamic "subnet" {
    for_each = toset(var.subnets)

    content {
      name           = subnet.value.name
      address_prefix = subnet.value.address_prefix
      security_group = azurerm_network_security_group.self.id
    }
  }
}
