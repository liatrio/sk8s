variable "cluster_name" {
  type = string
}

variable "is_private_cluster" {
  type = bool
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "namespace" {
  type = string
}

variable "use_fargate" {
  type = bool
}

variable "tags" {
  type = map(string)
}

locals {
  subnets = var.is_private_cluster ? var.private_subnets : concat(var.private_subnets, var.public_subnets)
}
