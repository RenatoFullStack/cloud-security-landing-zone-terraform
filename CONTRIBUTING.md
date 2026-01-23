# Contributing to Cloud Security Landing Zone

Thank you for your interest in contributing to this project!

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs or request features
- Include your environment details (OS, Terraform version, AWS CLI version)
- Provide clear steps to reproduce the issue

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run validation checks (see below)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Validation Checks

Before submitting a PR, ensure:

```bash
# Format check
terraform fmt -check -recursive terraform/

# Validate all modules
for dir in terraform/modules/*/; do
  terraform -chdir="$dir" init -backend=false
  terraform -chdir="$dir" validate
done

# Security scan
checkov -d terraform/ --framework terraform

# Lint
tflint --recursive terraform/
```

## Code Standards

### Terraform

- Follow [Terraform best practices](https://www.terraform.io/docs/language/index.html)
- Use meaningful resource names with consistent prefixes
- Include descriptions for all variables and outputs
- Add comments for complex logic only
- Keep modules focused and single-purpose

### Documentation

- Update relevant docs when changing functionality
- Follow ADR format for architectural decisions
- Keep README sections up to date

### Security

- Never commit secrets or credentials
- All resources must be encrypted by default
- Follow least privilege principle for IAM
- Security group rules must be explicit (no `0.0.0.0/0` without justification)

## Questions?

Open an issue for any questions about contributing.
