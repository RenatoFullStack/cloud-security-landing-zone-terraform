output "config_recorder_id" {
  description = "ID of the AWS Config recorder"
  value       = var.enable_config_recorder ? aws_config_configuration_recorder.main[0].id : null
}

output "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  value       = var.enable_config_recorder ? aws_config_configuration_recorder.main[0].name : null
}

output "config_role_arn" {
  description = "ARN of the IAM role used by AWS Config"
  value       = var.enable_config_recorder ? aws_iam_role.config[0].arn : null
}

output "config_rules" {
  description = "Map of enabled Config rules and their ARNs"
  value = {
    s3_bucket_public_read_prohibited  = var.config_rules_enabled.s3_bucket_public_read_prohibited ? aws_config_config_rule.s3_bucket_public_read_prohibited[0].arn : null
    s3_bucket_public_write_prohibited = var.config_rules_enabled.s3_bucket_public_write_prohibited ? aws_config_config_rule.s3_bucket_public_write_prohibited[0].arn : null
    s3_bucket_ssl_requests_only       = var.config_rules_enabled.s3_bucket_ssl_requests_only ? aws_config_config_rule.s3_bucket_ssl_requests_only[0].arn : null
    encrypted_volumes                 = var.config_rules_enabled.encrypted_volumes ? aws_config_config_rule.encrypted_volumes[0].arn : null
    iam_password_policy               = var.config_rules_enabled.iam_password_policy ? aws_config_config_rule.iam_password_policy[0].arn : null
    root_account_mfa_enabled          = var.config_rules_enabled.root_account_mfa_enabled ? aws_config_config_rule.root_account_mfa_enabled[0].arn : null
    iam_user_no_policies_check        = var.config_rules_enabled.iam_user_no_policies_check ? aws_config_config_rule.iam_user_no_policies_check[0].arn : null
    access_keys_rotated               = var.config_rules_enabled.access_keys_rotated ? aws_config_config_rule.access_keys_rotated[0].arn : null
    vpc_flow_logs_enabled             = var.config_rules_enabled.vpc_flow_logs_enabled ? aws_config_config_rule.vpc_flow_logs_enabled[0].arn : null
    incoming_ssh_disabled             = var.config_rules_enabled.incoming_ssh_disabled ? aws_config_config_rule.incoming_ssh_disabled[0].arn : null
    restricted_incoming_traffic       = var.config_rules_enabled.restricted_incoming_traffic ? aws_config_config_rule.restricted_incoming_traffic[0].arn : null
    vpc_default_security_group_closed = var.config_rules_enabled.vpc_default_security_group_closed ? aws_config_config_rule.vpc_default_security_group_closed[0].arn : null
  }
}

output "enabled_rules_count" {
  description = "Number of enabled Config rules"
  value = sum([
    var.config_rules_enabled.s3_bucket_public_read_prohibited ? 1 : 0,
    var.config_rules_enabled.s3_bucket_public_write_prohibited ? 1 : 0,
    var.config_rules_enabled.s3_bucket_ssl_requests_only ? 1 : 0,
    var.config_rules_enabled.encrypted_volumes ? 1 : 0,
    var.config_rules_enabled.iam_password_policy ? 1 : 0,
    var.config_rules_enabled.root_account_mfa_enabled ? 1 : 0,
    var.config_rules_enabled.iam_user_no_policies_check ? 1 : 0,
    var.config_rules_enabled.access_keys_rotated ? 1 : 0,
    var.config_rules_enabled.vpc_flow_logs_enabled ? 1 : 0,
    var.config_rules_enabled.incoming_ssh_disabled ? 1 : 0,
    var.config_rules_enabled.restricted_incoming_traffic ? 1 : 0,
    var.config_rules_enabled.vpc_default_security_group_closed ? 1 : 0,
  ])
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

output "guardduty_detector_arn" {
  description = "ARN of the GuardDuty detector"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].arn : null
}
