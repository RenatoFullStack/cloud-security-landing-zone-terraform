# Logging & Audit Module

This module implements centralized logging and audit controls.

## Features

- **CloudTrail**: Multi-region API audit logging with log file validation
- **Hardened S3 Bucket**: KMS encryption, versioning, public access block, lifecycle policies
- **CloudWatch Logs**: Centralized log storage with configurable retention
- **Security Alerts**: SNS notifications for critical security events

## Security Alerts

| Alert | Trigger | Description |
|-------|---------|-------------|
| Root Login | Root account usage | Detects when AWS root account is used |
| IAM Changes | Policy modifications | Detects IAM policy create/delete/attach/detach |

## Usage

```hcl
module "logging_audit" {
  source = "../../modules/logging-audit"

  environment  = "shared"
  project_name = "myproject"
  kms_key_arn  = module.data_protection.kms_key_arn

  log_retention_days     = 365
  s3_log_retention_days  = 90
  s3_log_glacier_days    = 365
  s3_log_expiration_days = 2555  # ~7 years

  alert_email = "security@example.com"

  tags = {
    Owner = "security-team"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name | `string` | n/a | yes |
| project_name | Project name for naming | `string` | `"lz"` | no |
| kms_key_arn | KMS key ARN for encryption | `string` | n/a | yes |
| log_retention_days | CloudWatch log retention | `number` | `365` | no |
| s3_log_retention_days | Days before S3 transition to IA | `number` | `90` | no |
| s3_log_glacier_days | Days before S3 transition to Glacier | `number` | `365` | no |
| s3_log_expiration_days | Days before S3 log deletion | `number` | `2555` | no |
| enable_cloudtrail | Enable CloudTrail | `bool` | `true` | no |
| cloudtrail_is_multi_region | Multi-region CloudTrail | `bool` | `true` | no |
| enable_log_file_validation | Enable log integrity validation | `bool` | `true` | no |
| alert_email | Email for alerts | `string` | `""` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| log_bucket_arn | ARN of the log bucket |
| log_bucket_name | Name of the log bucket |
| cloudtrail_arn | ARN of CloudTrail |
| cloudwatch_log_group_arn | ARN of CloudWatch Log Group |
| sns_topic_arn | ARN of alerts SNS topic |

## S3 Bucket Lifecycle

```
Day 0-90:    STANDARD storage class
Day 90-365:  STANDARD_IA (Infrequent Access)
Day 365+:    GLACIER
Day 2555:    Deleted (configurable for compliance)
```

## Security Controls

| Control | Implementation |
|---------|----------------|
| Encryption | KMS-SSE for S3 and CloudWatch |
| Access | S3 public access blocked, HTTPS enforced |
| Integrity | CloudTrail log file validation |
| Retention | Lifecycle policies with Glacier archival |
| Alerting | SNS + CloudWatch alarms for security events |
