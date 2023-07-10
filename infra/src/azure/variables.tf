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
