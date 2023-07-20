/* 
 * The EKS cluster to be created. This resource only spins up the components that make up the control plane, and are
 * responsible for managing the lifecycle of worker nodes and scheduling pods on them. The worker nodes themselves
 * are deployed separately and registered to this EKS cluster.
 */
resource "aws_eks_cluster" "self" {
  name      = var.cluster_name
  role_arn  = aws_iam_role.eks_cluster_role.arn
  tags      = var.tags

  vpc_config {
    endpoint_private_access = var.is_private
    endpoint_public_access  = !var.is_private
    subnet_ids              = local.subnets
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_iam_role" "eks_cluster_role" {
  name                = "${var.tags["Project"]}EKSClusterRole"
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

/*
 * These policies are required for EKS to, among other things, register instances to the cluster, enable communication
 * between the worker nodes and the Kubernetes control plane, provision Elastc Load Balancers, and permit shipment of
 * cluster logs to CloudWatch.
 */
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "node_group" {
  name = "${var.tags["Project"]}ManagedNodeGroupRole"

  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

/*
 * Standard policies required for worker nodes to identify themselves when joining the cluster, create elastic network
 * interfaces, and allocate IP addresses to pods pulled down from ECR.
 */
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
  node_group_name = "${var.cluster_name}-workers"
  subnet_ids      = var.private_subnets
  node_role_arn   = aws_iam_role.node_group.arn
  instance_types  = [var.instance_type]
  disk_size       = var.disk_size
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = local.min_nodes
    min_size     = local.min_nodes
    max_size     = local.max_nodes
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

/*
 * The OICD provider is required to grant IAM permissions allowing the EKS cluster to autoscale, and to deploy the ALB
 * ingress controller for ingress-based load balancing when using Fargate.
 */
data "tls_certificate" "self" {
  url = aws_eks_cluster.self.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "self" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.self.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.self.identity.0.oidc.0.issuer
}

data "aws_iam_policy_document" "autoscaler" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.self.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:autoscaler-aws-cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.self.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "autoscaler" {
  name = "${var.tags["Project"]}EKSClusterAutoscalerIAMPolicy"
  policy = jsonencode({
    Statement = [{
      Action    = [
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:DescribeTags",
        "ec2:DescribeLaunchTemplateVersions"
      ]
      Effect    = "Allow"
      Resource  = "*"
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role" "autoscaler" {
  assume_role_policy = data.aws_iam_policy_document.autoscaler.json
  name               = "${var.tags["Project"]}EKSClusterAutoscalerServiceAccountRole"
}

resource "aws_iam_role_policy_attachment" "autoscaler" {
  policy_arn = aws_iam_policy.autoscaler.arn
  role       = aws_iam_role.autoscaler.id
}

/*
 * Everything below this comment block strictly applies to EKS clusters that use Fargate.
 */

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
  name               = "${var.tags["Project"]}EKSPodExecutionRole"

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
  name    = "${var.tags["Project"]}AWSLoadBalancerControllerIAMPolicy"
  policy  = file("${path.module}/iam_policies/ingress_controller_policy.json")
}

resource "aws_iam_role" "alb" {
  assume_role_policy = data.aws_iam_policy_document.alb.json
  name               = "${var.tags["Project"]}ALBIngressControllerServiceAccountRole"
}

resource "aws_iam_role_policy_attachment" "alb" {
  policy_arn = aws_iam_policy.alb.arn
  role       = aws_iam_role.alb.id
}

data "aws_region" "current" { }

/*
 * CoreDNS expects to run on EC2 instances, so we must patch the deployment to remove the annotation. See:
 * https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1286.
 */
resource "null_resource" "coredns" {
  // This only works if we can reach the Kubernetes API server over the command line. If this runs as part of a CI/CD
  // pipeline then we may not need additional check, but we have to assume that this could be run locally.
  count = !var.is_private && var.use_fargate ? 1 : 0
  provisioner "local-exec" {
    command = <<EOH
aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${aws_eks_cluster.self.name} && \
kubectl patch deployment coredns -n kube-system --type json \
  -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
EOH
  }

  depends_on = [aws_eks_fargate_profile.coredns]
}
