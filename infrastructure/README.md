# AWS Infrastructure for Java Application (IaC)

This directory contains the Terraform configurations to set up the AWS infrastructure for our 3-tier Java application deployment. The infrastructure follows AWS best practices, ensuring a secure, scalable, and highly available architecture.

---

## Infrastructure Overview

The resources provisioned by these Terraform templates include:

1. **VPC & Networking** (`modules/vpc`):
   - A primary VPC (e.g., CIDR `192.168.0.0/16`).
   - Public subnets for the Application Load Balancer (ALB) and private subnets for application and database layers.
   - Internet Gateway (IGW) for public entry, and NAT Gateway for secure outbound internet traffic from private subnets.

2. **Security Groups** (`modules/security`):
   - Firewalls controlling access: ALB (allows public port 80/443) -> Tomcat/Nginx instances (allows traffic from ALB on port 80) -> RDS MySQL (allows traffic from Tomcat on port 3306).

3. **Application Load Balancer** (`modules/alb`):
   - Public-facing ALB listening on port 80 and forwarding traffic to Nginx reverse proxy running on Tomcat servers.

4. **Compute & Auto Scaling** (`modules/asg`):
   - EC2 Launch Templates configuring Tomcat 9 and Java 11.
   - Nginx installed and configured as a reverse proxy (port 80 -> port 8080).
   - IAM Instance Profile allowing Tomcat instances to pull deployment artifacts from S3.
   - Auto Scaling Group to dynamically scale instance count between 1 and 3.

5. **Data Layer** (`modules/rds`):
   - Amazon RDS MySQL Instance deployed across multiple Availability Zones (Multi-AZ) for automatic failover.

6. **Artifact Storage** (`modules/s3`):
   - Private, versioned, and encrypted S3 bucket to securely host application `.war` build artifacts.

---

## Directory Structure

```
infrastructure/
├── main.tf             # Main entry point to call modules
├── variables.tf        # Input variables definitions
├── README.md           # Infrastructure documentation (this file)
└── modules/
    ├── vpc/            # VPC and networking components
    ├── security/       # Security groups and rules
    ├── alb/            # Application Load Balancer (ALB)
    ├── asg/            # Auto Scaling Group (ASG) & Nginx configuration
    ├── rds/            # RDS MySQL Database
    └── s3/             # S3 bucket for artifacts
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

### Step 5: Clean Up Resources (CRITICAL)

> [!IMPORTANT]
> Because this project implements an **Auto Scaling Group (ASG)**, simply stopping or terminating the EC2 instances in the AWS console will NOT clean them up. The ASG will detect they are missing and launch new instances, continuing to consume resources.
> 
> To permanently tear down the infrastructure and avoid any unexpected AWS costs, **always run the destroy command**:
```bash
terraform destroy -auto-approve
```
