output "app_full_access_policy_arn" {
  description = "ARN of the (overly permissive) app full access policy"
  value       = aws_iam_policy.app_full_access.arn
}

output "app_readonly_policy_arn" {
  description = "ARN of the read-only policy"
  value       = aws_iam_policy.app_readonly.arn
}

output "alerts_topic_arn" {
  description = "SNS alerts topic ARN"
  value       = aws_sns_topic.alerts.arn
}

output "app_log_group" {
  description = "Application CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}
