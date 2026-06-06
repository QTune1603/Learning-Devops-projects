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
