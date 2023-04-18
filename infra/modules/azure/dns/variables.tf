variable "domain_name" {
  type        = string
  description = "Domain name suffix of public/private DNS zone."

  validation {
    condition     = can(regex("^([a-z0-9][a-z0-9-_]{0,62}\\.)+([a-z]{2,6})$", var.domain_name))
    error_message = "Domain name syntax must follow specification in RFC 1035."
  }
}

variable "is_public" {
  type        = bool
  description = "Whether the DNS zone is public or private."

  default = false
}

variable "resource_group_name" {
  type        = string
  description = "Name of Azure resource group in which DNS zone resides."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_.()]*[a-zA-Z0-9-_()]$", var.resource_group_name)) && length(var.resource_group_name) <= 24
    error_message = "Resource group name breaks with Azure's naming conventions."
  }
}
