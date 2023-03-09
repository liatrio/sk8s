module "network" {
  source             = "./modules/network"

  network_name       = var.network_name
  cidr_block         = var.cidr_block
  availability_zones = var.availability_zones
  subnet_range       = var.subnet_range
  cluster_name       = var.cluster_name
  tags               = var.tags
}

module "eks" {
  source          = "./modules/eks"

  cluster_name    = var.cluster_name
  is_private      = true
  instance_type   = var.instance_type
  disk_size       = var.disk_size
  namespace       = var.namespace
  public_subnets  = module.network.public_subnets
  private_subnets = module.network.private_subnets
  use_fargate     = false
  tags            = var.tags
}
