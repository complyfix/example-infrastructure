# Security Module — IAM, CloudTrail, CloudWatch, SNS
#
# VIOLATIONS IN THIS FILE:
# - IAM policy too permissive *:* (CKV_AWS_1)
# - CloudTrail disabled (CKV_AWS_35)
# - MFA not enforced (CKV_AWS_79)
# - CloudWatch no retention (CKV_AWS_66)
# - SNS not encrypted (CKV_AWS_26)
#
# COMPLIANT: read-only role is properly scoped

# ──────────────────────────────────────────────
# IAM — Application Roles
# ──────────────────────────────────────────────

# VIOLATION: IAM policy too permissive — uses *:* (CKV_AWS_1)
# "Give me admin so I can debug" — never got restricted
resource "aws_iam_policy" "app_full_access" {
  name        = "${var.project_name}-${var.environment}-app-full-access"
  description = "Full access for application services — needs to be scoped down"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "FullAccess"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# COMPLIANT: Read-only role is properly scoped
resource "aws_iam_policy" "app_readonly" {
  name        = "${var.project_name}-${var.environment}-app-readonly"
  description = "Read-only access for monitoring services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadOnly"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      },
      {
        Sid    = "DynamoDBReadOnly"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/${var.project_name}-*"
      },
      {
        Sid    = "CloudWatchReadOnly"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "logs:GetLogEvents",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# VIOLATION: No MFA enforcement policy (CKV_AWS_79)
resource "aws_iam_group" "developers" {
  name = "${var.project_name}-developers"
}

resource "aws_iam_group_policy_attachment" "developers_access" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.app_full_access.arn
}

# ──────────────────────────────────────────────
# CloudTrail — VIOLATION: Disabled via variable
# ──────────────────────────────────────────────

# VIOLATION: CloudTrail not enabled (CKV_AWS_35)
# var.enable_cloudtrail is false in terraform.tfvars
resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0

  name                       = "${var.project_name}-${var.environment}-trail"
  s3_bucket_name             = var.s3_bucket_arn
  include_global_service_events = true
  is_multi_region_trail      = true
  enable_log_file_validation = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-cloudtrail"
  })
}

# ──────────────────────────────────────────────
# CloudWatch — Log Groups
# ──────────────────────────────────────────────

# VIOLATION: No retention period set (CKV_AWS_66)
resource "aws_cloudwatch_log_group" "app" {
  name = "/ecs/${var.project_name}/${var.environment}/app"

  # VIOLATION: retention_in_days not set — logs kept indefinitely
  # retention_in_days = 365

  tags = merge(var.tags, {
    Name = "${var.project_name}-app-logs"
  })
}

# VIOLATION: No retention period set (CKV_AWS_66)
resource "aws_cloudwatch_log_group" "eks" {
  name = "/eks/${var.eks_cluster_name}/cluster"

  # VIOLATION: retention_in_days not set
  # retention_in_days = 365

  tags = merge(var.tags, {
    Name = "${var.project_name}-eks-logs"
  })
}

# COMPLIANT: Lambda logs have retention set
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-event-processor"
  retention_in_days = 90

  tags = merge(var.tags, {
    Name = "${var.project_name}-lambda-logs"
  })
}

# ──────────────────────────────────────────────
# SNS — Alerting
# ──────────────────────────────────────────────

# VIOLATION: SNS topic not encrypted (CKV_AWS_26)
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  # VIOLATION: Missing kms_master_key_id
  # kms_master_key_id = aws_kms_key.sns.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-alerts"
  })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "team@example.com"
}

# ──────────────────────────────────────────────
# CloudWatch Alarms
# ──────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = var.tags
}
