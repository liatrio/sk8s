variable "resource_group_name" {
  type        = string
  description = "Name of Azure resource group in which to create the network."
}

variable "network_name" {
  type        = string
  description = "Name of virtual network."
}

variable "address_space" {
  type        = string
  description = ""
}

variable "private_cluster" {
  type        = bool
  description = "Determine whether aks cluster will be private or public"
  default     = true
}

variable "default_node_pool" {
  type = object({
    auto_scaler_profile = object({
      enabled        = bool
      expander       = optional(string, "random")
      max_node_count = optional(number, 3)
      min_node_count = optional(number, 1)
    })
    node_count = optional(number, 3)
    node_size  = string
    zones      = optional(list(string))
  })
  description = "Default node pool configuration"

  default = {
    auto_scaler_profile = {
      enabled        = true
      max_node_count = 9
      min_node_count = 3
    }
    node_size = "Standard_D2s_v3"
    zones     = ["1", "2", "3"]
  }
}

variable "additional_node_pools" {
  type = map(object({
    auto_scaler_profile = object({
      enabled        = bool
      max_node_count = optional(number, 3)
      min_node_count = optional(number, 1)
    })
    node_count = optional(number, 3)
    node_size  = optional(string, "Standard_D2s_v3")
    node_os    = optional(string, "Linux")
    priority   = object({
      spot_enabled = bool
      spot_price   = optional(number, -1)
    })
    zones = optional(list(string), ["1", "2", "3"])
  }))
  description = "Additional node pools to create"

  default = {}
}

variable "system_managed_dns"{
  type        = bool
  description = "Determine if dns zone is managed by system"

  default = true
}

variable "subnets" {
  type = list(object({
    name           = string
    address_prefix = string
    attributes     = object({
       routing     = string
       managed     = bool
       services    = list(string)
    })
  }))
  description = "List of subnets to create in the virtual network."
}

variable "peering_connection" {
  type = object({
    virtual_network_name = string
    subnet_name          = string
    resource_group       = string
  })
  description = "Virtual network to peer with."

  default = null
}

variable "firewall" {
  type = object({
    name           = string
    resource_group = string
  })
  description = "Firewall to use for outbound traffic."

  default = null
}

variable "network_rules" {
  type = list(object({
      name                  = string
      protocols             = list(string)
      source_addresses      = list(string)
      destination_addresses = list(string)
      destination_ports     = list(string)
  }))
  description = "List of network rules to be passed into the firewall policy"

  default = null
}

variable "application_rules" {
  type = list(object({
    name              = string
    source_addresses  = list(string)
    destination_fqdns = list(string)
    protocols         = object({
      port = string
      type = string
    })
  }))
  description = "List of application rules to be passed into the firewall policy"

  default = null
}

variable "vpn-gateway" {
    type = object({
      name          = string
      address_space = string
      tenant_id     = string
    })
    description = "Vpn-gateway configuration to connect to the cluster"

    default = null
}

variable "tags" {
  type = map(string)
}
