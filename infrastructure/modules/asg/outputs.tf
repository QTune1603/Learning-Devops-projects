output "asg_name" {
    description = "Name of Auto Scaling Group"
    value = aws_autoscaling_group.main.name
}

output "asg_arn" {
    description = "ARN Code of Auto Scaling Group"
    value = aws_autoscaling_group.main.arn
}