output "zone_id" {
  value = var.system_managed_dns ? null : (var.is_public ? azurerm_dns_zone.self.0.id : azurerm_private_dns_zone.self.0.id)
}
