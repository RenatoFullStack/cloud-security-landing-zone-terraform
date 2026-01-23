output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key"
  value       = aws_kms_key.main.arn
}

output "kms_key_id" {
  description = "ID of the customer-managed KMS key"
  value       = aws_kms_key.main.key_id
}

output "kms_key_alias_arn" {
  description = "ARN of the KMS key alias"
  value       = aws_kms_alias.main.arn
}

output "kms_key_alias_name" {
  description = "Name of the KMS key alias"
  value       = aws_kms_alias.main.name
}

output "s3_account_public_access_block_enabled" {
  description = "Whether S3 account-level public access block is enabled"
  value       = var.enable_s3_account_public_access_block
}

output "ebs_default_encryption_enabled" {
  description = "Whether EBS default encryption is enabled"
  value       = var.enable_ebs_default_encryption
}
