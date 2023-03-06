variable "network_name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_network" {
  type = bool
}

variable "subnet_range" {
  type = number
}

variable "cluster_name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "app_name" {
  type = string
}

variable "tags" {
  type = map(string)
}
