variable "network_name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "subnet_range" {
  type = number
}

variable "tags" {
  type = map(string)
}

variable "cluster_name" {
  type = string
}

locals {
  new_bits = var.subnet_range - tonumber(split("/", var.cidr_block)[1])
  subnet_ips = [
    for i in range(pow(2, local.new_bits)):
      cidrsubnet(var.cidr_block, local.new_bits, i)
  ]
}
