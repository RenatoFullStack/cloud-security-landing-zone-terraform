# Data Protection Module

This module implements data protection controls for the landing zone.

## Features

- **KMS Customer-Managed Key**: Centralized encryption key with automatic annual rotation
- **S3 Account Public Access Block**: Prevents any S3 bucket from being made public
- **EBS Default Encryption**: All new EBS volumes are encrypted by default

## Usage

```hcl
module "data_protection" {
  source = "../../modules/data-protection"

  environment  = "shared"
  project_name = "myproject"

  kms_key_administrators = [
    "arn:aws:iam::123456789012:role/SecurityAdmin"
  ]

  kms_key_users = [
    "arn:aws:iam::123456789012:role/DeploymentRole"
  ]

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
| environment | Environment name (shared, nonprod, prod) | `string` | n/a | yes |
| project_name | Project name used for resource naming | `string` | `"lz"` | no |
| kms_key_deletion_window | Duration in days before KMS key is deleted | `number` | `30` | no |
| enable_key_rotation | Enable automatic annual rotation | `bool` | `true` | no |
| kms_key_administrators | IAM ARNs that can administer the key | `list(string)` | `[]` | no |
| kms_key_users | IAM ARNs that can use the key | `list(string)` | `[]` | no |
| enable_s3_account_public_access_block | Enable S3 account public access block | `bool` | `true` | no |
| enable_ebs_default_encryption | Enable EBS default encryption | `bool` | `true` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| kms_key_arn | ARN of the KMS key |
| kms_key_id | ID of the KMS key |
| kms_key_alias_arn | ARN of the KMS key alias |
| kms_key_alias_name | Name of the KMS key alias |
| s3_account_public_access_block_enabled | Whether S3 block is enabled |
| ebs_default_encryption_enabled | Whether EBS encryption is enabled |

## Security Controls

| Control | Implementation |
|---------|----------------|
| Encryption at rest | KMS CMK for all services |
| Key rotation | Automatic annual rotation enabled |
| Public exposure prevention | Account-level S3 public access block |
| Default encryption | EBS volumes encrypted by default |
