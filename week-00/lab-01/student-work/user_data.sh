#!/bin/bash
# WordPress Installation Script for Amazon Linux 2023
# This script runs automatically when the EC2 instance first boots
#
# What this script does:
# 1. Updates system packages
# 2. Installs Apache, PHP, and MariaDB
# 3. Creates WordPress database and user
# 4. Downloads and configures WordPress
# 5. Sets proper file permissions
#
# Debug tip: Check /var/log/user-data.log for output

# Log all output for debugging
exec > /var/log/user-data.log 2>&1
set -x

echo "=========================================="
echo "Starting WordPress installation..."
echo "Time: $(date)"
echo "=========================================="

# Update system packages
echo "Updating system packages..."
dnf update -y

# Install Apache, PHP, and MariaDB
echo "Installing Apache, PHP, and MariaDB..."
dnf install -y httpd php php-mysqli php-json php-gd php-mbstring mariadb105-server wget

# Start and enable Apache
echo "Starting Apache..."
systemctl start httpd
systemctl enable httpd

# Start and enable MariaDB
echo "Starting MariaDB..."
systemctl start mariadb
systemctl enable mariadb

# Create WordPress database and user
echo "Configuring MariaDB for WordPress..."
mysql -e "CREATE DATABASE wordpress;"
mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'WPpassword123!';"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Download and install WordPress
echo "Downloading WordPress..."
cd /var/www/html
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* .
rm -rf wordpress latest.tar.gz

# Configure WordPress
echo "Configuring WordPress..."
cp wp-config-sample.php wp-config.php

# Set database configuration
sed -i "s/database_name_here/wordpress/" wp-config.php
sed -i "s/username_here/wpuser/" wp-config.php
sed -i "s/password_here/WPpassword123!/" wp-config.php

# Generate and set unique authentication keys and salts
# This fetches random keys from the WordPress API
SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Remove the placeholder lines
sed -i "/AUTH_KEY/d" wp-config.php
sed -i "/SECURE_AUTH_KEY/d" wp-config.php
sed -i "/LOGGED_IN_KEY/d" wp-config.php
sed -i "/NONCE_KEY/d" wp-config.php
sed -i "/AUTH_SALT/d" wp-config.php
sed -i "/SECURE_AUTH_SALT/d" wp-config.php
sed -i "/LOGGED_IN_SALT/d" wp-config.php
sed -i "/NONCE_SALT/d" wp-config.php

# Append the new salts to the config file
echo "$SALT" >> wp-config.php

# Set proper file permissions
echo "Setting file permissions..."
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Restart Apache to apply all changes
echo "Restarting Apache..."
systemctl restart httpd

# Get instance metadata for final message (using IMDSv2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

echo "=========================================="
echo "WordPress installation complete!"
echo "Time: $(date)"
echo "=========================================="
echo ""
echo "Access your site at: http://$PUBLIC_IP"
echo ""
echo "Complete the WordPress setup wizard in your browser."
echo "=========================================="
