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

variable "enable_config_recorder" {
  description = "Enable AWS Config recorder"
  type        = bool
  default     = true
}

variable "config_log_bucket_name" {
  description = "S3 bucket name for AWS Config logs"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of SNS topic for Config rule violation notifications"
  type        = string
  default     = ""
}

variable "config_rules_enabled" {
  description = "Map of config rules to enable"
  type = object({
    s3_bucket_public_read_prohibited  = bool
    s3_bucket_public_write_prohibited = bool
    s3_bucket_ssl_requests_only       = bool
    encrypted_volumes                 = bool
    iam_password_policy               = bool
    root_account_mfa_enabled          = bool
    iam_user_no_policies_check        = bool
    access_keys_rotated               = bool
    vpc_flow_logs_enabled             = bool
    incoming_ssh_disabled             = bool # HIGH-005 addition
    restricted_incoming_traffic       = bool # HIGH-005 addition
    vpc_default_security_group_closed = bool # HIGH-005 addition
  })
  default = {
    s3_bucket_public_read_prohibited  = true
    s3_bucket_public_write_prohibited = true
    s3_bucket_ssl_requests_only       = true
    encrypted_volumes                 = true
    iam_password_policy               = true
    root_account_mfa_enabled          = true
    iam_user_no_policies_check        = true
    access_keys_rotated               = true
    vpc_flow_logs_enabled             = true
    incoming_ssh_disabled             = true # HIGH-005 addition
    restricted_incoming_traffic       = true # HIGH-005 addition
    vpc_default_security_group_closed = true # HIGH-005 addition
  }
}

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty threat detection (HIGH-004)"
  type        = bool
  default     = true
}

variable "access_key_max_age_days" {
  description = "Maximum age in days for access keys before they are considered non-compliant"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
