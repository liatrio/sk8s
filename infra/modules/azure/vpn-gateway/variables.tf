variable "resource_group_name" {
  type        = string
  description = "Name of Azure resource group in which to create the network."
}

#variable "address_space" {
#  type        = string
#  description = "The CIDR block of the virtual network."
#}

variable "vpn-gateway" {
    type = object({
      name          = string
      address_space = string
      tenant_id     = string    
      })
}

variable "network" {
  type = object({
    virtual_network_name = string
    subnet_id            = string
    managed              = bool
  })
}

variable "tags" {
  type = map(string)
}