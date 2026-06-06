output "alb_dns_name" {
  description = "Public DNS Name to access website via ALB"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "ARN of ALB Target Group (used for Auto Scaling Group)"
  value       = aws_lb_target_group.main.arn
}
