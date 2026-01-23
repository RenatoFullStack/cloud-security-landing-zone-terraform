output "log_bucket_arn" {
  description = "ARN of the centralized log bucket"
  value       = aws_s3_bucket.logs.arn
}

output "log_bucket_name" {
  description = "Name of the centralized log bucket"
  value       = aws_s3_bucket.logs.id
}

output "log_bucket_domain_name" {
  description = "Domain name of the log bucket"
  value       = aws_s3_bucket.logs.bucket_domain_name
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudTrail CloudWatch Log Group"
  value       = var.enable_cloudtrail ? aws_cloudwatch_log_group.cloudtrail[0].arn : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudTrail CloudWatch Log Group"
  value       = var.enable_cloudtrail ? aws_cloudwatch_log_group.cloudtrail[0].name : null
}

output "sns_topic_arn" {
  description = "ARN of the security alerts SNS topic"
  value       = aws_sns_topic.security_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the security alerts SNS topic"
  value       = aws_sns_topic.security_alerts.name
}
