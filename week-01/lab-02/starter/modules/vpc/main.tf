# modules/vpc/main.tf
# VPC Module Resources
# Students must research AWS provider documentation to complete this

locals {
  # Standard tags applied to all resources
  default_tags = {
    Name        = var.vpc_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "vpc"
  }

  # Merge default tags with user-provided tags
  all_tags = merge(local.default_tags, var.tags)
}

# TODO: Create the VPC resource
# RESEARCH: Navigate to https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
# FIND: What are the required arguments for aws_vpc?
# HINT: At minimum you need cidr_block
resource "aws_vpc" "this" {
  # TODO: Add required arguments here
  # cidr_block = ?

  # TODO: Add optional arguments for DNS
  # enable_dns_hostnames = ?
  # enable_dns_support = ?

  tags = merge(local.all_tags, {
    Name = var.vpc_name
  })
}

# TODO: Create Internet Gateway
# RESEARCH: Look up aws_internet_gateway resource
# QUESTION: What does an Internet Gateway do?
# HINT: It allows communication between your VPC and the internet
resource "aws_internet_gateway" "this" {
  # TODO: Attach this IGW to your VPC
  # vpc_id = ?

  tags = merge(local.all_tags, {
    Name = "${var.vpc_name}-igw"
  })
}

# TODO: Create public subnets
# RESEARCH: Look up aws_subnet resource
# CHALLENGE: You need to create multiple subnets, one per AZ
# HINT: Use count or for_each to create multiple resources
# THINK: Which approach is more flexible?
resource "aws_subnet" "public" {
  # TODO: Use count or for_each to create multiple subnets
  # count = ?
  # for_each = ?

  # TODO: Add required arguments
  # vpc_id = ?
  # cidr_block = ?
  # availability_zone = ?

  # TODO: Make these subnets "public"
  # RESEARCH: What makes a subnet public vs private?
  # HINT: map_public_ip_on_launch = true

  tags = merge(local.all_tags, {
    Name = "${var.vpc_name}-public-${count.index + 1}"  # Adjust if using for_each
    Type = "Public"
  })
}

# TODO: Create private subnets
# RESEARCH: Same as public subnets, but different configuration
# THINK: Should private subnets auto-assign public IPs?
resource "aws_subnet" "private" {
  # TODO: Similar to public subnets, but for private subnet CIDRs

  tags = merge(local.all_tags, {
    Name = "${var.vpc_name}-private-${count.index + 1}"  # Adjust if using for_each
    Type = "Private"
  })
}

# TODO: Create route table for public subnets
# RESEARCH: Look up aws_route_table resource
# QUESTION: What's a route table and why do you need one?
# HINT: It controls where network traffic is directed
resource "aws_route_table" "public" {
  # TODO: Associate with your VPC
  # vpc_id = ?

  tags = merge(local.all_tags, {
    Name = "${var.vpc_name}-public-rt"
    Type = "Public"
  })
}

# TODO: Create route for internet access
# RESEARCH: Look up aws_route resource
# QUESTION: How do you route traffic to the internet?
# HINT: 0.0.0.0/0 means "all traffic"
resource "aws_route" "public_internet" {
  # TODO: Add route to internet gateway
  # route_table_id = ?
  # destination_cidr_block = "0.0.0.0/0"
  # gateway_id = ?
}

# TODO: Associate public subnets with public route table
# RESEARCH: Look up aws_route_table_association resource
# CHALLENGE: You need to associate each public subnet
# HINT: Use count or for_each matching your subnets
resource "aws_route_table_association" "public" {
  # TODO: Associate each public subnet with the public route table
  # count = ?
  # subnet_id = ?
  # route_table_id = ?
}

# TODO: Create route table for private subnets
# RESEARCH: Do private subnets need a route table?
# THINK: Private subnets don't need internet access, but they need local routing
# NOTE: We're not implementing NAT Gateway in this lab (cost optimization)
resource "aws_route_table" "private" {
  # TODO: Create private route table
  # vpc_id = ?

  tags = merge(local.all_tags, {
    Name = "${var.vpc_name}-private-rt"
    Type = "Private"
  })
}

# TODO: Associate private subnets with private route table
# RESEARCH: Similar to public subnet associations
resource "aws_route_table_association" "private" {
  # TODO: Associate each private subnet with the private route table
  # count = ?
  # subnet_id = ?
  # route_table_id = ?
}

# TODO: Create DB subnet group for RDS
# RESEARCH: Look up aws_db_subnet_group resource
# QUESTION: Why does RDS need its own subnet group?
# HINT: RDS requires specific subnet configuration for high availability
resource "aws_db_subnet_group" "this" {
  # TODO: Configure DB subnet group
  # name = "${var.vpc_name}-db-subnet-group"
  # subnet_ids = [list of private subnet IDs]

  tags = merge(local.all_tags, {
    Name = "${var.vpc_name}-db-subnet-group"
  })
}