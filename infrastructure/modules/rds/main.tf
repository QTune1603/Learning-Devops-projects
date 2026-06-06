# 1. Create Database Subnet Group (cluster subnets for RDS to choose to place the database)
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

# 2. Initialize RDS MySQL Database Instance
resource "aws_db_instance" "main" {
  identifier           = "${var.environment}-database"
  allocated_storage    = 20                  # 20 GB of storage (part of AWS Free Tier)
  max_allocated_storage = 100                # Automatically scales up to 100 GB when full
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"       # Free tier virtual machine
  
  db_name              = "UserDB"            # Database name initialized in advance (must match Java application settings)
  username             = var.db_username
  password             = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id] # Only receive firewall rules from the RDS Security Group
  
  skip_final_snapshot  = true                # Ignore snapshot backup when deleting (easy to delete resources when learning)
  publicly_accessible  = false               # Not publicly accessible (only internal VPC access)

  tags = {
    Name        = "${var.environment}-db-instance"
    Environment = var.environment
  }
}
