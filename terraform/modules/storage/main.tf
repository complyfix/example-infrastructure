# Storage Module — S3 Buckets, EBS Volumes
#
# VIOLATIONS IN THIS FILE:
# - S3 no encryption (CKV_AWS_19) — app-data bucket
# - S3 no versioning (CKV_AWS_21) — app-data bucket
# - S3 public access not blocked (CKV_AWS_53/54/55/56) — uploads bucket
# - S3 no access logging (CKV_AWS_18) — app-data bucket
# - EBS not encrypted (CKV_AWS_3) — data volume
#
# COMPLIANT: backup bucket has encryption enabled

# ──────────────────────────────────────────────
# App Data Bucket — stores user uploads, reports
# ──────────────────────────────────────────────

# VIOLATION: No encryption (CKV_AWS_19)
# VIOLATION: No versioning (CKV_AWS_21)
# VIOLATION: No access logging (CKV_AWS_18)
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.project_name}-${var.environment}-app-data"

  tags = merge(var.tags, {
    Name    = "${var.project_name}-app-data"
    Purpose = "Application data storage"
  })
}

# VIOLATION: No server-side encryption configuration
# (Missing aws_s3_bucket_server_side_encryption_configuration resource)

# VIOLATION: No versioning
# (Missing aws_s3_bucket_versioning resource)

# VIOLATION: No access logging
# (Missing aws_s3_bucket_logging resource)

# ──────────────────────────────────────────────
# User Uploads Bucket — avatar images, attachments
# ──────────────────────────────────────────────

resource "aws_s3_bucket" "uploads" {
  bucket = "${var.project_name}-${var.environment}-uploads"

  tags = merge(var.tags, {
    Name    = "${var.project_name}-uploads"
    Purpose = "User file uploads"
  })
}

# VIOLATION: Public access not blocked (CKV_AWS_53, CKV_AWS_54, CKV_AWS_55, CKV_AWS_56)
# Intentionally left open for "easy CDN access" — needs fixing
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ──────────────────────────────────────────────
# Logs Bucket — CloudTrail, access logs destination
# ──────────────────────────────────────────────

resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-${var.environment}-logs"

  tags = merge(var.tags, {
    Name    = "${var.project_name}-logs"
    Purpose = "Centralized logging"
  })
}

# Logs bucket has encryption (this one is compliant)
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────────────────────────────────────
# Backup Bucket — database backups (COMPLIANT)
# ──────────────────────────────────────────────

resource "aws_s3_bucket" "backups" {
  bucket = "${var.project_name}-${var.environment}-backups"

  tags = merge(var.tags, {
    Name    = "${var.project_name}-backups"
    Purpose = "Database and system backups"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "archive-old-backups"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# ──────────────────────────────────────────────
# EBS Volumes — persistent storage for stateful workloads
# ──────────────────────────────────────────────

# VIOLATION: EBS not encrypted (CKV_AWS_3)
resource "aws_ebs_volume" "data" {
  availability_zone = "us-east-1a"
  size              = 100
  type              = "gp3"

  # encrypted = true  # Missing — violation

  tags = merge(var.tags, {
    Name = "${var.project_name}-data-volume"
  })
}
