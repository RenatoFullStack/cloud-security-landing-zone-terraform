# Encryption and Key Management

This document describes the data protection controls implemented in the data-protection module.

---

## Overview

| Control | Purpose |
|---------|---------|
| KMS CMK | Customer-managed encryption key |
| S3 Public Access Block | Account-level public exposure prevention |
| EBS Default Encryption | Automatic volume encryption |

---

## KMS Customer-Managed Key

### Why CMK vs AWS-Managed Keys?

| Aspect | AWS-Managed | Customer-Managed |
|--------|-------------|------------------|
| Key policy control | AWS only | Customer defined |
| Rotation control | Automatic (3 years) | Configurable (1 year) |
| Cross-account access | Not possible | Configurable |
| Audit granularity | Limited | Full CloudTrail |
| Deletion protection | Cannot delete | Configurable wait period |

Customer-managed keys provide the control needed for compliance and security requirements.

### Key Configuration

| Setting | Value | Rationale |
|---------|-------|-----------|
| Key spec | SYMMETRIC_DEFAULT | AES-256-GCM |
| Usage | ENCRYPT_DECRYPT | Standard encryption |
| Rotation | Enabled (annual) | Reduce key exposure window |
| Deletion window | 30 days | Recovery time if accidental |
| Multi-region | No | Single region for demo |

### Key Policy Structure

```
Root Account
  |-- Full key administration
  |
+-- CloudTrail Service
|     |-- Encrypt/Decrypt for log encryption
|
+-- CloudWatch Logs Service
|     |-- Encrypt/Decrypt for log group encryption
|
+-- S3 Service
      |-- Encrypt/Decrypt for bucket encryption
```

Each service principal has conditions limiting access to specific resource patterns.

### Key Usage

| Service | Purpose |
|---------|---------|
| CloudTrail | Log file encryption |
| S3 | Audit log bucket encryption |
| CloudWatch Logs | Log group encryption |
| EBS | Volume encryption (optional) |

---

## S3 Account Public Access Block

### Configuration

| Setting | Value | Effect |
|---------|-------|--------|
| BlockPublicAcls | true | Reject PUT requests with public ACLs |
| IgnorePublicAcls | true | Ignore existing public ACLs |
| BlockPublicPolicy | true | Reject policies granting public access |
| RestrictPublicBuckets | true | Restrict access to AWS principals only |

### Why Account-Level?

Bucket-level blocks can be overridden per bucket. Account-level blocks:

1. Apply to all buckets in the account
2. Cannot be overridden by bucket policies
3. Provide defense-in-depth

### Exception Process

If a bucket legitimately needs public access (e.g., static website hosting):

1. Submit exception request via template
2. Security review and approval
3. Apply bucket-level settings (account block still applies)
4. Document in exception registry

---

## EBS Default Encryption

### Configuration

When enabled, all new EBS volumes are encrypted automatically:

| Setting | Value |
|---------|-------|
| Enabled | true |
| Default key | AWS-managed (aws/ebs) or CMK |

### Coverage

| Volume Type | Encryption |
|-------------|------------|
| New volumes | Automatic |
| Snapshots from encrypted volumes | Encrypted |
| AMIs from encrypted volumes | Encrypted |
| Restored volumes | Encrypted |

### Existing Volumes

Existing unencrypted volumes are not automatically encrypted. Migration process:

1. Create snapshot of unencrypted volume
2. Copy snapshot with encryption enabled
3. Create new volume from encrypted snapshot
4. Replace original volume

---

## Module Configuration

```hcl
module "data_protection" {
  source = "../../modules/data-protection"

  environment  = "shared"
  project_name = "lz"

  enable_key_rotation      = true
  key_deletion_window_days = 30
  enable_ebs_encryption    = true
}
```

---

## Outputs

| Output | Description |
|--------|-------------|
| `kms_key_arn` | ARN of the KMS CMK |
| `kms_key_id` | ID of the KMS CMK |
| `kms_key_alias_arn` | ARN of the key alias |

---

## Operational Procedures

### Key Rotation

Automatic rotation creates new key material annually while keeping old material for decryption:

```
Year 1: Key Material A (active)
Year 2: Key Material B (active), A (decrypt only)
Year 3: Key Material C (active), B, A (decrypt only)
```

No action required for automatic rotation. Verify rotation is enabled:

```bash
aws kms get-key-rotation-status --key-id <key-id>
```

### Key Deletion

If key deletion is required:

1. Identify all resources encrypted with the key
2. Re-encrypt data with new key or export
3. Schedule key deletion (minimum 7 days, default 30)
4. Cancel if deletion was accidental

```bash
# Schedule deletion
aws kms schedule-key-deletion \
  --key-id <key-id> \
  --pending-window-in-days 30

# Cancel if needed
aws kms cancel-key-deletion --key-id <key-id>
```

### Auditing Key Usage

CloudTrail logs all KMS API calls:

```
fields @timestamp, eventName, userIdentity.arn, requestParameters.keyId
| filter eventSource = "kms.amazonaws.com"
| sort @timestamp desc
| limit 100
```

---

## Compliance Mapping

| Requirement | Control |
|-------------|---------|
| Encryption at rest | KMS CMK for all supported services |
| Key rotation | Annual automatic rotation enabled |
| Key access logging | CloudTrail + KMS key deletion alert |
| Public exposure prevention | S3 account public access block |
| Volume encryption | EBS default encryption |

---

## Design Considerations

### Single Key vs Multiple Keys

This implementation uses a single CMK for simplicity. Production considerations:

| Approach | Use Case |
|----------|----------|
| Single key | Demo, small workloads |
| Per-service keys | Separation of duties |
| Per-environment keys | Stronger isolation |
| Per-data-classification keys | Compliance requirements |

### Cross-Region Considerations

The CMK is single-region. For multi-region deployments:

1. Create CMK in each region
2. Use multi-region keys (MRK) for cross-region access
3. Replicate encrypted data with region-specific keys

### Cost Considerations

| Item | Cost |
|------|------|
| CMK | $1/month |
| API requests | $0.03 per 10,000 requests |
| Automatic rotation | Included |

KMS costs are minimal compared to the security benefit.
