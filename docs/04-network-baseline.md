# Network Baseline

This document describes the network security controls implemented in the network-baseline module.

---

## Overview

| Component | Purpose |
|-----------|---------|
| VPC | Isolated network boundary |
| Subnets | Public/private tier separation |
| NAT Gateway | Controlled outbound access |
| Security Groups | Instance-level firewall |
| Flow Logs | Network traffic audit |

---

## VPC Architecture

### CIDR Allocation

| Environment | VPC CIDR | Public Subnets | Private Subnets |
|-------------|----------|----------------|-----------------|
| Nonprod | 10.1.0.0/16 | 10.1.1.0/24, 10.1.2.0/24 | 10.1.11.0/24, 10.1.12.0/24 |
| Prod | 10.2.0.0/16 | 10.2.1.0/24, 10.2.2.0/24, 10.2.3.0/24 | 10.2.11.0/24, 10.2.12.0/24, 10.2.13.0/24 |

### Subnet Layout

```
VPC (10.x.0.0/16)
|
+-- Public Subnets (10.x.1-3.0/24)
|   |-- NAT Gateway(s)
|   |-- Load Balancers (if needed)
|   |-- Bastion hosts (if needed)
|
+-- Private Subnets (10.x.11-13.0/24)
    |-- Application workloads
    |-- Databases
    |-- Internal services
```

### Routing

| Route Table | Destination | Target |
|-------------|-------------|--------|
| Public | 0.0.0.0/0 | Internet Gateway |
| Public | 10.x.0.0/16 | Local |
| Private | 0.0.0.0/0 | NAT Gateway |
| Private | 10.x.0.0/16 | Local |

---

## NAT Gateway Configuration

### Nonprod (Cost Optimization)

Single NAT Gateway shared across all private subnets:

```
Private Subnet 1 --+
                   +--> NAT Gateway --> Internet
Private Subnet 2 --+
```

Trade-off: Lower cost, single point of failure

### Prod (High Availability)

NAT Gateway per Availability Zone:

```
Private Subnet 1 --> NAT Gateway 1 --> Internet
Private Subnet 2 --> NAT Gateway 2 --> Internet
Private Subnet 3 --> NAT Gateway 3 --> Internet
```

Trade-off: Higher cost, AZ-independent resilience

---

## Security Groups

### Default Security Group (Deny All)

The VPC default security group is locked down:

| Direction | Rule |
|-----------|------|
| Ingress | None (deny all) |
| Egress | None (deny all) |

This prevents accidental use of the default SG. Resources must explicitly use a defined security group.

### Baseline Workload Security Group

Template for workload security groups with minimal egress:

| Direction | Port | Protocol | Destination | Purpose |
|-----------|------|----------|-------------|---------|
| Egress | 443 | TCP | 0.0.0.0/0 | HTTPS (AWS APIs, updates) |
| Egress | 53 | UDP | VPC CIDR | DNS resolution |
| Egress | 53 | TCP | VPC CIDR | DNS resolution (TCP fallback) |

No ingress rules by default. Add per-workload ingress as needed.

### Using the Baseline SG

```hcl
resource "aws_security_group" "app" {
  name        = "my-app-sg"
  description = "Security group for my application"
  vpc_id      = module.network.vpc_id

  # Inherit baseline egress by referencing
  # Or define custom egress

  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

## VPC Flow Logs

### Configuration

| Setting | Value |
|---------|-------|
| Traffic type | ALL (accepted + rejected) |
| Destination | CloudWatch Logs |
| Aggregation interval | 60 seconds |
| Encryption | KMS CMK |

### Retention

| Environment | Retention |
|-------------|-----------|
| Nonprod | 30 days |
| Prod | 365 days |

### Log Format

Default flow log format includes:

- Source/destination IP and port
- Protocol
- Packets and bytes
- Start/end time
- Action (ACCEPT/REJECT)
- Log status

### Analysis Queries

**Rejected traffic by source:**
```
fields @timestamp, srcAddr, dstAddr, dstPort, action
| filter action = "REJECT"
| stats count(*) by srcAddr
| sort count desc
| limit 20
```

**Top talkers by bytes:**
```
fields @timestamp, srcAddr, dstAddr, bytes
| stats sum(bytes) as totalBytes by srcAddr, dstAddr
| sort totalBytes desc
| limit 20
```

---

## Module Configuration

```hcl
module "network" {
  source = "../../modules/network-baseline"

  environment  = "prod"
  project_name = "lz"

  vpc_cidr             = "10.2.0.0/16"
  public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnet_cidrs = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false  # HA for prod

  enable_flow_logs         = true
  flow_logs_retention_days = 365
  kms_key_arn              = var.shared_kms_key_arn
}
```

---

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC identifier |
| `vpc_cidr_block` | VPC CIDR range |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `nat_gateway_public_ips` | NAT Gateway public IPs |
| `default_security_group_id` | Default SG ID (deny all) |
| `baseline_workload_security_group_id` | Baseline workload SG ID |
| `flow_logs_log_group_name` | CloudWatch Log Group for flow logs |

---

## Design Decisions

### Why No Public IPs on Launch?

`map_public_ip_on_launch = false` for public subnets because:

1. Instances should use Elastic IPs or Load Balancers for public access
2. Prevents accidental public exposure of instances
3. Forces explicit decision about public accessibility

### Why DNS Traffic to VPC Only?

The baseline SG restricts DNS (port 53) to VPC CIDR because:

1. AWS VPC DNS resolver is at VPC CIDR + 2
2. External DNS could be used for data exfiltration
3. Workloads should use VPC DNS for internal resolution

### Why HTTPS Egress to 0.0.0.0/0?

Wide HTTPS egress is allowed because:

1. AWS API endpoints require HTTPS
2. Package managers and updates need HTTPS
3. VPC endpoints can further restrict if needed

For stricter control, add VPC endpoints for AWS services and restrict egress to known CIDRs.

---

## Future Enhancements

| Enhancement | Benefit |
|-------------|---------|
| VPC Endpoints for S3/DynamoDB | Reduce NAT costs, keep traffic private |
| Network ACLs for private subnets | Additional layer of defense |
| Transit Gateway | Multi-VPC connectivity |
| AWS Network Firewall | Deep packet inspection |
