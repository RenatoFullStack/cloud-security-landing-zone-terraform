# Network Baseline Module

This module implements network security controls for the landing zone.

## Features

- **VPC**: Isolated network with DNS support
- **Public Subnets**: For internet-facing resources (load balancers, bastion hosts)
- **Private Subnets**: For internal workloads (no direct internet access)
- **NAT Gateway**: Controlled egress for private subnets
- **Default Security Group**: Deny-all configuration (unused by design)
- **VPC Flow Logs**: Network traffic audit logging

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                              VPC                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    PUBLIC SUBNETS                        │    │
│  │  ┌─────────────┐  ┌─────────────┐                       │    │
│  │  │  Public-1   │  │  Public-2   │ ◄── Internet Gateway  │    │
│  │  │  (AZ-a)     │  │  (AZ-b)     │                       │    │
│  │  └──────┬──────┘  └──────┬──────┘                       │    │
│  │         │                │                               │    │
│  │         └───────┬────────┘                               │    │
│  │                 │                                        │    │
│  │           NAT Gateway                                    │    │
│  │                 │                                        │    │
│  └─────────────────┼────────────────────────────────────────┘    │
│                    │                                             │
│  ┌─────────────────┼────────────────────────────────────────┐    │
│  │                 ▼          PRIVATE SUBNETS               │    │
│  │  ┌─────────────┐  ┌─────────────┐                       │    │
│  │  │  Private-1  │  │  Private-2  │ ◄── No direct internet│    │
│  │  │  (AZ-a)     │  │  (AZ-b)     │                       │    │
│  │  └─────────────┘  └─────────────┘                       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  [VPC Flow Logs] ──► CloudWatch Logs                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

```hcl
module "network" {
  source = "../../modules/network-baseline"

  environment  = "nonprod"
  project_name = "myproject"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization for non-prod

  enable_flow_logs         = true
  flow_logs_retention_days = 90
  kms_key_arn              = module.data_protection.kms_key_arn

  tags = {
    Owner = "platform-team"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name | `string` | n/a | yes |
| project_name | Project name | `string` | `"lz"` | no |
| vpc_cidr | VPC CIDR block | `string` | `"10.0.0.0/16"` | no |
| availability_zones | AZs to use | `list(string)` | `[]` | no |
| public_subnet_cidrs | Public subnet CIDRs | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | no |
| private_subnet_cidrs | Private subnet CIDRs | `list(string)` | `["10.0.11.0/24", "10.0.12.0/24"]` | no |
| enable_nat_gateway | Enable NAT Gateway | `bool` | `true` | no |
| single_nat_gateway | Use single NAT Gateway | `bool` | `true` | no |
| enable_flow_logs | Enable VPC Flow Logs | `bool` | `true` | no |
| flow_logs_retention_days | Flow log retention | `number` | `90` | no |
| kms_key_arn | KMS key for encryption | `string` | `null` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr_block | CIDR of the VPC |
| public_subnet_ids | Public subnet IDs |
| private_subnet_ids | Private subnet IDs |
| nat_gateway_ids | NAT Gateway IDs |
| default_security_group_id | Default SG ID (deny all) |
| flow_logs_log_group_arn | Flow Logs CloudWatch ARN |

## Security Controls

| Control | Implementation |
|---------|----------------|
| Network isolation | Separate public/private subnets |
| Default deny | Default SG blocks all traffic |
| Egress control | NAT Gateway for controlled outbound |
| Audit logging | VPC Flow Logs to CloudWatch |
| No public IPs | `map_public_ip_on_launch = false` |
