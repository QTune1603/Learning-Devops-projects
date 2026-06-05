# Security group outputs definition goes here
output "alb_security_group_id" {
  description = "ID of ALB Security Group"
  value       = aws_security_group.alb.id
}

output "tomcat_security_group_id" {
  description = "ID of Tomcat Security Group"
  value       = aws_security_group.tomcat.id
}

output "rds_security_group_id" {
  description = "ID of RDS Security Group"
  value       = aws_security_group.rds.id
}
