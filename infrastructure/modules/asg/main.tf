# 1. Initialize Launch Template (Template configuration to automatically create EC2 servers)
resource "aws_launch_template" "main" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI in us-east-1 region (North Virginia)
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
              # Install Java 11 (Amazon Corretto)
              yum install -y java-11-amazon-corretto
              # Install Apache Tomcat
              yum install -y tomcat

              # Download the application artifact from S3 bucket and deploy it as ROOT.war
              aws s3 cp s3://${var.s3_bucket_name}/dptweb-1.0.war /usr/share/tomcat/webapps/ROOT.war
              chown tomcat:tomcat /usr/share/tomcat/webapps/ROOT.war

              # Insert database connection variables into Tomcat system configuration file
              echo "DB_HOST=${var.db_host}" >> /etc/tomcat/tomcat.conf
              echo "DB_USER=${var.db_user}" >> /etc/tomcat/tomcat.conf
              echo "DB_PASSWORD=${var.db_password}" >> /etc/tomcat/tomcat.conf

              # Install Nginx
              amazon-linux-extras install -y nginx1 || yum install -y nginx

              # Configure Nginx as a Reverse Proxy pointing to Tomcat on localhost:8080
              cat << 'NGINXEOF' > /etc/nginx/nginx.conf
              user nginx;
              worker_processes auto;
              error_log /var/log/nginx/error.log;
              pid /run/nginx.pid;

              include /usr/share/nginx/modules/*.conf;

              events {
                  worker_connections 1024;
              }

              http {
                  log_format  main  '$$remote_addr - $$remote_user [$$time_local] "$$request" '
                                    '$$status $$body_bytes_sent "$$http_referer" '
                                    '"$$http_user_agent" "$$http_x_forwarded_for"';

                  access_log  /var/log/nginx/access.log  main;

                  sendfile            on;
                  tcp_nopush          on;
                  tcp_nodelay         on;
                  keepalive_timeout   65;
                  types_hash_max_size 4096;

                  include             /etc/nginx/mime.types;
                  default_type        application/octet-stream;

                  include /etc/nginx/conf.d/*.conf;

                  server {
                      listen       80 default_server;
                      listen       [::]:80 default_server;
                      server_name  _;

                      location / {
                          proxy_pass http://127.0.0.1:8080;
                          proxy_set_header Host $$host;
                          proxy_set_header X-Real-IP $$remote_addr;
                          proxy_set_header X-Forwarded-For $$proxy_add_x_forwarded_for;
                          proxy_set_header X-Forwarded-Proto $$scheme;
                      }
                  }
              }
              NGINXEOF

              # Start services
              systemctl enable tomcat
              systemctl start tomcat
              systemctl enable nginx
              systemctl start nginx
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
