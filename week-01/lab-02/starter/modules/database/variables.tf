# modules/database/variables.tf
# Database Module Input Variables
# Students will research RDS requirements and MySQL configuration

variable "db_name" {
  description = "Name for the database instance"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters."
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
# THINK: How does the database module know which VPC to use?
# HINT: This will come from the VPC module output
variable "vpc_id" {
  description = "ID of the VPC where the database will be created"
  type        = string
  # TODO: Add validation to ensure this looks like a VPC ID
  # HINT: VPC IDs start with "vpc-"
}

# TODO: Add DB subnet group name variable
# RESEARCH: What's a DB subnet group and why is it needed?
# HINT: RDS uses subnet groups to determine which subnets it can use
variable "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  type        = string
}

# TODO: Add database engine variable
# RESEARCH: What database engines does RDS support?
# HINT: mysql, postgres, mariadb, oracle-ee, sqlserver-ex, etc.
variable "engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
  # TODO: Add validation for supported engines
  # HINT: Use contains() function
}

# TODO: Add engine version variable
# RESEARCH: What MySQL versions are available in RDS?
# HINT: Check the AWS RDS documentation or aws_db_instance docs
variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "8.0"
  # NOTE: Students should research current supported versions
}

# TODO: Add instance class variable
# RESEARCH: What RDS instance classes are available?
# HINT: db.t3.micro is the smallest (and cheapest) option
variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
  # TODO: Add validation for valid instance classes
  # HINT: Instance classes start with "db."
}

# TODO: Add allocated storage variable
# RESEARCH: What's the minimum storage for RDS MySQL?
# HINT: Different engines have different minimum requirements
variable "allocated_storage" {
  description = "Initial amount of storage (in GB)"
  type        = number
  default     = 20
  # TODO: Add validation for minimum storage requirements
  # HINT: MySQL minimum is typically 20GB
}

# TODO: Add database credentials variables
# SECURITY: Never hardcode passwords in Terraform!
variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
  # TODO: Add validation for username requirements
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true  # This prevents the password from showing in logs
  # TODO: Add validation for password complexity
  # HINT: AWS has specific password requirements
}

# TODO: Add backup retention variable
# RESEARCH: What are RDS backup options?
# THINK: How long should backups be retained in each environment?
variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
  # TODO: Add validation for backup retention limits
}

# TODO: Add backup window variable
# RESEARCH: What's a backup window and why does it matter?
# HINT: Backups can impact performance, so timing matters
variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
  # TODO: Add validation for backup window format
}

# TODO: Add maintenance window variable
# RESEARCH: What's a maintenance window?
# THINK: When should database maintenance happen?
variable "maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
  # TODO: Add validation for maintenance window format
}

# TODO: Add monitoring variable
# RESEARCH: What monitoring options does RDS provide?
# HINT: Enhanced monitoring provides additional metrics
variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable)"
  type        = number
  default     = 0
  # TODO: Add validation for valid monitoring intervals
  # HINT: Valid values are 0, 1, 5, 10, 15, 30, 60
}

# TODO: Add deletion protection variable
# SECURITY: Should production databases be easy to delete?
variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
  # NOTE: Set to true for production environments
}

# TODO: Add storage encryption variable
# SECURITY: Should database storage be encrypted?
variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
  # NOTE: Always encrypt in production
}

# TODO: Add publicly accessible variable
# SECURITY: Should the database be accessible from the internet?
variable "publicly_accessible" {
  description = "Make the database publicly accessible"
  type        = bool
  default     = false
  # SECURITY: Should almost always be false
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}