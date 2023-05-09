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

variable "subnets" {
  type        = list(object({
    name           = string
    address_prefix = string
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

variable "tags" {
  type = map(string)
}
