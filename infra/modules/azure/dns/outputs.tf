output "zone_id" {
  value = var.is_public ? azurerm_dns_zone.self.0.id : azurerm_private_dns_zone.self.0.id
}
