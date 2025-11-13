# Lab 1 Submission Checklist

## Required Deliverables

### 1. Code Requirements

Your `student-work/` directory must contain:

- [ ] `main.tf` with all required resources
- [ ] `variables.tf` with student_name, instance_type, and my_ip variables
- [ ] `outputs.tf` with all required outputs
- [ ] `backend.tf` with S3 remote state configuration
- [ ] `.gitignore` that prevents committing state files and tfvars
- [ ] All code passes `terraform fmt -check`
- [ ] All code passes `terraform validate`

### 2. Resource Requirements

#### AWS Key Pair (5 points)
- [ ] `aws_key_pair` resource defined
- [ ] Key name includes student identifier
- [ ] All required tags present

#### Security Group (10 points)
- [ ] `aws_security_group` resource defined
- [ ] Ingress rule allowing SSH (port 22) from specific IP (not 0.0.0.0/0)
- [ ] Egress rule allowing all outbound traffic
- [ ] Description field populated
- [ ] All required tags present

#### EC2 Instance (20 points)
- [ ] `aws_instance` resource defined
- [ ] Uses data source for AMI (not hardcoded AMI ID)
- [ ] Instance type is t3.micro or smaller
- [ ] References key_pair resource
- [ ] References security_group resource
- [ ] **IMDSv2 Configuration:**
  - [ ] `http_endpoint = "enabled"`
  - [ ] `http_tokens = "required"` (enforces IMDSv2)
  - [ ] `http_put_response_hop_limit = 1`
  - [ ] `instance_metadata_tags = "enabled"`
- [ ] User data script defined (optional but recommended)
- [ ] All required tags present

#### Data Source (5 points)
- [ ] `data "aws_ami"` block for Amazon Linux 2023
- [ ] Filters for latest AMI
- [ ] Referenced in instance configuration

### 3. Required Tags

All resources must include these tags:

- [ ] `Name` - Descriptive resource name
- [ ] `Environment` - Set to "Learning"
- [ ] `ManagedBy` - Set to "Terraform"
- [ ] `Student` - Your GitHub username
- [ ] `AutoTeardown` - Set to "8h"

### 4. Outputs

Required outputs in `outputs.tf`:

- [ ] `instance_id` - EC2 instance ID
- [ ] `instance_public_ip` - Public IP address
- [ ] `instance_public_dns` - Public DNS name
- [ ] `ssh_connection_command` - Full SSH command
- [ ] `ami_id` - AMI ID used
- [ ] `key_pair_name` - Key pair name
- [ ] `security_group_id` - Security group ID

### 5. Backend Configuration

- [ ] Backend configured for S3
- [ ] State path is `week-00/lab-01/terraform.tfstate`
- [ ] Encryption enabled
- [ ] `use_lockfile = true` for S3 native locking
- [ ] No state files (terraform.tfstate) committed to Git

### 6. Security Requirements

- [ ] No hardcoded credentials in code
- [ ] No terraform.tfvars committed to Git
- [ ] SSH access restricted to specific IP (not 0.0.0.0/0)
- [ ] IMDSv2 is **required** (not optional)
- [ ] Private keys never committed to Git

### 7. Cost Management

- [ ] Instance type is free-tier eligible (t3.micro recommended)
- [ ] Infracost report generated
- [ ] Estimated monthly cost under $10
- [ ] AutoTeardown tag present on all resources

### 8. Testing & Verification

Before submitting, verify:

- [ ] `terraform init` succeeds
- [ ] `terraform validate` passes
- [ ] `terraform fmt -check` passes (no formatting needed)
- [ ] `terraform plan` shows expected resources
- [ ] `terraform apply` succeeds
- [ ] Can SSH into instance using generated key
- [ ] IMDSv1 requests fail (curl without token)
- [ ] IMDSv2 requests succeed (curl with token)
- [ ] User data script executed successfully
- [ ] All outputs display correctly
- [ ] Infracost analysis runs successfully

### 9. Documentation (Optional but Recommended)

- [ ] README.md in student-work directory
- [ ] Comments explaining complex configurations
- [ ] Notes about any challenges or learnings

## Grading Rubric (100 points)

### Code Quality (25 points)
- Terraform formatting (5 pts)
- Terraform validation (5 pts)
- No hardcoded credentials (5 pts)
- Naming conventions and tags (5 pts)
- Terraform version requirement (5 pts)

### Functionality (30 points)
- Key pair resource exists and configured correctly (5 pts)
- Security group with proper SSH rules (5 pts)
- EC2 instance resource properly configured (10 pts)
- Data source for AMI (5 pts)
- All outputs defined and working (5 pts)

### IMDSv2 Configuration (15 points)
- `http_tokens = "required"` (5 pts)
- `http_endpoint = "enabled"` (3 pts)
- `http_put_response_hop_limit = 1` (3 pts)
- `instance_metadata_tags = "enabled"` (2 pts)
- Configuration can be verified in plan JSON (2 pts)

### Cost Management (15 points)
- Infracost analysis completed (3 pts)
- Instance type is free-tier eligible (5 pts)
- Monthly cost under budget (5 pts)
- AutoTeardown tag present (2 pts)

### Security (10 points)
- SSH restricted to specific IP (not 0.0.0.0/0) (5 pts)
- No secrets in code (3 pts)
- Checkov security scan results (2 pts)

### Documentation (5 points)
- Code comments (3 pts)
- Optional README (2 pts)

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
#   .gitignore
#   README.md (optional)

git commit -m "Week 0 Lab 1 - EC2 with IMDSv2 - [Your Name]"
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
## Lab 1 Submission - EC2 with IMDSv2

### Completed Tasks
- [x] Created SSH key pair resource
- [x] Configured security group with restricted SSH access
- [x] Deployed EC2 instance with Amazon Linux 2023
- [x] Configured IMDSv2 (required mode)
- [x] Set up remote state in S3
- [x] Tested SSH connectivity
- [x] Verified IMDSv2 functionality

### Resources Created
- 1 EC2 instance (t3.micro)
- 1 SSH key pair
- 1 Security group

### Testing Results
- [x] SSH connection successful
- [x] IMDSv1 requests blocked (as expected)
- [x] IMDSv2 requests working
- [x] User data executed successfully

### Cost Analysis
**Estimated Monthly Cost:** $[X.XX from Infracost]
- EC2 instance (t3.micro): ~$7.59/month
- Within budget: Yes

### Questions/Notes
[Add any questions or notes about the lab]
EOF
)"
```

**Or via GitHub Web UI:**
1. Go to your fork: `https://github.com/YOUR-USERNAME/labs_terraform_course`
2. Click "Pull requests" → "New pull request"
3. Set base: `YOUR-USERNAME/labs_terraform_course:main`
4. Set compare: `YOUR-USERNAME/labs_terraform_course:week-00-lab-01`
5. Fill out the template above
6. Click "Create pull request"

### 4. Wait for Automated Grading

The grading workflow will automatically:
- ✅ Check code formatting and validation
- ✅ Verify IMDSv2 configuration
- ✅ Check security group rules
- ✅ Validate key pair resource
- ✅ Run cost analysis (Infracost)
- ✅ Perform security scanning (Checkov)
- ✅ Calculate grade (0-100 points)
- ✅ Post results as PR comment

**Expected grading time:** 3-5 minutes

### 5. Review Feedback and Iterate

1. Check the automated comment on your PR for detailed feedback
2. If improvements are needed:
   - Make changes to your code
   - Commit and push to the same branch
   - Workflow will automatically re-run
3. Once satisfied with your grade, tag instructor: `@shart-cloud`

## Common Issues and Solutions

### Issue: "InvalidKeyPair.Duplicate"
**Solution:** Key pair name already exists
```bash
# Delete existing key pair
aws ec2 delete-key-pair --key-name terraform-lab-01-yourname

# Or use a different name in main.tf
```

### Issue: SSH Connection Refused
**Solutions:**
- Wait 1-2 minutes for instance to fully boot
- Verify security group allows your current IP
- Check instance is running: `terraform output instance_id`

### Issue: "Permission denied (publickey)"
**Solutions:**
```bash
# Fix private key permissions
chmod 600 ~/.ssh/terraform-lab-01

# Verify you're using the correct key path
ls -la ~/.ssh/terraform-lab-01
```

### Issue: IMDSv1 Working (Should Not Be)
**Problem:** IMDSv2 not properly configured
**Solution:** Verify in main.tf:
```hcl
metadata_options {
  http_tokens = "required"  # Must be "required" not "optional"
}
```

### Issue: Security Group Allows 0.0.0.0/0
**Problem:** SSH open to the world (security risk)
**Solution:** Use specific IP in terraform.tfvars:
```hcl
my_ip = "YOUR.IP.ADDRESS/32"
```

### Issue: State File in Git
**Problem:** terraform.tfstate being committed
**Solution:**
```bash
# Remove from git
git rm --cached terraform.tfstate terraform.tfstate.backup

# Verify .gitignore includes:
# *.tfstate
# *.tfstate.*
```

### Issue: Infracost Fails
**Solutions:**
- Verify Infracost API key: `infracost configure get api_key`
- Check internet connectivity
- Ensure terraform init has been run

## Validation Script Details

The automated validator checks:

### 1. Key Pair Resource (5 points)
- Resource type: `aws_key_pair`
- Has `key_name` attribute
- Has `public_key` attribute
- All required tags present

### 2. Security Group (10 points)
- Resource type: `aws_security_group`
- Has ingress rule for port 22
- Ingress NOT from 0.0.0.0/0 (must be restricted)
- Has egress rules
- All required tags present

### 3. EC2 Instance (20 points)
- Resource type: `aws_instance`
- Uses data source for AMI (not hardcoded)
- Instance type is t3.micro or smaller
- References key_pair via `key_name`
- References security_group via `vpc_security_group_ids`
- All required tags present

### 4. IMDSv2 Configuration (15 points)
- `metadata_options` block exists
- `http_tokens = "required"` (not "optional")
- `http_endpoint = "enabled"`
- `http_put_response_hop_limit = 1`
- `instance_metadata_tags = "enabled"`

### 5. Data Source (5 points)
- Data source type: `aws_ami`
- Has filters for Amazon Linux 2023
- `most_recent = true`

### 6. Outputs (5 points)
- At least 5 outputs defined
- Includes instance_id, public_ip, and ssh_connection_command

## Required Files Summary

```
week-00/lab-01/student-work/
├── .gitignore              # Prevents committing sensitive files
├── backend.tf              # S3 backend configuration
├── main.tf                 # Resources (key pair, security group, EC2)
├── variables.tf            # Input variables
├── outputs.tf              # Outputs for instance info
├── terraform.tfvars        # Variable values (NOT committed to Git)
└── README.md               # Optional documentation
```

**NOT included in Git:**
- `terraform.tfstate`
- `terraform.tfstate.backup`
- `.terraform/` directory
- `terraform.tfvars`
- `*.tfplan`

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
# Check no instances remain
aws ec2 describe-instances \
  --filters "Name=tag:Student,Values=YOUR-USERNAME" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'

# Check security groups (may need manual cleanup if not tagged)
aws ec2 describe-security-groups \
  --filters "Name=tag:Student,Values=YOUR-USERNAME"

# Check key pairs
aws ec2 describe-key-pairs \
  --filters "Name=tag:Student,Values=YOUR-USERNAME"
```

## Questions?

- Review the [lab README](README.md) troubleshooting section
- Check workflow logs in the Actions tab
- Post in course discussion forum
- Tag instructor in PR: `@shart-cloud`

## Grade Appeal

If you believe your grade is incorrect:
1. Review the detailed feedback in the PR comment
2. Check the workflow logs for errors
3. Verify all requirements in this checklist
4. Tag instructor with specific questions: `@shart-cloud`

---

**Good luck!** This lab builds essential skills for managing cloud infrastructure securely.
