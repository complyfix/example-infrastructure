# Production Environment
# This file calls the root module with prod-specific overrides

module "acme_platform" {
  source = "../../"

  aws_region  = "us-east-1"
  environment = "prod"

  # Network
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  admin_cidr_blocks  = ["0.0.0.0/0"]  # TODO: restrict to VPN

  # Database
  db_instance_class = "db.r6g.xlarge"
  db_name           = "acme_production"
  db_username       = "acme_admin"
  db_password       = var.db_password

  # Compute
  eks_cluster_version     = "1.29"
  eks_node_instance_types = ["m6i.2xlarge"]
  eks_desired_capacity    = 5

  # Storage — still not enabled
  enable_s3_versioning  = false
  s3_encryption_enabled = false

  # Security
  enable_cloudtrail = false
}

variable "db_password" {
  type      = string
  sensitive = true
}
