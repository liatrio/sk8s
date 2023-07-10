output "route_table_id" {
  value = var.firewall == null ? null : azurerm_subnet_route_table_association.self[0].id
}