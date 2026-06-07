# Data source to dynamically get the latest Amazon Linux 2 AMI in the active region
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 1. Initialize Launch Template (Template configuration to automatically create EC2 servers)
resource "aws_launch_template" "main" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id # Dynamically uses the latest Amazon Linux 2 AMI for the active region
  instance_type = var.instance_type

  # Attach IAM Instance Profile to allow reading from S3
  iam_instance_profile {
    name = aws_iam_instance_profile.tomcat_profile.name
  }

  # Assign Tomcat Security Group (only allow traffic from ALB)
  vpc_security_group_ids = [var.tomcat_security_group_id]

  # Script Bash auto exec when EC2 starts (Bootstrap Script)
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              # Install Java 17 (Amazon Corretto)
              yum install -y java-17-amazon-corretto

              # Create application directory
              mkdir -p /opt/app

              # Download the application artifact from S3 bucket
              aws s3 cp s3://${var.s3_bucket_name}/dptweb-1.0.war /opt/app/dptweb-1.0.war
              chmod 500 /opt/app/dptweb-1.0.war

              # Create a systemd service to run the Spring Boot application (uses embedded Tomcat 9)
              cat << 'JVMEF' > /etc/systemd/system/java-app.service
              [Unit]
              Description=Java Login Web Application
              After=syslog.target network.target

              [Service]
              User=root
              ExecStart=/usr/bin/java -jar /opt/app/dptweb-1.0.war
              SuccessExitStatus=143
              Restart=always
              RestartSec=10
              Environment=DB_HOST=${var.db_host}
              Environment=DB_USER=${var.db_user}
              Environment=DB_PASSWORD=${var.db_password}

              [Install]
              WantedBy=multi-user.target
              JVMEF

              # Start services
              systemctl daemon-reload
              systemctl enable java-app
              systemctl start java-app
              EOF
  )


  # Automatically assign labels (Tags) to EC2 servers created
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-tomcat-server"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 2. Initialize Auto Scaling Group (Automatically manage the number and status of servers)
resource "aws_autoscaling_group" "main" {
  name_prefix         = "${var.environment}-asg-"
  vpc_zone_identifier = var.private_subnet_ids # Run EC2 servers hidden inside Private Subnets
  target_group_arns   = [var.target_group_arn]   # Automatically register new EC2 with ALB Target Group

  min_size            = 1                        # Minimum number of servers to maintain
  max_size            = 3                        # Maximum number of servers when overloaded
  desired_capacity    = 2                        # Desired number of servers operating normally (to run in parallel across 2 AZs)

  force_delete        = true

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  # Automatically pass ASG Tags to each child EC2 instance when started
  tag {
    key                 = "Name"
    value               = "${var.environment}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
