################################################################################
# Network Outputs
################################################################################

output "vpc_id" {
  description = "ID of the prod VPC"
  value       = module.network.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the prod VPC"
  value       = module.network.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.network.private_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Public IPs of NAT Gateways"
  value       = module.network.nat_gateway_public_ips
}

output "flow_logs_log_group_name" {
  description = "Name of VPC Flow Logs CloudWatch Log Group"
  value       = module.network.flow_logs_log_group_name
}

output "availability_zones" {
  description = "Availability zones used"
  value       = module.network.availability_zones
}

################################################################################
# Guardrails Outputs
################################################################################

output "config_recorder_id" {
  description = "ID of AWS Config recorder"
  value       = module.guardrails.config_recorder_id
}

output "enabled_config_rules_count" {
  description = "Number of enabled Config rules"
  value       = module.guardrails.enabled_rules_count
}

output "config_rules" {
  description = "Map of enabled Config rules"
  value       = module.guardrails.config_rules
}
