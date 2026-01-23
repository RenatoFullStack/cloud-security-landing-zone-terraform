variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "lz"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# Network
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (false = HA with NAT per AZ)"
  type        = bool
  default     = false # HA for prod
}

# Shared environment references
variable "shared_kms_key_arn" {
  description = "ARN of KMS key from shared environment"
  type        = string
  default     = ""
}

variable "shared_log_bucket_name" {
  description = "Name of log bucket from shared environment"
  type        = string
  default     = ""
}

variable "shared_sns_topic_arn" {
  description = "ARN of SNS topic from shared environment"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
