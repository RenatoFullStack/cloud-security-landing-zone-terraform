# Identity Baseline Module

This module implements IAM security controls for the landing zone.

## Features

- **Password Policy**: Strict account-level password requirements
- **Break-Glass Role**: Emergency access with monitoring and alerts
- **Deployment Role**: Least-privilege CI/CD role template
- **Audit Role**: Read-only role for security audits

## Break-Glass Role

The break-glass role is designed for emergency situations only:

| Control | Implementation |
|---------|----------------|
| Access | Limited to specific principals |
| MFA | Required by default |
| Session | Limited to 1 hour (configurable) |
| Monitoring | CloudWatch alarm on usage |
| Permissions | AdministratorAccess (emergency) |

### Break-Glass Procedure

1. **Activation**: Only designated personnel can assume the role
2. **MFA Required**: Multi-factor authentication is mandatory
3. **Time-Limited**: Sessions automatically expire
4. **Monitored**: All usage triggers immediate alerts
5. **Documented**: All incidents must be documented post-mortem

## Usage

```hcl
module "identity_baseline" {
  source = "../../modules/identity-baseline"

  environment  = "shared"
  project_name = "myproject"

  # Password Policy
  password_minimum_length   = 14
  password_max_age          = 90
  password_reuse_prevention = 24

  # Break-Glass
  enable_break_glass_role = true
  break_glass_trusted_principals = [
    "arn:aws:iam::123456789012:user/security-lead"
  ]
  break_glass_require_mfa          = true
  break_glass_max_session_duration = 3600  # 1 hour

  # Monitoring
  sns_topic_arn             = module.logging_audit.sns_topic_arn
  cloudwatch_log_group_name = module.logging_audit.cloudwatch_log_group_name

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
| password_max_age | Max password age (days) | `number` | `90` | no |
| password_minimum_length | Min password length | `number` | `14` | no |
| password_reuse_prevention | Passwords to remember | `number` | `24` | no |
| enable_break_glass_role | Create break-glass role | `bool` | `true` | no |
| break_glass_trusted_principals | Allowed principals | `list(string)` | `[]` | no |
| break_glass_require_mfa | Require MFA | `bool` | `true` | no |
| break_glass_max_session_duration | Session duration (sec) | `number` | `3600` | no |
| sns_topic_arn | SNS topic for alerts | `string` | `""` | no |
| cloudwatch_log_group_name | CloudTrail log group | `string` | `""` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| password_policy_minimum_length | Configured min password length |
| break_glass_role_arn | Break-glass role ARN |
| break_glass_role_name | Break-glass role name |
| deployment_role_arn | Deployment role ARN |
| audit_role_arn | Audit role ARN |
| break_glass_alarm_arn | Break-glass usage alarm ARN |

## Security Controls

| Control | Implementation |
|---------|----------------|
| Strong passwords | 14+ chars, complexity, rotation |
| MFA enforcement | Required for role assumption |
| Least privilege | Scoped deployment role |
| Emergency access | Monitored break-glass role |
| Audit capability | Read-only audit role |

## Related ADR

See [ADR-003: Break-Glass Procedure](../../docs/decision-records/ADR-003-break-glass.md) for design decisions.
