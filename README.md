# Deploy Java Application on AWS 3-Tier Architecture

This repository is a learning project dedicated to understanding DevOps practices by deploying a production-grade Java web application using AWS's robust 3-tier architecture. 

The implementation follows cloud-native best practices, ensuring high availability, scalability, and security across all application tiers.

---

## Architecture Overview

Here is a conceptual view of the architecture:

```
                  +---------------------------------------+
                  |         Internet/Users                |
                  +---------------------------------------+
                                      |
                                      v
                  +---------------------------------------+
                  |    Network Load Balancer (Public)     |
                  +---------------------------------------+
                                      |
                                      v
+--------------------------------------------------------------------------+
| Presentation Tier (Frontend) - Public Subnet                             |
|  - Nginx Web Servers (managed by Auto Scaling Group)                     |
|  - Static content cached via CloudFront Distribution                     |
+--------------------------------------------------------------------------+
                                      |
                                      v
                  +---------------------------------------+
                  |      Internal Load Balancer           |
                  +---------------------------------------+
                                      |
                                      v
+--------------------------------------------------------------------------+
| Application Tier (Backend) - Private Subnet                              |
|  - Apache Tomcat App Servers (managed by Auto Scaling Group)             |
|  - Session management with Amazon ElastiCache (Redis)                    |
+--------------------------------------------------------------------------+
                                      |
                                      v
+--------------------------------------------------------------------------+
| Data Tier - Private DB Subnet                                            |
|  - Amazon RDS MySQL (Multi-AZ with Automated Backups)                    |
|  - Read replicas for read-heavy workloads                                |
+--------------------------------------------------------------------------+
```

### Key Features
- **High Availability**: Multi-AZ deployment with automated failover.
- **Auto Scaling**: Dynamic resource allocation based on traffic demand.
- **Security**: Defense-in-depth approach with multiple security layers (Public/Private Subnets, Security Groups, NAT Gateways).
- **Monitoring**: Comprehensive logging and monitoring setup via CloudWatch.
- **CI/CD Integration**: Integrated with SonarCloud for code quality and JFrog Artifactory for binary artifact management.

---

## Pre-Requisites

### 1. AWS Account Setup
- Create an [AWS Free Tier Account](https://aws.amazon.com/free/).
- Install **AWS CLI v2** and configure it with your credentials:
  ```bash
  aws configure
  ```

### 2. Development & Devops Tools
- **Git**: Version control system.
- **Terraform** (>= 1.0.0): Infrastructure as Code tool.
- **JDK 11** & **Maven**: For building and packaging the Java Login Application.

### 3. Third-party SaaS Tools
- **SonarCloud Account**:
  - Sign up at [SonarCloud](https://sonarcloud.io/).
  - Generate an authentication token for code quality checks.
- **JFrog Artifactory**:
  - Create a free tier account on [JFrog Cloud](https://jfrog.com/start-free/).
  - Set up a Maven repository to store application artifacts.

---

## Directory Structure

```
Learning-Devops-projects/
├── .gitignore
├── README.md               # Main documentation (this file)
├── .github/
│   └── workflows/
│       └── maven-build.yml # GitHub Actions CI/CD Pipeline configuration
├── docs/
│   └── infrastructure_flow_guide.md  # Detailed architectural flow guide
├── Java-Login-App/         # Java application codebase
│   └── README.md           # Application & Database setup documentation
└── infrastructure/         # Terraform templates
    ├── README.md           # Infrastructure provisioning documentation
    ├── main.tf
    ├── variables.tf
    └── modules/            # Reusable modules (vpc, security, alb, asg, rds, s3)
```

---

## Next Steps

1. Go to the [infrastructure/](file:///e:/DevOps-projects/Learning-Devops-projects/infrastructure/README.md) directory to set up the AWS infrastructure.
2. Go to the [Java-Login-App/](file:///e:/DevOps-projects/Learning-Devops-projects/Java-Login-App/README.md) directory to explore the application and set up the MySQL database schema.

---
