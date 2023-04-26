output "virtual_network_name" {
  value = azurerm_virtual_network.self.name
}

output "subnets" {
  value = {
    for subnet in azurerm_subnet.self: subnet.name => {
      id               = subnet.id
      address_prefixes = subnet.address_prefixes
    }
  }
}
