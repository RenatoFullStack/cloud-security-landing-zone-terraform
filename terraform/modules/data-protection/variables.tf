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

variable "kms_key_deletion_window" {
  description = "Duration in days before KMS key is deleted after destruction (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "enable_key_rotation" {
  description = "Enable automatic annual rotation of KMS key"
  type        = bool
  default     = true
}

variable "kms_key_administrators" {
  description = "List of IAM ARNs that can administer the KMS key"
  type        = list(string)
  default     = []
}

variable "kms_key_users" {
  description = "List of IAM ARNs that can use the KMS key for encryption/decryption"
  type        = list(string)
  default     = []
}

variable "enable_s3_account_public_access_block" {
  description = "Enable S3 account-level public access block"
  type        = bool
  default     = true
}

variable "enable_ebs_default_encryption" {
  description = "Enable EBS default encryption at account level"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
