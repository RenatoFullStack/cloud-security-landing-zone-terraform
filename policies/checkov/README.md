# Custom Checkov Policies

This directory contains custom Checkov policies that enforce organization-specific security requirements beyond the built-in checks.

## Policies

| ID | Name | Severity | Description |
|----|------|----------|-------------|
| CUSTOM_AWS_001 | Required Tags | MEDIUM | All resources must have Environment and ManagedBy tags |
| CUSTOM_AWS_002 | S3 Versioning | HIGH | All S3 buckets must have versioning enabled |
| CUSTOM_AWS_003 | IAM Role Descriptions | LOW | All IAM roles must have descriptions |
| CUSTOM_AWS_004 | KMS Key Rotation | HIGH | All KMS keys must have rotation enabled |
| CUSTOM_AWS_005 | No Unrestricted SSH | CRITICAL | No SSH access from 0.0.0.0/0 |
| CUSTOM_AWS_006 | CloudTrail Validation | HIGH | CloudTrail log file validation enabled |

## Usage

### Local Scan

```bash
checkov -d terraform/ --external-checks-dir policies/checkov/
```

### CI Integration

The custom policies are automatically included in the CI pipeline via the `.checkov.yml` configuration file.

## Adding New Policies

1. Add the policy definition to `custom-policies.yaml`
2. Test locally with `checkov -d terraform/ --external-checks-dir policies/checkov/`
3. Update this README with the new policy details
4. Submit a PR for review

## Policy Severity Levels

- **CRITICAL**: Must be fixed immediately, blocks deployment
- **HIGH**: Should be fixed before production deployment
- **MEDIUM**: Should be addressed in next sprint
- **LOW**: Best practice, fix when convenient

## References

- [Checkov Custom Policies Documentation](https://www.checkov.io/3.Custom%20Policies/YAML%20Custom%20Policies.html)
- [Checkov Built-in Checks](https://www.checkov.io/5.Policy%20Index/terraform.html)
