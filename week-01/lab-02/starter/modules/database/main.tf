# modules/database/main.tf
# Database Module Resources
# Students must research RDS configuration and security groups

locals {
  default_tags = {
    Name        = var.db_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "database"
  }

  all_tags = merge(local.default_tags, var.tags)
}

# TODO: Create security group for RDS
# RESEARCH: Look up aws_security_group resource
# QUESTION: What ports does MySQL use? What about other databases?
# SECURITY: Who should be able to connect to your database?
resource "aws_security_group" "rds" {
  name        = "${var.db_name}-rds-sg"
  description = "Security group for RDS ${var.db_name}"
  # TODO: Associate with the correct VPC
  # vpc_id = ?

  # TODO: Create ingress rule for database access
  # RESEARCH: What port does MySQL use?
  # SECURITY: What should the source be? (Hint: not 0.0.0.0/0!)
  # THINK: Which resources need to connect to the database?
  ingress {
    description = "MySQL access from VPC"
    from_port   = 3306  # TODO: Verify this is correct for your engine
    to_port     = 3306
    protocol    = "tcp"
    # TODO: Set the source - should this be the VPC CIDR? Security group?
    # cidr_blocks = [?]
  }

  # TODO: Create egress rules if needed
  # QUESTION: Does RDS need outbound connectivity?
  # RESEARCH: Check AWS documentation for RDS network requirements

  tags = merge(local.all_tags, {
    Name = "${var.db_name}-rds-sg"
  })
}

# TODO: Create RDS instance
# RESEARCH: Look up aws_db_instance resource - it has MANY arguments!
# CHALLENGE: Figure out which arguments are required vs optional
# HINT: Start with the required ones, then add optional ones
resource "aws_db_instance" "this" {
  # TODO: Basic identification
  # identifier = ?

  # TODO: Database engine configuration
  # engine = ?
  # engine_version = ?
  # instance_class = ?

  # TODO: Storage configuration
  # allocated_storage = ?
  # storage_type = ?
  # storage_encrypted = ?

  # TODO: Database configuration
  # db_name = ?  # Note: This creates a database within the instance
  # username = ?
  # password = ?

  # TODO: Network configuration
  # db_subnet_group_name = ?
  # vpc_security_group_ids = [?]
  # publicly_accessible = ?

  # TODO: Backup configuration
  # backup_retention_period = ?
  # backup_window = ?
  # maintenance_window = ?

  # TODO: Monitoring configuration
  # monitoring_interval = ?

  # TODO: Protection settings
  # deletion_protection = ?
  # skip_final_snapshot = true  # For learning environments
  # final_snapshot_identifier = "${var.db_name}-final-snapshot"

  tags = merge(local.all_tags, {
    Name = var.db_name
  })

  # TODO: Add lifecycle rules if needed
  # RESEARCH: When might you want to ignore changes to certain attributes?
  # HINT: Password changes, engine version updates
}

# TODO: Research parameter groups (Advanced - Optional)
# QUESTION: What if you need custom database parameters?
# RESEARCH: Look up aws_db_parameter_group resource
# NOTE: This is optional for basic setups

# TODO: Research option groups (Advanced - Optional)
# QUESTION: What if you need database engine options?
# RESEARCH: Look up aws_db_option_group resource
# NOTE: This is optional for basic setups