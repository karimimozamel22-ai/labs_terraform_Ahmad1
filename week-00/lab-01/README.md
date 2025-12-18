# Lab 1: WordPress on EC2 - EC2 Fundamentals

## Objective

Deploy a fully functional WordPress site on a single EC2 instance with local MariaDB. This lab teaches EC2 fundamentals including security groups, user data scripts, SSH key management, and the Instance Metadata Service (IMDS). Along the way, you'll develop a solid understanding of Terraform's type system.

## Estimated Time

3-4 hours

## Prerequisites

- Completed Lab 0 (Terraform basics, S3, remote state)
- Personal AWS account with proper credentials configured
- Terraform 1.9.0+ installed
- AWS CLI configured
- SSH client installed on your system
- State storage bucket created from Lab 0

## Learning Outcomes

By completing this lab, you will:
- **Understand Terraform's type system** and how it prevents configuration errors
- Create and configure EC2 instances with Terraform
- Write and use user data scripts for application bootstrapping
- Configure security groups with appropriate ingress/egress rules
- Understand why Terraform requires explicit egress rules (unlike the AWS Console)
- Generate and use SSH key pairs for secure instance access
- Deploy a working WordPress site accessible via browser
- Use the Instance Metadata Service v2 (IMDSv2) to query instance information
- **Navigate AWS provider documentation** to find type information

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            Default VPC                                  │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                        Public Subnet                              │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │                    EC2 (t3.micro)                           │  │  │
│  │  │  ┌───────────────────────────────────────────────────────┐  │  │  │
│  │  │  │   Amazon Linux 2023                                   │  │  │  │
│  │  │  │   Apache + PHP                                        │  │  │  │
│  │  │  │   MariaDB (localhost)                                 │  │  │  │
│  │  │  │   WordPress                                           │  │  │  │
│  │  │  └───────────────────────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  │                            │                                      │  │
│  │                   Security Group                                  │  │
│  │                   - SSH (22) from your IP                         │  │
│  │                   - HTTP (80) from anywhere                       │  │
│  │                   - HTTPS (443) from anywhere                     │  │
│  │                   - All outbound traffic                          │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Background: Understanding Terraform Types

Before we dive into building infrastructure, let's understand how Terraform thinks about data. Every value in Terraform has a **type**, and understanding types will help you:
- Write correct configurations faster
- Debug errors more effectively
- Read documentation more efficiently

### The Primitive Types

Terraform has three primitive (basic) types:

| Type | What it holds | Example values |
|------|---------------|----------------|
| `string` | Text | `"t3.micro"`, `"ami-12345"`, `"us-east-1"` |
| `number` | Numeric values | `22`, `80`, `443`, `30` |
| `bool` | True or false | `true`, `false` |

### Collection Types

When you need multiple values, you use collections:

| Type | What it holds | Example |
|------|---------------|---------|
| `list(type)` | Ordered sequence of same type | `["us-east-1a", "us-east-1b"]` |
| `set(type)` | Unordered unique values | `toset(["sg-123", "sg-456"])` |
| `map(type)` | Key-value pairs | `{ Name = "web", Env = "prod" }` |

### Structural Types

For complex data structures:

| Type | What it holds | When to use |
|------|---------------|-------------|
| `object({...})` | Named attributes with different types | Configuration objects |
| `tuple([...])` | Fixed-length sequence with specific types | Rarely used directly |

### Why Types Matter: A Preview

In this lab, you'll encounter these types in real scenarios:

```hcl
# string - AMI IDs, instance types
instance_type = "t3.micro"

# number - ports in security groups
from_port = 22
to_port   = 22

# bool - enable/disable features
encrypted = true

# list(string) - CIDR blocks for security rules
cidr_blocks = ["0.0.0.0/0"]

# map(string) - resource tags
tags = {
  Name        = "wordpress-server"
  Environment = "learning"
}
```

### Type Constraints in Variables

When you declare a variable, you specify what type it accepts:

```hcl
variable "instance_type" {
  type        = string        # Only accepts text values
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "enable_encryption" {
  type        = bool          # Only accepts true or false
  description = "Enable EBS encryption"
  default     = true
}

variable "allowed_ports" {
  type        = list(number)  # Only accepts a list of numbers
  description = "Ports to open in security group"
  default     = [22, 80, 443]
}
```

### What Happens When Types Don't Match?

Terraform catches type errors during `plan`:

```
│ Error: Invalid value for variable
│
│   on main.tf line 5:
│    5:   instance_type = 123
│
│ The given value is not suitable for var.instance_type declared at
│ variables.tf:1,1-27: string required.
```

This is **good**! Type errors caught during `plan` are much better than runtime failures.

---

## 🔍 Type Scavenger Hunt

Before you start coding, complete this documentation exploration. This builds the research skills you'll need throughout the course and in the certification exam.

**Time**: 20-30 minutes  
**Where to look**: [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Hunt 1: EC2 Instance Arguments

Navigate to: **Resources > EC2 > aws_instance**

| Find this argument | What type does it expect? | Your answer |
|--------------------|---------------------------|-------------|
| `ami` | | |
| `instance_type` | | |
| `associate_public_ip_address` | | |
| `vpc_security_group_ids` | | |
| `tags` | | |
| `user_data` | | |

**Hint**: Look at the "Argument Reference" section. The type is often indicated by the description or example values.

---

### Hunt 2: Security Group Arguments

Navigate to: **Resources > VPC > aws_security_group**

| Find this argument | What type does it expect? | Your answer |
|--------------------|---------------------------|-------------|
| `name` | | |
| `description` | | |
| `ingress` | | |
| `ingress.from_port` | | |
| `ingress.cidr_blocks` | | |

**Question**: The `ingress` argument is a special type. What makes it different from a simple `list`?

Your answer: _________________________________________________

---

### Hunt 3: Data Source Return Types

Navigate to: **Data Sources > EC2 > aws_ami**

| Find this attribute | What type does it return? | Your answer |
|---------------------|---------------------------|-------------|
| `id` | | |
| `name` | | |
| `architecture` | | |
| `block_device_mappings` | | |

**Question**: Why is understanding return types important when you reference data sources?

Your answer: _________________________________________________

---

### Hunt 4: Metadata Options Block

Navigate to: **Resources > EC2 > aws_instance** and find the `metadata_options` block.

| Find this argument | What type does it expect? | Valid values (if applicable) |
|--------------------|---------------------------|------------------------------|
| `http_endpoint` | | |
| `http_tokens` | | |
| `http_put_response_hop_limit` | | |
| `instance_metadata_tags` | | |

**Question**: The `metadata_options` block is an example of which structural type?

Your answer: _________________________________________________

---

### Hunt 5: Type Conversion Functions

Navigate to: [Terraform Functions Documentation](https://developer.hashicorp.com/terraform/language/functions)

Find a function that could convert:

| Conversion needed | Function name | Your answer |
|-------------------|---------------|-------------|
| String to number | | |
| List to set | | |
| Number to string | | |

---

### Scavenger Hunt Answers

After completing the hunt, check your answers with your neighbor or the instructor. The goal isn't perfection—it's building comfort with documentation navigation.

**Save your answers!** Create a file called `TYPE_HUNT_ANSWERS.md` in your student-work directory.

---

## Background: Understanding EC2 Components

### What is EC2?

Amazon Elastic Compute Cloud (EC2) provides resizable compute capacity in the cloud. Think of it as renting a virtual computer that you can configure and control.

### Key Components We'll Use

1. **AMI (Amazon Machine Image)**: Template containing the OS and software
2. **Instance Type**: Defines CPU, memory, storage, and network capacity
3. **Key Pairs**: SSH public/private keys for secure authentication
4. **Security Groups**: Virtual firewalls controlling inbound/outbound traffic
5. **User Data**: Scripts that run when the instance first boots
6. **IMDS (Instance Metadata Service)**: API providing instance information

### Why IMDSv2 Matters

The Instance Metadata Service provides information about your EC2 instance (instance ID, public IP, IAM credentials, etc.). IMDSv2 adds security by requiring session-based authentication, preventing certain types of attacks like SSRF (Server-Side Request Forgery).

**Key differences:**
- **IMDSv1** (legacy): Simple HTTP requests, vulnerable to SSRF attacks
- **IMDSv2** (recommended): Requires session token, significantly more secure

We'll configure instances to **require** IMDSv2.

---

## Tasks

### Part 1: Set Up Backend Configuration (10 minutes)

Navigate to your student work directory:
```bash
cd week-00/lab-01/student-work
```

Create `backend.tf` for remote state storage (using the state bucket from Lab 0):

```hcl
# Backend configuration for remote state storage
terraform {
  backend "s3" {
    bucket       = "terraform-state-YOUR-ACCOUNT-ID"  # Replace with your actual account ID
    key          = "week-00/lab-01/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true  # Native S3 locking (Terraform 1.9+)
  }
}
```

**Quick way to get your bucket name:**
```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "terraform-state-$AWS_ACCOUNT_ID"
```

---

### Part 2: Create Terraform Configuration (15 minutes)

#### 2.1 Create `main.tf` with Provider Configuration

```hcl
# Terraform version and provider requirements
terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider configuration
provider "aws" {
  region = "us-east-1"
}
```

#### 2.2 Create `variables.tf`

Variables make your code reusable and easier to maintain. **Notice the type constraints** - these prevent configuration errors before deployment:

```hcl
variable "student_name" {
  description = "Your GitHub username or student ID"
  type        = string  # Must be text, not a number or boolean
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string  # Examples: "t3.micro", "t3.small"
  default     = "t3.micro"
}

variable "my_ip" {
  description = "Your public IP address for SSH access (CIDR notation, e.g., 203.0.113.42/32)"
  type        = string  # CIDR notation is text, even though it contains numbers
}

variable "enable_ebs_encryption" {
  description = "Enable encryption on the root EBS volume"
  type        = bool    # Only true or false
  default     = true
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number  # Must be a numeric value, no quotes
  default     = 30
}
```

**🎯 Type Learning Moment**: Notice how `my_ip` is a `string` even though it looks like numbers? That's because CIDR notation (`192.168.1.1/32`) is text that happens to contain numbers and special characters. Terraform wouldn't know how to do math on an IP address!

#### 2.3 Create `terraform.tfvars`

```hcl
student_name = "your-github-username"  # Replace with your username
my_ip        = "YOUR.IP.ADDRESS.HERE/32"  # Replace with your IP
```

**How to find your public IP:**
```bash
curl -s https://checkip.amazonaws.com
```

Then add `/32` to the end (this means "only this specific IP").

Example: If your IP is `203.0.113.42`, use `203.0.113.42/32`

**Important:** Make sure `.gitignore` includes `*.tfvars` to avoid committing your IP!

---

### Part 3: Find the Latest Amazon Linux 2023 AMI (15 minutes)

Instead of hardcoding an AMI ID, we'll use a **data source** to always get the latest Amazon Linux 2023 AMI.

**Why not hardcode AMI IDs?**
- AMI IDs are region-specific (different in us-east-1 vs us-west-2)
- AMI IDs change when Amazon releases updates
- Hardcoded IDs become stale and may be deprecated

Add to `main.tf`:

```hcl
# Data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true      # bool - we want the newest matching AMI
  owners      = ["amazon"] # list(string) - who published this AMI

  filter {
    name   = "name"                              # string
    values = ["al2023-ami-2023*-kernel-*-x86_64"] # list(string)
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

**🎯 Type Learning Moment**: Look at the `filter` blocks. Each filter has:
- `name` = `string` (single value)
- `values` = `list(string)` (could match multiple patterns)

The documentation tells you `values` expects a list, so even with one value, you use brackets: `["hvm"]`

**Understanding data sources:**
- `data` blocks query existing resources (they don't create anything)
- This finds the newest AL2023 AMI matching our filters
- We reference it as: `data.aws_ami.amazon_linux_2023.id`
- The query runs during `terraform plan` and `terraform apply`

**Test it:**
```bash
terraform init
terraform plan
```

You should see the AMI ID that will be used.

---

### Part 4: Generate SSH Key Pair (20 minutes)

EC2 instances use SSH keys for secure access. We'll generate a key pair locally and import the public key to AWS.

#### 4.1 Generate Local SSH Key

```bash
# Create SSH key with no passphrase (for learning purposes)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/wordpress-lab -N ""
```

This creates:
- Private key: `~/.ssh/wordpress-lab` (keep this secret!)
- Public key: `~/.ssh/wordpress-lab.pub` (safe to share with AWS)

**On Windows (PowerShell):**
```powershell
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\wordpress-lab -N '""'
```

**Verify the keys were created:**
```bash
ls -l ~/.ssh/wordpress-lab*
```

#### 4.2 Set Proper Permissions (Linux/macOS)

SSH requires private keys to have restrictive permissions:

```bash
chmod 600 ~/.ssh/wordpress-lab
```

#### 4.3 Import Public Key to AWS

Add to `main.tf`:

```hcl
# Import SSH public key to AWS
resource "aws_key_pair" "wordpress" {
  key_name   = "wordpress-${var.student_name}"    # string interpolation
  public_key = file("~/.ssh/wordpress-lab.pub")   # file() returns string

  tags = {
    Name         = "WordPress SSH Key - ${var.student_name}"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}
```

**🎯 Type Learning Moment**: The `tags` argument expects a `map(string)`. Every key AND value must be a string. This works:
```hcl
tags = { Name = "web", Port = "80" }  # "80" is a string
```
This would fail:
```hcl
tags = { Name = "web", Port = 80 }    # 80 is a number - type mismatch!
```

**Understanding this resource:**
- `file()` function reads the public key from your filesystem
- The public key gets uploaded to AWS
- The private key NEVER leaves your computer
- You'll reference this key when creating the instance

---

### Part 5: Create Security Group (25 minutes)

Security groups act as virtual firewalls. This is one of the most important parts of the lab.

#### 5.1 Understanding Security Group Rules

- **Ingress rules**: Inbound traffic (coming TO your instance)
- **Egress rules**: Outbound traffic (going FROM your instance)

For WordPress, we need:
- **SSH (port 22)**: For you to connect and troubleshoot
- **HTTP (port 80)**: For visitors to access WordPress
- **HTTPS (port 443)**: For secure connections (future use)
- **All outbound**: So the instance can download packages

#### 5.2 CRITICAL: Terraform vs AWS Console Behavior

> **IMPORTANT**: When you create a security group in the AWS Console, it automatically adds a default egress rule allowing all outbound traffic. **Terraform does NOT do this!**

If you forget to add an egress rule in Terraform, your instance:
- Cannot download packages (`dnf update` fails)
- Cannot download WordPress
- Cannot reach the internet at all
- Will appear to "hang" during user data execution

**This is one of the most common mistakes students make!**

#### 5.3 Create Security Group

Add to `main.tf`:

```hcl
# Security group for WordPress server
resource "aws_security_group" "wordpress" {
  name        = "wordpress-${var.student_name}"
  description = "Security group for WordPress server"

  # SSH access from your IP only
  ingress {
    description = "SSH from my IP"
    from_port   = 22          # number
    to_port     = 22          # number
    protocol    = "tcp"       # string
    cidr_blocks = [var.my_ip] # list(string) - note the brackets!
  }

  # HTTP access from anywhere (for WordPress)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # list with one element
  }

  # HTTPS access from anywhere (for future SSL)
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # CRITICAL: Terraform does NOT add default egress rules!
  # Without this, your instance cannot reach the internet
  # to download packages, WordPress, or anything else.
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # "-1" means all protocols (string, not number!)
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = "wordpress-sg-${var.student_name}"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}
```

**🎯 Type Learning Moment**: Look at the port numbers and protocol:
- `from_port = 22` — This is a `number`, no quotes
- `protocol = "tcp"` — This is a `string`, with quotes
- `protocol = "-1"` — Even though -1 looks like a number, the protocol argument expects a `string`!

This is why documentation navigation matters. The docs tell you what type each argument expects.

**Understanding the configuration:**
- `from_port` and `to_port`: Port range (22 for SSH, 80 for HTTP, etc.)
- `protocol`: `tcp`, `udp`, `icmp`, or `-1` (all protocols)
- `cidr_blocks`: IP ranges allowed
  - Your IP with `/32` for SSH (most restrictive)
  - `0.0.0.0/0` means "anywhere" (needed for public web access)

**Security note:** SSH should NEVER be open to `0.0.0.0/0` in production!

---

### Part 6: Create User Data Script (30 minutes)

User data is a script that runs automatically when an EC2 instance first boots. We'll use it to install and configure WordPress.

#### 6.1 Understanding User Data

- Runs as `root` user
- Executes only on first boot (not on restarts)
- Output logged to `/var/log/cloud-init-output.log`
- Must start with shebang (`#!/bin/bash`)

#### 6.2 Create the WordPress Installation Script

Create a file called `user_data.sh` in your `student-work/` directory:

```bash
#!/bin/bash
# WordPress Installation Script for Amazon Linux 2023
# This script runs automatically when the EC2 instance first boots

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

# Get public IP for WordPress URL configuration (using IMDSv2)
echo "Getting instance metadata..."
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Public IP: $PUBLIC_IP"

# Fetch authentication salts from WordPress API
echo "Fetching authentication salts..."
curl -s https://api.wordpress.org/secret-key/1.1/salt/ > /tmp/wp-salts.txt

# Create wp-config.php using heredoc (avoids sed issues with special characters)
echo "Creating wp-config.php..."
cat > /var/www/html/wp-config.php << 'WPCONFIG_START'
<?php
/**
 * WordPress Configuration File
 * Generated by user-data script
 */

// ** Database settings ** //
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', 'wpuser' );
define( 'DB_PASSWORD', 'WPpassword123!' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

WPCONFIG_START

# Add dynamic URL settings (these need variable expansion)
cat >> /var/www/html/wp-config.php << WPCONFIG_URLS
// ** URL settings (prevents login/redirect issues) ** //
define( 'WP_HOME', 'http://${PUBLIC_IP}' );
define( 'WP_SITEURL', 'http://${PUBLIC_IP}' );

WPCONFIG_URLS

# Add the salts from WordPress API
echo "// ** Authentication keys and salts ** //" >> /var/www/html/wp-config.php
cat /tmp/wp-salts.txt >> /var/www/html/wp-config.php
echo "" >> /var/www/html/wp-config.php

# Add remaining configuration
cat >> /var/www/html/wp-config.php << 'WPCONFIG_END'
// ** Database table prefix ** //
$table_prefix = 'wp_';

// ** Debugging ** //
define( 'WP_DEBUG', false );

// ** Absolute path to WordPress directory ** //
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

// ** Load WordPress ** //
require_once ABSPATH . 'wp-settings.php';
WPCONFIG_END

# Clean up
rm -f /tmp/wp-salts.txt

# Set proper file permissions
echo "Setting file permissions..."
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Restart Apache to apply all changes
echo "Restarting Apache..."
systemctl restart httpd

echo "=========================================="
echo "WordPress installation complete!"
echo "Time: $(date)"
echo "=========================================="
echo ""
echo "Access your site at: http://$PUBLIC_IP"
echo ""
echo "Complete the WordPress setup wizard in your browser."
echo "=========================================="
```

**What this script does:**
1. Updates all system packages
2. Installs Apache web server, PHP, and MariaDB database
3. Starts and enables services to run on boot
4. Creates a MySQL database and user for WordPress
5. Downloads and extracts WordPress
6. Configures `wp-config.php` with database credentials
7. Sets proper file ownership and permissions
8. Uses IMDSv2 to get the public IP for the completion message

---

### Part 7: Launch EC2 Instance (30 minutes)

Now we'll create the EC2 instance that will run WordPress.

#### 7.1 Create the EC2 Instance Resource

Add to `main.tf`:

```hcl
# EC2 instance running WordPress
resource "aws_instance" "wordpress" {
  ami                    = data.aws_ami.amazon_linux_2023.id  # string from data source
  instance_type          = var.instance_type                   # string from variable
  key_name               = aws_key_pair.wordpress.key_name     # string from resource
  vpc_security_group_ids = [aws_security_group.wordpress.id]   # list(string)!

  # User data script to install WordPress
  user_data = file("${path.module}/user_data.sh")  # file() returns string

  # IMDSv2 configuration (enhanced security)
  # This is an object/block type with specific attributes
  metadata_options {
    http_endpoint               = "enabled"   # string - not a bool!
    http_tokens                 = "required"  # string - not a bool!
    http_put_response_hop_limit = 1           # number
    instance_metadata_tags      = "enabled"   # string
  }

  # Root volume configuration - another nested block
  root_block_device {
    volume_size = var.root_volume_size  # number from variable
    volume_type = "gp3"                 # string
    encrypted   = var.enable_ebs_encryption  # bool from variable
  }

  tags = {
    Name         = "wordpress-${var.student_name}"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}
```

**🎯 Type Learning Moment**: Notice `vpc_security_group_ids`:
```hcl
vpc_security_group_ids = [aws_security_group.wordpress.id]
```
Even with ONE security group, you need brackets because the argument expects `list(string)`. This is one of the most common errors students make!

**Wrong:**
```hcl
vpc_security_group_ids = aws_security_group.wordpress.id  # Error! String, not list
```

**Right:**
```hcl
vpc_security_group_ids = [aws_security_group.wordpress.id]  # List with one element
```

**Understanding IMDSv2 settings:**

| Setting | Type | Value | Explanation |
|---------|------|-------|-------------|
| `http_endpoint` | `string` | `"enabled"` | Turn on IMDS |
| `http_tokens` | `string` | `"required"` | Force IMDSv2 (reject IMDSv1 requests) |
| `http_put_response_hop_limit` | `number` | `1` | Prevent IP forwarding attacks |
| `instance_metadata_tags` | `string` | `"enabled"` | Allow querying instance tags via IMDS |

---

### Part 8: Create Outputs (15 minutes)

Outputs display useful information after `terraform apply`.

Create `outputs.tf`:

```hcl
output "instance_id" {
  description = "ID of the WordPress EC2 instance"
  value       = aws_instance.wordpress.id  # Outputs a string
}

output "public_ip" {
  description = "Public IP address of the WordPress server"
  value       = aws_instance.wordpress.public_ip  # Outputs a string
}

output "public_dns" {
  description = "Public DNS name of the WordPress server"
  value       = aws_instance.wordpress.public_dns
}

output "wordpress_url" {
  description = "URL to access WordPress"
  value       = "http://${aws_instance.wordpress.public_ip}"  # String interpolation
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/wordpress-lab ec2-user@${aws_instance.wordpress.public_ip}"
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.wordpress.id
}
```

---

### Part 9: Deploy and Verify (30 minutes)

#### 9.1 Initialize and Validate

```bash
# Format code
terraform fmt

# Initialize
terraform init

# Validate syntax
terraform validate
```

#### 9.2 Review Plan

```bash
terraform plan
```

**What to look for in the plan:**
- 3 resources to create: key_pair, security_group, instance
- 1 data source to read: AMI
- Security group has 3 ingress rules (SSH, HTTP, HTTPS) and 1 egress rule
- Instance uses your key pair and security group
- IMDSv2 settings are correct (`http_tokens = "required"`)

#### 9.3 Deploy

```bash
terraform apply
```

Type `yes` when prompted.

**Expected output:**
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

ami_id = "ami-0abcdef1234567890"
instance_id = "i-0abcd1234efgh5678"
public_dns = "ec2-54-123-45-67.compute-1.amazonaws.com"
public_ip = "54.123.45.67"
security_group_id = "sg-0123456789abcdef0"
ssh_command = "ssh -i ~/.ssh/wordpress-lab ec2-user@54.123.45.67"
wordpress_url = "http://54.123.45.67"
```

#### 9.4 Wait for WordPress Installation

**IMPORTANT:** The user data script takes 2-3 minutes to complete. The instance will be "running" almost immediately, but WordPress won't be ready yet.

**Check instance status:**
```bash
# Via AWS CLI
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text
```

Should show: `running`

#### 9.5 Access WordPress

After waiting 2-3 minutes, open your browser and go to:

```bash
# Get the URL
terraform output wordpress_url
```

You should see the WordPress installation wizard!

**Complete the WordPress setup:**
1. Select your language
2. Enter site title, admin username, password, and email
3. Click "Install WordPress"
4. Log in with your new credentials

**Congratulations!** You've deployed WordPress using Terraform!

---

### Part 10: SSH and IMDS Exploration (30 minutes)

Now let's connect to the instance and explore.

#### 10.1 SSH Into Your Instance

```bash
# Get the SSH command from outputs
terraform output ssh_command

# Or connect directly
ssh -i ~/.ssh/wordpress-lab ec2-user@$(terraform output -raw public_ip)
```

**If connection fails:**
- Wait another minute (instance still booting)
- Check your IP hasn't changed: `curl -s https://checkip.amazonaws.com`
- Verify private key permissions: `chmod 600 ~/.ssh/wordpress-lab`

#### 10.2 Check User Data Execution

Once connected, verify the installation completed:

```bash
# Check the user data log
sudo cat /var/log/user-data.log

# Check if Apache is running
sudo systemctl status httpd

# Check if MariaDB is running
sudo systemctl status mariadb

# Check WordPress files
ls -la /var/www/html/
```

#### 10.3 Explore IMDSv2

The Instance Metadata Service provides information about your instance. Let's explore it!

**First, try IMDSv1 (should FAIL because we required IMDSv2):**
```bash
curl http://169.254.169.254/latest/meta-data/instance-id
```

Expected result: The request hangs or returns nothing (timeout after ~5 seconds).

**Now try IMDSv2 (should WORK):**
```bash
# Step 1: Get a session token (valid for 6 hours)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Step 2: Use the token to query metadata
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id

# You should see your instance ID!
```

**Query other metadata:**
```bash
# Instance type
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-type

# Availability zone
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone

# Public IP
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4

# Private IP
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/local-ipv4

# AMI ID
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/ami-id

# See all available metadata categories
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/

# Instance tags (because we enabled instance_metadata_tags)
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/tags/instance/Name
```

**What you just learned:**
- IMDSv2 requires a token obtained via PUT request
- The token has a TTL (time to live) - we set 6 hours (21600 seconds)
- All subsequent requests must include the token in a header
- This prevents SSRF attacks because attackers can't easily forge PUT requests

**Exit SSH when done:**
```bash
exit
```

---

### Part 11: Type Error Challenge (Optional - 15 minutes)

Now that you understand types, let's practice debugging type errors. Create a file called `broken_types.tf` and try to fix each error:

```hcl
# Challenge 1: Fix the type error
variable "ssh_port" {
  type    = string
  default = 22  # Is this the right type for the default?
}

# Challenge 2: Fix the type error
variable "enable_monitoring" {
  type    = bool
  default = "true"  # Something's wrong here...
}

# Challenge 3: Fix the type error
variable "availability_zones" {
  type    = list(string)
  default = "us-east-1a"  # Should this be a list?
}

# Challenge 4: Fix the type error
variable "instance_tags" {
  type = map(string)
  default = {
    Name = "web-server"
    Port = 8080  # Is this the right type for a map(string)?
  }
}
```

**How to test:**
```bash
terraform validate
```

Terraform will tell you exactly what's wrong with each one. Fix them until `validate` passes!

<details>
<summary>Click for solutions</summary>

```hcl
# Solution 1: Change default to string, or change type to number
variable "ssh_port" {
  type    = number  # Changed from string
  default = 22
}

# Solution 2: Remove quotes - booleans aren't strings
variable "enable_monitoring" {
  type    = bool
  default = true  # Not "true"
}

# Solution 3: Wrap in brackets to make it a list
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a"]  # Now it's a list
}

# Solution 4: Convert number to string
variable "instance_tags" {
  type = map(string)
  default = {
    Name = "web-server"
    Port = "8080"  # Now it's a string
  }
}
```

</details>

---

### Part 12: Run Cost Analysis (10 minutes)

Before considering your work complete, check costs:

```bash
infracost breakdown --path .
```

**Expected monthly cost:** ~$8-10 for a t3.micro running 24/7

**Cost breakdown:**
- t3.micro instance: ~$7.59/month (730 hours × $0.0104/hour)
- EBS storage (30 GB gp3): ~$2.40/month
- Data transfer: Minimal for this lab

**Remember:** Resources tagged with `AutoTeardown = "8h"` will be automatically destroyed after 8 hours!

---

### Part 13: Submit Your Work (20 minutes)

#### 13.1 Final Checklist

Before submitting, verify:

```bash
# Format code
terraform fmt -check

# Validate configuration
terraform validate

# Generate cost estimate
infracost breakdown --path .

# Verify all outputs work
terraform output
```

#### 13.2 Commit Your Work

```bash
# Create a branch
git checkout -b week-00-lab-01

# Add your files
git add week-00/lab-01/student-work/

# Verify state files are NOT being committed
git status

# You should see:
#   main.tf
#   variables.tf
#   outputs.tf
#   backend.tf
#   user_data.sh
#   TYPE_HUNT_ANSWERS.md (if you created it)
#   .gitignore
# You should NOT see terraform.tfstate, .terraform/, or terraform.tfvars

# Commit
git commit -m "Week 0 Lab 1 - WordPress on EC2 - [Your Name]"

# Push
git push origin week-00-lab-01
```

#### 13.3 Create Pull Request

**Using GitHub CLI:**
```bash
gh pr create --repo YOUR-USERNAME/labs_terraform_course \
  --base main \
  --head week-00-lab-01 \
  --title "Week 0 Lab 1 - [Your Name]" \
  --body "Completed Lab 1: WordPress on EC2 with security groups, user data, and IMDSv2"
```

**Or use GitHub web UI** (remember: PR within your fork, not to main repo!)

The grading workflow will automatically:
- ✅ Check formatting and validation
- ✅ Verify security group has all required rules (including egress!)
- ✅ Verify IMDSv2 is required
- ✅ Check for data source usage (not hardcoded AMI)
- ✅ Run cost analysis
- ✅ Perform security scanning
- ✅ Post grade as PR comment

---

### Part 14: Cleanup (10 minutes)

After your PR is graded, clean up resources:

```bash
cd week-00/lab-01/student-work

# Destroy infrastructure
terraform destroy
```

Type `yes` to confirm.

**Verify deletion:**
```bash
# Check no instances remain
aws ec2 describe-instances \
  --filters "Name=tag:Student,Values=YOUR-USERNAME" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table
```

**Alternative:** Wait 8 hours for auto-teardown to destroy resources automatically.

---

## Key Concepts Learned

### 1. Terraform Types

- **Primitives**: `string`, `number`, `bool`
- **Collections**: `list(type)`, `set(type)`, `map(type)`
- **Structural**: `object({...})`, blocks
- Type constraints prevent errors before deployment
- Documentation tells you what type each argument expects

### 2. EC2 Instance Components

- **AMI**: Template for the instance (OS and pre-installed software)
- **Instance Type**: Hardware specifications (t3.micro = 2 vCPU, 1 GB RAM)
- **Key Pair**: SSH authentication mechanism
- **Security Group**: Virtual firewall rules
- **User Data**: Initialization script that runs on first boot

### 3. Security Group Best Practices

- ✅ Restrict SSH to specific IPs (never use `0.0.0.0/0` for SSH)
- ✅ Always define explicit egress rules in Terraform
- ✅ Use descriptive names and descriptions
- ✅ Open only necessary ports (principle of least privilege)

### 4. User Data Scripts

- Run as root on first boot only
- Output logged to `/var/log/cloud-init-output.log`
- Must be idempotent (safe to run multiple times)
- Use `set -x` for debugging (logs all commands)

### 5. IMDSv2 Security

**What is IMDS?**
Instance Metadata Service provides information about your EC2 instance:
- Instance ID, type, AMI
- IAM credentials (if an IAM role is attached)
- Network configuration
- User data

**Why IMDSv2?**
IMDSv1 was vulnerable to SSRF attacks. IMDSv2 requires:
1. PUT request to get session token
2. Token included in subsequent requests
3. Token has TTL (time to live)

This prevents attackers from tricking web applications into revealing credentials.

### 6. Data Sources vs Resources

- **Resources** (`resource`): Create, update, or delete infrastructure
- **Data Sources** (`data`): Query existing infrastructure (read-only)

Using data sources for AMIs ensures you always get the latest version.

---

## Troubleshooting

### Type Errors in `terraform plan`

**Symptom:** Error message mentions "string required" or similar

**Solution:**
1. Check the documentation for the expected type
2. Common fixes:
   - Add quotes for strings: `"t3.micro"` not `t3.micro`
   - Remove quotes for numbers/bools: `22` not `"22"`, `true` not `"true"`
   - Add brackets for lists: `["sg-123"]` not `"sg-123"`

### WordPress Page Not Loading

**Symptom:** Browser shows connection timeout or error

**Solutions:**
1. **Wait longer** - User data takes 2-3 minutes
2. **Check user data log:**
   ```bash
   ssh -i ~/.ssh/wordpress-lab ec2-user@$(terraform output -raw public_ip)
   sudo cat /var/log/user-data.log
   ```
3. **Check security group** - Verify HTTP (port 80) is allowed
4. **Check egress rule** - If missing, the instance can't download packages!

### SSH Connection Refused

**Solutions:**
- Wait 1-2 minutes for instance to fully boot
- Verify your IP: `curl -s https://checkip.amazonaws.com`
- Update `terraform.tfvars` if your IP changed, then `terraform apply`
- Check instance is running: `terraform output instance_id`

### Permission Denied (publickey)

**Solutions:**
```bash
# Fix private key permissions
chmod 600 ~/.ssh/wordpress-lab

# Verify correct key path
ls -la ~/.ssh/wordpress-lab

# Verify username is ec2-user (for Amazon Linux)
ssh -i ~/.ssh/wordpress-lab ec2-user@...
```

### User Data Script Failed

**Symptom:** Apache or MariaDB not running, WordPress files missing

**Debug steps:**
```bash
# SSH into instance
ssh -i ~/.ssh/wordpress-lab ec2-user@$(terraform output -raw public_ip)

# Check the log
sudo cat /var/log/user-data.log

# Check cloud-init status
sudo cloud-init status

# Try running commands manually to see errors
sudo systemctl status httpd
sudo systemctl status mariadb
```

### "Instance can't reach internet"

**Cause:** Missing egress rule in security group

**Solution:** Make sure your security group has:
```hcl
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

Then run `terraform apply` to update.

### IMDSv1 Working (Should Not Be)

**Problem:** You can query IMDS without a token

**Solution:** Verify in `main.tf`:
```hcl
metadata_options {
  http_tokens = "required"  # Must be "required" not "optional"
}
```

Run `terraform apply` to update the instance.

---

## Your Complete File Structure

After completing this lab, your `student-work/` directory should contain:

```
week-00/lab-01/student-work/
├── .gitignore              # Prevents committing sensitive files
├── backend.tf              # S3 backend configuration
├── main.tf                 # Resources (key pair, security group, EC2)
├── variables.tf            # Input variables with type constraints
├── outputs.tf              # Output values
├── user_data.sh            # WordPress installation script
├── TYPE_HUNT_ANSWERS.md    # Your scavenger hunt answers (optional)
└── terraform.tfvars        # Variable values (NOT committed to Git)
```

**NOT included in Git:**
- `terraform.tfstate` (stored in S3)
- `terraform.tfstate.backup`
- `.terraform/` directory
- `terraform.tfvars`
- `broken_types.tf` (challenge file)

---

## Next Steps

In Week 1, you'll learn about:
- Terraform modules for reusability
- Testing Terraform configurations
- VPC networking fundamentals
- High availability architectures

The type knowledge you built here will be essential when working with complex module inputs!

---

## Support

- Check the troubleshooting section above
- Review workflow logs in GitHub Actions
- Post questions in course discussion forum
- Tag instructor in PR: `@jlgore`
