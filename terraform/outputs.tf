output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "eks_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.compute.eks_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.compute.eks_cluster_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.rds_endpoint
}

output "app_bucket_name" {
  description = "S3 bucket for application data"
  value       = module.storage.app_bucket_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for API service"
  value       = module.compute.ecr_repository_url
}
