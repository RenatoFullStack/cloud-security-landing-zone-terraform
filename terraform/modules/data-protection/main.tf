################################################################################
# Data Protection Module
#
# This module implements data protection controls:
# - Customer-managed KMS key with automatic rotation
# - S3 account-level public access block
# - EBS default encryption
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  default_tags = {
    Module      = "data-protection"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

################################################################################
# KMS Customer-Managed Key
################################################################################

resource "aws_kms_key" "main" {
  description             = "Customer-managed key for ${local.name_prefix} encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.enable_key_rotation
  is_enabled              = true
  multi_region            = false

  policy = data.aws_iam_policy_document.kms_policy.json

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-kms-key"
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}-key"
  target_key_id = aws_kms_key.main.key_id
}

data "aws_iam_policy_document" "kms_policy" {
  # Allow root account full access (required for key management)
  statement {
    sid    = "EnableRootAccountPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow key administrators to manage the key
  dynamic "statement" {
    for_each = length(var.kms_key_administrators) > 0 ? [1] : []

    content {
      sid    = "AllowKeyAdministration"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.kms_key_administrators
      }

      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ]

      resources = ["*"]
    }
  }

  # Allow key users to use the key for encryption/decryption
  dynamic "statement" {
    for_each = length(var.kms_key_users) > 0 ? [1] : []

    content {
      sid    = "AllowKeyUsage"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = var.kms_key_users
      }

      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]

      resources = ["*"]
    }
  }

  # Allow AWS services to use the key
  statement {
    sid    = "AllowServiceLinkedRoleUsage"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Allow CloudTrail to use the key
  statement {
    sid    = "AllowCloudTrailEncryption"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
    }
  }

  # Allow S3 to use the key for log bucket encryption
  statement {
    sid    = "AllowS3Encryption"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]

    resources = ["*"]
  }
}

################################################################################
# S3 Account-Level Public Access Block
################################################################################

resource "aws_s3_account_public_access_block" "main" {
  count = var.enable_s3_account_public_access_block ? 1 : 0

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################
# EBS Default Encryption
################################################################################

resource "aws_ebs_encryption_by_default" "main" {
  count   = var.enable_ebs_default_encryption ? 1 : 0
  enabled = true
}

resource "aws_ebs_default_kms_key" "main" {
  count   = var.enable_ebs_default_encryption ? 1 : 0
  key_arn = aws_kms_key.main.arn
}
