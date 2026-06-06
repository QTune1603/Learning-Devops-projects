variable "environment" {
  description = "Environment name (exp: dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of VPC where ALB is initialized"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of Public Subnet IDs to place ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security Group ID allocated to ALB"
  type        = string
}
