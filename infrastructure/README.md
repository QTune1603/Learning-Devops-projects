# AWS Infrastructure for Java Application (IaC)

This directory contains the Terraform configurations to set up the AWS infrastructure for our 3-tier Java application deployment. The infrastructure follows AWS best practices, ensuring a secure, scalable, and highly available architecture.

---

## Infrastructure Overview

The resources provisioned by these Terraform templates include:

1. **VPC & Networking** (`modules/vpc`):
   - A primary VPC (e.g., CIDR `192.168.0.0/16`).
   - Public subnets for Application Load Balancers (ALBs) and Bastion hosts.
   - Private subnets for Tomcat Application Servers and RDS Database instances.
   - Internet Gateway (IGW) for public routing, and NAT Gateway for private instances to access the internet securely.

2. **Security Groups** (`modules/security`):
   - Strict firewall rules allowing public traffic only to the frontend Load Balancers.
   - Internal traffic routing allowing Tomcat servers to communicate with the DB and ElastiCache tiers.
   - Bastion host security groups for secure administration access (SSH).

3. **Data Layer**:
   - RDS MySQL Database deployed across multiple Availability Zones (Multi-AZ) for automatic failover.

---

## Directory Structure

```
infrastructure/
├── main.tf             # Main entry point to call modules
├── variables.tf        # Input variables definitions
├── README.md           # Infrastructure documentation (this file)
└── modules/
    ├── vpc/            # VPC and networking components
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── security/       # Security groups and rules
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## How to Deploy the Infrastructure

Follow these steps to deploy:

### Step 1: Initialize Terraform
Navigate to this directory in your terminal and initialize the backend and download the AWS provider plugins:
```bash
cd infrastructure
terraform init
```

### Step 2: Configure Variables
Create a file named `terraform.tfvars` in this directory to specify your custom variables:
```hcl
environment      = "dev"
aws_region       = "us-east-1"
vpc_cidr         = "192.168.0.0/16"
public_subnets   = ["192.168.1.0/24", "192.168.2.0/24"]
private_subnets  = ["192.168.3.0/24", "192.168.4.0/24"]
db_username      = "admin"
db_password      = "ChooseASuperSecurePassword123!"
```
> [!WARNING]
> Never commit `terraform.tfvars` or any file containing passwords to GitHub! This is already blocked in the root `.gitignore`.

### Step 3: Run Terraform Plan
Generate and inspect an execution plan to verify the resources that Terraform will create:
```bash
terraform plan
```

### Step 4: Apply Configuration
Run the apply command to build the AWS infrastructure. This might take 10-15 minutes (mainly for the RDS instance):
```bash
terraform apply
```

### Step 5: Clean Up Resources
When you are done studying, do not forget to destroy the resources to avoid incurring unexpected AWS costs:
```bash
terraform destroy
```
