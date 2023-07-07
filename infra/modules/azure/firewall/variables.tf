variable "resource_group_name" {
  type        = string
  description = "Name of Azure resource group in which DNS zone resides."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_.()]*[a-zA-Z0-9-_()]$", var.resource_group_name)) && length(var.resource_group_name) <= 24
    error_message = "Resource group name breaks with Azure's naming conventions."
  }
}

variable "association_subnet_id" {
  type        = string
  description = "Subnet id to associate to the route table"
}

variable "network" {
  type = object({
    virtual_network_name = string
    subnet_name          = string
    subnet_id            = string
    managed              = bool
  })
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

variable "firewall" {
  type = object({
    name           = string
    resource_group = string
  })
  description = "Firewall to use for outbound traffic."

  default = null
}