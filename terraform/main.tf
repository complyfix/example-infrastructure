# Acme Platform — Production Infrastructure
#
# Architecture: VPC → EKS + RDS + S3 + supporting services
# Team: Platform Engineering (3 engineers)
# Last major change: Added Lambda processors (2026-02)

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Team        = "platform"
  }

  name_prefix = "${var.project_name}-${var.environment}"
}

# ──────────────────────────────────────────────
# Networking — VPC, subnets, security groups
# ──────────────────────────────────────────────

module "networking" {
  source = "./modules/networking"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
  project_name       = var.project_name
  admin_cidr_blocks  = var.admin_cidr_blocks

  tags = local.common_tags
}

# ──────────────────────────────────────────────
# Storage — S3 buckets, EBS volumes
# ──────────────────────────────────────────────

module "storage" {
  source = "./modules/storage"

  environment        = var.environment
  project_name       = var.project_name
  enable_versioning  = var.enable_s3_versioning
  encryption_enabled = var.s3_encryption_enabled

  tags = local.common_tags
}

# ──────────────────────────────────────────────
# Database — RDS PostgreSQL, DynamoDB
# ──────────────────────────────────────────────

module "database" {
  source = "./modules/database"

  environment     = var.environment
  project_name    = var.project_name
  vpc_id          = module.networking.vpc_id
  subnet_ids      = module.networking.private_subnet_ids
  db_sg_id        = module.networking.database_sg_id
  instance_class  = var.db_instance_class
  db_name         = var.db_name
  db_username     = var.db_username
  db_password     = var.db_password

  tags = local.common_tags
}

# ──────────────────────────────────────────────
# Compute — EKS cluster, Lambda, ECR
# ──────────────────────────────────────────────

module "compute" {
  source = "./modules/compute"

  environment         = var.environment
  project_name        = var.project_name
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  cluster_version     = var.eks_cluster_version
  node_instance_types = var.eks_node_instance_types
  desired_capacity    = var.eks_desired_capacity

  tags = local.common_tags
}

# ──────────────────────────────────────────────
# Security — IAM, CloudTrail, monitoring
# ──────────────────────────────────────────────

module "security" {
  source = "./modules/security"

  environment      = var.environment
  project_name     = var.project_name
  enable_cloudtrail = var.enable_cloudtrail
  s3_bucket_arn    = module.storage.logs_bucket_arn
  eks_cluster_name = module.compute.eks_cluster_name

  tags = local.common_tags
}
