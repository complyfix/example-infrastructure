output "eks_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_ca_cert" {
  description = "EKS cluster CA certificate"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "eks_token" {
  description = "EKS auth token"
  value       = data.aws_eks_cluster_auth.main.token
  sensitive   = true
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.api.repository_url
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}
