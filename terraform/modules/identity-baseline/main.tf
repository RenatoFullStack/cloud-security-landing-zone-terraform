################################################################################
# Identity Baseline Module
#
# This module implements IAM security controls:
# - Account password policy
# - Break-glass emergency access role
# - Break-glass usage monitoring and alerts
# - Standard role templates (deployment, audit)
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  default_tags = {
    Module      = "identity-baseline"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

################################################################################
# Permission Boundary Policy (HIGH-001 fix)
# Prevents privilege escalation by limiting what permissions can be granted
################################################################################

resource "aws_iam_policy" "permission_boundary" {
  name        = "${local.name_prefix}-permission-boundary"
  description = "Permission boundary to prevent privilege escalation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAllWithinBoundary"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "cloudwatch:*",
          "logs:*",
          "sns:*",
          "sqs:*",
          "lambda:*",
          "dynamodb:*",
          "rds:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "sts:AssumeRole",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyIAMModificationOutsideBoundary"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachUserPolicy",
          "iam:AttachRolePolicy",
          "iam:PutUserPolicy",
          "iam:PutRolePolicy",
          "iam:DeleteUserPolicy",
          "iam:DeleteRolePolicy",
          "iam:DetachUserPolicy",
          "iam:DetachRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:SetDefaultPolicyVersion"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "iam:PermissionsBoundary" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name_prefix}-permission-boundary"
          }
        }
      },
      {
        Sid    = "DenyBoundaryModification"
        Effect = "Deny"
        Action = [
          "iam:DeletePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:SetDefaultPolicyVersion"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.name_prefix}-permission-boundary"
      },
      {
        Sid    = "DenyBoundaryRemoval"
        Effect = "Deny"
        Action = [
          "iam:DeleteRolePermissionsBoundary",
          "iam:DeleteUserPermissionsBoundary"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.tags, {
    Name    = "${local.name_prefix}-permission-boundary"
    Purpose = "privilege-escalation-prevention"
  })
}

################################################################################
# Account Password Policy
################################################################################

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = var.password_minimum_length
  max_password_age               = var.password_max_age
  password_reuse_prevention      = var.password_reuse_prevention
  require_lowercase_characters   = var.password_require_lowercase
  require_uppercase_characters   = var.password_require_uppercase
  require_numbers                = var.password_require_numbers
  require_symbols                = var.password_require_symbols
  allow_users_to_change_password = true
  hard_expiry                    = false
}

################################################################################
# Break-Glass Emergency Access Role
################################################################################

resource "aws_iam_role" "break_glass" {
  count = var.enable_break_glass_role ? 1 : 0

  name        = "${local.name_prefix}-break-glass-role"
  description = "Emergency break-glass role for critical incident response. Usage is monitored and alerted."

  max_session_duration = var.break_glass_max_session_duration

  assume_role_policy = data.aws_iam_policy_document.break_glass_trust[0].json

  tags = merge(local.tags, {
    Name        = "${local.name_prefix}-break-glass-role"
    Purpose     = "emergency-access"
    Criticality = "high"
  })
}

data "aws_iam_policy_document" "break_glass_trust" {
  count = var.enable_break_glass_role ? 1 : 0

  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = length(var.break_glass_trusted_principals) > 0 ? var.break_glass_trusted_principals : [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    # Require MFA if enabled
    dynamic "condition" {
      for_each = var.break_glass_require_mfa ? [1] : []

      content {
        test     = "Bool"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["true"]
      }
    }
  }
}

# Break-glass role gets AdministratorAccess for emergency situations
resource "aws_iam_role_policy_attachment" "break_glass_admin" {
  count = var.enable_break_glass_role ? 1 : 0

  role       = aws_iam_role.break_glass[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

################################################################################
# Break-Glass Usage Monitoring
################################################################################

# Metric filter to detect break-glass role assumption
resource "aws_cloudwatch_log_metric_filter" "break_glass_usage" {
  count = var.enable_break_glass_role && var.cloudwatch_log_group_name != "" ? 1 : 0

  name           = "${local.name_prefix}-break-glass-usage"
  pattern        = "{ ($.eventName = AssumeRole) && ($.requestParameters.roleArn = \"*break-glass*\") }"
  log_group_name = var.cloudwatch_log_group_name

  metric_transformation {
    name      = "BreakGlassRoleUsage"
    namespace = "${local.name_prefix}/Security"
    value     = "1"
  }
}

# Alarm when break-glass role is used
resource "aws_cloudwatch_metric_alarm" "break_glass_usage" {
  count = var.enable_break_glass_role && var.sns_topic_arn != "" ? 1 : 0

  alarm_name          = "${local.name_prefix}-break-glass-usage-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "BreakGlassRoleUsage"
  namespace           = "${local.name_prefix}/Security"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CRITICAL: Break-glass emergency role has been assumed. Investigate immediately."
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  tags = local.tags
}

################################################################################
# Standard Roles - Deployment Role (Least Privilege Example)
################################################################################

resource "aws_iam_role" "deployment" {
  name                 = "${local.name_prefix}-deployment-role"
  description          = "Role for CI/CD deployments with least privilege"
  permissions_boundary = aws_iam_policy.permission_boundary.arn # HIGH-001 fix

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountAssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })

  tags = merge(local.tags, {
    Name    = "${local.name_prefix}-deployment-role"
    Purpose = "ci-cd-deployment"
  })
}

# Deployment role policy - example with limited permissions
resource "aws_iam_role_policy" "deployment" {
  name = "${local.name_prefix}-deployment-policy"
  role = aws_iam_role.deployment.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowTerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::*-tfstate-*",
          "arn:aws:s3:::*-tfstate-*/*"
        ]
      },
      {
        Sid    = "AllowTerraformStateLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/*-tflock-*"
      },
      {
        Sid    = "AllowEC2ReadOnly"
        Effect = "Allow"
        Action = [
          "ec2:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

################################################################################
# Standard Roles - Audit Role (Read-Only)
################################################################################

resource "aws_iam_role" "audit" {
  name                 = "${local.name_prefix}-audit-role"
  description          = "Read-only role for security audits and compliance checks"
  permissions_boundary = aws_iam_policy.permission_boundary.arn # HIGH-001 fix

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountAssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })

  tags = merge(local.tags, {
    Name    = "${local.name_prefix}-audit-role"
    Purpose = "security-audit"
  })
}

resource "aws_iam_role_policy_attachment" "audit_security_audit" {
  role       = aws_iam_role.audit.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_role_policy_attachment" "audit_read_only" {
  role       = aws_iam_role.audit.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
