# modules/database/outputs.tf
# Database Module Outputs
# Think: What database information will other modules need?

# TODO: Output database endpoint
# RESEARCH: What's a database endpoint and how is it used?
# HINT: Applications need this to connect to the database
output "db_endpoint" {
  description = "RDS instance endpoint (hostname:port)"
  # TODO: Reference the RDS instance endpoint
  # HINT: aws_db_instance.this.endpoint
  value = ""  # TODO: Replace with actual endpoint
}

# TODO: Output database address (hostname only)
# THINK: Sometimes you only need the hostname, not the port
output "db_address" {
  description = "RDS instance hostname"
  # TODO: Reference the RDS instance address
  value = ""  # TODO: Replace with actual address
}

# TODO: Output database port
# RESEARCH: What port does your database engine use?
output "db_port" {
  description = "RDS instance port"
  # TODO: Reference the RDS instance port
  value = 0  # TODO: Replace with actual port
}

# TODO: Output database name
# THINK: Applications need to know which database to connect to
output "db_name" {
  description = "Name of the database"
  # TODO: This should be the database name within the instance
  value = ""  # TODO: Replace with actual database name
}

# TODO: Output database username
# SECURITY: Is it safe to output the username?
# THINK: Applications need this for connections
output "db_username" {
  description = "Master username for the database"
  # TODO: Reference the master username
  value = ""  # TODO: Replace with actual username
}

# SECURITY NOTE: Never output the database password!
# The password should be stored securely (AWS Secrets Manager, etc.)
# Applications should retrieve it securely at runtime

# TODO: Output security group ID
# THINK: Other modules might need to reference the database security group
output "security_group_id" {
  description = "ID of the database security group"
  # TODO: Reference the security group resource
  value = ""  # TODO: Replace with actual security group ID
}

# TODO: Output RDS instance identifier
# ADMIN: Useful for administration and monitoring
output "db_instance_id" {
  description = "RDS instance identifier"
  # TODO: Reference the RDS instance identifier
  value = ""  # TODO: Replace with actual instance identifier
}

# TODO: Output database engine and version
# INFO: Useful for documentation and debugging
output "db_engine" {
  description = "Database engine"
  value       = var.engine
}

output "db_engine_version" {
  description = "Database engine version"
  # TODO: Should this be the input variable or actual version from AWS?
  # HINT: aws_db_instance.this.engine_version gives the actual version
  value = var.engine_version
}