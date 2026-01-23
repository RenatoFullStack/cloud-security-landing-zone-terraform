# Guardrails Module

This module implements AWS Config rules for continuous compliance monitoring.

## Features

- **AWS Config Recorder**: Records all resource configurations
- **Managed Config Rules**: Pre-built AWS compliance rules
- **Compliance Categories**: S3, encryption, IAM, network security

## Config Rules

| Rule | Category | Description |
|------|----------|-------------|
| `s3_bucket_public_read_prohibited` | S3 | No public read access |
| `s3_bucket_public_write_prohibited` | S3 | No public write access |
| `s3_bucket_ssl_requests_only` | S3 | HTTPS required |
| `encrypted_volumes` | Encryption | EBS encryption required |
| `iam_password_policy` | IAM | Password policy compliance |
| `root_account_mfa_enabled` | IAM | Root MFA required |
| `iam_user_no_policies_check` | IAM | No inline user policies |
| `access_keys_rotated` | IAM | Access key rotation |
| `vpc_flow_logs_enabled` | Network | VPC Flow Logs enabled |

## Usage

```hcl
module "guardrails" {
  source = "../../modules/guardrails"

  environment            = "prod"
  project_name           = "myproject"
  config_log_bucket_name = module.logging_audit.log_bucket_name

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
  }

  access_key_max_age_days = 90

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
| project_name | Project name | `string` | `"lz"` | no |
| enable_config_recorder | Enable Config recorder | `bool` | `true` | no |
| config_log_bucket_name | S3 bucket for Config logs | `string` | n/a | yes |
| sns_topic_arn | SNS topic for notifications | `string` | `""` | no |
| config_rules_enabled | Map of rules to enable | `object` | See defaults | no |
| access_key_max_age_days | Max access key age | `number` | `90` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| config_recorder_id | Config recorder ID |
| config_recorder_name | Config recorder name |
| config_role_arn | Config IAM role ARN |
| config_rules | Map of enabled rules and ARNs |
| enabled_rules_count | Count of enabled rules |

## Compliance Mapping

| Control | Config Rule | CIS Benchmark |
|---------|-------------|---------------|
| No public S3 | `s3_bucket_public_*` | 2.1.1, 2.1.2 |
| Encryption | `encrypted_volumes` | 2.2.1 |
| MFA | `root_account_mfa_enabled` | 1.5 |
| Password policy | `iam_password_policy` | 1.8-1.11 |
| Access keys | `access_keys_rotated` | 1.4 |
| Logging | `vpc_flow_logs_enabled` | 2.9 |
