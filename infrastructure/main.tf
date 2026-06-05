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

# --- VPC & Networking Module Placeholder ---
# module "vpc" {
#   source = "./modules/vpc"
#   vpc_cidr        = var.vpc_cidr
#   public_subnets  = var.public_subnets
#   private_subnets = var.private_subnets
#   environment     = var.environment
# }

# --- Security Groups Module Placeholder ---
# module "security" {
#   source = "./modules/security"
#   vpc_id = module.vpc.vpc_id
#   environment = var.environment
# }
