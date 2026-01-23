variable "environment" {
  description = "Environment name (shared, nonprod, prod)"
  type        = string

  validation {
    condition     = contains(["shared", "nonprod", "prod"], var.environment)
    error_message = "Environment must be one of: shared, nonprod, prod."
  }
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "lz"
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encrypting logs"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 365

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention value."
  }
}

variable "s3_log_retention_days" {
  description = "Number of days to retain S3 logs before transitioning to Glacier"
  type        = number
  default     = 90
}

variable "s3_log_glacier_days" {
  description = "Number of days before transitioning logs to Glacier Deep Archive"
  type        = number
  default     = 365
}

variable "s3_log_expiration_days" {
  description = "Number of days before deleting logs from S3"
  type        = number
  default     = 2555 # ~7 years for compliance
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail logging"
  type        = bool
  default     = true
}

variable "cloudtrail_is_multi_region" {
  description = "Enable CloudTrail for all regions"
  type        = bool
  default     = true
}

variable "enable_log_file_validation" {
  description = "Enable CloudTrail log file integrity validation"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for security alerts (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
