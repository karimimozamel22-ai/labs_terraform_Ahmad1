# modules/wordpress/variables.tf
# WordPress Composition Module
# This module orchestrates VPC, Database, and Compute modules together

variable "project_name" {
  description = "Name for the WordPress project (used for resource naming)"
  type        = string

  validation {
    condition     = length(var.project_name) > 0
    error_message = "Project name cannot be empty."
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

# VPC Configuration
# TODO: Add VPC-related variables
# THINK: What VPC settings should be configurable vs. set by the module?

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  # TODO: Add validation for CIDR format
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  # TODO: Add validation for minimum AZ count
  # HINT: RDS needs at least 2 AZs
}

# Database Configuration
# TODO: Add database-related variables

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial amount of storage (in GB)"
  type        = number
  default     = 20
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
  # TODO: Add validation for password complexity
}

# Compute Configuration
# TODO: Add compute-related variables

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of AWS key pair for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to the instance"
  type        = string
  # TODO: Add validation for CIDR format
}

# WordPress Configuration

variable "wordpress_admin_username" {
  description = "WordPress admin username"
  type        = string
  default     = "admin"

  validation {
    condition     = var.wordpress_admin_username != "admin"
    error_message = "WordPress admin username should not be 'admin' for security reasons."
  }
}

variable "wordpress_admin_password" {
  description = "WordPress admin password"
  type        = string
  sensitive   = true
  # TODO: Add validation for password complexity
}

variable "wordpress_admin_email" {
  description = "WordPress admin email"
  type        = string
  # TODO: Add validation for email format
}

variable "wordpress_site_title" {
  description = "Title for the WordPress site"
  type        = string
  default     = "My WordPress Site"
}

# Optional Configuration

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the database"
  type        = bool
  default     = false
  # NOTE: Should be true for production environments
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}