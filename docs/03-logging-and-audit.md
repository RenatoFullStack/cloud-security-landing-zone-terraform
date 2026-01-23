# Logging and Audit

This document describes the centralized logging architecture implemented in the logging-audit module.

---

## Overview

| Component | Purpose |
|-----------|---------|
| CloudTrail | API activity logging |
| S3 Bucket | Tamper-resistant log storage |
| CloudWatch Logs | Real-time log analysis |
| Metric Filters | Pattern detection |
| Alarms | Automated alerting |
| SNS Topic | Alert distribution |

---

## CloudTrail Configuration

### Trail Settings

| Setting | Value | Rationale |
|---------|-------|-----------|
| Multi-region | Yes | Capture activity in all regions |
| Global events | Yes | Include IAM, STS, CloudFront |
| Log validation | Enabled | Detect log tampering |
| Encryption | KMS CMK | Protect log confidentiality |

### Data Events

The trail captures data-level operations for:

| Resource Type | Events Captured |
|---------------|-----------------|
| S3 Objects | GetObject, PutObject, DeleteObject |
| Lambda Functions | Invoke |

This provides visibility into data access patterns, not just management operations.

### Log Delivery

```
CloudTrail --> CloudWatch Logs --> Metric Filters
     |
     v
S3 Bucket (s3://[prefix]-audit-logs-[account-id]/cloudtrail/)
```

---

## S3 Log Bucket

### Security Hardening

| Control | Implementation |
|---------|----------------|
| Encryption | SSE-KMS with customer-managed key |
| Versioning | Enabled (prevent deletion) |
| Public access | Blocked at bucket level |
| HTTPS only | Bucket policy denies non-SSL requests |
| Lifecycle | Transition to IA (90d), Glacier (365d), expire (2555d) |

### Bucket Policy

The bucket policy implements:

1. **DenyNonHTTPS** - Rejects requests without TLS
2. **AllowCloudTrailGetBucketAcl** - Required for CloudTrail delivery
3. **AllowCloudTrailPutObject** - CloudTrail log writes with source ARN condition

### Lifecycle Rules

| Age | Action |
|-----|--------|
| 90 days | Move to STANDARD_IA |
| 365 days | Move to GLACIER |
| 2555 days (7 years) | Delete |
| Noncurrent versions | Delete after 90 days |

Adjust `s3_log_retention_days`, `s3_log_glacier_days`, and `s3_log_expiration_days` variables as needed.

---

## Security Alerts

### Alert Architecture

```
CloudWatch Logs --> Metric Filter --> Metric --> Alarm --> SNS Topic
                         |
                         v
                    Pattern Match
                    (e.g., root login)
```

### Implemented Alerts

| Alert | Pattern | Threshold | Severity |
|-------|---------|-----------|----------|
| Root Account Usage | `$.userIdentity.type = "Root"` | 1 event | Critical |
| IAM Policy Changes | CreatePolicy, AttachRolePolicy, etc. | 1 event | High |
| Console Login Failures | `$.errorMessage = "Failed authentication"` | 3 events/5min | High |
| Security Group Changes | AuthorizeSecurityGroupIngress, etc. | 1 event | Medium |
| KMS Key Deletion | ScheduleKeyDeletion | 1 event | Critical |

### Alert Details

#### Root Account Usage

Detects any use of the root account, excluding AWS service events.

```
Pattern: { $.userIdentity.type = "Root" &&
           $.userIdentity.invokedBy NOT EXISTS &&
           $.eventType != "AwsServiceEvent" }
```

Response: Immediate investigation. Root should only be used for account-level operations that require it.

#### IAM Policy Changes

Detects modifications to IAM policies that could alter access controls.

```
Pattern: { ($.eventName = CreatePolicy) ||
           ($.eventName = DeletePolicy) ||
           ($.eventName = AttachRolePolicy) ||
           ... }
```

Response: Verify change was authorized and follows change management process.

#### Console Login Failures

Detects multiple failed console login attempts, indicating potential brute force.

```
Pattern: { ($.eventName = ConsoleLogin) &&
           ($.errorMessage = "Failed authentication") }
Threshold: 3 failures within 5 minutes
```

Response: Check source IP, verify if legitimate user having issues, consider blocking IP if malicious.

#### Security Group Changes

Detects modifications to security group rules (CIS Benchmark 3.10).

```
Pattern: { ($.eventName = AuthorizeSecurityGroupIngress) ||
           ($.eventName = RevokeSecurityGroupEgress) ||
           ... }
```

Response: Verify change was authorized, check if overly permissive rules were added.

#### KMS Key Deletion

Detects scheduling of KMS key deletion, which could cause data loss.

```
Pattern: { ($.eventSource = kms.amazonaws.com) &&
           ($.eventName = ScheduleKeyDeletion) }
```

Response: Verify deletion is intended, confirm data encrypted with key is no longer needed or has been re-encrypted.

---

## SNS Topic

### Configuration

| Setting | Value |
|---------|-------|
| Encryption | KMS CMK |
| Access policy | CloudWatch alarms only (with account condition) |
| HTTPS enforcement | Deny publish without SecureTransport |

### Subscription Options

Configure via the `alert_email` variable or add subscriptions manually:

| Protocol | Use Case |
|----------|----------|
| Email | Human notification |
| Lambda | Automated response |
| SQS | Queue for processing |
| HTTPS | Webhook to external system |

---

## Log Retention

| Log Type | Location | Retention |
|----------|----------|-----------|
| CloudTrail (real-time) | CloudWatch Logs | Configurable (default 90 days) |
| CloudTrail (archive) | S3 | 7 years (default) |
| VPC Flow Logs | CloudWatch Logs | 30 days (nonprod) / 365 days (prod) |

---

## Module Configuration

```hcl
module "logging" {
  source = "../../modules/logging-audit"

  environment  = "shared"
  project_name = "lz"

  enable_cloudtrail           = true
  cloudtrail_is_multi_region  = true
  enable_log_file_validation  = true

  kms_key_arn = module.data_protection.kms_key_arn

  log_retention_days     = 90
  s3_log_retention_days  = 90
  s3_log_glacier_days    = 365
  s3_log_expiration_days = 2555

  alert_email = "security-team@example.com"
}
```

---

## Outputs

| Output | Description |
|--------|-------------|
| `cloudtrail_arn` | ARN of the CloudTrail trail |
| `log_bucket_name` | Name of the S3 log bucket |
| `log_bucket_arn` | ARN of the S3 log bucket |
| `cloudtrail_log_group_name` | CloudWatch Log Group name |
| `sns_topic_arn` | ARN of the security alerts topic |

---

## Operational Procedures

### Investigating an Alert

1. Check CloudWatch Logs Insights for context:
   ```
   fields @timestamp, eventName, userIdentity.arn, sourceIPAddress
   | filter eventName = "ConsoleLogin"
   | sort @timestamp desc
   | limit 50
   ```

2. Correlate with other events from same source IP or user

3. Document findings and take remediation action

### Log Retention Changes

If compliance requires longer retention:

1. Update `s3_log_expiration_days` variable
2. Apply Terraform changes
3. Lifecycle policy updates automatically

### Adding New Alerts

1. Add metric filter resource in module
2. Add corresponding alarm resource
3. Connect alarm to SNS topic
4. Apply and test with simulated event
