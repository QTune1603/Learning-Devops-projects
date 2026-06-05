# Security group variables definition goes here
variable "vpc_id" {
  description = "ID of VPC where Security Groups will be created"
  type        = string
}

variable "environment" {
  description = "Environment name (exp: dev, prod)"
  type        = string
}
