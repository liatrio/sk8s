output "cluster_name" {
    value = aws_eks_cluster.self.name
}

output "cluster_endpoint" {
    value = aws_eks_cluster.self.endpoint
}

output "cluster_ca_cert" {
    value = aws_eks_cluster.self.certificate_authority.0.data
}
