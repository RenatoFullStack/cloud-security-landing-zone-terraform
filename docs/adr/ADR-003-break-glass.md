# ADR-003: Break-Glass Emergency Access Design

## Status

Accepted

## Date

2024-01-15

## Context

Emergency access mechanisms are required for scenarios where normal access paths fail. The design must balance:
- Availability during emergencies
- Security against misuse
- Auditability of access
- Simplicity of use under stress

Options considered:

1. **IAM role with MFA and monitoring** - Assumable role with alerting
2. **Separate IAM user with hardware MFA** - Dedicated break-glass user
3. **AWS SSO emergency access** - SSO-based emergency group
4. **Third-party PAM solution** - External privileged access management

## Decision

IAM role with MFA requirement and CloudWatch monitoring is selected.

## Rationale

### Simplicity Under Stress

Emergencies are stressful. The access mechanism must be:
- Familiar (standard AWS role assumption)
- Quick (no additional system login)
- Reliable (no dependency on external systems)

An IAM role with role assumption is the simplest mechanism that meets security requirements.

### Native AWS Integration

Using AWS-native controls means:
- No external dependencies that could fail
- CloudTrail automatically logs usage
- CloudWatch alarms trigger on any usage
- SNS delivers alerts immediately

### MFA Enforcement

MFA is required via trust policy condition:
```hcl
condition {
  test     = "Bool"
  variable = "aws:MultiFactorAuthPresent"
  values   = ["true"]
}
```

This ensures credentials alone cannot access the role.

### Immediate Detection

Any usage triggers:
1. CloudWatch metric filter matches AssumeRole event
2. Metric triggers alarm (threshold = 1)
3. Alarm sends SNS notification
4. Security team investigates

Detection time: seconds to minutes after role assumption.

### AdministratorAccess Scope

The break-glass role has AdministratorAccess because:
- Emergencies may require any action
- Time-limiting reduces exposure
- Monitoring provides accountability
- Restricting would reduce utility when needed most

## Consequences

### Positive

- Simple to use during emergencies
- No external dependencies
- Immediate detection of usage
- Full audit trail
- MFA protection

### Negative

- Powerful role if misused
- Requires trusted principals to be defined
- MFA device must be available during emergency
- No just-in-time provisioning

### Mitigations

- Short session duration (1 hour)
- Immediate alerting on usage
- Regular review of trusted principals
- Document usage procedures
- Post-incident review requirement

## Security Controls Summary

| Control | Implementation |
|---------|----------------|
| Authentication | MFA required |
| Authorization | Restricted trust policy |
| Session limit | 1 hour maximum |
| Detection | CloudWatch metric filter |
| Alerting | CloudWatch alarm to SNS |
| Audit | CloudTrail logging |

## Usage Procedure

1. Confirm emergency requiring elevated access
2. Authenticate with MFA-enabled credentials
3. Assume role via CLI or Console:
   ```bash
   aws sts assume-role \
     --role-arn arn:aws:iam::ACCOUNT:role/lz-shared-break-glass-role \
     --role-session-name emergency-access \
     --serial-number arn:aws:iam::ACCOUNT:mfa/username \
     --token-code 123456
   ```
4. Perform necessary actions
5. Document actions in incident ticket
6. Security team reviews triggered alert

## Alternatives Considered

### Separate IAM User

Rejected because:
- Static credentials are higher risk
- Would need secure storage for credentials
- No session-based access control
- Less integration with role-based access patterns

### AWS SSO Emergency Access

Rejected because:
- Adds dependency on SSO availability
- SSO outage is a common emergency scenario
- More complex to configure
- May not be available in all account types

### Third-party PAM

Rejected because:
- External dependency
- Additional cost
- Adds complexity
- May not be available during cloud-specific emergencies

## References

- AWS IAM Best Practices
- NIST SP 800-53 AC-2 (Account Management)
- CIS AWS Foundations Benchmark (Monitoring section)
