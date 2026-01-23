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

# Password Policy
variable "password_max_age" {
  description = "Maximum age of password in days"
  type        = number
  default     = 90
}

variable "password_minimum_length" {
  description = "Minimum password length"
  type        = number
  default     = 14
}

variable "password_reuse_prevention" {
  description = "Number of previous passwords to prevent reuse"
  type        = number
  default     = 24
}

variable "password_require_lowercase" {
  description = "Require lowercase characters"
  type        = bool
  default     = true
}

variable "password_require_uppercase" {
  description = "Require uppercase characters"
  type        = bool
  default     = true
}

variable "password_require_numbers" {
  description = "Require numeric characters"
  type        = bool
  default     = true
}

variable "password_require_symbols" {
  description = "Require special characters"
  type        = bool
  default     = true
}

# Break-Glass Role
variable "enable_break_glass_role" {
  description = "Create break-glass emergency access role"
  type        = bool
  default     = true
}

variable "break_glass_trusted_principals" {
  description = "List of IAM ARNs allowed to assume break-glass role"
  type        = list(string)
  default     = []
}

variable "break_glass_require_mfa" {
  description = "Require MFA to assume break-glass role"
  type        = bool
  default     = true
}

variable "break_glass_max_session_duration" {
  description = "Maximum session duration for break-glass role in seconds"
  type        = number
  default     = 3600 # 1 hour

  validation {
    condition     = var.break_glass_max_session_duration >= 3600 && var.break_glass_max_session_duration <= 43200
    error_message = "Session duration must be between 3600 (1h) and 43200 (12h) seconds."
  }
}

# Alerts
variable "sns_topic_arn" {
  description = "ARN of SNS topic for break-glass usage alerts"
  type        = string
  default     = ""
}

variable "cloudwatch_log_group_name" {
  description = "Name of CloudTrail CloudWatch Log Group for metric filters"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
