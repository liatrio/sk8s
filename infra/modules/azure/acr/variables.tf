variable "container_registry_name" {
  type        = string
  description = "Name of Azure Container Registry."

  validation {
    condition     = can(regex("^[a-zA-Z0-9]*$", var.container_registry_name)) && length(var.container_registry_name) <= 50
    error_message = "Container registry name can only contain alphanumeric characters."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of Azure resource group in which DNS zone resides."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_.()]*[a-zA-Z0-9-_()]$", var.resource_group_name)) && length(var.resource_group_name) <= 24
    error_message = "Resource group name breaks with Azure's naming conventions."
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for attaching private endpoint."
}

variable "private_zone_id" {
  type        = string
  description = "ID of private DNS zone for looking up container registry private endpoint."
}
