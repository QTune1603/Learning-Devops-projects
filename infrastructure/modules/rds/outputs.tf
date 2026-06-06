output "db_endpoint" {
  description = "Endpoint address to connect to RDS Database (including port)"
  value       = aws_db_instance.main.endpoint
}

output "db_hostname" {
  description = "Hostname address of RDS Database (without port)"
  value       = aws_db_instance.main.address
}
