variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail logging"
  type        = bool
  default     = true
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for CloudTrail logs"
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name for log group naming"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
