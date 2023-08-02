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

variable "cluster_name" {
  type = string
}

variable "private_cluster" {
  type = bool
}

variable "instance_type" {
  type = string
}

variable "disk_size" {
  type = number
}

variable "tags" {
  type = map(string)
}
