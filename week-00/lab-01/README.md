# Lab 1: EC2 Instances, Key Pairs, and Instance Metadata Service (IMDS)

## Objective

Learn to deploy and secure EC2 instances using Terraform, including SSH key pair management, security group configuration, and proper Instance Metadata Service (IMDSv2) configuration for enhanced security.

## Estimated Time

2-3 hours

## Prerequisites

- Completed Lab 0 (Terraform basics, S3, remote state)
- AWS account with proper credentials configured
- Terraform 1.9.0+ installed
- AWS CLI configured
- SSH client installed on your system
- State storage bucket created from Lab 0

## Learning Outcomes

By completing this lab, you will:
- Create and manage SSH key pairs for EC2 access
- Deploy EC2 instances with proper security configurations
- Configure security groups to control network traffic
- Implement IMDSv2 for enhanced instance security
- Use Terraform data sources to query AWS resources
- Understand EC2 instance lifecycle management
- Connect to instances securely via SSH

## Background: Understanding EC2 Components

### What is EC2?

Amazon Elastic Compute Cloud (EC2) provides resizable compute capacity in the cloud. Think of it as renting a virtual computer that you can configure and control.

### Key Components We'll Use

1. **Key Pairs**: SSH public/private key pairs for secure authentication
2. **Security Groups**: Virtual firewalls controlling inbound/outbound traffic
3. **AMI (Amazon Machine Image)**: Template for the instance (OS + software)
4. **Instance Type**: Defines CPU, memory, storage, and network capacity
5. **IMDS (Instance Metadata Service)**: API providing instance information

### Why IMDSv2 Matters

Instance Metadata Service provides information about your EC2 instance (instance ID, IAM credentials, etc.). IMDSv2 adds security by requiring session-based authentication, preventing certain types of attacks (like SSRF - Server-Side Request Forgery).

**Key differences:**
- **IMDSv1** (legacy): Simple HTTP requests, vulnerable to SSRF
- **IMDSv2** (recommended): Requires session token, more secure

We'll configure instances to **require** IMDSv2.

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
    bucket       = "terraform-state-YOUR-ACCOUNT-ID"  # Replace with your state bucket
    key          = "week-00/lab-01/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

**Remember:** Replace `YOUR-ACCOUNT-ID` with your AWS account ID.

**Quick way to get it:**
```bash
echo "terraform-state-$(aws sts get-caller-identity --query Account --output text)"
```

### Part 2: Create Terraform Configuration Skeleton (15 minutes)

#### 2.1 Create `main.tf` with Terraform and Provider Blocks

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

Variables make your code reusable and easier to maintain:

```hcl
variable "student_name" {
  description = "Your GitHub username or student ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # Free tier eligible
}

variable "my_ip" {
  description = "Your public IP address for SSH access (CIDR notation)"
  type        = string
}
```

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

### Part 3: Get the Latest Amazon Linux 2023 AMI (15 minutes)

Instead of hardcoding an AMI ID, we'll use a **data source** to always get the latest Amazon Linux 2023 AMI.

Add to `main.tf`:

```hcl
# Data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

**Understanding data sources:**
- `data` blocks query existing resources (don't create anything)
- This finds the newest AL2023 AMI matching our filters
- We can reference it as: `data.aws_ami.amazon_linux_2023.id`
- AMIs are region-specific, so this finds the AMI for us-east-1

**Test it:**
```bash
terraform init
terraform plan
```

### Part 4: Create an SSH Key Pair (20 minutes)

EC2 instances need SSH keys for secure access. We'll create a key pair using Terraform.

#### 4.1 Generate Local SSH Key

First, generate a key pair on your local machine:

```bash
# Create SSH key with no passphrase (for learning purposes)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/terraform-lab-01 -N ""
```

This creates:
- Private key: `~/.ssh/terraform-lab-01` (keep this secret!)
- Public key: `~/.ssh/terraform-lab-01.pub` (safe to share)

**On Windows (PowerShell):**
```powershell
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\terraform-lab-01 -N '""'
```

**Verify the keys were created:**
```bash
ls -l ~/.ssh/terraform-lab-01*
```

#### 4.2 Import Public Key to AWS

Add to `main.tf`:

```hcl
# Import SSH public key to AWS
resource "aws_key_pair" "lab_key" {
  key_name   = "terraform-lab-01-${var.student_name}"
  public_key = file("~/.ssh/terraform-lab-01.pub")
  
  tags = {
    Name         = "Lab 01 SSH Key"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}
```

**Understanding this resource:**
- `file()` function reads the public key from your filesystem
- The public key gets uploaded to AWS
- The private key NEVER leaves your computer
- You'll reference this key when creating the instance

**Note:** The `file()` function needs to work in GitHub Actions too. For the grading workflow, we'll handle this differently (the validator will accept any valid key pair resource).

### Part 5: Create a Security Group (25 minutes)

Security groups act as virtual firewalls. We'll create one that allows SSH from only your IP.

#### 5.1 Understanding Security Group Rules

- **Ingress rules**: Inbound traffic (coming TO your instance)
- **Egress rules**: Outbound traffic (going FROM your instance)

For this lab:
- **Allow SSH (port 22)** from your IP only
- **Allow all outbound traffic** (for updates, etc.)

#### 5.2 Create Security Group

Add to `main.tf`:

```hcl
# Security group for EC2 instance
resource "aws_security_group" "lab_sg" {
  name        = "terraform-lab-01-${var.student_name}"
  description = "Security group for Lab 01 EC2 instance"
  
  # SSH access from your IP only
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  
  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name         = "Lab 01 Security Group"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}
```

**Understanding the configuration:**
- `from_port` and `to_port`: Port range (22 is standard SSH port)
- `protocol`: `tcp`, `udp`, `icmp`, or `-1` (all)
- `cidr_blocks`: IP ranges allowed (your IP for SSH)
- `0.0.0.0/0`: Allows all IP addresses (used for outbound)

**Security best practice:** Never allow SSH from `0.0.0.0/0` in production!

### Part 6: Launch EC2 Instance with IMDSv2 (30 minutes)

Now we'll create the actual EC2 instance with enhanced security settings.

#### 6.1 Understanding IMDSv2 Configuration

```hcl
# EC2 instance with IMDSv2 required
resource "aws_instance" "lab_instance" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.lab_key.key_name
  
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
  
  # IMDSv2 configuration (enhanced security)
  metadata_options {
    http_endpoint               = "enabled"   # Enable IMDS
    http_tokens                 = "required"  # Require IMDSv2 (session tokens)
    http_put_response_hop_limit = 1           # Restrict to instance only
    instance_metadata_tags      = "enabled"   # Allow access to instance tags
  }
  
  # User data script to install and configure basic tools
  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y
              
              # Install useful tools
              yum install -y htop tree
              
              # Create a welcome message
              echo "Welcome to Lab 01 EC2 Instance" > /home/ec2-user/welcome.txt
              echo "This instance was created with Terraform" >> /home/ec2-user/welcome.txt
              chown ec2-user:ec2-user /home/ec2-user/welcome.txt
              EOF
  
  tags = {
    Name         = "Lab 01 EC2 Instance - ${var.student_name}"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}
```

**Understanding IMDSv2 settings:**

| Setting | Value | Explanation |
|---------|-------|-------------|
| `http_endpoint` | `enabled` | Turn on IMDS |
| `http_tokens` | `required` | Force IMDSv2 (reject IMDSv1 requests) |
| `http_put_response_hop_limit` | `1` | Prevent IP forwarding attacks |
| `instance_metadata_tags` | `enabled` | Allow querying instance tags via IMDS |

**Understanding user_data:**
- Runs once when instance first launches
- Must start with `#!/bin/bash` (shebang)
- Useful for initial configuration, installing software
- Logs available at `/var/log/cloud-init-output.log`

### Part 7: Create Outputs (15 minutes)

Outputs display useful information after `terraform apply`.

Create `outputs.tf`:

```hcl
# Output the instance ID
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.lab_instance.id
}

# Output the public IP
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.lab_instance.public_ip
}

# Output the public DNS
output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.lab_instance.public_dns
}

# Output SSH connection command
output "ssh_connection_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i ~/.ssh/terraform-lab-01 ec2-user@${aws_instance.lab_instance.public_ip}"
}

# Output the AMI ID used
output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.amazon_linux_2023.id
}

# Output the key pair name
output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.lab_key.key_name
}

# Output security group ID
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.lab_sg.id
}
```

### Part 8: Deploy Infrastructure (20 minutes)

#### 8.1 Initialize and Validate

```bash
# Format code
terraform fmt

# Initialize
terraform init

# Validate syntax
terraform validate
```

#### 8.2 Review Plan

```bash
terraform plan
```

**What to look for in the plan:**
- 3 resources to create: key_pair, security_group, instance
- 1 data source to read: AMI
- Check that security group uses your IP
- Verify IMDSv2 settings are correct

#### 8.3 Deploy

```bash
terraform apply
```

Type `yes` when prompted.

**Expected output:**
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

ami_id = "ami-0c55b159cbfafe1f0"
instance_id = "i-0abcd1234efgh5678"
instance_public_ip = "54.123.45.67"
instance_public_dns = "ec2-54-123-45-67.compute-1.amazonaws.com"
key_pair_name = "terraform-lab-01-yourname"
security_group_id = "sg-0123456789abcdef0"
ssh_connection_command = "ssh -i ~/.ssh/terraform-lab-01 ec2-user@54.123.45.67"
```

**Wait 1-2 minutes** for the instance to fully boot before attempting SSH.

### Part 9: Verify and Test (30 minutes)

#### 9.1 Check Instance Status

```bash
# Via Terraform
terraform show | grep instance_state

# Via AWS CLI
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].State.Name'
```

Should show: `"running"`

#### 9.2 Test SSH Connection

Use the command from outputs:

```bash
# Get the SSH command
terraform output ssh_connection_command

# Or manually
ssh -i ~/.ssh/terraform-lab-01 ec2-user@$(terraform output -raw instance_public_ip)
```

**On Windows PowerShell:**
```powershell
$IP = terraform output -raw instance_public_ip
ssh -i $env:USERPROFILE\.ssh\terraform-lab-01 ec2-user@$IP
```

**If connection is refused:**
- Wait another minute (instance still booting)
- Check security group allows your current IP
- Verify private key permissions: `chmod 600 ~/.ssh/terraform-lab-01`

**Once connected, you should see:**
```
   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'

Last login: ...
[ec2-user@ip-10-0-1-123 ~]$
```

#### 9.3 Test IMDSv2 Configuration

While SSH'd into the instance, test that IMDSv2 is working:

**First, try IMDSv1 (should fail):**
```bash
curl http://169.254.169.254/latest/meta-data/instance-id
```

Expected result: No response or error (because we required IMDSv2)

**Now try IMDSv2 (should work):**
```bash
# Get session token
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Use token to get instance ID
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id
```

Should output your instance ID (e.g., `i-0abcd1234efgh5678`)

**Query other metadata:**
```bash
# Instance type
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type

# Availability zone
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone

# Public IP
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4

# AMI ID
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/ami-id

# Instance tags
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/tags/instance/Name
```

#### 9.4 Check User Data Execution

```bash
# Check the welcome file created by user data
cat /home/ec2-user/welcome.txt

# View user data script execution log
sudo cat /var/log/cloud-init-output.log
```

#### 9.5 Verify Security Group Rules

From your local machine:

```bash
# Get security group ID
SG_ID=$(terraform output -raw security_group_id)

# Describe security group rules
aws ec2 describe-security-groups --group-ids $SG_ID --query 'SecurityGroups[0].IpPermissions'
```

Should show SSH (port 22) allowed from your IP only.

**Exit the SSH session:**
```bash
exit
```

### Part 10: Run Cost Analysis (10 minutes)

Before considering your work complete, check costs:

```bash
infracost breakdown --path .
```

**Expected monthly cost:** ~$7-8 for a t3.micro running 24/7

**Cost breakdown:**
- t3.micro instance: ~$7.59/month (730 hours × $0.0104/hour)
- Data transfer: Minimal for this lab
- EBS storage: Included in instance pricing

**Remember:** Resources tagged with `AutoTeardown = "8h"` will be automatically destroyed after 8 hours!

### Part 11: Document Your Work (15 minutes)

Create a simple `README.md` in your `student-work/` directory:

```markdown
# Lab 01 - EC2 Instance Deployment

## What I Built

- EC2 instance running Amazon Linux 2023
- SSH key pair for secure access
- Security group restricting SSH to my IP
- IMDSv2 configuration for enhanced security

## Key Learnings

- How to create and manage SSH key pairs
- Security group configuration for network access control
- IMDSv2 vs IMDSv1 differences and benefits
- Using data sources to query AWS resources
- EC2 user data for instance initialization

## Resources Created

- 1 EC2 instance (t3.micro)
- 1 SSH key pair
- 1 Security group

## Outputs

- Instance ID: `[from terraform output]`
- Public IP: `[from terraform output]`
- AMI used: `[from terraform output]`

## Notes

[Add any challenges you faced or interesting observations]
```

### Part 12: Submit Your Work (20 minutes)

#### 12.1 Final Checklist

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

#### 12.2 Commit Your Work

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
#   README.md (optional)
#   .gitignore
# You should NOT see terraform.tfstate or .terraform/

# Commit
git commit -m "Week 0 Lab 1 - EC2 with IMDSv2 - [Your Name]"

# Push
git push origin week-00-lab-01
```

#### 12.3 Create Pull Request

**Using GitHub CLI:**
```bash
gh pr create --repo YOUR-USERNAME/labs_terraform_course \
  --base main \
  --head week-00-lab-01 \
  --title "Week 0 Lab 1 - [Your Name]" \
  --body "Completed Lab 1: EC2 instance with IMDSv2, key pairs, and security groups"
```

**Or use GitHub web UI** (remember: PR within your fork, not to main repo!)

The grading workflow will automatically:
- ✅ Check formatting and validation
- ✅ Verify IMDSv2 is required
- ✅ Check security group configuration
- ✅ Verify key pair resource exists
- ✅ Run cost analysis
- ✅ Perform security scanning
- ✅ Post grade as PR comment

### Part 13: Cleanup (10 minutes)

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
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'

# Should show empty or terminated instances
```

**Alternative:** Wait 8 hours for auto-teardown to destroy resources automatically.

## Key Concepts Learned

### 1. EC2 Instance Components

- **AMI**: Template for the instance (OS and software)
- **Instance Type**: Hardware specifications (CPU, RAM, network)
- **Key Pair**: SSH authentication mechanism
- **Security Group**: Virtual firewall rules
- **User Data**: Initialization script

### 2. Security Best Practices

- ✅ Restrict SSH to specific IPs (never `0.0.0.0/0`)
- ✅ Use IMDSv2 (not IMDSv1) for metadata access
- ✅ Use SSH keys (never passwords)
- ✅ Set `http_put_response_hop_limit = 1` to prevent IP forwarding
- ✅ Keep private keys secret and local

### 3. Terraform Features Used

- **Data Sources**: Query existing AWS resources (`data "aws_ami"`)
- **Resource Dependencies**: Automatic ordering based on references
- **Variables**: Make code reusable (`var.student_name`)
- **Outputs**: Extract and display useful information
- **Functions**: `file()` to read local files

### 4. IMDSv2 Security

**What is IMDS?**
Instance Metadata Service provides information about your EC2 instance:
- Instance ID, type, AMI
- IAM credentials
- User data
- Network configuration

**Why IMDSv2?**
IMDSv1 was vulnerable to SSRF attacks. IMDSv2 requires:
1. PUT request to get session token
2. Token included in subsequent requests
3. Token has TTL (time to live)

This prevents attackers from tricking web applications into revealing credentials.

**Configuration we used:**
```hcl
metadata_options {
  http_endpoint               = "enabled"   # Turn on IMDS
  http_tokens                 = "required"  # Require session token (IMDSv2)
  http_put_response_hop_limit = 1           # One hop only (no IP forwarding)
  instance_metadata_tags      = "enabled"   # Allow tag access
}
```

## Troubleshooting

### SSH Connection Issues

**"Connection refused"**
- Wait 1-2 minutes for instance to fully boot
- Check security group allows your IP
- Verify instance is running: `aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)`

**"Permission denied (publickey)"**
- Check private key permissions: `chmod 600 ~/.ssh/terraform-lab-01`
- Verify you're using the correct key: `-i ~/.ssh/terraform-lab-01`
- Check username is `ec2-user` (for Amazon Linux)

**"Network error: Connection timed out"**
- Verify your public IP hasn't changed
- Update security group with new IP if needed
- Check you're using public IP (not private): `terraform output instance_public_ip`

### Security Group Issues

**Can't SSH from different location**
- Your IP changed - update `terraform.tfvars` with new IP
- Run `terraform apply` to update security group
- Or add additional CIDR blocks to security group

**Want to allow multiple IPs**
```hcl
cidr_blocks = [
  "203.0.113.42/32",  # Home IP
  "198.51.100.17/32", # Office IP
]
```

### IMDSv1 Not Working

**This is expected!** We configured the instance to require IMDSv2. If IMDSv1 works, something is wrong with your configuration.

**Verify IMDSv2 is required:**
```bash
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].MetadataOptions.HttpTokens'
```

Should output: `"required"`

### Terraform Errors

**"Error: error creating EC2 Key Pair: InvalidKeyPair.Duplicate"**
- A key pair with that name already exists
- Either use a different name or delete the existing one:
```bash
aws ec2 delete-key-pair --key-name terraform-lab-01-yourname
```

**"Error: Error launching source instance: InvalidAMIID.NotFound"**
- The AMI ID doesn't exist in your region
- Make sure you're using the data source (not a hardcoded AMI)
- Verify you're in us-east-1

**"InvalidGroup.NotFound" when applying**
- Security group was deleted outside Terraform
- Run `terraform refresh` to update state
- Then `terraform apply` to recreate

## Advanced Challenges (Optional)

Want to go further? Try these:

### Challenge 1: Multiple Instances

Deploy 2 instances with a single configuration using `count`:

```hcl
resource "aws_instance" "lab_instance" {
  count = 2
  
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  # ... rest of config
  
  tags = {
    Name = "Lab 01 Instance ${count.index + 1} - ${var.student_name}"
    # ... other tags
  }
}
```

### Challenge 2: Install Web Server

Modify user_data to install and start nginx:

```hcl
user_data = <<-EOF
            #!/bin/bash
            yum update -y
            yum install -y nginx
            systemctl start nginx
            systemctl enable nginx
            echo "<h1>Hello from $(hostname -f)</h1>" > /usr/share/nginx/html/index.html
            EOF
```

Add HTTP (port 80) to security group and test with: `curl http://$(terraform output -raw instance_public_ip)`

### Challenge 3: EBS Volume

Add a separate EBS volume:

```hcl
resource "aws_ebs_volume" "lab_volume" {
  availability_zone = aws_instance.lab_instance.availability_zone
  size              = 10  # GB
  
  tags = {
    Name = "Lab 01 Volume - ${var.student_name}"
    # ... other tags
  }
}

resource "aws_volume_attachment" "lab_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.lab_volume.id
  instance_id = aws_instance.lab_instance.id
}
```

### Challenge 4: Custom VPC

Instead of using the default VPC, create your own:

```hcl
resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "Lab 01 VPC - ${var.student_name}"
    # ... other tags
  }
}

resource "aws_subnet" "lab_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Lab 01 Subnet - ${var.student_name}"
    # ... other tags
  }
}

# Internet Gateway, route table, etc.
```

## Additional Resources

- [AWS EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [AWS Instance Metadata Service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html)
- [IMDSv2 Security Best Practices](https://aws.amazon.com/blogs/security/defense-in-depth-open-firewalls-reverse-proxies-ssrf-vulnerabilities-ec2-instance-metadata-service/)
- [Terraform AWS Provider: aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [Amazon Linux 2023 User Guide](https://docs.aws.amazon.com/linux/al2023/ug/what-is-amazon-linux.html)

## Next Steps

Proceed to Week 1 labs where you'll learn about:
- Load balancers
- Auto scaling groups
- RDS databases
- VPC networking

## Support

- Check the [troubleshooting section](#troubleshooting) above
- Review workflow logs in GitHub Actions
- Post questions in course discussion forum
- Tag instructor: `@jlgore` in PR comments
