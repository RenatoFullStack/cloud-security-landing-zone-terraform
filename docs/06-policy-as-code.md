# Policy as Code

This document describes the CI/CD security pipeline and policy enforcement.

---

## Overview

Security checks are integrated into the development workflow:

```
Developer --> Pull Request --> CI Pipeline --> Security Gate --> Merge
                                   |
                                   +-- Format Check
                                   +-- Validation
                                   +-- Linting
                                   +-- Security Scan (Checkov)
                                   +-- Security Scan (tfsec)
```

All checks must pass before merge. No exceptions without documented approval.

---

## CI Pipeline Stages

### Stage 1: Terraform Format

Ensures consistent code formatting across the repository.

| Setting | Value |
|---------|-------|
| Command | `terraform fmt -check -recursive -diff` |
| Blocking | Yes |
| Auto-fix | No (developer must run `terraform fmt`) |

### Stage 2: Terraform Validate

Validates syntax and configuration correctness.

| Setting | Value |
|---------|-------|
| Command | `terraform validate` |
| Matrix | All modules and environments |
| Backend | Disabled (`-backend=false`) |

### Stage 3: TFLint

Lints Terraform code for AWS best practices.

| Setting | Value |
|---------|-------|
| Tool | TFLint v0.50.0 |
| Ruleset | AWS |
| Blocking | Soft (TFLint failures are warnings) |

### Stage 4: Checkov Security Scan

Static analysis for security misconfigurations.

| Setting | Value |
|---------|-------|
| Tool | Checkov |
| Framework | Terraform |
| Blocking | Yes (hard fail) |
| Output | CLI + SARIF |

### Stage 5: tfsec Security Scan

Additional security scanning with different rule coverage.

| Setting | Value |
|---------|-------|
| Tool | tfsec |
| Blocking | Yes (hard fail) |
| Output | SARIF (uploaded to GitHub) |

### Stage 6: Security Gate

Final aggregation of all security checks.

| Condition | Result |
|-----------|--------|
| All checks pass | Merge allowed |
| Any check fails | Merge blocked |

---

## Checkov Configuration

### Global Configuration

File: `.checkov.yml`

```yaml
framework:
  - terraform

directory:
  - terraform/

skip-check:
  - CKV2_AWS_38  # Route 53 DNS logging (not applicable)
  - CKV2_AWS_39  # Route 53 DNSSEC (not applicable)

soft-fail: false
compact: true
```

### Custom Policies

Location: `policies/checkov/custom-policies.yaml`

| Policy | Purpose |
|--------|---------|
| CUSTOM_AWS_1 | Require specific tags on all resources |
| CUSTOM_AWS_2 | Require S3 versioning |
| CUSTOM_AWS_3 | Require IAM role descriptions |
| CUSTOM_AWS_4 | Require KMS key rotation |
| CUSTOM_AWS_5 | Deny SSH from 0.0.0.0/0 |
| CUSTOM_AWS_6 | Require CloudTrail log validation |

### Skipped Checks

Checks may be skipped with documented rationale:

| Check ID | Reason |
|----------|--------|
| CKV2_AWS_38 | Route 53 not used in this project |
| CKV2_AWS_39 | Route 53 not used in this project |

To skip a check inline:

```hcl
resource "aws_s3_bucket" "example" {
  #checkov:skip=CKV_AWS_XX:Reason for skipping
  bucket = "example"
}
```

---

## Pre-commit Hooks

Optional local enforcement via pre-commit.

File: `.pre-commit-config.yaml`

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_checkov
```

### Installation

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

---

## Security Scanning Results

### SARIF Integration

Both Checkov and tfsec output SARIF format, uploaded to GitHub:

1. GitHub Security tab shows findings
2. Code scanning alerts created for issues
3. PR annotations for inline feedback

### Interpreting Results

| Severity | Action |
|----------|--------|
| Critical | Must fix before merge |
| High | Must fix before merge |
| Medium | Should fix, can request exception |
| Low | Recommended to fix |

---

## Exception Process

When a security check fails but the code is intentionally designed that way:

1. **Document** the reason in the exception request template
2. **Submit** for security review
3. **Approval** from security team
4. **Skip** the check with inline comment referencing exception ID
5. **Track** in exception registry

Example skip annotation:

```hcl
resource "aws_security_group_rule" "allow_http" {
  #checkov:skip=CKV_AWS_XX:Exception EXC-2024-001 approved for legacy app
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
}
```

---

## Local Development

### Running Checks Locally

```bash
# Format
terraform fmt -recursive terraform/

# Validate all modules
for dir in terraform/modules/*/; do
  terraform -chdir="$dir" init -backend=false
  terraform -chdir="$dir" validate
done

# Security scan
checkov -d terraform/ --config-file .checkov.yml
tfsec terraform/
```

### IDE Integration

Recommended VS Code extensions:

| Extension | Purpose |
|-----------|---------|
| HashiCorp Terraform | Syntax highlighting, validation |
| tfsec | Inline security warnings |
| Checkov | Inline security warnings |

---

## Pipeline Configuration

File: `.github/workflows/ci.yml`

Key configuration points:

```yaml
env:
  TF_VERSION: "1.5.0"
  TFLINT_VERSION: "v0.50.0"

jobs:
  checkov:
    steps:
      - uses: bridgecrewio/checkov-action@v12
        with:
          soft_fail: false  # Blocking
          config_file: .checkov.yml
```

### Branch Protection

Recommended GitHub branch protection settings:

| Setting | Value |
|---------|-------|
| Require status checks | Yes |
| Required checks | terraform-fmt, terraform-validate, checkov, tfsec, security-gate |
| Require up-to-date branches | Yes |
| Require review | 1 approval minimum |

---

## Metrics and Reporting

### Security Posture

Track over time:

- Number of Checkov findings per PR
- Time to remediate findings
- Exception requests per month
- Policy coverage (% of resources scanned)

### Dashboard

GitHub Security tab provides:

- Open security alerts
- Alert trends
- Code scanning coverage
