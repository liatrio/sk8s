data "azurerm_client_config" "self" {}

data "azurerm_resource_group" "self" {
  name = var.resource_group_name
}

resource "azurerm_public_ip" "self" {
  count = var.vpn-gateway != null ? 1 : 0

  name                = "${var.vpn-gateway.name}-pip"
  location            = data.azurerm_resource_group.self.location
  resource_group_name = data.azurerm_resource_group.self.name
  allocation_method   = "Dynamic"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "self" {
  count = var.vpn-gateway != null ? 1 : 0

  name                = var.vpn-gateway.name
  location            = data.azurerm_resource_group.self.location
  resource_group_name = data.azurerm_resource_group.self.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "VpnGw1"
  tags                = var.tags

  ip_configuration {
    name                          = "${var.vpn-gateway.name}-config"
    public_ip_address_id          = azurerm_public_ip.self[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.network.subnet_id
  }

  vpn_client_configuration {
    address_space        = [ var.vpn-gateway.address_space ]
    vpn_client_protocols = [ "OpenVPN" ]
    vpn_auth_types       = [ "AAD" ]
    aad_tenant           = "https://login.microsoftonline.com/${var.vpn-gateway.tenant_id}/"
    aad_audience         = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
    aad_issuer           = "https://sts.windows.net/${var.vpn-gateway.tenant_id}/"

  }
}