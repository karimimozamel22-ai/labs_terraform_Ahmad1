# week-01/lab-02/starter/main.tf
# Student Starter File - Modular WordPress with RDS
# Students will use the WordPress composition module they build

# TODO: Use the WordPress composition module
# RESEARCH: How do you call a module that's in the project root?
# PATH: The WordPress module is at ../../../modules/wordpress
module "wordpress_site" {
  source = "./modules/wordpress"

  # TODO: Configure the WordPress project
  # project_name = ?
  # environment = ?

  # TODO: Configure VPC settings
  # THINK: What availability zones are available in us-east-1?
  # RESEARCH: Use aws_availability_zones data source to find them
  # availability_zones = ?

  # TODO: Configure database settings
  # SECURITY: Generate a strong database password
  # HINT: Use terraform console to generate random values for testing
  # db_password = ?

  # TODO: Configure compute settings
  # REQUIREMENT: You'll need an SSH key pair
  # key_name = ?
  # allowed_ssh_cidr = ?  # Your IP address

  # TODO: Configure WordPress admin settings
  # SECURITY: Don't use 'admin' as username
  # wordpress_admin_username = ?
  # wordpress_admin_password = ?
  # wordpress_admin_email = ?

  # Optional: Add custom tags
  tags = {
    Student      = var.student_name
    Lab          = "week-01-lab-02"
    AutoTeardown = "8h"
  }
}

# TODO: Data source to get available availability zones
# RESEARCH: Look up aws_availability_zones data source
# HINT: This helps make your code portable across regions
data "aws_availability_zones" "available" {
  # TODO: Configure to get available AZs
  # state = "available"
}

# TODO: Data source to get your current IP (optional)
# RESEARCH: Look up http data source or use external command
# SECURITY: This helps automatically configure SSH access
# data "http" "my_ip" {
#   url = "https://checkip.amazonaws.com"
# }