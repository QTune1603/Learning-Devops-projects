# VPC outputs definition goes here

output "vpc_id" {
    description = "ID of VPC just created"
    value = aws_vpc.main.id
}

output "public_subnet_ids" {
    description = "List of ID Public Subnets"
    value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
    description = "List of ID Private Subnets"
    value = aws_subnet.private[*].id
}