variable "network_name" {
  type        = string
  description = "The name of the VPC to create."
}

variable "cidr_block" {
  type        = string
  description = "The IP address space of the virtual private network."
}

variable "availability_zones" {
  type        = list(string)
  description = "The list of Availability Zones in which to deploy."
}

variable "subnet_range" {
  type        = number
  description = "Subnet prefix to calculate the total number of public and private subnets to create."
}

variable "tags" {
  type        = map(string)
  description = "The tags used to identify network resources."
}

variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster (for automatic subnet discovery)."
}

locals {
  new_bits   = var.subnet_range - tonumber(split("/", var.cidr_block)[1])
  subnet_ips = [
    for i in range(pow(2, local.new_bits)):
      cidrsubnet(var.cidr_block, local.new_bits, i)
  ]
}
