variable "environment" {
  description = "Environment name (for ex: dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of Private Subnet IDs for running EC2 Tomcat"
  type        = list(string)
}

variable "tomcat_security_group_id" {
  description = "ID of Security Group used for Tomcat Server"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of ALB Target Group for registering EC2"
  type        = string
}       

variable "instance_type" {
  description = "EC2 instance type to run applications"
  type        = string
}
