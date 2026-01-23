# Architecture Overview

This document describes the high-level architecture of the Cloud Security Landing Zone.

---

## Design Principles

1. **Defense in depth** - Multiple layers of security controls
2. **Least privilege** - Minimal permissions by default
3. **Separation of concerns** - Isolated environments with shared services
4. **Auditability** - Comprehensive logging with tamper protection
5. **Automation** - Infrastructure as code with policy gates

---

## Environment Model

```
+------------------------------------------------------------------+
|                        AWS Account                                |
|                                                                   |
|  +-------------------+  +------------------+  +----------------+  |
|  |      SHARED       |  |     NONPROD      |  |      PROD      |  |
|  |                   |  |                  |  |                |  |
|  | - CloudTrail      |  | - VPC            |  | - VPC (HA)     |  |
|  | - KMS CMK         |  | - Flow Logs      |  | - Flow Logs    |  |
|  | - S3 Log Bucket   |  | - Config Rules   |  | - Config Rules |  |
|  | - IAM Baseline    |  | - GuardDuty      |  | - GuardDuty    |  |
|  | - SNS Alerts      |  | - Single NAT     |  | - Multi-AZ NAT |  |
|  |                   |  |                  |  |                |  |
|  +-------------------+  +------------------+  +----------------+  |
|           |                     |                    |            |
|           +---------------------+--------------------+            |
|                          References                               |
+------------------------------------------------------------------+
```

### Shared Environment

Centralized security services consumed by workload environments:

| Component | Purpose |
|-----------|---------|
| CloudTrail | API audit logging with S3 + Lambda data events |
| KMS CMK | Customer-managed encryption key with rotation |
| S3 Log Bucket | Hardened bucket for audit logs (versioned, encrypted, HTTPS-only) |
| IAM Baseline | Password policy, break-glass role, permission boundaries |
| SNS Topic | Security alert notifications |

### Workload Environments (nonprod/prod)

Isolated VPCs with environment-specific guardrails:

| Component | Nonprod | Prod |
|-----------|---------|------|
| VPC CIDR | 10.1.0.0/16 | 10.2.0.0/16 |
| Availability Zones | 2 | 3 |
| NAT Gateway | Single (cost optimization) | Per-AZ (high availability) |
| Flow Logs Retention | 30 days | 365 days |
| Config Rules | 12 rules | 12 rules |
| GuardDuty | Enabled | Enabled |

---

## Network Architecture

```
                           Internet
                              |
                     +--------+--------+
                     |  Internet GW    |
                     +--------+--------+
                              |
        +---------------------+---------------------+
        |                     |                     |
+-------+-------+     +-------+-------+     +-------+-------+
| Public Subnet |     | Public Subnet |     | Public Subnet |
|   10.x.1.0/24 |     |   10.x.2.0/24 |     |   10.x.3.0/24 |
+-------+-------+     +-------+-------+     +-------+-------+
        |                     |                     |
   +----+----+           +----+----+           +----+----+
   | NAT GW  |           | NAT GW  |           | NAT GW  |
   +---------+           +---------+           +---------+
        |                     |                     |
+-------+-------+     +-------+-------+     +-------+-------+
| Private Subnet|     | Private Subnet|     | Private Subnet|
|  10.x.11.0/24 |     |  10.x.12.0/24 |     |  10.x.13.0/24 |
+---------------+     +---------------+     +---------------+
```

### Security Groups

| Security Group | Purpose | Ingress | Egress |
|----------------|---------|---------|--------|
| default | Deny-all baseline | None | None |
| baseline-workload | Template for workloads | None (add per workload) | HTTPS (443), DNS (53 to VPC) |

The default security group is locked down to prevent accidental use. Workloads should clone the baseline-workload SG and add required ingress rules.

---

## Data Flow

### Audit Logging

```
API Call --> CloudTrail --> CloudWatch Logs --> Metric Filters --> Alarms --> SNS
                  |
                  v
            S3 Log Bucket (encrypted, versioned)
```

### Security Alerts

| Event | Detection | Response |
|-------|-----------|----------|
| Root login | CloudWatch metric filter | SNS notification |
| IAM policy change | CloudWatch metric filter | SNS notification |
| Failed console logins (3+) | CloudWatch metric filter | SNS notification |
| Security group modification | CloudWatch metric filter | SNS notification |
| KMS key deletion scheduled | CloudWatch metric filter | SNS notification |
| High severity threat | GuardDuty | EventBridge to SNS |
| Config rule violation | AWS Config | (configurable) |

---

## IAM Architecture

### Role Hierarchy

```
                    +-------------------+
                    |   Account Root    |
                    | (MFA required)    |
                    +--------+----------+
                             |
        +--------------------+--------------------+
        |                    |                    |
+-------+-------+    +-------+-------+    +-------+-------+
|  Break-Glass  |    |  Deployment   |    |    Audit      |
|  (emergency)  |    |   (CI/CD)     |    |  (read-only)  |
+---------------+    +---------------+    +---------------+
        |                    |                    |
        v                    v                    v
  Admin Access       Limited Actions      SecurityAudit +
  + Monitoring      + Perm Boundary       ReadOnlyAccess
```

### Permission Boundaries

All non-emergency roles have a permission boundary that:
- Allows standard workload operations
- Denies IAM modifications without boundary propagation
- Prevents boundary removal

This contains blast radius if credentials are compromised.

---

## Encryption Architecture

### Key Hierarchy

```
+------------------+
|   KMS CMK        |  <-- Customer-managed, auto-rotation enabled
|  (shared env)    |
+--------+---------+
         |
    +----+----+----+----+
    |         |         |
    v         v         v
CloudTrail  S3 Logs   EBS Volumes
Logs        Bucket    (default)
```

### Encryption Coverage

| Resource | Encryption | Key |
|----------|------------|-----|
| CloudTrail logs | At rest | KMS CMK |
| S3 log bucket | At rest | KMS CMK |
| CloudWatch logs | At rest | KMS CMK |
| EBS volumes | Default encryption | AWS managed (or CMK) |
| SNS topics | At rest | KMS CMK |

---

## Compliance Mapping

### CIS AWS Foundations Benchmark v1.5

| Section | Controls Implemented |
|---------|---------------------|
| 1. Identity and Access Management | Password policy, root MFA check, access key rotation |
| 2. Logging | CloudTrail multi-region, log validation, S3 logging |
| 3. Monitoring | 5 CloudWatch alarms (root, IAM, console, SG, KMS) |
| 4. Networking | VPC flow logs, default SG closed, restricted ingress |
| 5. Storage | S3 public access blocked, encryption enforced |

### AWS Well-Architected Security Pillar

| Best Practice | Implementation |
|---------------|----------------|
| SEC01 - Operate securely | CI/CD with security gates |
| SEC02 - Identity management | Break-glass, permission boundaries |
| SEC03 - Detection | GuardDuty, Config rules, CloudWatch alarms |
| SEC04 - Infrastructure protection | VPC isolation, SG baseline |
| SEC05 - Data protection | KMS encryption, S3 hardening |
| SEC06 - Incident response | Break-glass role, alert notifications |

---

## Module Dependencies

```
                    +------------------+
                    | data-protection  |
                    | (KMS, S3 block)  |
                    +--------+---------+
                             |
              +--------------+--------------+
              |                             |
    +---------v---------+         +---------v---------+
    |   logging-audit   |         | identity-baseline |
    | (CloudTrail, S3)  |         | (IAM, break-glass)|
    +---------+---------+         +---------+---------+
              |                             |
              +-------------+---------------+
                            |
              +-------------v--------------+
              |         guardrails         |
              |   (Config, GuardDuty)      |
              +----------------------------+
                            |
              +-------------v--------------+
              |      network-baseline      |
              |    (VPC, Flow Logs, SG)    |
              +----------------------------+
```

Deploy order:
1. data-protection (KMS key needed by others)
2. logging-audit (S3 bucket, SNS topic)
3. identity-baseline (needs SNS topic ARN)
4. guardrails (needs S3 bucket name)
5. network-baseline (can reference KMS for flow logs)
