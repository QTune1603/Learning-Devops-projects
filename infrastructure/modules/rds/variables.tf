variable "environment" {
  description = "Environment name(ex: dev, prod)"
  type        = string
}

variable "subnet_ids" {
  description = "List ID subnets to place the database(Should be private subnets)"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "ID of Security Group used for RDS database"
  type        = string
}

variable "db_username" {
  description = "Database admin username"
  type        = string
}

variable "db_password" {
  description = "Password for database admin user"
  type        = string
  sensitive   = true
}
