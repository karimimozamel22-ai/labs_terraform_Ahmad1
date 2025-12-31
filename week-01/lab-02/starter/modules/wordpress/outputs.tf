# modules/wordpress/outputs.tf
# WordPress Composition Module Outputs
# Expose useful information from all composed modules

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  # TODO: Pass through VPC module output
  # value = module.vpc.vpc_id
  value = ""  # TODO: Replace with module output
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  # TODO: Pass through VPC module output
  value = []  # TODO: Replace with module output
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  # TODO: Pass through VPC module output
  value = []  # TODO: Replace with module output
}

# Database Information
output "database_endpoint" {
  description = "RDS instance endpoint"
  # TODO: Pass through database module output
  value = ""  # TODO: Replace with module output
}

output "database_name" {
  description = "Name of the database"
  # TODO: Pass through database module output
  value = ""  # TODO: Replace with module output
}

# SECURITY NOTE: Don't output database credentials!
# Credentials should be managed securely (AWS Secrets Manager, etc.)

# Compute Information
output "wordpress_public_ip" {
  description = "Public IP address of the WordPress server"
  # TODO: Pass through compute module output
  value = ""  # TODO: Replace with module output
}

output "wordpress_url" {
  description = "URL to access WordPress"
  # TODO: Construct URL using compute module output
  # HINT: "http://${module.compute.public_ip}"
  value = ""  # TODO: Replace with computed URL
}

output "ssh_command" {
  description = "SSH command to connect to the WordPress server"
  # TODO: Pass through compute module output
  value = ""  # TODO: Replace with module output
}

# Resource IDs for management
output "instance_id" {
  description = "ID of the EC2 instance"
  # TODO: Pass through compute module output
  value = ""  # TODO: Replace with module output
}

output "database_instance_id" {
  description = "ID of the RDS instance"
  # TODO: Pass through database module output
  value = ""  # TODO: Replace with module output
}

# Summary information
output "summary" {
  description = "Summary of deployed WordPress infrastructure"
  value = {
    # TODO: Create a useful summary object
    # project_name = var.project_name
    # environment = var.environment
    # vpc_id = module.vpc.vpc_id
    # database_engine = module.database.db_engine
    # instance_type = var.instance_type
    # wordpress_url = "http://${module.compute.public_ip}"
  }
}