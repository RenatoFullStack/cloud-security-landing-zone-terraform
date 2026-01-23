################################################################################
# Shared Environment
#
# Centralized security services for the landing zone:
# - KMS customer-managed keys
# - CloudTrail and centralized logging
# - IAM baseline and break-glass role
################################################################################

locals {
  environment = "shared"

  common_tags = merge(var.tags, {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  })
}

################################################################################
# Data Protection Module
# - KMS CMK for encryption
# - S3 account-level public access block
# - EBS default encryption
################################################################################

module "data_protection" {
  source = "../../modules/data-protection"

  environment  = local.environment
  project_name = var.project_name

  kms_key_deletion_window = var.kms_key_deletion_window
  enable_key_rotation     = true

  enable_s3_account_public_access_block = true
  enable_ebs_default_encryption         = true

  tags = local.common_tags
}

################################################################################
# Logging & Audit Module
# - CloudTrail (multi-region)
# - Hardened S3 log bucket
# - Security alerts (root login, IAM changes)
################################################################################

module "logging_audit" {
  source = "../../modules/logging-audit"

  environment  = local.environment
  project_name = var.project_name

  kms_key_arn = module.data_protection.kms_key_arn

  log_retention_days     = var.log_retention_days
  s3_log_retention_days  = 90
  s3_log_glacier_days    = 365
  s3_log_expiration_days = var.s3_log_expiration_days

  enable_cloudtrail          = true
  cloudtrail_is_multi_region = true
  enable_log_file_validation = true

  alert_email = var.alert_email

  tags = local.common_tags
}

################################################################################
# Identity Baseline Module
# - Account password policy
# - Break-glass emergency role
# - Standard deployment and audit roles
################################################################################

module "identity_baseline" {
  source = "../../modules/identity-baseline"

  environment  = local.environment
  project_name = var.project_name

  # Password Policy
  password_minimum_length   = var.password_minimum_length
  password_max_age          = 90
  password_reuse_prevention = 24
  password_require_symbols  = true

  # Break-Glass Role
  enable_break_glass_role          = true
  break_glass_trusted_principals   = var.break_glass_trusted_principals
  break_glass_require_mfa          = true
  break_glass_max_session_duration = 3600

  # Monitoring
  sns_topic_arn             = module.logging_audit.sns_topic_arn
  cloudwatch_log_group_name = module.logging_audit.cloudwatch_log_group_name

  tags = local.common_tags
}
