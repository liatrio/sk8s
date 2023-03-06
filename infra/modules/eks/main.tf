resource "aws_eks_cluster" "self" {
  name      = var.cluster_name
  role_arn  = aws_iam_role.eks_cluster_role.arn
  tags      = var.tags

  vpc_config {
    endpoint_private_access = var.is_private_cluster
    endpoint_public_access  = !var.is_private_cluster
    subnet_ids              = local.subnets
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_iam_role" "eks_cluster_role" {
  name                = "${upper(var.tags["Environment"])}EKSClusterRole"
  assume_role_policy  = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "node_group" {
  name = "eks-node-group-example"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_eks_node_group" "self" {
  count           = var.use_fargate ? 0 : 1
  cluster_name    = aws_eks_cluster.self.name
  node_group_name = "${var.cluster_name}-primary"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = local.subnets

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_eks_fargate_profile" "coredns" {
  count                   = var.use_fargate ? 1 : 0
  cluster_name            = aws_eks_cluster.self.name
  fargate_profile_name    = "coredns"
  pod_execution_role_arn  = aws_iam_role.eks_pod_execution_role.0.arn
  subnet_ids              = var.private_subnets
  tags                    = var.tags

  selector {
    namespace = "kube-system"
  }
}

resource "aws_eks_fargate_profile" "self" {
  count                   = var.use_fargate ? 1 : 0
  cluster_name            = aws_eks_cluster.self.name
  fargate_profile_name    = var.namespace
  pod_execution_role_arn  = aws_iam_role.eks_pod_execution_role.0.arn
  subnet_ids              = var.private_subnets
  tags                    = var.tags

  selector {
    namespace = var.namespace
  }
}

resource "aws_iam_role" "eks_pod_execution_role" {
  count              = var.use_fargate ? 1 : 0
  name               = "${upper(var.tags["Environment"])}EKSPodExecutionRole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_pod_execution_policy" {
  count      = var.use_fargate ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_pod_execution_role.0.name
}

data "tls_certificate" "self" {
  url = aws_eks_cluster.self.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "self" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.self.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.self.identity.0.oidc.0.issuer
}

data "aws_iam_policy_document" "alb" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.self.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.self.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "alb" {
  name    = "${upper(var.tags["Environment"])}AWSLoadBalancerControllerIAMPolicy"
  policy  = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role" "alb" {
  assume_role_policy = data.aws_iam_policy_document.alb.json
  name               = "${upper(var.tags["Environment"])}ALBIngressControllerServiceAccountRole"
}

resource "aws_iam_role_policy_attachment" "alb" {
  policy_arn = aws_iam_policy.alb.arn
  role       = aws_iam_role.alb.id
}

# data "aws_region" "current" { }

# resource "null_resource" "coredns" {
#   provisioner "local-exec" {
#     command = <<EOH
# aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${aws_eks_cluster.self.name} && \
# kubectl patch deployment coredns -n kube-system --type json \
#   -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
# EOH
#   }

#   depends_on = [aws_eks_fargate_profile.coredns]
# }
