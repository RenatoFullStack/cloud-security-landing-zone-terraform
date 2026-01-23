################################################################################
# Logging & Audit Module
#
# This module implements centralized logging:
# - CloudTrail for API audit logging
# - Hardened S3 bucket for log storage
# - CloudWatch Log Groups
# - Security alerts via SNS
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  default_tags = {
    Module      = "logging-audit"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

################################################################################
# S3 Bucket for Centralized Logs
################################################################################

resource "aws_s3_bucket" "logs" {
  bucket = "${local.name_prefix}-audit-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-audit-logs"
  })
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "log-lifecycle"
    status = "Enabled"

    transition {
      days          = var.s3_log_retention_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.s3_log_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.s3_log_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_bucket_policy.json
}

data "aws_iam_policy_document" "logs_bucket_policy" {
  # Deny non-HTTPS access
  statement {
    sid    = "DenyNonHTTPS"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Allow CloudTrail to write logs
  statement {
    sid    = "AllowCloudTrailGetBucketAcl"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logs.arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${local.name_prefix}-trail"]
    }
  }

  statement {
    sid    = "AllowCloudTrailPutObject"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${local.name_prefix}-trail"]
    }
  }
}

################################################################################
# CloudWatch Log Group for CloudTrail
################################################################################

resource "aws_cloudwatch_log_group" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  name              = "/aws/cloudtrail/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-cloudtrail-logs"
  })
}

################################################################################
# IAM Role for CloudTrail to CloudWatch Logs
################################################################################

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  count = var.enable_cloudtrail ? 1 : 0

  name = "${local.name_prefix}-cloudtrail-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  count = var.enable_cloudtrail ? 1 : 0

  name = "${local.name_prefix}-cloudtrail-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_cloudwatch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
      }
    ]
  })
}

################################################################################
# CloudTrail
################################################################################

resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = "${local.name_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.logs.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = var.cloudtrail_is_multi_region
  enable_log_file_validation    = var.enable_log_file_validation
  kms_key_id                    = var.kms_key_arn

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch[0].arn

  # Management events
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    # S3 data events - track object-level operations
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3"]
    }
  }

  # Lambda data events - track function invocations (CRITICAL-001 fix)
  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-trail"
  })

  depends_on = [aws_s3_bucket_policy.logs]
}

################################################################################
# SNS Topic for Security Alerts
################################################################################

resource "aws_sns_topic" "security_alerts" {
  name              = "${local.name_prefix}-security-alerts"
  kms_master_key_id = var.kms_key_arn

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-security-alerts"
  })
}

resource "aws_sns_topic_policy" "security_alerts" {
  arn    = aws_sns_topic.security_alerts.arn
  policy = data.aws_iam_policy_document.sns_policy.json
}

data "aws_iam_policy_document" "sns_policy" {
  # Deny non-HTTPS publishing (HIGH-006 fix)
  statement {
    sid    = "DenyNonHTTPS"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.security_alerts.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowCloudWatchAlarms"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.security_alerts.arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

################################################################################
# CloudWatch Metric Filters and Alarms
################################################################################

# Alert 1: Root Account Login
resource "aws_cloudwatch_log_metric_filter" "root_login" {
  count = var.enable_cloudtrail ? 1 : 0

  name           = "${local.name_prefix}-root-login"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name

  metric_transformation {
    name      = "RootLoginCount"
    namespace = "${local.name_prefix}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_login" {
  count = var.enable_cloudtrail ? 1 : 0

  alarm_name          = "${local.name_prefix}-root-login-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootLoginCount"
  namespace           = "${local.name_prefix}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when root account is used"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = local.tags
}

# Alert 2: IAM Policy Changes
resource "aws_cloudwatch_log_metric_filter" "iam_changes" {
  count = var.enable_cloudtrail ? 1 : 0

  name           = "${local.name_prefix}-iam-changes"
  pattern        = "{ ($.eventName = CreatePolicy) || ($.eventName = DeletePolicy) || ($.eventName = CreatePolicyVersion) || ($.eventName = DeletePolicyVersion) || ($.eventName = AttachRolePolicy) || ($.eventName = DetachRolePolicy) || ($.eventName = AttachUserPolicy) || ($.eventName = DetachUserPolicy) || ($.eventName = AttachGroupPolicy) || ($.eventName = DetachGroupPolicy) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name

  metric_transformation {
    name      = "IAMPolicyChanges"
    namespace = "${local.name_prefix}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_changes" {
  count = var.enable_cloudtrail ? 1 : 0

  alarm_name          = "${local.name_prefix}-iam-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "IAMPolicyChanges"
  namespace           = "${local.name_prefix}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when IAM policies are modified"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = local.tags
}

################################################################################
# Alert 3: Console Login Failures (CRITICAL-003 fix)
# Detects brute force attacks against IAM users
################################################################################

resource "aws_cloudwatch_log_metric_filter" "console_login_failure" {
  count = var.enable_cloudtrail ? 1 : 0

  name           = "${local.name_prefix}-console-login-failure"
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name

  metric_transformation {
    name      = "ConsoleLoginFailures"
    namespace = "${local.name_prefix}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_login_failure" {
  count = var.enable_cloudtrail ? 1 : 0

  alarm_name          = "${local.name_prefix}-console-login-failure-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ConsoleLoginFailures"
  namespace           = "${local.name_prefix}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 3 # Alert after 3 failed attempts within 5 minutes
  alarm_description   = "Alert when multiple console login failures detected (potential brute force)"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = local.tags
}

################################################################################
# Alert 4: Security Group Changes (HIGH-002 fix)
# CIS Benchmark 3.10 - Ensure security group changes are monitored
################################################################################

resource "aws_cloudwatch_log_metric_filter" "security_group_changes" {
  count = var.enable_cloudtrail ? 1 : 0

  name           = "${local.name_prefix}-security-group-changes"
  pattern        = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name

  metric_transformation {
    name      = "SecurityGroupChanges"
    namespace = "${local.name_prefix}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "security_group_changes" {
  count = var.enable_cloudtrail ? 1 : 0

  alarm_name          = "${local.name_prefix}-security-group-changes-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "SecurityGroupChanges"
  namespace           = "${local.name_prefix}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when security groups are modified (CIS 3.10)"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = local.tags
}

################################################################################
# Alert 5: KMS Key Deletion Scheduled (MEDIUM-003 fix)
# Critical alert for potential data loss
################################################################################

resource "aws_cloudwatch_log_metric_filter" "kms_key_deletion" {
  count = var.enable_cloudtrail ? 1 : 0

  name           = "${local.name_prefix}-kms-key-deletion"
  pattern        = "{ ($.eventSource = kms.amazonaws.com) && ($.eventName = ScheduleKeyDeletion) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail[0].name

  metric_transformation {
    name      = "KMSKeyDeletion"
    namespace = "${local.name_prefix}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "kms_key_deletion" {
  count = var.enable_cloudtrail ? 1 : 0

  alarm_name          = "${local.name_prefix}-kms-key-deletion-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "KMSKeyDeletion"
  namespace           = "${local.name_prefix}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CRITICAL: KMS key deletion has been scheduled - potential data loss risk"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = local.tags
}
