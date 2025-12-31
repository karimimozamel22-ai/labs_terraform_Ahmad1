# week-01/lab-02/starter/outputs.tf
# Root Module Outputs

# TODO: Output the WordPress URL
# CONVENIENCE: Users want to know where to access the site
output "wordpress_url" {
  description = "URL to access your WordPress site"
  # TODO: Get this from the WordPress module
  # value = module.wordpress_site.wordpress_url
  value = ""  # TODO: Replace with module output
}

# TODO: Output SSH command
# CONVENIENCE: Ready-to-use SSH command for troubleshooting
output "ssh_command" {
  description = "SSH command to connect to the WordPress server"
  # TODO: Get this from the WordPress module
  value = ""  # TODO: Replace with module output
}

# TODO: Output resource IDs for management
output "vpc_id" {
  description = "ID of the VPC"
  # TODO: Get this from the WordPress module
  value = ""  # TODO: Replace with module output
}

output "instance_id" {
  description = "ID of the EC2 instance"
  # TODO: Get this from the WordPress module
  value = ""  # TODO: Replace with module output
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  # TODO: Get this from the WordPress module
  value = ""  # TODO: Replace with module output
  sensitive = true  # Database endpoints might be sensitive
}

# TODO: Output a summary of deployed infrastructure
output "deployment_summary" {
  description = "Summary of deployed WordPress infrastructure"
  value = {
    student_name     = var.student_name
    wordpress_url    = module.wordpress_site.wordpress_url
    instance_type    = "t3.micro"  # TODO: Make this dynamic
    database_engine  = "mysql"     # TODO: Make this dynamic
    deployment_time  = timestamp()
  }
}