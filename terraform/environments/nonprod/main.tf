################################################################################
# Nonprod Environment
#
# Development and testing workloads with:
# - Isolated VPC
# - VPC Flow Logs
# - AWS Config guardrails
# - References shared environment for logging/encryption
################################################################################

locals {
  environment = "nonprod"

  common_tags = merge(var.tags, {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  })
}

################################################################################
# Network Baseline Module
# - Isolated VPC for nonprod workloads
# - Public and private subnets
# - Single NAT Gateway (cost optimization for nonprod)
# - VPC Flow Logs enabled
################################################################################

module "network" {
  source = "../../modules/network-baseline"

  environment  = local.environment
  project_name = var.project_name

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = true # Cost optimization for nonprod

  enable_flow_logs         = true
  flow_logs_retention_days = 30 # Shorter retention for nonprod
  kms_key_arn              = var.shared_kms_key_arn != "" ? var.shared_kms_key_arn : null

  tags = local.common_tags
}

################################################################################
# Guardrails Module
# - AWS Config rules for compliance monitoring
# - Standard security rules enabled
################################################################################

module "guardrails" {
  source = "../../modules/guardrails"

  environment  = local.environment
  project_name = var.project_name

  enable_config_recorder  = true
  config_log_bucket_name  = var.shared_log_bucket_name
  sns_topic_arn           = var.shared_sns_topic_arn
  access_key_max_age_days = 90

  # GuardDuty threat detection
  enable_guardduty = true

  # All rules enabled for nonprod (same as prod for consistency)
  config_rules_enabled = {
    s3_bucket_public_read_prohibited  = true
    s3_bucket_public_write_prohibited = true
    s3_bucket_ssl_requests_only       = true
    encrypted_volumes                 = true
    iam_password_policy               = true
    root_account_mfa_enabled          = true
    iam_user_no_policies_check        = true
    access_keys_rotated               = true
    vpc_flow_logs_enabled             = true
    incoming_ssh_disabled             = true # HIGH-005 fix
    restricted_incoming_traffic       = true # HIGH-005 fix
    vpc_default_security_group_closed = true # HIGH-005 fix
  }

  tags = local.common_tags
}
