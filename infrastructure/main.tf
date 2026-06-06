# Terraform configuration for AWS 3-Tier Architecture

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Call Module VPC to create network infrastructure
module "vpc" {
  source          = "./modules/vpc"
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = var.availability_zones
  environment     = var.environment
}
# 2. Call Module Security to configure Security Groups
module "security" {
  source      = "./modules/security"
  vpc_id      = module.vpc.vpc_id  # Get the ID of the VPC just created in Module VPC and pass it here
  environment = var.environment
}

# 3. Call Module RDS to initialize MySQL Database
module "rds" {
  source                = "./modules/rds"
  environment           = var.environment
  subnet_ids            = module.vpc.private_subnet_ids # Get private subnets from VPC
  rds_security_group_id = module.security.rds_security_group_id # Get DB security group from Module Security
  db_username           = var.db_username
  db_password           = var.db_password
}

# 4. Call Module ALB to config Load Balancer
module "alb" {
  source = "./modules/alb"
  environment = var.environment
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids # Put ALB into Public Subnets
  alb_security_group_id = module.security.alb_security_group_id # # Get ALB Security group from module security
}

# 5. Call Module ASG to manage EC2 server cluster running Tomcat
module "asg" {
  source                   = "./modules/asg"
  environment              = var.environment
  vpc_id                   = module.vpc.vpc_id
  private_subnet_ids       = module.vpc.private_subnet_ids       # Run EC2 servers in private subnets
  tomcat_security_group_id = module.security.tomcat_security_group_id # Get Security group for Tomcat
  target_group_arn         = module.alb.target_group_arn         # Register EC2 with ALB Target Group
  instance_type            = var.instance_type

  # Pass DB connection information to EC2 servers
  db_host                  = module.rds.db_hostname  # Get actual hostname of database created from Module RDS
  db_user                  = var.db_username
  db_password              = var.db_password

  # Pass S3 Bucket info for artifact deployment
  s3_bucket_name           = module.s3.bucket_name
  s3_bucket_arn            = module.s3.bucket_arn
}

# 6. Call Module S3 to create application deployment artifact bucket
module "s3" {
  source      = "./modules/s3"
  environment = var.environment
}


