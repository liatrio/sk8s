variable "cluster_name" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "namespace" {
  type = string
}

variable "tags" {
  type = map(string)
}
