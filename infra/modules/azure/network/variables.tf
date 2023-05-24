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

variable "tags" {
  type = map(string)
}
