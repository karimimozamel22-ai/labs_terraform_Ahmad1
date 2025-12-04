# Lab 1 Submission Checklist - WordPress on EC2

## Required Deliverables

### 1. Code Requirements

Your `student-work/` directory must contain:

- [ ] `main.tf` with all required resources
- [ ] `variables.tf` with student_name, instance_type, and my_ip variables
- [ ] `outputs.tf` with all required outputs
- [ ] `backend.tf` with S3 remote state configuration
- [ ] `user_data.sh` with WordPress installation script
- [ ] `.gitignore` that prevents committing state files and tfvars
- [ ] All code passes `terraform fmt -check`
- [ ] All code passes `terraform validate`

### 2. Resource Requirements

#### AWS Key Pair (5 points)
- [ ] `aws_key_pair` resource defined
- [ ] Key name includes student identifier
- [ ] References local public key file
- [ ] All required tags present

#### Security Group (15 points)
- [ ] `aws_security_group` resource defined
- [ ] **Ingress rule: SSH (port 22)** from specific IP (not 0.0.0.0/0)
- [ ] **Ingress rule: HTTP (port 80)** from 0.0.0.0/0
- [ ] **Ingress rule: HTTPS (port 443)** from 0.0.0.0/0
- [ ] **Egress rule: Allow all outbound** (CRITICAL - Terraform doesn't add this by default!)
- [ ] Description fields populated
- [ ] All required tags present

#### EC2 Instance (20 points)
- [ ] `aws_instance` resource defined
- [ ] Uses data source for AMI (not hardcoded AMI ID)
- [ ] Instance type is t3.micro or t2.micro
- [ ] References key_pair resource
- [ ] References security_group resource
- [ ] **IMDSv2 Configuration:**
  - [ ] `http_endpoint = "enabled"`
  - [ ] `http_tokens = "required"` (enforces IMDSv2)
  - [ ] `http_put_response_hop_limit = 1`
  - [ ] `instance_metadata_tags = "enabled"`
- [ ] User data script referenced
- [ ] Root block device configured (20 GB, encrypted)
- [ ] All required tags present

#### Data Source (5 points)
- [ ] `data "aws_ami"` block for Amazon Linux 2023
- [ ] Filters for latest AMI (`most_recent = true`)
- [ ] Filters for correct architecture (x86_64)
- [ ] Referenced in instance configuration

### 3. Required Tags

All resources must include these tags:

- [ ] `Name` - Descriptive resource name
- [ ] `Environment` - Set to "Learning"
- [ ] `ManagedBy` - Set to "Terraform"
- [ ] `Student` - Your GitHub username
- [ ] `AutoTeardown` - Set to "8h"

### 4. Required Outputs

Your `outputs.tf` must include:

- [ ] `instance_id` - EC2 instance ID
- [ ] `public_ip` - Public IP address
- [ ] `public_dns` - Public DNS name
- [ ] `wordpress_url` - Full HTTP URL to access WordPress
- [ ] `ssh_command` - Complete SSH command with key path
- [ ] `ami_id` - AMI ID used
- [ ] `security_group_id` - Security group ID

### 5. Backend Configuration

- [ ] Backend configured for S3
- [ ] State path is `week-00/lab-01/terraform.tfstate`
- [ ] Encryption enabled (`encrypt = true`)
- [ ] `use_lockfile = true` for S3 native locking
- [ ] No state files (terraform.tfstate) committed to Git

### 6. Security Requirements

- [ ] No hardcoded credentials in code
- [ ] No terraform.tfvars committed to Git
- [ ] SSH access restricted to specific IP (not 0.0.0.0/0)
- [ ] IMDSv2 is **required** (not optional)
- [ ] Private SSH keys never committed to Git
- [ ] EBS volume encryption enabled

### 7. User Data Script Requirements

- [ ] `user_data.sh` file exists
- [ ] Installs Apache (httpd), PHP, MariaDB
- [ ] Creates WordPress database and user
- [ ] Downloads and configures WordPress
- [ ] Sets proper file permissions
- [ ] Logs output for debugging

### 8. Cost Management

- [ ] Instance type is cost-effective (t3.micro or t2.micro)
- [ ] Infracost report generated
- [ ] Estimated monthly cost under $15
- [ ] AutoTeardown tag present on all resources

### 9. Testing & Verification

Before submitting, verify:

- [ ] `terraform init` succeeds
- [ ] `terraform validate` passes
- [ ] `terraform fmt -check` passes (no formatting needed)
- [ ] `terraform plan` shows expected resources
- [ ] `terraform apply` succeeds
- [ ] Can SSH into instance using your key
- [ ] IMDSv1 requests fail (curl without token)
- [ ] IMDSv2 requests succeed (curl with token)
- [ ] WordPress accessible via browser at public IP
- [ ] WordPress installation wizard appears
- [ ] All outputs display correctly
- [ ] Infracost analysis runs successfully

---

## Grading Rubric (100 points)

### Code Quality (25 points)
| Check | Points |
|-------|--------|
| Terraform formatting passes | 5 |
| Terraform validation passes | 5 |
| No hardcoded credentials | 5 |
| Proper naming conventions | 5 |
| Uses data source for AMI (not hardcoded) | 5 |

### Functionality (30 points)
| Check | Points |
|-------|--------|
| Key pair resource exists and configured | 5 |
| Security group with SSH rule (restricted) | 5 |
| Security group with HTTP/HTTPS rules | 5 |
| **Security group with egress rule** | 5 |
| EC2 instance properly configured | 5 |
| All required outputs defined | 5 |

### IMDSv2 Configuration (15 points)
| Check | Points |
|-------|--------|
| `http_tokens = "required"` | 5 |
| `http_endpoint = "enabled"` | 3 |
| `http_put_response_hop_limit = 1` | 4 |
| `instance_metadata_tags = "enabled"` | 3 |

### Cost Management (15 points)
| Check | Points |
|-------|--------|
| Infracost analysis completed | 5 |
| Instance type is cost-effective | 5 |
| AutoTeardown tag present | 5 |

### Security (10 points)
| Check | Points |
|-------|--------|
| SSH restricted to specific IP | 5 |
| EBS volume encrypted | 3 |
| Checkov security scan passes | 2 |

### Documentation (5 points)
| Check | Points |
|-------|--------|
| Code comments explaining key sections | 3 |
| Variables have descriptions | 2 |

---

## Submission Instructions

### 1. Prepare Your Submission

```bash
cd week-00/lab-01/student-work

# Final checks
terraform fmt
terraform validate
terraform plan
infracost breakdown --path .
```

### 2. Commit Your Code

```bash
git checkout -b week-00-lab-01
git add week-00/lab-01/student-work/
git status  # Verify no .tfstate or .tfvars files

# You should see:
#   main.tf
#   variables.tf
#   outputs.tf
#   backend.tf
#   user_data.sh
#   .gitignore

git commit -m "Week 0 Lab 1 - WordPress on EC2 - [Your Name]"
git push origin week-00-lab-01
```

### 3. Create Pull Request

**IMPORTANT:** Create PR within YOUR fork (not to main repo)!

**Using GitHub CLI:**
```bash
gh pr create --repo YOUR-USERNAME/labs_terraform_course \
  --base main \
  --head week-00-lab-01 \
  --title "Week 0 Lab 1 - [Your Name]" \
  --body "$(cat <<'EOF'
## Lab 1 Submission - WordPress on EC2

### Completed Tasks
- [x] Created SSH key pair resource
- [x] Configured security group with SSH, HTTP, HTTPS, and egress rules
- [x] Deployed EC2 instance with Amazon Linux 2023
- [x] Configured IMDSv2 (required mode)
- [x] Created user data script for WordPress installation
- [x] Set up remote state in S3
- [x] Tested SSH connectivity
- [x] Verified WordPress loads in browser
- [x] Tested IMDSv2 functionality

### Resources Created
- 1 EC2 instance (t3.micro)
- 1 SSH key pair
- 1 Security group

### Testing Results
- [x] SSH connection successful
- [x] IMDSv1 requests blocked (as expected)
- [x] IMDSv2 requests working
- [x] WordPress accessible at public IP
- [x] User data script executed successfully

### Cost Analysis
**Estimated Monthly Cost:** $[X.XX from Infracost]
- EC2 instance (t3.micro): ~$7.59/month
- EBS storage (20 GB): ~$2.00/month

### Questions/Notes
[Add any questions or notes about the lab]
EOF
)"
```

### 4. Wait for Automated Grading

The grading workflow will automatically:
- ✅ Check code formatting and validation
- ✅ Verify security group has egress rule
- ✅ Verify IMDSv2 configuration
- ✅ Check for data source usage (not hardcoded AMI)
- ✅ Validate all required outputs
- ✅ Run cost analysis (Infracost)
- ✅ Perform security scanning (Checkov)
- ✅ Calculate grade (0-100 points)
- ✅ Post results as PR comment

**Expected grading time:** 3-5 minutes

---

## Common Issues and Solutions

### Issue: "Security group egress rule missing"
**Solution:** Add the egress rule to your security group:
```hcl
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

### Issue: WordPress not loading
**Possible causes:**
1. Missing egress rule (instance can't download packages)
2. User data script still running (wait 2-3 minutes)
3. HTTP port 80 not open in security group

**Debug:**
```bash
ssh -i ~/.ssh/wordpress-lab ec2-user@$(terraform output -raw public_ip)
sudo cat /var/log/user-data.log
```

### Issue: SSH Connection Refused
**Solutions:**
- Wait 1-2 minutes for instance boot
- Verify your IP: `curl -s https://checkip.amazonaws.com`
- Check security group allows your IP on port 22
- Verify key permissions: `chmod 600 ~/.ssh/wordpress-lab`

### Issue: "Permission denied (publickey)"
**Solutions:**
```bash
chmod 600 ~/.ssh/wordpress-lab
ls -la ~/.ssh/wordpress-lab
```

### Issue: IMDSv1 Working (Should Fail)
**Solution:** Verify `http_tokens = "required"` in metadata_options block

### Issue: State File in Git
**Solution:**
```bash
git rm --cached terraform.tfstate terraform.tfstate.backup
# Ensure .gitignore includes *.tfstate*
```

---

## Validation Script Checks

The automated validator checks:

### 1. Key Pair Resource (5 points)
- Resource type: `aws_key_pair`
- Has `key_name` attribute
- Has `public_key` attribute
- Required tags present

### 2. Security Group (15 points)
- Resource type: `aws_security_group`
- Ingress rule for port 22 (SSH) - NOT from 0.0.0.0/0
- Ingress rule for port 80 (HTTP)
- Ingress rule for port 443 (HTTPS)
- **Egress rule exists** (CRITICAL)
- Required tags present

### 3. EC2 Instance (20 points)
- Resource type: `aws_instance`
- Uses data source for AMI
- Instance type is t3.micro or t2.micro
- References key_pair via `key_name`
- References security_group via `vpc_security_group_ids`
- User data is not empty
- Required tags present

### 4. IMDSv2 Configuration (15 points)
- `metadata_options` block exists
- `http_tokens = "required"`
- `http_endpoint = "enabled"`
- `http_put_response_hop_limit = 1`
- `instance_metadata_tags = "enabled"`

### 5. Data Source (5 points)
- Data source type: `aws_ami`
- Has filters for Amazon Linux 2023
- `most_recent = true`

### 6. Outputs (5 points)
- At least 5 outputs defined
- Includes instance_id, public_ip, wordpress_url, and ssh_command

---

## Required Files Summary

```
week-00/lab-01/student-work/
├── .gitignore              # Prevents committing sensitive files
├── backend.tf              # S3 backend configuration
├── main.tf                 # Resources (key pair, security group, EC2)
├── variables.tf            # Input variables
├── outputs.tf              # Outputs for instance info
├── user_data.sh            # WordPress installation script
└── terraform.tfvars        # Variable values (NOT committed to Git)
```

**NOT included in Git:**
- `terraform.tfstate`
- `terraform.tfstate.backup`
- `.terraform/` directory
- `terraform.tfvars`
- `*.tfplan`

---

## After Submission

### Destroy Resources

After your PR is reviewed:

```bash
cd week-00/lab-01/student-work
terraform destroy
```

**Or wait for auto-teardown** (8 hours based on AutoTeardown tag)

### Verify Cleanup

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Student,Values=YOUR-USERNAME" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table
```

---

## Questions?

- Review the [lab README](README.md) troubleshooting section
- Check workflow logs in the Actions tab
- Post in course discussion forum
- Tag instructor in PR: `@jlgore`
