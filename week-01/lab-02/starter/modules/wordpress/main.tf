# modules/wordpress/main.tf
# WordPress Composition Module
# This module demonstrates how to compose multiple modules together

locals {
  # Common tags applied to all resources
  common_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "wordpress"
  }, var.tags)

  # Calculate subnet CIDRs based on VPC CIDR
  # TODO: Students should research how to split a VPC CIDR into subnets
  # HINT: Use cidrsubnets() function
  # EXAMPLE: cidrsubnets("10.0.0.0/16", 8, 8, 8, 8) creates 4 /24 subnets
  public_subnet_cidrs  = [] # TODO: Replace with calculated public subnet CIDRs
  private_subnet_cidrs = [] # TODO: Replace with calculated private subnet CIDRs
}

# TODO: Create VPC using the VPC module
# RESEARCH: How do you call a module in Terraform?
# PATH: The VPC module is at ../vpc from this module
module "vpc" {
  source = "../vpc"

  # TODO: Pass required variables to the VPC module
  # HINT: Look at modules/vpc/variables.tf to see what's required
  # vpc_name = ?
  # environment = ?
  # vpc_cidr = ?
  # availability_zones = ?
  # public_subnet_cidrs = ?
  # private_subnet_cidrs = ?

  # Pass common tags
  tags = local.common_tags
}

# TODO: Create database using the Database module
# DEPENDENCY: This needs VPC to be created first
# RESEARCH: How do Terraform modules handle dependencies?
module "database" {
  source = "../database"

  # TODO: Pass required variables to the Database module
  # db_name = "${var.project_name}db"
  # environment = ?

  # TODO: Pass VPC-related information from VPC module outputs
  # DEPENDENCY: How do you reference module outputs?
  # HINT: module.vpc.output_name
  # vpc_id = ?
  # db_subnet_group_name = ?

  # TODO: Pass database configuration
  # instance_class = ?
  # allocated_storage = ?
  # db_username = ?
  # db_password = ?

  # TODO: Configure backup and maintenance
  # backup_retention_period = ?
  # deletion_protection = ?

  tags = local.common_tags

  # TODO: Add explicit dependency if needed
  # depends_on = [module.vpc]
}

# TODO: Create compute resources using the Compute module
# DEPENDENCY: This needs both VPC and Database to be ready
module "compute" {
  source = "../compute"

  # TODO: Pass required variables to the Compute module
  # instance_name = "${var.project_name}-web"
  # environment = ?

  # TODO: Pass VPC information
  # QUESTION: Which subnet should the EC2 instance go in?
  # THINK: WordPress needs internet access for users
  # vpc_id = ?
  # subnet_id = ? # Should this be public[0] or private[0]?

  # TODO: Pass instance configuration
  # instance_type = ?
  # key_name = ?
  # allowed_ssh_cidr = ?

  # TODO: Pass database connection information
  # DEPENDENCY: How do you get database connection info?
  # db_endpoint = ?
  # db_name = ?
  # db_username = ?
  # db_password = ?
  # db_security_group_id = ?

  # TODO: Pass WordPress configuration
  # wordpress_admin_username = ?
  # wordpress_admin_password = ?
  # wordpress_admin_email = ?

  tags = local.common_tags

  # TODO: Add explicit dependencies
  # depends_on = [module.vpc, module.database]
}

# NOTE: Site URL is handled by the user_data script using IMDS
# The script queries the instance metadata for the public IP after the
# instance is running. This eliminates any circular dependency issues.