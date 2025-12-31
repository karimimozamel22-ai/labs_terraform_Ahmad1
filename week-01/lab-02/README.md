# Week 01 - Lab 02: Modular WordPress Architecture

## Overview

Take your WordPress deployment to the next level! In this lab, you'll refactor the monolithic WordPress from Week-00/Lab-01 into a **multi-tier, modular architecture** using separate modules for networking, database, and compute resources.

Instead of one EC2 instance with a local database, you'll build:
- **VPC Module**: Custom networking with public/private subnets
- **Database Module**: Managed RDS MySQL instance
- **Compute Module**: EC2 instance connecting to external database
- **WordPress Module**: Composition module that orchestrates everything

## Architecture Evolution

### Before (Week-00/Lab-01): Monolithic
```
┌─────────────────────────┐
│    EC2 Instance         │
│  ┌─────────────────────┐│
│  │ WordPress + Apache  ││
│  │ Local MariaDB       ││
│  └─────────────────────┘│
└─────────────────────────┘
```

### After (Week-01/Lab-02): Modular
```
┌─────────────────────────────────────────────────────────┐
│                        VPC Module                        │
│  ┌──────────────────┐           ┌───────────────────┐    │
│  │  Public Subnet   │           │  Private Subnet   │    │
│  │  ┌─────────────┐ │           │ ┌───────────────┐ │    │
│  │  │   EC2       │ │           │ │   RDS MySQL   │ │    │
│  │  │ WordPress   │◄┼───────────┼►│   Database    │ │    │
│  │  └─────────────┘ │           │ └───────────────┘ │    │
│  └──────────────────┘           └───────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## Learning Objectives

By completing this lab, you will:
- **Design modular infrastructure** using Terraform modules
- **Implement module composition** (modules calling other modules)
- **Manage complex dependencies** between infrastructure components
- **Research AWS services** using official documentation
- **Debug module integration issues** and dependency problems
- **Understand real-world architecture patterns** used in production

## Prerequisites

- Completed Week-01/Lab-00 (S3 Module) and Lab-01 (Hugo + CloudFront)
- Understanding of Terraform modules from Lab-00
- AWS CLI configured with credentials
- Terraform >= 1.9.0
- SSH key pair for EC2 access

## Learning Approach: Guided Discovery

This lab uses a **guided discovery approach**. Instead of copying complete code, you'll:

1. **Research** AWS services and Terraform resources
2. **Solve** specific implementation challenges
3. **Debug** integration issues between modules
4. **Learn** by doing, with hints and guidance

---

## Phase 1: Research & Planning (60 minutes)

Before writing any code, understand what you're building.

### Architecture Research Questions

**📚 Use these resources to answer the questions:**
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### VPC Research (20 minutes)

| Question | Your Answer |
|----------|-------------|
| What is a VPC and why not use the default VPC? | |
| What's the difference between public and private subnets? | |
| Why do you need an Internet Gateway? | |
| What does a route table control? | |
| Why does RDS need subnets in multiple AZs? | |

### RDS Research (20 minutes)

| Question | Your Answer |
|----------|-------------|
| What's the minimum storage for RDS MySQL? | |
| What instance classes are available? What's cheapest? | |
| What's a DB subnet group and why is it required? | |
| What ports does MySQL use by default? | |
| How do you secure RDS access? | |

### Module Architecture Research (20 minutes)

| Question | Your Answer |
|----------|-------------|
| How do you pass data between modules? | |
| What happens if Module A needs output from Module B? | |
| How do you handle circular dependencies? | |
| When should you use `depends_on` vs. implicit dependencies? | |

**💡 Hint**: Save your answers! You'll reference them while coding.

---

## Phase 2: Module Implementation (3-4 hours)

Now implement each module step by step. The starter files provide structure and TODOs, but you must research and fill in the details.

### Step 1: Implement VPC Module (45 minutes)

**Location**: `terraform-course/modules/vpc/`

**Your mission**: Create a VPC with public and private subnets.

#### Documentation Hunt Checklist:
- [ ] Find `aws_vpc` resource in Terraform docs
- [ ] Find `aws_subnet` resource arguments
- [ ] Find `aws_internet_gateway` resource
- [ ] Find `aws_route_table` and `aws_route` resources
- [ ] Find `aws_db_subnet_group` resource

#### Implementation Checklist:
- [ ] Complete all TODO items in `variables.tf`
- [ ] Complete all TODO items in `main.tf`
- [ ] Complete all TODO items in `outputs.tf`
- [ ] Test with `terraform validate`

#### Key Challenges:
1. **CIDR Calculation**: How do you split `10.0.0.0/16` into 4 subnets?
2. **Multiple Resources**: How do you create 2 public + 2 private subnets?
3. **Route Tables**: How do you make subnets "public" vs "private"?

#### Success Criteria:
```bash
cd terraform-course/modules/vpc
terraform init
terraform validate  # Should pass
```

### Step 2: Implement Database Module (45 minutes)

**Location**: `terraform-course/modules/database/`

**Your mission**: Create an RDS MySQL instance with proper security.

#### Documentation Hunt Checklist:
- [ ] Find `aws_db_instance` resource and all its arguments
- [ ] Find `aws_security_group` ingress/egress rules
- [ ] Research RDS instance classes and engine versions
- [ ] Find backup and maintenance window formats

#### Implementation Checklist:
- [ ] Complete all TODO items in `variables.tf`
- [ ] Complete all TODO items in `main.tf`
- [ ] Complete all TODO items in `outputs.tf`
- [ ] Test with `terraform validate`

#### Key Challenges:
1. **Security Groups**: How do you allow MySQL access from EC2 but not internet?
2. **Subnet Groups**: How do you configure RDS to use private subnets?
3. **Password Security**: How do you handle sensitive database passwords?

### Step 3: Implement Compute Module (60 minutes)

**Location**: `terraform-course/modules/compute/`

**Your mission**: Create EC2 instance that connects to external RDS database.

#### Documentation Hunt Checklist:
- [ ] Review `aws_instance` resource from Week-00/Lab-01
- [ ] Find `aws_security_group_rule` resource
- [ ] Research how to template user data scripts
- [ ] Find instance metadata service configuration

#### Implementation Checklist:
- [ ] Complete all TODO items in `variables.tf`
- [ ] Complete all TODO items in `main.tf`
- [ ] Complete all TODO items in `outputs.tf`
- [ ] Adapt the `user_data.sh` script for external database
- [ ] Test with `terraform validate`

#### Key Challenges:
1. **Database Connection**: How does the user data script connect to RDS?
2. **Security Groups**: How do you allow EC2 to access RDS MySQL?
3. **Script Adaptation**: What changes from the Week-00 WordPress script?
4. **Site URL Discovery**: How can the script determine the WordPress URL dynamically?

#### User Data Script Adaptation:

You need to modify the user data script to:
- ❌ **Remove**: Local MariaDB installation and configuration
- ✅ **Add**: Remote MySQL connection testing
- ✅ **Add**: IMDS queries to get the instance's public IP
- ✅ **Change**: wp-config.php to use RDS endpoint and dynamic site URL
- ✅ **Add**: Error handling for database connectivity

#### IMDS Research Challenge:

**Research Question**: How can a user_data script determine the instance's public IP without creating a circular dependency in Terraform?

**Your Mission**: Research the EC2 Instance Metadata Service (IMDS) and answer:

1. **What is IMDS?** What information does it provide?
2. **IMDSv1 vs IMDSv2**: What's the security difference?
3. **Dynamic Discovery**: How can a script query its own public IP?
4. **WordPress Integration**: How do you use the discovered IP in wp-config.php?

**Key IMDS Endpoints to Research:**
- Token endpoint: `http://169.254.169.254/latest/api/token`
- Metadata endpoint: `http://169.254.169.254/latest/meta-data/`
- Public IP: `http://169.254.169.254/latest/meta-data/public-ipv4`

### Step 4: Implement WordPress Composition Module (60 minutes)

**Location**: `terraform-course/modules/wordpress/`

**Your mission**: Orchestrate VPC, Database, and Compute modules together.

#### Documentation Hunt Checklist:
- [ ] Review module composition patterns
- [ ] Research `cidrsubnets()` function for subnet calculation
- [ ] Find how to reference module outputs
- [ ] Research module dependency management

#### Implementation Checklist:
- [ ] Complete all TODO items in `variables.tf`
- [ ] Complete all TODO items in `main.tf`
- [ ] Complete all TODO items in `outputs.tf`
- [ ] Test with `terraform validate`

#### Key Challenges:
1. **Module Dependencies**: What order should modules be created?
2. **Data Flow**: How do you pass VPC outputs to Database and Compute modules?
3. **CIDR Calculation**: How do you split the VPC CIDR into subnet CIDRs?
4. **IMDS for Site URL**: How do you use EC2 metadata to dynamically configure WordPress?

---

## Phase 3: Integration & Testing (1-2 hours)

### Step 5: Set Up Your Working Directory (5 minutes)

**Location**: `week-01/lab-02/`

Copy the starter files to your student-work directory:

#### Setup:
```bash
cd week-01/lab-02
cp -r starter/* student-work/
cd student-work
```

#### Implementation Checklist:
- [ ] Complete all TODO items in `main.tf`
- [ ] Complete all TODO items in `variables.tf`
- [ ] Complete all TODO items in `outputs.tf`
- [ ] Create `terraform.tfvars` from the example
- [ ] Configure backend for remote state storage

#### Key Configuration Decisions:
1. **Availability Zones**: Which AZs will you use?
2. **Credentials**: How will you securely provide database passwords?
3. **SSH Access**: What's your current IP address for SSH access?
4. **Key Pair**: Which AWS key pair will you use?

### Step 6: Deploy and Troubleshoot (30-60 minutes)

Now for the moment of truth!

```bash
# Initialize and validate
terraform init
terraform validate
terraform plan

# Deploy (this will take 5-10 minutes)
terraform apply
```

#### Expected Resources:
- 1 VPC with 4 subnets
- 1 Internet Gateway and 2 route tables
- 1 RDS MySQL instance
- 1 EC2 instance
- Multiple security groups
- 1 DB subnet group

#### Common Issues & Debugging:

**Issue**: "InvalidParameterValue: CIDR block is not valid"
```bash
# Check your CIDR calculations
terraform console
> cidrsubnets("10.0.0.0/16", 8, 8, 8, 8)
```

**Issue**: "DB subnet group doesn't meet availability zone coverage requirement"
```bash
# Check your AZ configuration - RDS needs 2+ AZs
data.aws_availability_zones.available.names
```

**Issue**: "Error connecting to database"
```bash
# SSH to instance and check connectivity
ssh -i ~/.ssh/your-key ec2-user@<public-ip>
mysql -h <db-endpoint> -u admin -p
```

**Issue**: "Module not found"
```bash
# Check your module source paths
terraform get -update
```

---

## Phase 4: Validation & Testing (30 minutes)

### Functional Testing

1. **Access WordPress**: Visit the public IP in your browser
2. **Complete Setup**: Follow the WordPress installation wizard
3. **Create Content**: Create a test post to verify database connectivity
4. **SSH Access**: Confirm you can SSH to troubleshoot

### Infrastructure Validation

```bash
# Verify all resources exist
terraform show | grep "# aws_"

# Check costs
infracost breakdown --path .

# Test module outputs
terraform output
```

### Success Criteria:
- [ ] WordPress loads in browser
- [ ] Database connection works (can create posts)
- [ ] SSH access works for troubleshooting
- [ ] All module outputs display correctly
- [ ] Infrastructure costs are reasonable (< $15/month)

---

## Expected File Structure

After completion, you should have:

```
week-01/lab-02/student-work/                   # Your working directory
├── modules/                                   # Your custom modules
│   ├── vpc/                                  # VPC module
│   │   ├── main.tf                           # VPC, subnets, routing
│   │   ├── variables.tf                      # VPC configuration
│   │   └── outputs.tf                        # VPC IDs and info
│   ├── database/                             # Database module
│   │   ├── main.tf                           # RDS instance, security
│   │   ├── variables.tf                      # DB configuration
│   │   └── outputs.tf                        # DB connection info
│   ├── compute/                              # Compute module
│   │   ├── main.tf                           # EC2, security groups
│   │   ├── variables.tf                      # Instance configuration
│   │   ├── outputs.tf                        # Instance info
│   │   └── user_data.sh                      # WordPress install script
│   └── wordpress/                            # Composition module
│       ├── main.tf                           # Orchestrates all modules
│       ├── variables.tf                      # High-level config
│       └── outputs.tf                        # Aggregated outputs
├── main.tf                                   # Uses WordPress module
├── variables.tf                              # Root variables
├── outputs.tf                                # Root outputs
├── providers.tf                              # Provider config
├── terraform.tfvars                          # Your specific values
└── .gitignore                                # Ignore sensitive files
```

**After completing the lab**: Copy your working modules to the project root for use in future labs:
```bash
cp -r student-work/modules/* ../../modules/
```

---

## Troubleshooting Guide

### Module Issues

**"Module not found"**
- Check source path: `../../../modules/module-name`
- Run `terraform get -update`
- Verify module directory exists and has .tf files

**"No configuration files"**
- Ensure module directory has main.tf, variables.tf, outputs.tf
- Check file permissions and extensions (.tf not .txt)

### Dependency Issues

**"Resource not found"**
- Check module output references: `module.vpc.output_name`
- Verify module outputs are defined correctly
- Use `terraform plan` to see dependency graph

**"Cycle in dependency graph"**
- Remove circular dependencies between modules
- Use data sources to query existing resources
- Restructure module interfaces to avoid cycles

### AWS Resource Issues

**RDS Issues:**
- Verify 2+ AZs for subnet group
- Check security group rules allow MySQL (3306)
- Confirm instance class is supported
- Verify password meets AWS requirements

**EC2 Issues:**
- Check SSH key pair exists in AWS
- Verify security group allows SSH (22) and HTTP (80)
- Confirm user data script has correct database endpoint
- Check subnet is public (has Internet Gateway route)

**Network Issues:**
- Verify route tables have Internet Gateway route for public subnets
- Check CIDR blocks don't overlap
- Ensure security groups allow required traffic

---

## Cost Management

Expected monthly costs (if running 24/7):
- **t3.micro EC2**: ~$7.59/month
- **db.t3.micro RDS**: ~$12.41/month
- **EBS Storage**: ~$2.40/month
- **Total**: ~$22.40/month

**Cost Optimization Tips:**
1. Use `AutoTeardown = "8h"` tags for automatic cleanup
2. Stop instances when not needed (RDS can't be stopped easily)
3. Use smaller instance types for development
4. Enable deletion protection only for production

---

## Submission Checklist

### Before Submitting:
- [ ] All modules validate successfully (`terraform validate` in each module directory)
- [ ] WordPress loads and works correctly in browser
- [ ] Database connectivity confirmed (can create/edit posts)
- [ ] SSH access works for troubleshooting
- [ ] All TODO comments removed or completed with working code
- [ ] Costs analyzed with infracost (should be < $25/month)
- [ ] No hardcoded values (everything parameterized)

### Submission Process:
1. **Clean up your code**: Remove or complete all TODO comments
2. **Copy modules to project root** for future labs:
   ```bash
   cd week-01/lab-02
   cp -r student-work/modules/* ../../modules/
   ```
3. **Destroy infrastructure** (save costs):
   ```bash
   cd student-work
   terraform destroy
   ```
4. **Commit your work**:
   ```bash
   git add .
   git commit -m "Week 01 Lab 02 - Modular WordPress Architecture - [Your Name]"
   git push origin your-branch-name
   ```
5. **Create Pull Request** with title: `Week 01 Lab 02 - [Your Name]`
6. **Include in PR description**:
   - Screenshot of working WordPress site
   - Brief description of your architecture
   - Any challenges you overcame
   - Infracost output

## Grading Criteria (100 points)

| Category | Points | Criteria |
|----------|--------|----------|
| **VPC Module** | 20 | Correct subnets, routing, DB subnet group |
| **Database Module** | 20 | RDS instance, security groups, outputs |
| **Compute Module** | 20 | EC2 instance, security, user data script |
| **WordPress Module** | 20 | Module composition, dependencies |
| **Integration** | 10 | Root module, working WordPress |
| **Code Quality** | 10 | Clean code, no hardcoded values, validation |

## What's Next?

In Week 02, you'll learn advanced state management, including:
- State locking and remote backends
- Handling state drift and importing existing resources
- Using `moved` and `removed` blocks for refactoring
- Team collaboration with Terraform Cloud

This modular foundation will serve you well as infrastructure grows in complexity!

---

## Resources & References

### AWS Documentation
- [VPC User Guide](https://docs.aws.amazon.com/vpc/)
- [RDS User Guide](https://docs.aws.amazon.com/rds/)
- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)

### Terraform Documentation
- [Terraform Modules](https://developer.hashicorp.com/terraform/language/modules)
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Module Sources](https://developer.hashicorp.com/terraform/language/modules/sources)

### WordPress & MySQL
- [WordPress Database Configuration](https://wordpress.org/support/article/editing-wp-config-php/)
- [MySQL Connection Testing](https://dev.mysql.com/doc/refman/8.0/en/connecting.html)

---

**Need Help?**
- Review the troubleshooting section above
- Check AWS CloudTrail for API errors
- Use `terraform plan` to understand dependencies
- Post questions in the course discussion forum