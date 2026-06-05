# VPC variables definition goes here
variable "vpc_cidr" {
    description = "Cidr IP for VPC"
    type = string
}

variable "public_subnets" {
    description = "List of CIDR IP for Public Subnet"
    type = list(string)
}

variable "private_subnets" {
    description = "List of CIDR IP for Private Subnet"
    type = list(string)
}

variable "azs" {
    description = "List of Availability Zones for create Subnet"
    type = list(string)
}

variable "environment" {
    description = "Name environment(exp: dev, prod)"
    type = string
}