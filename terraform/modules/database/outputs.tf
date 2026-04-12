output "rds_endpoint" {
  description = "RDS primary endpoint"
  value       = aws_db_instance.primary.endpoint
}

output "rds_replica_endpoint" {
  description = "RDS read replica endpoint"
  value       = aws_db_instance.read_replica.endpoint
}

output "dynamodb_table_name" {
  description = "DynamoDB sessions table name"
  value       = aws_dynamodb_table.sessions.name
}

output "rds_instance_id" {
  description = "RDS primary instance ID"
  value       = aws_db_instance.primary.id
}
