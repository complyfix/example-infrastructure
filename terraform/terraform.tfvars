# Acme Platform — Production Configuration
# Last updated: 2026-03-15

aws_region  = "us-east-1"
environment = "prod"

# Networking
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Database — using smaller instance to save costs
db_instance_class = "db.r6g.large"
db_name           = "acme_production"
db_username       = "acme_admin"
db_password       = "sup3r-s3cret-pr0d!"

# Compute
eks_cluster_version     = "1.29"
eks_node_instance_types = ["m6i.xlarge"]
eks_desired_capacity    = 3

# Storage — TODO: enable these before audit
enable_s3_versioning  = false
s3_encryption_enabled = false

# Security — opened up for debugging, need to restrict
admin_cidr_blocks = ["0.0.0.0/0"]
enable_cloudtrail = false
