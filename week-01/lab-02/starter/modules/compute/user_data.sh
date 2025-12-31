#!/bin/bash
# WordPress Installation Script for External Database
# Uses IMDS to get site URL (no circular dependency!)

# Log all output for debugging
exec > /var/log/user-data.log 2>&1
set -x

echo "=========================================="
echo "Starting WordPress installation with external database..."
echo "Time: $(date)"
echo "Database endpoint: ${db_endpoint}"
echo "=========================================="

# Update system packages
echo "Updating system packages..."
dnf update -y

# Install required packages (no MariaDB server!)
echo "Installing Apache, PHP, and MySQL client..."
dnf install -y httpd php php-mysqli php-json php-gd php-mbstring mysql wget

# Start and enable Apache
echo "Starting Apache..."
systemctl start httpd
systemctl enable httpd

# Test database connectivity before proceeding
echo "Testing database connectivity..."
DB_HOST="$${db_endpoint%%:*}"
mysql -h "$DB_HOST" -u "${db_username}" -p"${db_password}" -e "SELECT 1" || {
  echo "ERROR: Cannot connect to database at $DB_HOST"
  exit 1
}
echo "Database connection successful!"

# Download and install WordPress
echo "Downloading WordPress..."
cd /var/www/html
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* .
rm -rf wordpress latest.tar.gz

# Get instance metadata using IMDSv2
echo "Getting instance metadata using IMDSv2..."
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
PUBLIC_DNS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-hostname)

echo "Public IP: $PUBLIC_IP"
echo "Public DNS: $PUBLIC_DNS"

# Determine the site URL
SITE_URL="http://$PUBLIC_IP"
echo "WordPress site URL: $SITE_URL"

# Fetch WordPress authentication salts
echo "Fetching authentication salts..."
curl -s https://api.wordpress.org/secret-key/1.1/salt/ > /tmp/wp-salts.txt

# Create wp-config.php for external database
echo "Creating wp-config.php for external database..."
cat > /var/www/html/wp-config.php << 'WPCONFIG_START'
<?php
/**
 * WordPress Configuration File
 * Generated for external RDS database
 * Site URL determined dynamically from IMDS
 */

// ** Database settings ** //
define( 'DB_NAME', '${db_name}' );
define( 'DB_USER', '${db_username}' );
define( 'DB_PASSWORD', '${db_password}' );
define( 'DB_HOST', '${db_endpoint}' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

WPCONFIG_START

# Add dynamic URL settings using IMDS values
cat >> /var/www/html/wp-config.php << EOF
// ** URL settings (from IMDS) ** //
define( 'WP_HOME', '$SITE_URL' );
define( 'WP_SITEURL', '$SITE_URL' );

EOF

# Add authentication salts
echo "// ** Authentication keys and salts ** //" >> /var/www/html/wp-config.php
cat /tmp/wp-salts.txt >> /var/www/html/wp-config.php
echo "" >> /var/www/html/wp-config.php

# Add remaining WordPress configuration
cat >> /var/www/html/wp-config.php << 'WPCONFIG_END'
// ** Database table prefix ** //
$table_prefix = 'wp_';

// ** Debugging ** //
define( 'WP_DEBUG', false );

// ** Security settings ** //
define( 'DISALLOW_FILE_EDIT', true );
define( 'WP_AUTO_UPDATE_CORE', true );

// ** Absolute path to WordPress directory ** //
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

// ** Load WordPress ** //
require_once ABSPATH . 'wp-settings.php';
WPCONFIG_END

# Clean up temporary files
rm -f /tmp/wp-salts.txt

# Set proper file permissions
echo "Setting file permissions..."
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Install WordPress via WP-CLI (Advanced - Optional)
echo "Installing WP-CLI..."
curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

echo "Setting up WordPress via WP-CLI with real site URL..."
cd /var/www/html
sudo -u apache wp core install \
  --url="$SITE_URL" \
  --title="My WordPress Site" \
  --admin_user="${admin_username}" \
  --admin_password="${admin_password}" \
  --admin_email="${admin_email}"

# Restart Apache
echo "Restarting Apache..."
systemctl restart httpd

echo "=========================================="
echo "WordPress installation complete!"
echo "Time: $(date)"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Access your site at: $SITE_URL"
echo "2. WordPress setup complete via WP-CLI"
echo "3. Database connectivity verified"
echo "4. Site URL determined from IMDS"
echo "=========================================="

# Health check
echo "Performing health checks..."
# Test HTTP response
curl -f "$SITE_URL" > /dev/null && echo "WordPress site responding" || echo "WARNING: WordPress site not responding"

# Test database connection from WordPress
sudo -u apache php -r "
\$connection = mysqli_connect('$${db_endpoint%%:*}', '${db_username}', '${db_password}', '${db_name}');
if (\$connection) {
  echo 'Database connection successful';
  mysqli_close(\$connection);
} else {
  echo 'Database connection failed: ' . mysqli_connect_error();
}
"