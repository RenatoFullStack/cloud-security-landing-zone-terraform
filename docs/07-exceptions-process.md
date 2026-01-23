# Security Exceptions Process

This document describes the process for requesting and managing security exceptions.

---

## Overview

Security controls exist to protect the organization. Exceptions are granted when:

1. A legitimate business need conflicts with a control
2. Technical constraints prevent full compliance
3. Temporary deviation is required for migration

Exceptions are not granted for convenience or to avoid remediation effort.

---

## Exception Categories

| Category | Example | Typical Duration |
|----------|---------|------------------|
| Permanent | Legacy application requires HTTP | Indefinite (with annual review) |
| Temporary | Migration requires elevated access | 30-90 days |
| Conditional | Public bucket for static website | Until business need ends |

---

## Request Process

```
+-------------+     +----------------+     +-------------+     +------------+
|   Requestor | --> | Security Review| --> |  Approval   | --> | Implement  |
|   Submits   |     |   and Risk     |     |  Decision   |     | Exception  |
+-------------+     +----------------+     +-------------+     +------------+
                           |                      |
                           v                      v
                    Risk Assessment         Document in
                    and Mitigations         Registry
```

### Step 1: Submit Request

Use the exception request template in `templates/EXCEPTION_REQUEST.md`.

Required information:

- Business justification
- Technical details of the exception
- Risk assessment
- Proposed mitigations
- Requested duration
- Responsible owner

### Step 2: Security Review

Security team evaluates:

| Criteria | Questions |
|----------|-----------|
| Necessity | Can the requirement be met another way? |
| Scope | Is the exception as narrow as possible? |
| Risk | What is the residual risk? |
| Mitigations | Are compensating controls adequate? |
| Duration | Is the timeframe reasonable? |

### Step 3: Approval Decision

| Decision | Criteria |
|----------|----------|
| Approved | Risk is acceptable with mitigations |
| Approved with conditions | Additional controls required |
| Denied | Risk exceeds tolerance |
| Deferred | More information needed |

### Step 4: Implementation

If approved:

1. Add skip annotation to code with exception ID
2. Document in exception registry
3. Set review reminder for expiration
4. Implement compensating controls

---

## Exception Registry

Track all active exceptions:

| ID | Description | Risk Level | Owner | Expiration | Status |
|----|-------------|------------|-------|------------|--------|
| EXC-2024-001 | HTTP allowed for legacy app | Medium | App Team | 2024-12-31 | Active |
| EXC-2024-002 | Public S3 for static site | Low | Web Team | Permanent | Active |

### Registry Location

Maintain in a secure location accessible to security and compliance teams. Options:

- Internal wiki with access controls
- Ticketing system (Jira, ServiceNow)
- GRC platform

---

## Code Annotations

When implementing an approved exception:

### Checkov Skip

```hcl
resource "aws_security_group_rule" "legacy_http" {
  #checkov:skip=CKV_AWS_260:Exception EXC-2024-001 - Legacy app requires HTTP
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
}
```

### tfsec Ignore

```hcl
resource "aws_s3_bucket" "public_website" {
  #tfsec:ignore:aws-s3-no-public-buckets Exception EXC-2024-002
  bucket = "company-public-website"
}
```

---

## Compensating Controls

When an exception is granted, compensating controls reduce residual risk:

| Exception | Compensating Controls |
|-----------|----------------------|
| HTTP allowed | WAF in front, internal network only, monitoring |
| Public S3 bucket | No sensitive data, access logging, CDN in front |
| Elevated IAM access | Time-limited, session logging, MFA required |
| Missing encryption | Data classification (non-sensitive), access controls |

---

## Review Process

### Periodic Review

| Frequency | Scope |
|-----------|-------|
| Monthly | New exceptions from past month |
| Quarterly | All active exceptions |
| Annually | Permanent exceptions |

### Review Criteria

- Is the business need still valid?
- Has the risk level changed?
- Are compensating controls still effective?
- Can the exception be removed?

### Expiration Handling

30 days before expiration:

1. Notify exception owner
2. Request renewal or remediation plan
3. If no response, escalate

On expiration:

1. Remove skip annotation
2. CI pipeline will fail if issue not fixed
3. Block merge until remediated or renewed

---

## Escalation Path

| Level | Role | Criteria |
|-------|------|----------|
| L1 | Security Engineer | Standard exceptions |
| L2 | Security Architect | High-risk exceptions |
| L3 | CISO | Critical risk, policy changes |
| L4 | Executive | Business-critical with significant risk |

---

## Metrics

Track exception health:

| Metric | Target |
|--------|--------|
| Average exception duration | < 90 days |
| Exceptions per 100 resources | < 5% |
| Overdue reviews | 0 |
| Exceptions removed after fix | > 50% |

---

## Template Location

Exception request template: `templates/EXCEPTION_REQUEST.md`

Complete the template and submit via:

- Pull request adding the completed template
- Security team ticket
- GRC platform request

---

## Examples

### Example 1: Legacy Application HTTP

**Request:** Allow HTTP (port 80) ingress for legacy application that cannot be modified.

**Justification:** Application is 15 years old, vendor no longer exists, TLS termination not possible in app layer.

**Mitigations:**
- TLS termination at load balancer
- Restrict to internal network (10.0.0.0/8)
- WAF rules for common attacks
- Enhanced monitoring

**Decision:** Approved with conditions
- Must document migration plan
- Annual review required
- Monitoring alerts for anomalies

### Example 2: Public S3 Bucket

**Request:** Allow public read access for static website assets.

**Justification:** Marketing website serves static assets directly from S3.

**Mitigations:**
- No sensitive data in bucket
- CloudFront distribution in front
- Access logging enabled
- Bucket policy restricts to GET only

**Decision:** Approved (permanent with annual review)
