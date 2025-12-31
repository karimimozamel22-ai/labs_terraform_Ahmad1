# modules/compute/outputs.tf
# Compute Module Outputs
# Think: What information about the EC2 instance will be useful?

# TODO: Output instance ID
# ADMIN: Useful for management and monitoring
output "instance_id" {
  description = "ID of the EC2 instance"
  # TODO: Reference the EC2 instance
  # HINT: aws_instance.wordpress.id
  value = ""  # TODO: Replace with actual instance ID
}

# TODO: Output public IP address
# ACCESS: Users need this to reach the WordPress site
output "public_ip" {
  description = "Public IP address of the instance"
  # TODO: Reference the instance public IP
  value = ""  # TODO: Replace with actual public IP
}

# TODO: Output private IP address
# NETWORKING: Useful for internal communication
output "private_ip" {
  description = "Private IP address of the instance"
  # TODO: Reference the instance private IP
  value = ""  # TODO: Replace with actual private IP
}

# TODO: Output public DNS name
# ACCESS: Alternative way to reach the instance
output "public_dns" {
  description = "Public DNS name of the instance"
  # TODO: Reference the instance public DNS
  value = ""  # TODO: Replace with actual public DNS
}

# TODO: Output WordPress URL
# CONVENIENCE: Direct link to the WordPress site
output "wordpress_url" {
  description = "URL to access the WordPress site"
  # TODO: Construct the URL using the public IP
  # HINT: "http://${aws_instance.wordpress.public_ip}"
  value = ""  # TODO: Replace with actual URL
}

# TODO: Output SSH command
# CONVENIENCE: Ready-to-use SSH command for troubleshooting
output "ssh_command" {
  description = "SSH command to connect to the instance"
  # TODO: Construct SSH command
  # HINT: "ssh -i ~/.ssh/your-key ec2-user@${aws_instance.wordpress.public_ip}"
  value = ""  # TODO: Replace with actual SSH command
}

# TODO: Output security group ID
# REFERENCE: Other resources might need the security group
output "security_group_id" {
  description = "ID of the instance security group"
  # TODO: Reference the security group
  value = ""  # TODO: Replace with actual security group ID
}

# TODO: Output subnet ID
# INFO: Which subnet was the instance placed in?
output "subnet_id" {
  description = "ID of the subnet where the instance is located"
  value       = var.subnet_id
}

# TODO: Output availability zone
# INFO: Which AZ is the instance in?
output "availability_zone" {
  description = "Availability zone of the instance"
  # TODO: Reference the instance AZ
  value = ""  # TODO: Replace with actual AZ
}