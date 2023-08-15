data "azurerm_client_config" "self" {}

data "azurerm_resource_group" "self" {
  name = var.resource_group_name
}

resource "azurerm_kubernetes_cluster" "self" {
  name                       = var.cluster_name
  node_resource_group        = "${data.azurerm_resource_group.self.name}-${var.cluster_name}"
  resource_group_name        = data.azurerm_resource_group.self.name
  location                   = data.azurerm_resource_group.self.location
  private_cluster_enabled    = var.private_cluster
  dns_prefix                 = var.identity.assignment == "SystemAssigned" ? var.cluster_name : null
  dns_prefix_private_cluster = var.identity.assignment == "SystemAssigned" ? null : var.cluster_name
  private_dns_zone_id        = var.identity.assignment == "SystemAssigned" ? null : var.private_zone_id

  default_node_pool {
    name                   = "hot"
    vnet_subnet_id         = var.network.subnet_id
    vm_size                = var.default_node_pool.node_size
    enable_auto_scaling    = var.default_node_pool.auto_scaler_profile.enabled
    min_count              = var.default_node_pool.auto_scaler_profile.enabled ? var.default_node_pool.auto_scaler_profile.min_node_count : null
    node_count             = var.default_node_pool.auto_scaler_profile.enabled ? null : var.default_node_pool.node_count
    max_count              = var.default_node_pool.auto_scaler_profile.enabled ? var.default_node_pool.auto_scaler_profile.max_node_count : null
    zones                  = var.default_node_pool.zones
    node_labels            = var.default_node_pool.labels
    # enable_host_encryption = true <- this needs to be enabled at the subscription level first
    tags                   = var.tags
  }

  dynamic "aci_connector_linux" {
    for_each = var.virtual_nodes.enabled ? [1] : []

    content {
      subnet_name = var.virtual_nodes.subnet_name
    }
  }

  dynamic "auto_scaler_profile" {
    for_each = var.default_node_pool.auto_scaler_profile.enabled ? [1] : []

    content {
      expander = var.default_node_pool.auto_scaler_profile.expander
    }
  }

  dynamic "oms_agent" {
    for_each = var.container_insights_enabled ? [1] : []

    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.self.0.id
    }
  }

  identity {
    type         = var.identity.assignment
    identity_ids = var.identity.assignment == "SystemAssigned" ? null : [var.identity.id]
  }

  network_profile {
    network_plugin     = var.network.plugin
    network_policy     = var.network.plugin == "azure" ? "calico" : null
    dns_service_ip     = var.network.dns_service_ip
    outbound_type      = var.network.user_defined_routing ? "userDefinedRouting" : "loadBalancer"
    pod_cidr           = var.network.plugin == "azure" ? null : var.network.pod_cidr
    service_cidr       = var.network.service_cidr
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "self" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.self.id
  vnet_subnet_id        = var.network.subnet_id
  vm_size               = each.value.node_size
  os_type               = each.value.node_os
  enable_auto_scaling   = each.value.auto_scaler_profile.enabled
  min_count             = each.value.auto_scaler_profile.enabled ? each.value.auto_scaler_profile.min_node_count : null
  node_count            = each.value.auto_scaler_profile.enabled ? null : each.value.node_count
  max_count             = each.value.auto_scaler_profile.enabled ? each.value.auto_scaler_profile.max_node_count : null
  zones                 = each.value.zones
  node_labels           = each.value.labels
  # enable_host_encryption = true <- not enabled at the subscription level
  priority              = each.value.priority.spot_enabled ? "Spot" : "Regular"
  spot_max_price        = each.value.priority.spot_enabled ? each.value.priority.spot_price : null
  eviction_policy       = each.value.priority.spot_enabled ? "Delete" : null
  tags                  = var.tags

  lifecycle {
    ignore_changes = [
      node_taints
    ]
  }
}

resource "azurerm_role_assignment" "aci-default-route" {
  count = var.virtual_nodes.enabled ? 1 : 0

  principal_id         = azurerm_kubernetes_cluster.self.aci_connector_linux[0].connector_identity[0].object_id
  role_definition_name = "Network Contributor"
  scope                = "/subscriptions/${data.azurerm_client_config.self.subscription_id}/resourceGroups/${data.azurerm_resource_group.self.name}/providers/Microsoft.Network/virtualNetworks/${var.network.virtual_network_name}/subnets/${var.virtual_nodes.subnet_name}"
}

resource "azurerm_role_assignment" "aci-custom-route" {
  count = var.network.user_defined_routing && var.virtual_nodes.enabled ? 1 : 0

  principal_id         = azurerm_kubernetes_cluster.self.aci_connector_linux[0].connector_identity[0].object_id
  role_definition_name = "Network Contributor"
  scope                = "/subscriptions/${data.azurerm_client_config.self.subscription_id}/resourceGroups/${data.azurerm_resource_group.self.name}/providers/Microsoft.Network/virtualNetworks/${var.network.virtual_network_name}"
}

resource "azurerm_log_analytics_workspace" "self" {
  count = var.container_insights_enabled ? 1 : 0

  name                = "${data.azurerm_resource_group.self.name}-logs"
  resource_group_name = data.azurerm_resource_group.self.name
  location            = data.azurerm_resource_group.self.location
  sku                 = "PerGB2018"
  tags                = var.tags
}

resource "azurerm_log_analytics_solution" "self" {
  count = var.container_insights_enabled ? 1 : 0

  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.self.0.location
  resource_group_name   = data.azurerm_resource_group.self.name
  workspace_resource_id = azurerm_log_analytics_workspace.self.0.id
  workspace_name        = azurerm_log_analytics_workspace.self.0.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "self" {
  count = var.container_insights_enabled ? 1 : 0

  name                       = "AKS Control Plane Logging"
  target_resource_id         = azurerm_kubernetes_cluster.self.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.self.0.id

  enabled_log {
    category = "cloud-controller-manager"

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  enabled_log {
    category = "cluster-autoscaler"

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  enabled_log {
    category = "csi-azuredisk-controller"

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  enabled_log {
    category = "csi-azurefile-controller"

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  enabled_log {
    category = "csi-snapshot-controller"

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  enabled_log {
    category = "kube-apiserver"

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  enabled_log {
    category = "kube-controller-manager"

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  enabled_log {
    category = "kube-scheduler"

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false

    retention_policy {
      enabled = false
      days    = 0
    }
  }
}
