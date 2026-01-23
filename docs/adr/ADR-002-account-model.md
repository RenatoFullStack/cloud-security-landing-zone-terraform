# ADR-002: Account and Environment Model

## Status

Accepted

## Date

2024-01-15

## Context

A security landing zone requires separation between different workload types and security levels. The account/environment model determines how this separation is achieved.

Options considered:

1. **Multi-account with AWS Organizations** - Separate AWS accounts per environment
2. **Single account with VPC separation** - One account, isolated VPCs
3. **Hybrid** - Shared services account + workload accounts

## Decision

Single account with VPC-based separation is selected for this implementation.

## Rationale

### Simplicity for Demonstration

Multi-account architectures require:
- AWS Organizations setup
- Cross-account IAM roles
- Centralized billing configuration
- Account vending automation

For a portfolio project demonstrating security patterns, this complexity obscures the security controls being showcased.

### Security Patterns Transfer

The security controls implemented at VPC level demonstrate the same principles as account-level separation:
- Network isolation (VPC boundaries vs account boundaries)
- IAM separation (role-based vs account-based)
- Centralized logging (cross-VPC vs cross-account)
- Shared services pattern (shared environment vs shared account)

An evaluator can see the patterns and understand how they scale to multi-account.

### Cost Considerations

A portfolio project should minimize costs:
- Single account = single set of baseline resources
- No cross-account data transfer costs
- Simpler state management

### Implementation Scope

VPC-based separation is sufficient for:
- Demonstrating network security controls
- Showing environment isolation patterns
- Implementing shared services architecture

## Consequences

### Positive

- Simpler to deploy and demonstrate
- Lower cost for portfolio project
- Security patterns clearly visible
- Faster evaluation for reviewers

### Negative

- Does not demonstrate AWS Organizations experience
- Less blast radius protection than true account separation
- IAM policies in shared account increase complexity
- Cannot demonstrate Service Control Policies (SCPs)

### Mitigations

- Document how patterns scale to multi-account
- Note where SCPs would replace IAM boundaries
- Architecture diagrams show logical separation
- Add comments explaining multi-account equivalent

## Production Recommendation

For production landing zones, multi-account architecture is recommended:

```
AWS Organizations
|
+-- Management Account
|     +-- Organizations, Billing, SSO
|
+-- Security Account
|     +-- CloudTrail, GuardDuty, Security Hub
|
+-- Log Archive Account
|     +-- Centralized log storage
|
+-- Shared Services Account
|     +-- Transit Gateway, DNS, shared tooling
|
+-- Workload Accounts
      +-- Nonprod Account
      +-- Prod Account
```

This provides:
- Stronger blast radius containment
- Simplified IAM (account-level trust)
- SCP enforcement at OU level
- Clearer billing attribution

## References

- AWS Organizations Best Practices
- AWS Landing Zone Accelerator
- AWS Control Tower
- Well-Architected Multi-Account Strategy
