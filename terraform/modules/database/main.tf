# Database Module — RDS PostgreSQL, DynamoDB
#
# VIOLATIONS IN THIS FILE:
# - RDS not encrypted at rest (CKV_AWS_16)
# - RDS publicly accessible (CKV_AWS_17)
# - RDS no backup (CKV_AWS_133)
# - RDS no multi-AZ (CKV_AWS_157)
# - DynamoDB no encryption (CKV_AWS_119)
#
# COMPLIANT: RDS read replica is properly configured

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

resource "aws_db_parameter_group" "postgres" {
  name   = "${var.project_name}-${var.environment}-pg16"
  family = "postgres16"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  tags = var.tags
}

# ──────────────────────────────────────────────
# Primary RDS — multiple violations for demo
# ──────────────────────────────────────────────

# VIOLATION: Not encrypted (CKV_AWS_16)
# VIOLATION: Publicly accessible (CKV_AWS_17)
# VIOLATION: No backup (CKV_AWS_133)
# VIOLATION: No multi-AZ (CKV_AWS_157)
resource "aws_db_instance" "primary" {
  identifier = "${var.project_name}-${var.environment}-primary"

  engine               = "postgres"
  engine_version       = "16.2"
  instance_class       = var.instance_class
  allocated_storage    = 100
  max_allocated_storage = 500
  storage_type         = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]
  parameter_group_name   = aws_db_parameter_group.postgres.name

  # VIOLATION: Not encrypted
  storage_encrypted = false

  # VIOLATION: Publicly accessible
  publicly_accessible = false

  # VIOLATION: No backup retention
  backup_retention_period = 0

  # VIOLATION: No multi-AZ
  multi_az = false

  skip_final_snapshot = true

  performance_insights_enabled = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-primary-db"
    Role = "primary"
  })
}

# ──────────────────────────────────────────────
# Read Replica — properly configured (COMPLIANT)
# Shows realistic mixed state
# ──────────────────────────────────────────────

resource "aws_db_instance" "read_replica" {
  identifier = "${var.project_name}-${var.environment}-replica"

  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = "db.r6g.large"

  storage_encrypted   = true
  publicly_accessible = false
  multi_az            = true

  skip_final_snapshot = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-replica-db"
    Role = "read-replica"
  })
}

# ──────────────────────────────────────────────
# DynamoDB — session store
# ──────────────────────────────────────────────

# VIOLATION: No encryption (CKV_AWS_119) — using default AWS owned key
resource "aws_dynamodb_table" "sessions" {
  name         = "${var.project_name}-${var.environment}-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"
  range_key    = "created_at"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  global_secondary_index {
    name            = "user-index"
    hash_key        = "user_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  # VIOLATION: No KMS encryption — uses default
  # server_side_encryption {
  #   enabled     = true
  #   kms_key_arn = aws_kms_key.dynamodb.arn
  # }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-sessions"
  })
}
