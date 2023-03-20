variable "cluster_name" {
  type       = string
  description = "The name of the EKS cluster to create."
}

variable "is_private" {
  type        = bool
  description = "Whether or not the Kubernetes API server endpoint should be private."
}

variable "private_subnets" {
  type        = list(string)
  description = "The private subnets in which to deploy the worker nodes."
}

variable "public_subnets" {
  type        = list(string)
  description = "The public subnets assigned to the EKS cluster for routing application traffic to the Internet."
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type to use when deploying a managed node group."

  default     = "t3.medium"
}

variable "disk_size" {
  type        = number
  description = "The disk size in GiB for worker nodes."

  default     = 20
}

variable "use_fargate" {
  type        = bool
  description = "Whether or not to leverage Fargate for running pods."
}

variable "namespace" {
  type        = string
  description = "The default Kubernetes namespace in which to deploy pods (only applies to Fargate)."

  default     = "primary"
}

variable "tags" {
  type        = map(string)
  description = "The tags applied to EKS cluster resources."
}

/*
 * This is a hack to get the prefix length of the private subnets so that we can determine the maximum number of worker
 * nodes that can be deployed to the cluster.
 */
data "aws_subnet" "private" {
  id = var.private_subnets[0]
}

data "aws_ec2_instance_type" "self" {
  instance_type = var.instance_type
}

locals {
  subnets       = concat(var.private_subnets, var.public_subnets)
  available_ips = data.aws_ec2_instance_type.self.maximum_network_interfaces * data.aws_ec2_instance_type.self.maximum_ipv4_addresses_per_interface
  prefix        = tonumber(split("/", data.aws_subnet.private.cidr_block)[1])
  // The desired node count is the same as min_nodes; each private subnet initially hosts a single worker node.
  min_nodes     = length(var.private_subnets)
  max_nodes     = floor(length(var.private_subnets) * (pow(2, 32 - local.prefix) - 6) / local.available_ips)
}
