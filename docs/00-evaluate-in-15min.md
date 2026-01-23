# Evaluate This Project in 15 Minutes

This guide provides a structured walkthrough for technical reviewers to assess the quality and depth of this Cloud Security Landing Zone implementation.

---

## Quick Assessment Checklist

| Area | What to Look For | Where to Find It |
|------|------------------|------------------|
| Architecture | 3-environment separation, shared services pattern | `terraform/environments/` |
| Identity | Break-glass role, permission boundaries, MFA enforcement | `terraform/modules/identity-baseline/` |
| Logging | CloudTrail with validation, 5 security alerts | `terraform/modules/logging-audit/` |
| Network | VPC Flow Logs, default deny SG, baseline workload SG | `terraform/modules/network-baseline/` |
| Encryption | KMS CMK with rotation, S3 public block, EBS default encryption | `terraform/modules/data-protection/` |
| Guardrails | 12 AWS Config rules, GuardDuty enabled | `terraform/modules/guardrails/` |
| CI/CD | Blocking security gates, policy-as-code | `.github/workflows/ci.yml` |
| Decisions | ADRs explaining key choices | `docs/adr/` |

---

## 5-Minute Code Review

### 1. Module Structure (1 min)

```
terraform/
  modules/
    identity-baseline/    # IAM controls, break-glass, permission boundaries
    logging-audit/        # CloudTrail, S3 hardened bucket, alerts
    network-baseline/     # VPC, subnets, flow logs, security groups
    data-protection/      # KMS, encryption defaults
    guardrails/           # Config rules, GuardDuty
  environments/
    shared/               # Centralized security services
    nonprod/              # Development workloads
    prod/                 # Production workloads
```

### 2. Key Security Controls (2 min)

Open these files to verify implementation quality:

**Break-glass emergency access** - `terraform/modules/identity-baseline/main.tf`
- Look for: MFA requirement, session duration limits, CloudWatch alarm on usage

**CloudTrail configuration** - `terraform/modules/logging-audit/main.tf`
- Look for: Multi-region, log validation enabled, S3 + Lambda data events

**Default deny networking** - `terraform/modules/network-baseline/main.tf`
- Look for: Empty default security group, baseline workload SG with HTTPS-only egress

### 3. CI Pipeline (2 min)

Review `.github/workflows/ci.yml`:
- Terraform format and validate
- TFLint for best practices
- Checkov and tfsec for security scanning
- Blocking gates (not soft-fail)

---

## 10-Minute Deep Dive

### Security Alerts Implementation

The logging-audit module implements 5 CloudWatch metric filters with alarms:

| Alert | Pattern | Threshold |
|-------|---------|-----------|
| Root account usage | `$.userIdentity.type = "Root"` | 1 event |
| IAM policy changes | CreatePolicy, AttachRolePolicy, etc. | 1 event |
| Console login failures | `$.errorMessage = "Failed authentication"` | 3 events/5min |
| Security group changes | AuthorizeSecurityGroupIngress, etc. | 1 event |
| KMS key deletion | ScheduleKeyDeletion | 1 event |

### AWS Config Rules

12 rules covering CIS Benchmark requirements:

| Category | Rules |
|----------|-------|
| S3 Security | public-read-prohibited, public-write-prohibited, ssl-requests-only |
| Encryption | encrypted-volumes |
| IAM | password-policy, root-mfa-enabled, user-no-policies, access-keys-rotated |
| Network | vpc-flow-logs-enabled, incoming-ssh-disabled, restricted-incoming-traffic, vpc-default-sg-closed |

### Permission Boundaries

The identity-baseline module creates a permission boundary that:
- Allows common workload actions (EC2, S3, Lambda, etc.)
- Denies IAM modifications unless the boundary is propagated
- Prevents removal of the boundary itself

This prevents privilege escalation even if a role is compromised.

---

## Questions This Project Answers

1. **How do you implement break-glass access securely?**
   - See `identity-baseline` module: MFA-required role with CloudWatch alerting

2. **How do you detect security group misconfigurations?**
   - AWS Config rules + CloudWatch alerts on SG changes

3. **How do you prevent data exfiltration via Lambda?**
   - CloudTrail Lambda data events + baseline SG with restricted egress

4. **How do you enforce encryption across the account?**
   - KMS CMK, S3 account-level public access block, EBS default encryption

5. **How do you implement policy-as-code?**
   - Checkov + tfsec in CI with blocking gates, custom policies in `policies/checkov/`

---

## Validation Commands

```bash
# Validate all modules
for dir in terraform/modules/*/; do
  terraform -chdir="$dir" init -backend=false
  terraform -chdir="$dir" validate
done

# Run security scan locally
checkov -d terraform/ --config-file .checkov.yml
```

---

## Architecture Decision Records

See `docs/adr/` for documented decisions:
- ADR-001: Cloud provider selection (AWS)
- ADR-002: Account model (VPC-based isolation)
- ADR-003: Break-glass access design
- ADR-004: Logging retention policy
