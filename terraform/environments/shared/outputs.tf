################################################################################
# Data Protection Outputs
################################################################################

output "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  value       = module.data_protection.kms_key_arn
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = module.data_protection.kms_key_id
}

output "kms_key_alias" {
  description = "Alias of the KMS key"
  value       = module.data_protection.kms_key_alias_name
}

################################################################################
# Logging & Audit Outputs
################################################################################

output "log_bucket_name" {
  description = "Name of the centralized log bucket"
  value       = module.logging_audit.log_bucket_name
}

output "log_bucket_arn" {
  description = "ARN of the centralized log bucket"
  value       = module.logging_audit.log_bucket_arn
}

output "cloudtrail_arn" {
  description = "ARN of CloudTrail"
  value       = module.logging_audit.cloudtrail_arn
}

output "cloudwatch_log_group_name" {
  description = "Name of CloudTrail CloudWatch Log Group"
  value       = module.logging_audit.cloudwatch_log_group_name
}

output "sns_topic_arn" {
  description = "ARN of security alerts SNS topic"
  value       = module.logging_audit.sns_topic_arn
}

################################################################################
# Identity Baseline Outputs
################################################################################

output "break_glass_role_arn" {
  description = "ARN of the break-glass emergency role"
  value       = module.identity_baseline.break_glass_role_arn
}

output "deployment_role_arn" {
  description = "ARN of the deployment role"
  value       = module.identity_baseline.deployment_role_arn
}

output "audit_role_arn" {
  description = "ARN of the audit role"
  value       = module.identity_baseline.audit_role_arn
}
