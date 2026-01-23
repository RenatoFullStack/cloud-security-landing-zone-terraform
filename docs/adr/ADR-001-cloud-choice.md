# ADR-001: Cloud Provider Selection

## Status

Accepted

## Date

2024-01-15

## Context

This project aims to demonstrate cloud security expertise for a portfolio targeting Platform Security and Security Architect roles. A cloud provider must be selected for the implementation.

Options considered:

1. **AWS** - Most widely adopted, extensive security services
2. **Azure** - Strong enterprise presence, integrated with Microsoft ecosystem
3. **GCP** - Modern architecture, strong in data/ML
4. **Multi-cloud** - Demonstrate breadth across providers

## Decision

AWS is selected as the sole cloud provider.

## Rationale

### Market Adoption

AWS has the largest market share, particularly among:
- Startups and scale-ups (common employer targets)
- Technology companies
- Companies undergoing digital transformation

Demonstrating AWS security expertise maximizes relevance to potential employers.

### Security Service Maturity

AWS offers mature, well-documented security services:
- IAM with fine-grained policies
- CloudTrail for comprehensive audit logging
- GuardDuty for threat detection
- Config for compliance monitoring
- KMS for key management

These services have extensive Terraform provider support.

### Terraform Provider Quality

The AWS Terraform provider is:
- Feature-complete for security services
- Well-maintained with frequent updates
- Extensively documented
- Widely used with community examples

### Single Cloud Focus

Multi-cloud was rejected because:
- Dilutes depth of expertise shown
- Increases maintenance burden
- Cloud-specific security patterns don't transfer directly
- Employers typically use one primary cloud

A deep implementation on one cloud demonstrates stronger expertise than shallow implementations across multiple.

## Consequences

### Positive

- Clear focus on AWS security patterns
- Comprehensive coverage of AWS security services
- Easier to maintain single provider
- Aligns with largest employment market

### Negative

- Does not demonstrate Azure/GCP knowledge
- AWS-specific patterns may need adaptation for other clouds
- Some employers prioritize other clouds

### Mitigations

- Document which concepts are cloud-agnostic
- Note equivalent services in other clouds where relevant
- Architecture patterns (defense in depth, least privilege) transfer to any cloud

## References

- Gartner Cloud Infrastructure Market Share
- AWS Well-Architected Security Pillar
- HashiCorp AWS Provider Documentation
