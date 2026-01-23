# ADR-004: Logging Retention Policy

## Status

Accepted

## Date

2024-01-15

## Context

Audit logs must be retained for compliance, security investigations, and operational needs. Retention periods must balance:
- Compliance requirements
- Investigation needs
- Storage costs
- Query performance

Different log types have different retention needs.

## Decision

Tiered retention policy based on log type and environment:

| Log Type | Real-time (CloudWatch) | Archive (S3) | Total Retention |
|----------|------------------------|--------------|-----------------|
| CloudTrail | 90 days | 7 years | 7 years |
| VPC Flow Logs (nonprod) | 30 days | N/A | 30 days |
| VPC Flow Logs (prod) | 365 days | N/A | 365 days |

S3 lifecycle transitions:
- Standard: 0-90 days
- Standard-IA: 90-365 days
- Glacier: 365-2555 days
- Delete: After 2555 days (7 years)

## Rationale

### 7-Year CloudTrail Retention

Most compliance frameworks require 5-7 years:
- SOC 2: Typically 7 years for financial services
- PCI DSS: 1 year minimum, often 7 years
- HIPAA: 6 years
- GDPR: Varies, but audit trails should cover retention periods

7 years provides margin for most requirements.

### Real-time vs Archive Split

CloudWatch Logs for recent queries:
- Fast query performance
- Higher cost per GB
- 90 days covers most investigations

S3 for long-term archive:
- Lower cost with lifecycle transitions
- Acceptable query latency for old logs
- Glacier for rarely-accessed historical data

### Environment-Based VPC Flow Logs

Nonprod (30 days):
- Lower criticality
- Cost optimization
- Sufficient for debugging

Prod (365 days):
- Higher criticality
- Longer investigation window
- Compliance may require

### Storage Class Transitions

| Age | Storage Class | Cost (approx) | Access Time |
|-----|---------------|---------------|-------------|
| 0-90 days | Standard | $0.023/GB | Immediate |
| 90-365 days | Standard-IA | $0.0125/GB | Immediate |
| 365-2555 days | Glacier | $0.004/GB | 3-5 hours |

Transitions reduce long-term costs by ~80% vs Standard.

## Consequences

### Positive

- Meets common compliance requirements
- Cost-optimized storage
- Fast access to recent logs
- Older logs available if needed

### Negative

- Glacier retrieval takes hours
- 7 years is longer than some requirements
- CloudWatch costs for 90-day retention

### Mitigations

- Use S3 Glacier Instant Retrieval for faster access if needed
- Adjust retention via variables for specific compliance needs
- Consider CloudWatch Logs Insights for cost-effective queries

## Configuration

Variables to adjust retention:

```hcl
# CloudWatch Logs retention
log_retention_days = 90

# S3 lifecycle
s3_log_retention_days  = 90    # Transition to IA
s3_log_glacier_days    = 365   # Transition to Glacier
s3_log_expiration_days = 2555  # Delete (7 years)

# VPC Flow Logs
flow_logs_retention_days = 30  # nonprod
flow_logs_retention_days = 365 # prod
```

## Compliance Mapping

| Framework | Requirement | This Implementation |
|-----------|-------------|---------------------|
| SOC 2 | Retain audit logs | 7 years in S3 |
| PCI DSS | 1 year minimum | 7 years exceeds |
| HIPAA | 6 years | 7 years exceeds |
| CIS AWS | Log retention defined | Configurable |
| ISO 27001 | Define retention policy | Documented |

## Cost Estimate

For 10 GB/month of CloudTrail logs:

| Component | Monthly Cost |
|-----------|--------------|
| CloudWatch Logs (90 days, 30 GB) | ~$15 |
| S3 Standard (90 days, 30 GB) | ~$0.70 |
| S3 Standard-IA (275 days, ~90 GB) | ~$1.10 |
| S3 Glacier (6 years, ~720 GB) | ~$2.90 |
| **Total** | ~$20/month |

Costs scale linearly with log volume.

## References

- AWS CloudWatch Logs Pricing
- AWS S3 Storage Classes
- SOC 2 Trust Services Criteria
- PCI DSS v4.0 Requirement 10
- HIPAA 45 CFR 164.530(j)
