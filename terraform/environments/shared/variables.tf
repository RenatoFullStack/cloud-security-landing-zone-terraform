variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "lz"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "shared"
}

# Data Protection
variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

# Logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 365
}

variable "s3_log_expiration_days" {
  description = "S3 log expiration in days"
  type        = number
  default     = 2555 # ~7 years
}

variable "alert_email" {
  description = "Email address for security alerts"
  type        = string
  default     = ""
}

# Identity
variable "password_minimum_length" {
  description = "Minimum password length"
  type        = number
  default     = 14
}

variable "break_glass_trusted_principals" {
  description = "IAM ARNs allowed to assume break-glass role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
