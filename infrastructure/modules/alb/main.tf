# 1. Initialize Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false                     # false means public ALB (has public IP to receive traffic from Internet)
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id] # Assign security group dedicated to ALB
  subnets            = var.public_subnet_ids     # Place ALB in Public Subnets to allow user access

  enable_deletion_protection = false             # Disable deletion protection to facilitate resource deletion after learning

  tags = {
    Name        = "${var.environment}-alb"
    Environment = var.environment
  }
}

# 2. Create Target Group (Group of targets for ALB to forward traffic to EC2 Tomcat cluster)
resource "aws_lb_target_group" "main" {
  name        = "${var.environment}-tg-8080"
  port        = 8080                              # ALB routes traffic to Tomcat on port 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"                        # Route traffic to EC2 Instances

  # Health Check configuration for ALB to automatically check if Tomcat servers are alive or dead
  health_check {
    enabled             = true
    path                = "/"                     # Path used to send request to check health
    port                = "traffic-port"          # Use port 8080
    protocol            = "HTTP"
    interval            = 30                      # Check every 30 seconds
    timeout             = 5                       # Maximum response wait time is 5 seconds
    healthy_threshold   = 3                       # 3 consecutive successful checks -> server is healthy
    unhealthy_threshold = 3                       # 3 consecutive failed checks -> server is faulty and ALB will stop sending requests to it
    matcher             = "200,302,401"           # Accept 200 OK, 302 Redirect, and 401 Unauthorized (for protected endpoints)
  }

  tags = {
    Name        = "${var.environment}-target-group"
    Environment = var.environment
  }
}

# 3. Create HTTP Listener to listen for traffic on port 80 and forward it to the Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"                        # Listen on port 80 (default HTTP port for users)
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn # Forward traffic to the Target Group containing Tomcat servers
  }
}
