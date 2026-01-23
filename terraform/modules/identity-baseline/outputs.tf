output "password_policy_expire_passwords" {
  description = "Whether passwords expire"
  value       = aws_iam_account_password_policy.strict.expire_passwords
}

output "password_policy_minimum_length" {
  description = "Minimum password length"
  value       = aws_iam_account_password_policy.strict.minimum_password_length
}

output "break_glass_role_arn" {
  description = "ARN of the break-glass emergency role"
  value       = var.enable_break_glass_role ? aws_iam_role.break_glass[0].arn : null
}

output "break_glass_role_name" {
  description = "Name of the break-glass emergency role"
  value       = var.enable_break_glass_role ? aws_iam_role.break_glass[0].name : null
}

output "deployment_role_arn" {
  description = "ARN of the deployment role"
  value       = aws_iam_role.deployment.arn
}

output "deployment_role_name" {
  description = "Name of the deployment role"
  value       = aws_iam_role.deployment.name
}

output "audit_role_arn" {
  description = "ARN of the audit role"
  value       = aws_iam_role.audit.arn
}

output "audit_role_name" {
  description = "Name of the audit role"
  value       = aws_iam_role.audit.name
}

output "break_glass_alarm_arn" {
  description = "ARN of the break-glass usage alarm"
  value       = var.enable_break_glass_role && var.sns_topic_arn != "" ? aws_cloudwatch_metric_alarm.break_glass_usage[0].arn : null
}

output "permission_boundary_arn" {
  description = "ARN of the permission boundary policy"
  value       = aws_iam_policy.permission_boundary.arn
}

output "permission_boundary_name" {
  description = "Name of the permission boundary policy"
  value       = aws_iam_policy.permission_boundary.name
}
