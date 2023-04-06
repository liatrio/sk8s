data "azurerm_resource_group" "self" {
  name = var.resource_group_name
}

resource "azurerm_container_registry" "self" {
  name                          = var.container_registry_name
  resource_group_name           = data.azurerm_resource_group.self.name
  location                      = data.azurerm_resource_group.self.location
  sku                           = "Premium"
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "self" {
  name                          = "${var.container_registry_name}-private"
  resource_group_name           = data.azurerm_resource_group.self.name
  location                      = data.azurerm_resource_group.self.location
  subnet_id                     = var.subnet_id
  custom_network_interface_name = "${var.container_registry_name}-nic"

  private_service_connection {
    name                           = "${var.container_registry_name}-svconn"
    private_connection_resource_id = azurerm_container_registry.self.id
    subresource_names              = ["registry"]
    is_manual_connection           = false

  }

  private_dns_zone_group {
    name                 = "${var.container_registry_name}-dns"
    private_dns_zone_ids = [var.private_zone_id]
  }
}
