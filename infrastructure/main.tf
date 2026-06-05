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
