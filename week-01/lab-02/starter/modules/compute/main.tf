# modules/compute/main.tf
# Compute Module Resources
# Students will adapt Week-00 WordPress setup for external database

locals {
  default_tags = {
    Name        = var.instance_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "compute"
  }

  all_tags = merge(local.default_tags, var.tags)
}

# TODO: Get the latest Amazon Linux 2023 AMI
# REFERENCE: You did this in Week-00, Lab-01
# RESEARCH: aws_ami data source
data "aws_ami" "amazon_linux_2023" {
  # TODO: Configure the data source to get the latest AL2023 AMI
  # most_recent = ?
  # owners = ?

  # TODO: Add filters for AL2023
  # filter {
  #   name = "name"
  #   values = [?]
  # }
}

# TODO: Create security group for EC2 instance
# RESEARCH: aws_security_group resource
# THINK: What ports does WordPress need? What about SSH?
resource "aws_security_group" "wordpress" {
  name        = "${var.instance_name}-sg"
  description = "Security group for WordPress server"
  # TODO: Associate with the VPC
  # vpc_id = ?

  # TODO: SSH access rule
  # SECURITY: Only allow SSH from specified IP
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # TODO: Set the allowed CIDR block
    # cidr_blocks = [?]
  }

  # TODO: HTTP access rule
  # THINK: Who should be able to access WordPress over HTTP?
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # TODO: Set the source for web traffic
    # cidr_blocks = [?]
  }

  # TODO: HTTPS access rule (optional)
  # CONDITIONAL: Only add if HTTPS is enabled
  # RESEARCH: How do you conditionally create resources in Terraform?
  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # TODO: Set the source for secure web traffic
    # cidr_blocks = [?]
  }

  # TODO: Database access rule
  # NETWORKING: This instance needs to connect to RDS
  # THINK: What port does MySQL use? Where is the database?
  egress {
    description = "Database access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # TODO: How do you allow access to the database security group?
    # HINT: security_groups = [var.db_security_group_id]
    # cidr_blocks = [?]
  }

  # TODO: Internet access for updates
  # REQUIREMENT: Instance needs to download packages and WordPress updates
  egress {
    description = "Internet access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.all_tags, {
    Name = "${var.instance_name}-sg"
  })
}

# TODO: Update database security group to allow EC2 access
# NETWORKING: RDS security group needs to allow this EC2 security group
# RESEARCH: aws_security_group_rule resource
resource "aws_security_group_rule" "db_access" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  # TODO: Allow access from the EC2 security group to the DB security group
  # source_security_group_id = ?
  # security_group_id = ?
}

# TODO: Create user data script
# REFERENCE: Adapt the script from Week-00, Lab-01
# CHANGE: Remove local MariaDB setup, configure remote MySQL connection
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    # TODO: Pass variables to the user data script
    db_endpoint    = var.db_endpoint
    db_name        = var.db_name
    db_username    = var.db_username
    db_password    = var.db_password
    # NOTE: No site_url needed! The script will get it from IMDS
    admin_username = var.wordpress_admin_username
    admin_password = var.wordpress_admin_password
    admin_email    = var.wordpress_admin_email
  }))
}

# TODO: Create EC2 instance
# REFERENCE: You did this in Week-00, Lab-01
# RESEARCH: aws_instance resource
resource "aws_instance" "wordpress" {
  # TODO: Configure the instance
  # ami = ?
  # instance_type = ?
  # key_name = ?
  # subnet_id = ?
  # vpc_security_group_ids = [?]

  # TODO: Add user data
  # user_data = ?

  # TODO: Configure root block device
  # REFERENCE: Week-00 Lab-01 had this configuration
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  # TODO: Enable detailed monitoring (optional)
  # monitoring = true

  # TODO: Add metadata options for security
  # REFERENCE: Week-00 Lab-01 used IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(local.all_tags, {
    Name = var.instance_name
  })
}