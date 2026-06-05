# VPC module implementation goes here
# 1. Init VPC
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "${var.environment}-vpc"
        Environment = var.environment
    }
}

# 2. Create Internet Gateway 
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.environment}-igw"
        Environment = var.environment
    }
}

# 3. Create Public Subnets(For Load Balancer / Nginx Frontend)
resource "aws_subnet" "public" {
    count = length(var.public_subnets)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnets[count.index]
    availability_zone = var.azs[count.index]
    map_public_ip_on_launch = true # Auto assign public IP for resource in this subnet

    tags = {
        Name = "${var.environment}-public-subnet-${count.index + 1}"
        Environment = var.environment
    }
}

# 4. Create Private Subnets (For App Server / Database)
resource "aws_subnet" "private" {
    count = length(var.private_subnets)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnets[count.index]
    availability_zone = var.azs[count.index]

    tags = {
        Name = "${var.environment}-private-subnet-${count.index + 1}"
        Environment = var.environment
    }
}

# 5. Create Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
    domain = "vpc"

    tags = {
        Name = "${var.environment}-nat-eip"
        Environment = var.environment
    }
}

# 6. Create NAT Gateway(Support servers in Private Subnet download application/connect internet outbound)
resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id 
    subnet_id = aws_subnet.public[0].id  # Set NAT Gateway in the first public subnet

    tags = {
        Name = "${var.environment}-nat"
        Environment = var.environment
    }

    # Only create NAT Gateway after Internet Gateway(IGW) created
    depends_on = [aws_internet_gateway.main]
}

# 7. Route table for Public Subnets
resource "aws_route_table" "public" {
    vpc_id =aws_vpc.main.id
    # Route all public traffic outbound Internet(0.0.0.0/0) through Internet Gateway(IGW)
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
        } 

    tags = {
        Name = "${var.environment}-public-rt"
        Environment = var.environment
    }
}

# 8. Route table for Private Subnets
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    # Route all traffic to Internet through NAT Gateway(for download  package, update security,...)
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main.id
    }

    tags = {
        Name = "${var.environment}-private-rt"
        Environment = var.environment
    }
}

# 9. Connect Public Subnets with Public Route table
resource "aws_route_table_association" "public" {
    count = length(var.public_subnets)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

# 10. Connect Private Subnets with Private Route Table resource
resource "aws_route_table_association" "private" {
    count = length(var.private_subnets)
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}