################################################################################
# Guardrails Module
#
# This module implements AWS Config rules for compliance monitoring:
# - S3 public access prevention
# - EBS encryption enforcement
# - IAM best practices
# - VPC Flow Logs verification
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  default_tags = {
    Module      = "guardrails"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

################################################################################
# AWS Config Recorder
################################################################################

resource "aws_config_configuration_recorder" "main" {
  count = var.enable_config_recorder ? 1 : 0

  name     = "${local.name_prefix}-config-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_configuration_recorder_status" "main" {
  count = var.enable_config_recorder ? 1 : 0

  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_config_delivery_channel" "main" {
  count = var.enable_config_recorder ? 1 : 0

  name           = "${local.name_prefix}-config-delivery"
  s3_bucket_name = var.config_log_bucket_name
  s3_key_prefix  = "config"

  snapshot_delivery_properties {
    delivery_frequency = "TwentyFour_Hours"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

################################################################################
# IAM Role for AWS Config
################################################################################

resource "aws_iam_role" "config" {
  count = var.enable_config_recorder ? 1 : 0

  name = "${local.name_prefix}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count = var.enable_config_recorder ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role_policy" "config_s3" {
  count = var.enable_config_recorder ? 1 : 0

  name = "${local.name_prefix}-config-s3-policy"
  role = aws_iam_role.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "arn:aws:s3:::${var.config_log_bucket_name}/config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${var.config_log_bucket_name}"
      }
    ]
  })
}

################################################################################
# Config Rules - S3 Security
################################################################################

resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  count = var.config_rules_enabled.s3_bucket_public_read_prohibited ? 1 : 0

  name        = "${local.name_prefix}-s3-public-read-prohibited"
  description = "Checks that S3 buckets do not allow public read access"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  tags = local.tags

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "s3_bucket_public_write_prohibited" {
  count = var.config_rules_enabled.s3_bucket_public_write_prohibited ? 1 : 0

  name        = "${local.name_prefix}-s3-public-write-prohibited"
  description = "Checks that S3 buckets do not allow public write access"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }

  tags = local.tags

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "s3_bucket_ssl_requests_only" {
  count = var.config_rules_enabled.s3_bucket_ssl_requests_only ? 1 : 0

  name        = "${local.name_prefix}-s3-ssl-requests-only"
  description = "Checks that S3 buckets require SSL for requests"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }

  tags = local.tags

  depends_on = [aws_config_configuration_recorder.main]
}

################################################################################
# Config Rules - Encryption
################################################################################

resource "aws_config_config_rule" "encrypted_volumes" {
  count = var.config_rules_enabled.encrypted_volumes ? 1 : 0

  name        = "${local.name_prefix}-encrypted-volumes"
  description = "Checks that EBS volumes are encrypted"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  tags = local.tags

  depends_on = [aws_config_configuration_recorder.main]
}

################################################################################
# Config Rules - IAM Security
################################################################################

resource "aws_config_config_rule" "iam_password_policy" {
  count = var.config_rules_enabled.iam_password_policy ? 1 : 0

  name        = "${local.name_prefix}-iam-password-policy"
  description = "Checks that IAM password policy meets requirements"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode({
    RequireUppercaseCharacters = "true"
    RequireLowercaseCharacters = "true"
    RequireSymbols             = "true"
    RequireNumbers             = "true"
    MinimumPasswordLength      = "14"
    PasswordReusePrevention    = "24"
    MaxPasswordAge             = "90"
  })

  tags = local.tags

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "root_account_mfa_enabled" {
  count = var.config_rules_enabled.root_account_mfa_enabled ? 1 : 0

  name        = "${local.name_prefix}-root-mfa-enabled"
  description = "Checks that MFA is enabled for the root account"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  tags = local.tags

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "iam_user_no_policies_check" {
  count = var.config_rules_enabled.iam_user_no_policies_check ? 1 : 0

  name        = "${local.name_prefix}-iam-user-no-policies"
  description = "Checks that IAM users do not have inline policies attached directly"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_NO_POLICIES_CHECK"
  }

  tags = local.tags

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "access_keys_rotated" {
  count = var.config_rules_enabled.access_keys_rotated ? 1 : 0

  name        = "${local.name_prefix}-access-keys-rotated"
  description = "Checks that access keys are rotated within specified days"

  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }

  input_parameters = jsonencode({
    maxAccessKeyAge = tostring(var.access_key_max_age_days)
  })

  tags = local.tags

  depends_on = [aws_config_configuration_recorder.main]
}

################################################################################
# Config Rules - Network Security
################################################################################

resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  count = var.config_rules_enabled.vpc_flow_logs_enabled ? 1 : 0

  name        = "${local.name_prefix}-vpc-flow-logs-enabled"
  description = "Checks that VPC Flow Logs are enabled"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  tags = local.tags

  depends_on = [aws_config_configuration_recorder.main]
}

# HIGH-005: Detect security groups with SSH open to 0.0.0.0/0
resource "aws_config_config_rule" "incoming_ssh_disabled" {
  count = var.config_rules_enabled.incoming_ssh_disabled ? 1 : 0

  name        = "${local.name_prefix}-incoming-ssh-disabled"
  description = "Checks that security groups do not allow unrestricted SSH access"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  tags = local.tags

  depends_on = [aws_config_configuration_recorder.main]
}

# HIGH-005: Detect security groups with unrestricted ingress
resource "aws_config_config_rule" "restricted_incoming_traffic" {
  count = var.config_rules_enabled.restricted_incoming_traffic ? 1 : 0

  name        = "${local.name_prefix}-restricted-incoming-traffic"
  description = "Checks that security groups do not allow unrestricted incoming traffic"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  input_parameters = jsonencode({
    blockedPort1 = "22"
    blockedPort2 = "3389"
    blockedPort3 = "3306"
    blockedPort4 = "5432"
    blockedPort5 = "1433"
  })

  tags = local.tags

  depends_on = [aws_config_configuration_recorder.main]
}

# HIGH-005: Ensure default security group is closed
resource "aws_config_config_rule" "vpc_default_security_group_closed" {
  count = var.config_rules_enabled.vpc_default_security_group_closed ? 1 : 0

  name        = "${local.name_prefix}-vpc-default-sg-closed"
  description = "Checks that default security groups restrict all traffic"

  source {
    owner             = "AWS"
    source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
  }

  tags = local.tags

  depends_on = [aws_config_configuration_recorder.main]
}

################################################################################
# AWS GuardDuty - Threat Detection (HIGH-004 fix)
################################################################################

resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-guardduty"
  })
}

################################################################################
# EventBridge Rule for GuardDuty High Severity Findings
################################################################################

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  count = var.enable_guardduty && var.sns_topic_arn != "" ? 1 : 0

  name        = "${local.name_prefix}-guardduty-high-findings"
  description = "Capture high severity GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [
        { numeric = [">=", 7] }
      ]
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  count = var.enable_guardduty && var.sns_topic_arn != "" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.guardduty_findings[0].name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      severity    = "$.detail.severity"
      title       = "$.detail.title"
      description = "$.detail.description"
      account     = "$.detail.accountId"
      region      = "$.detail.region"
    }
    input_template = "\"GuardDuty HIGH severity finding: <title>. Severity: <severity>. Account: <account>. Region: <region>. Description: <description>\""
  }
}
