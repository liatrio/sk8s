module "network" {
  # TODO: ditch public network
  source              = "./modules/network"

  network_name        = var.network_name
  public_network      = var.public_network
  cidr_block          = var.cidr_block
  availability_zones  = var.availability_zones
  subnet_range        = var.subnet_range
  cluster_name        = var.cluster_name
  tags                = var.tags
}

module "eks" {
  source             = "./modules/eks"

  cluster_name       = var.cluster_name
  is_private_cluster = true
  namespace          = var.namespace
  public_subnets     = module.network.public_subnets
  private_subnets    = module.network.private_subnets
  use_fargate        = false
  tags               = var.tags
}
