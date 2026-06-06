# 1. Initialize Launch Template (Template configuration to automatically create EC2 servers)
resource "aws_launch_template" "main" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI in us-east-1 region (North Virginia)
  instance_type = var.instance_type

  # Assign Tomcat Security Group (only allow traffic from ALB)
  vpc_security_group_ids = [var.tomcat_security_group_id]

    # Script Bash auto exec when EC2 starts (Bootstrap Script)
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              # Install Java 11 (Amazon Corretto)
              yum install -y java-11-amazon-corretto
              # Install Apache Tomcat
              yum install -y tomcat

              # Insert database connection variables into Tomcat system configuration file
              echo "DB_HOST=${var.db_host}" >> /etc/tomcat/tomcat.conf
              echo "DB_USER=${var.db_user}" >> /etc/tomcat/tomcat.conf
              echo "DB_PASSWORD=${var.db_password}" >> /etc/tomcat/tomcat.conf

              # Start Tomcat service
              systemctl enable tomcat
              systemctl start tomcat
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
