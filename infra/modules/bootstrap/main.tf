provider "kubectl" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_cert)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

resource "kubectl_manifest" "self" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: ${var.alb_iam_role}
YAML
}

data "kustomization" "self" {
  path = "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
}

resource "kustomization_resource" "self" {
  for_each = data.kustomization.self.ids

  manifest = data.kustomization.self.manifests[each.value]
}

data "aws_region" "current" { }

resource "helm_release" "self" {
  depends_on = [kustomization_resource.self]

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  namespace = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "region"
    value = data.aws_region.current.name
  }
  set {
    name  = "vpcId"
    value =  var.vpc_id
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}
