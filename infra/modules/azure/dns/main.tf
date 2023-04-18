resource "azurerm_dns_zone" "self" {
  count = var.is_public ? 1 : 0

  name                = var.domain_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone" "self" {
  count = var.is_public ? 0 : 1

  name                = var.domain_name
  resource_group_name = var.resource_group_name
}
