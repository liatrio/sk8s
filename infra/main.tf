module "network" {
  source              = "./modules/network"

  network_name        = var.network_name
  cidr_block          = var.cidr_block
  availability_zones  = var.availability_zones
  subnet_range        = var.subnet_range
  cluster_name        = var.cluster_name
  tags                = var.tags
}

module "registry" {
  source  = "./modules/registry"

  name    = var.app_name
  tags    = var.tags
}

module "eks_fargate" {
  source          = "./modules/eks-fargate"

  cluster_name    = var.cluster_name
  namespace       = var.namespace
  subnets         = concat(module.network.public_subnets, module.network.private_subnets)
  private_subnets = module.network.private_subnets
  tags            = var.tags
}

# module "bootstrap" {
#   source            = "./modules/bootstrap"

#   cluster_name      = module.eks_fargate.cluster_name
#   cluster_endpoint  = module.eks_fargate.cluster_endpoint
#   cluster_ca_cert   = module.eks_fargate.cluster_ca_cert
#   vpc_id            = module.network.vpc_id
#   alb_iam_role      = module.eks_fargate.iam_role_arn
# }
