output "app_bucket_name" {
  description = "App data S3 bucket name"
  value       = aws_s3_bucket.app_data.id
}

output "app_bucket_arn" {
  description = "App data S3 bucket ARN"
  value       = aws_s3_bucket.app_data.arn
}

output "uploads_bucket_name" {
  description = "Uploads S3 bucket name"
  value       = aws_s3_bucket.uploads.id
}

output "logs_bucket_arn" {
  description = "Logs S3 bucket ARN"
  value       = aws_s3_bucket.logs.arn
}

output "logs_bucket_name" {
  description = "Logs S3 bucket name"
  value       = aws_s3_bucket.logs.id
}

output "backups_bucket_name" {
  description = "Backups S3 bucket name (compliant)"
  value       = aws_s3_bucket.backups.id
}
