# Identity Baseline

This document describes the IAM security controls implemented in the identity-baseline module.

---

## Overview

The identity-baseline module establishes foundational IAM controls:

| Control | Purpose |
|---------|---------|
| Password Policy | Enforce strong passwords for console users |
| Break-glass Role | Emergency access with monitoring |
| Permission Boundaries | Prevent privilege escalation |
| Standard Roles | Deployment and audit role templates |

---

## Password Policy

Enforced settings aligned with CIS Benchmark:

| Setting | Value | Rationale |
|---------|-------|-----------|
| Minimum length | 14 characters | NIST SP 800-63B recommendation |
| Require uppercase | Yes | Character diversity |
| Require lowercase | Yes | Character diversity |
| Require numbers | Yes | Character diversity |
| Require symbols | Yes | Character diversity |
| Password expiration | 90 days | Periodic rotation |
| Reuse prevention | 24 passwords | Prevent cycling |
| Allow self-change | Yes | User autonomy |

---

## Break-Glass Emergency Access

### Purpose

The break-glass role provides emergency administrative access when normal access paths fail. Typical scenarios:

- IdP outage preventing SSO login
- Misconfigured IAM policies blocking access
- Security incident requiring immediate response
- Disaster recovery operations

### Security Controls

```
+-------------------+     +-------------------+     +-------------------+
|  Request Access   | --> |  Assume Role      | --> |  CloudWatch       |
|  (MFA required)   |     |  (time-limited)   |     |  Alert Fires      |
+-------------------+     +-------------------+     +-------------------+
                                                             |
                                                             v
                                                    +-------------------+
                                                    |  SNS Notification |
                                                    |  to Security Team |
                                                    +-------------------+
```

| Control | Configuration |
|---------|---------------|
| Trust Policy | Account root only (or specified principals) |
| MFA Requirement | Enforced via condition |
| Session Duration | 1 hour maximum |
| Permissions | AdministratorAccess (emergency scope) |
| Monitoring | CloudWatch metric filter on AssumeRole |
| Alerting | Alarm triggers on any usage |

### Usage Procedure

1. Verify legitimate need for emergency access
2. Authenticate with MFA-enabled credentials
3. Assume the break-glass role via CLI or Console
4. Complete necessary actions
5. Document actions taken in incident ticket
6. Review triggered alerts and close

### Module Configuration

```hcl
module "identity" {
  source = "../../modules/identity-baseline"

  environment  = "shared"
  project_name = "lz"

  enable_break_glass_role        = true
  break_glass_require_mfa        = true
  break_glass_max_session_duration = 3600  # 1 hour

  # Optional: restrict to specific principals
  break_glass_trusted_principals = [
    "arn:aws:iam::123456789012:user/security-admin"
  ]

  sns_topic_arn            = module.logging.sns_topic_arn
  cloudwatch_log_group_name = module.logging.cloudtrail_log_group_name
}
```

---

## Permission Boundaries

### Problem Statement

IAM privilege escalation is a common attack vector:

1. Attacker compromises a role with `iam:CreateRole` permission
2. Attacker creates a new role with `AdministratorAccess`
3. Attacker assumes the new role
4. Attacker has full account access

### Solution

Permission boundaries limit what permissions a role can grant, even if its policy allows broader access.

```
+-------------------------+
|     Role Policy         |  <-- What the role CAN do
|  (iam:CreateRole, etc.) |
+------------+------------+
             |
             | Intersection
             v
+------------+------------+
|  Permission Boundary    |  <-- What the role is ALLOWED to do
|  (workload actions)     |
+------------+------------+
             |
             v
+-------------------------+
|   Effective Permissions |  <-- Actual permissions
|   (limited scope)       |
+-------------------------+
```

### Boundary Policy Structure

```
Statement 1: AllowAllWithinBoundary
  - Common workload actions (EC2, S3, Lambda, RDS, etc.)
  - Limited KMS actions (encrypt, decrypt, generate key)
  - STS actions for role assumption

Statement 2: DenyIAMModificationOutsideBoundary
  - Denies IAM modifications UNLESS the new entity
    also has this permission boundary attached
  - Prevents creating unbounded roles

Statement 3: DenyBoundaryModification
  - Denies modification of the boundary policy itself
  - Prevents weakening the constraint

Statement 4: DenyBoundaryRemoval
  - Denies removing boundaries from roles/users
  - Prevents escaping the constraint
```

### Attached To

| Role | Boundary Applied |
|------|------------------|
| Deployment Role | Yes |
| Audit Role | Yes |
| Break-glass Role | No (emergency access) |

---

## Standard Roles

### Deployment Role

Purpose: CI/CD pipeline operations with minimal privileges

| Permission | Scope |
|------------|-------|
| S3 state access | `*-tfstate-*` buckets |
| DynamoDB locking | `*-tflock-*` tables |
| EC2 read | Describe operations only |

This role demonstrates least-privilege for Terraform operations. Extend as needed for actual deployments.

### Audit Role

Purpose: Security assessments and compliance checks

| Attached Policy | Purpose |
|-----------------|---------|
| SecurityAudit | AWS-managed policy for security review |
| ReadOnlyAccess | AWS-managed read-only policy |

The audit role cannot modify resources, only inspect them.

---

## Outputs

| Output | Description |
|--------|-------------|
| `break_glass_role_arn` | ARN of the break-glass role |
| `break_glass_alarm_arn` | ARN of the usage alarm |
| `deployment_role_arn` | ARN of the deployment role |
| `audit_role_arn` | ARN of the audit role |
| `permission_boundary_arn` | ARN of the permission boundary policy |

---

## Operational Procedures

### Adding a New Role

1. Create the role with `permissions_boundary` set to the boundary ARN
2. Attach required policies (intersection with boundary applies)
3. Test that the role cannot escalate privileges

### Responding to Break-glass Alerts

1. Alert fires when break-glass role is assumed
2. Security team verifies legitimacy
3. If unauthorized: revoke sessions, investigate, remediate
4. If authorized: document in incident system

### Rotating Break-glass Credentials

The break-glass role uses role assumption, not static credentials. If the trusted principals need rotation:

1. Update `break_glass_trusted_principals` variable
2. Apply Terraform changes
3. Verify trust policy updated
