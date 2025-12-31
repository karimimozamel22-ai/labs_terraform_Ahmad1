# modules/compute/variables.tf
# Compute Module Input Variables
# Students will build on Week-00 EC2 knowledge to create WordPress servers

variable "instance_name" {
  description = "Name for the EC2 instance"
  type        = string

  validation {
    condition     = length(var.instance_name) > 0
    error_message = "Instance name cannot be empty."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# TODO: Add VPC ID variable
# THINK: How does the compute module know which VPC to use?
variable "vpc_id" {
  description = "ID of the VPC where the instance will be created"
  type        = string
}

# TODO: Add subnet ID variable
# THINK: Which subnet should the EC2 instance go in? Public or private?
# HINT: WordPress needs internet access for users and updates
variable "subnet_id" {
  description = "ID of the subnet where the instance will be placed"
  type        = string
}

# TODO: Add instance type variable
# RESEARCH: What instance types are available? What's appropriate for WordPress?
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  # TODO: Add validation for valid instance types
}

# TODO: Add key name variable
# SECURITY: How will you SSH into the instance?
# THINK: Should this be optional or required?
variable "key_name" {
  description = "Name of AWS key pair for SSH access"
  type        = string
  # TODO: Should this have a default value or be required?
}

# TODO: Add allowed SSH IP variable
# SECURITY: Who should be able to SSH to your instance?
variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to the instance"
  type        = string
  # TODO: Add validation for CIDR format
}

# Database connection information
# THINK: How does WordPress connect to the separate database?

# TODO: Add database endpoint variable
# CONNECTION: WordPress needs to know where the database is
variable "db_endpoint" {
  description = "Database endpoint (hostname:port)"
  type        = string
}

# TODO: Add database name variable
variable "db_name" {
  description = "Database name"
  type        = string
}

# TODO: Add database username variable
variable "db_username" {
  description = "Database username"
  type        = string
}

# TODO: Add database password variable
# SECURITY: How should you handle the database password securely?
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# TODO: Add database security group variable
# NETWORKING: How does EC2 get access to RDS?
# HINT: The EC2 security group needs to be allowed by the RDS security group
variable "db_security_group_id" {
  description = "ID of the database security group"
  type        = string
}

# WordPress configuration

# NOTE: We don't need a wordpress_site_url variable!
# BREAKTHROUGH: The user_data script will get the site URL from IMDS
# RESEARCH: What is EC2 Instance Metadata Service (IMDS)?
# HINT: IMDS provides information about the instance, including public IP
# QUESTION: How can the user_data script query IMDS for the public IP?

# TODO: Add WordPress admin credentials variables
# SECURITY: WordPress needs an admin user
variable "wordpress_admin_username" {
  description = "WordPress admin username"
  type        = string
  default     = "admin"
}

variable "wordpress_admin_password" {
  description = "WordPress admin password"
  type        = string
  sensitive   = true
}

variable "wordpress_admin_email" {
  description = "WordPress admin email"
  type        = string
  # TODO: Add validation for email format
}

# Optional customization
variable "enable_https" {
  description = "Enable HTTPS redirect in Apache"
  type        = bool
  default     = false
  # NOTE: Requires SSL certificate setup
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}