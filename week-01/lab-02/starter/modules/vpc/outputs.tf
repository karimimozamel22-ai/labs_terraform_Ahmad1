# modules/vpc/outputs.tf
# VPC Module Outputs
# Think: What information will other modules need from this VPC?

# Basic VPC information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

# TODO: Output public subnet IDs
# THINK: Which other modules need to know about public subnets?
# HINT: The compute module will place EC2 instances in public subnets
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  # TODO: Extract IDs from your public subnet resources
  # HINT: aws_subnet.public[*].id if using count
  # HINT: values(aws_subnet.public)[*].id if using for_each
  value = []  # TODO: Replace with actual subnet IDs
}

# TODO: Output private subnet IDs
# THINK: Which modules need private subnets?
# HINT: The database module uses private subnets
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  # TODO: Extract IDs from your private subnet resources
  value = []  # TODO: Replace with actual subnet IDs
}

# TODO: Output DB subnet group name
# THINK: How will the database module know which subnet group to use?
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  # TODO: Reference your DB subnet group resource
  value = ""  # TODO: Replace with actual DB subnet group name
}

# TODO: Output availability zones
# THINK: Other modules might need to know which AZs are being used
output "availability_zones" {
  description = "Availability zones used by this VPC"
  value       = var.availability_zones
}

# Internet Gateway ID (might be useful for advanced configurations)
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

# Route table IDs (for advanced networking)
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}