# AWS Security Landing Zone

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-844fba.svg?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS_Provider-~%3E5.0-FF9900.svg?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Checkov](https://img.shields.io/badge/Checkov-passing-4CAF50.svg?logo=paloaltonetworks)](https://www.checkov.io/)
[![tfsec](https://img.shields.io/badge/tfsec-passing-1F8ACB.svg?logo=aquasecurity)](https://aquasecurity.github.io/tfsec/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CIS Benchmark](https://img.shields.io/badge/CIS_AWS-v1.5-orange.svg)](https://www.cisecurity.org/benchmark/amazon_web_services)

This project started as a way to consolidate security patterns I've implemented across different AWS environments into a reusable baseline. Too often I've seen landing zones that tick compliance boxes but miss practical security controls - or worse, implement them inconsistently across environments.

The goal here is to have a working reference that demonstrates how detection, prevention, and audit controls fit together in a real AWS deployment.

---

## TL;DR

**What this proves:**
- Infrastructure-as-code with security baked in, not bolted on
- Policy-as-code gates that actually block insecure deployments
- Detection and alerting that catches real attack patterns
- Exception workflow for when security needs to flex

**Verify controls work:**

```bash
# Check all modules validate
for dir in terraform/modules/*/; do
  terraform -chdir="$dir" init -backend=false && terraform -chdir="$dir" validate
done

# Run security scans (these would block a PR)
checkov -d terraform/ --config-file .checkov.yml
tfsec terraform/

# See what gets deployed
terraform -chdir=terraform/environments/shared plan
```

---

## Security Highlights

<table>
<tr>
<td width="50%" valign="top">

### Detection & Monitoring

| Control | Implementation |
|---------|----------------|
| Audit trail | CloudTrail multi-region with S3 + Lambda data events |
| Threat detection | GuardDuty with S3/EKS protection |
| Compliance checks | 12 AWS Config rules (CIS sections 1-4) |
| Log integrity | Validation enabled, immutable bucket |

</td>
<td width="50%" valign="top">

### Alerting

| Trigger | Rationale |
|---------|-----------|
| Root account usage | Should never happen in normal ops |
| IAM policy changes | Catch privilege escalation |
| 3+ login failures/5min | Brute force detection |
| Security group changes | Network exposure drift |
| KMS key deletion | Data loss prevention |

</td>
</tr>
<tr>
<td width="50%" valign="top">

### Prevention

| Control | Implementation |
|---------|----------------|
| Network isolation | Default SG with zero rules |
| Egress control | Baseline SG: HTTPS only, no ingress |
| Privilege boundaries | Permission boundaries on all roles |
| Public exposure | S3 public access blocked at account level |
| Encryption | KMS CMK with annual rotation, EBS default encryption |

</td>
<td width="50%" valign="top">

### Governance

| Control | Implementation |
|---------|----------------|
| Policy-as-code | Checkov + tfsec blocking gates |
| Exception process | Risk assessment, compensating controls, expiration |
| Emergency access | Break-glass role with MFA + immediate alerting |
| Retention | 7-year CloudTrail, tiered S3 lifecycle |

</td>
</tr>
</table>

---

## Why This Project?

I built this for a few reasons:

| Audience | What they get |
|----------|---------------|
| **Myself** | A reference I can actually reuse instead of rebuilding from scratch |
| **Teams I work with** | Baseline that's opinionated but flexible enough to extend |
| **Reviewers** | Evidence of how I approach cloud security architecture |

This isn't a "deploy and forget" solution. It's a foundation that needs tuning for specific workloads, compliance requirements, and organizational context.

---

## Architecture

```
terraform/
  environments/
    shared/       # CloudTrail, KMS, IAM baseline, SNS alerts
    nonprod/      # VPC (single NAT), Config rules, GuardDuty
    prod/         # VPC (HA NAT per AZ), stricter retention

  modules/
    identity-baseline/    # Password policy, break-glass, permission boundaries
    logging-audit/        # CloudTrail, log bucket, 5 security alarms
    network-baseline/     # VPC, subnets, security groups, flow logs
    data-protection/      # KMS, S3 public block, EBS encryption
    guardrails/           # Config rules, GuardDuty
```

The shared environment deploys first and creates resources that workload environments reference (KMS key ARN, SNS topic for alerts). This mirrors how security accounts work in multi-account setups.

---

## Standards Alignment

| Standard | Coverage |
|----------|----------|
| **CIS AWS Foundations v1.5** | Sections 1-4: Identity, Logging, Monitoring, Networking |
| **AWS Well-Architected (Security Pillar)** | SEC01-SEC10 addressed at baseline level |
| **NIST 800-53** | AC, AU, SC control families |
| **SOC 2** | CC6.1, CC6.6, CC6.7 (logical access, system operations) |

The [08-threat-model.md](docs/08-threat-model.md) maps specific attack scenarios to controls.

---

## CI Pipeline

Every PR runs through:

```
terraform fmt -check
       |
terraform validate (matrix: all modules + environments)
       |
tflint
       |
checkov (soft_fail: false)
       |
tfsec (soft_fail: false)
       |
security-gate (aggregates results)
```

Both security scanners run with blocking enabled. If either finds issues, the PR cannot merge. The exception process exists for when this needs to be overridden with proper justification.

---

## Documentation

| Doc | Content |
|-----|---------|
| [00-evaluate-in-15min.md](docs/00-evaluate-in-15min.md) | Quick walkthrough for code reviewers |
| [01-architecture-overview.md](docs/01-architecture-overview.md) | Environment model, data flows |
| [02-identity-baseline.md](docs/02-identity-baseline.md) | Break-glass design, permission boundaries |
| [03-logging-and-audit.md](docs/03-logging-and-audit.md) | CloudTrail config, alert patterns |
| [04-network-baseline.md](docs/04-network-baseline.md) | VPC layout, security group strategy |
| [05-encryption-and-keys.md](docs/05-encryption-and-keys.md) | KMS key policy, rotation |
| [06-policy-as-code.md](docs/06-policy-as-code.md) | CI pipeline, Checkov config |
| [07-exceptions-process.md](docs/07-exceptions-process.md) | How to deviate from controls safely |
| [08-threat-model.md](docs/08-threat-model.md) | Attack scenarios, residual risks |

### Architecture Decision Records

- [ADR-001: Cloud choice](docs/adr/ADR-001-cloud-choice.md) - Why AWS for this implementation
- [ADR-002: Account model](docs/adr/ADR-002-account-model.md) - VPC isolation vs multi-account tradeoffs
- [ADR-003: Break-glass design](docs/adr/ADR-003-break-glass.md) - Emergency access approach
- [ADR-004: Log retention](docs/adr/ADR-004-logging-retention.md) - 7-year retention rationale

---

## What This Doesn't Cover

This is a baseline, not a complete solution:

- **Workload IAM** - You'll need roles specific to your applications
- **Application security groups** - Use the baseline SG as a starting point
- **Secrets management** - Integrate Secrets Manager or Parameter Store
- **Backup policies** - Define based on RPO/RTO requirements
- **Cost controls** - Add budgets and alerts for your context

For multi-account at scale, look at AWS Control Tower or Landing Zone Accelerator. This project demonstrates the patterns; those tools add the account vending and guardrails distribution.

---

## License

MIT. See [LICENSE](LICENSE).
