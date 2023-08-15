variable "cluster_name" {
  type        = string
  description = "Name of Azure Container Registry."

  validation {
    condition     = can(regex("^[a-zA-Z0-9]+[a-zA-Z0-9-_]+[a-zA-Z0-9]$", var.cluster_name)) && length(var.cluster_name) <= 50
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

variable "private_cluster" {
  type        = bool
  description = "Determine whether aks cluster will be private or public"
  default     = true
}

variable "private_zone_id" {
  type        = string
  description = "ID of private DNS zone for looking up container registry private endpoint."
}

variable "network" {
  type = object({
    virtual_network_name = string
    subnet_id            = string
    user_defined_routing = optional(bool, false)
    dns_service_ip       = string
    docker_bridge_cidr   = string
    plugin               = string
    pod_cidr             = optional(string)
    service_cidr         = string
  })
}

variable "default_node_pool" {
  type = object({
    auto_scaler_profile = object({
      enabled        = optional(bool, true)
      expander       = optional(string, "random")
      max_node_count = optional(number, 3)
      min_node_count = optional(number, 1)
    })
    node_count = optional(number, 3)
    node_size  = optional(string, "Standard_D2s_v3")
    zones      = optional(list(string), ["1", "2", "3"])
    labels     = optional(map(string), {})
  })
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
    zones  = optional(list(string), ["1", "2", "3"])
    labels = optional(map(string), {})
  }))
  default = {}
}

variable "virtual_nodes" {
  type = object({
    enabled     = bool
    subnet_name = optional(string)
  })
  default = {
    enabled = false
  }
}

variable "identity" {
  type = object({
    assignment  = string
    id          = optional(string)
  })
}

variable "container_insights_enabled" {
  type    = bool
  default = false
}

variable "tags" {
  type = map(string)
  default = {}
}
