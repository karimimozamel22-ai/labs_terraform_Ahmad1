# modules/vpc/variables.tf
# VPC Module Input Variables
# Students will need to research AWS VPC requirements to complete this module

variable "vpc_name" {
  description = "Name for the VPC and associated resources"
  type        = string

  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "VPC name cannot be empty."
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

# TODO: Add vpc_cidr variable
# RESEARCH: What CIDR block should you use for a VPC?
# HINT: Look at RFC 1918 private address ranges
# EXAMPLE: "10.0.0.0/16" gives you 65,534 host addresses
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  # TODO: Add validation to ensure this is a valid CIDR block
  # HINT: Use can() function with regex or cidrhost()
}

# TODO: Add availability_zones variable
# RESEARCH: Why do you need multiple availability zones?
# HINT: RDS requires subnets in at least 2 AZs for high availability
variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  # TODO: Add validation to ensure at least 2 AZs
  # HINT: Use length() function
}

# TODO: Add public_subnet_cidrs variable
# RESEARCH: How many public subnets do you need? What size?
# THINK: Public subnets are for resources that need internet access
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  # TODO: Add validation to ensure number of CIDRs matches number of AZs
}

# TODO: Add private_subnet_cidrs variable
# RESEARCH: What goes in private subnets? Why separate them?
# THINK: Private subnets are for databases and internal resources
variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  # TODO: Add validation to ensure number of CIDRs matches number of AZs
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
  # NOTE: Required for RDS to work properly
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
  # NOTE: Required for basic DNS resolution
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}