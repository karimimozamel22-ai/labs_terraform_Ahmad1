# Lab 01 Validator

This directory contains the automated validation script for Lab 01.

## Purpose

The validator script (`validate.sh`) automatically checks student submissions for:
- Correct resource types and configuration
- IMDSv2 security requirements
- Security group rules (SSH restricted)
- Proper tagging
- Data source usage for AMI

## Validation Criteria

### 1. AWS Key Pair (5 points)
- Resource type: `aws_key_pair`
- Has `key_name` attribute
- Has `public_key` attribute

### 2. Security Group (10 points)
- Resource type: `aws_security_group`
- Has ingress rule for SSH (port 22)
- **SSH NOT from 0.0.0.0/0** (must be restricted to specific IP)
- Has egress rules defined

### 3. EC2 Instance (10 points)
- Resource type: `aws_instance`
- Instance type is cost-effective (t2/t3/t4 family)
- References key pair via `key_name`
- Has security group(s) attached via `vpc_security_group_ids`
- Has AMI specified

### 4. IMDSv2 Configuration (15 points) - CRITICAL
- `metadata_options` block exists
- **`http_tokens = "required"`** (enforces IMDSv2, not optional)
- `http_endpoint = "enabled"`
- `http_put_response_hop_limit = 1` (prevents IP forwarding attacks)
- `instance_metadata_tags = "enabled"`

### 5. Data Source for AMI (5 points)
- Data source type: `aws_ami`
- `most_recent = true` (gets latest AMI)

### 6. Required Tags (5 points)
Checks all resources for required tags:
- `Name`
- `Environment`
- `ManagedBy`
- `Student`
- `AutoTeardown`

**Total: 50 points** (from lab-specific validation)

## Usage

The validator is called automatically by the GitHub Actions grading workflow.

Manual testing:
```bash
cd week-00/lab-01/student-work
terraform init
terraform plan -out=tfplan
terraform show -json tfplan > /tmp/plan.json
bash ../.validator/validate.sh /tmp/plan.json
```

## Exit Codes

- `0`: All checks passed or mostly passed (≥70%)
- `1`: Validation failed (<70%)

## Key Validation Points

### IMDSv2 Enforcement

The most critical check is:
```json
"metadata_options": {
  "http_tokens": "required"  // Must be "required", not "optional"
}
```

This ensures students understand the security implications of IMDSv2.

### Security Group SSH Restriction

Checks that SSH is NOT open to the world:
```json
"ingress": [{
  "from_port": 22,
  "cidr_blocks": ["X.X.X.X/32"]  // NOT "0.0.0.0/0"
}]
```

### Data Source vs Hardcoded AMI

Validates that students use a data source to query the latest AMI:
```hcl
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  // ...
}
```

Instead of hardcoding:
```hcl
ami = "ami-0c55b159cbfafe1f0"  // BAD - hardcoded
```

## Common Failures

### 1. IMDSv2 Optional Instead of Required
**Issue:** `http_tokens = "optional"`
**Fix:** Change to `http_tokens = "required"`

### 2. SSH Open to Internet
**Issue:** `cidr_blocks = ["0.0.0.0/0"]`
**Fix:** Use specific IP: `cidr_blocks = ["YOUR.IP/32"]`

### 3. Missing Metadata Options
**Issue:** No `metadata_options` block
**Fix:** Add complete metadata_options configuration

### 4. Missing Tags
**Issue:** Resources missing required tags
**Fix:** Add all 5 required tags to each resource

### 5. Hardcoded AMI
**Issue:** AMI ID hardcoded in aws_instance
**Fix:** Use data source and reference: `data.aws_ami.amazon_linux_2023.id`

## Testing the Validator

To test the validator with a sample configuration:

```bash
# Create test configuration
cd week-00/lab-01/student-work

# Generate plan
terraform init
terraform plan -out=tfplan

# Convert to JSON
terraform show -json tfplan > /tmp/plan.json

# Run validator
bash ../.validator/validate.sh /tmp/plan.json
```

Expected output for passing submission:
```
================================================
Lab 01 Validation - EC2 with IMDSv2
================================================

🔍 Checking Lab Requirements...

Requirement 1: AWS Key Pair Resource (5 points)
✅ AWS Key Pair found (1 instance(s))
  ✅ Key name: terraform-lab-01-student
  ✅ Public key: ssh-rsa AAAA...

Requirement 2: Security Group with SSH Access (10 points)
✅ Security Group found (1 instance(s))
  ✅ Ingress rules defined (1 rule(s))
  ✅ SSH (port 22) ingress rule found
  ✅ SSH restricted to specific IP (not 0.0.0.0/0): 203.0.113.42/32
  ✅ Egress rules defined

Requirement 3: EC2 Instance Resource (10 points)
✅ EC2 Instance found (1 instance(s))
  ✅ Instance type is cost-effective: t3.micro
  ✅ Key pair referenced: terraform-lab-01-student
  ✅ Security group(s) attached: 1
  ✅ AMI ID specified: ami-0c55b159cbfafe1f0

Requirement 4: IMDSv2 Configuration (15 points)
  ✅ metadata_options block defined
  ✅ http_tokens = "required" (IMDSv2 enforced)
  ✅ http_endpoint = "enabled"
  ✅ http_put_response_hop_limit = 1
  ✅ instance_metadata_tags = "enabled"

Requirement 5: Data Source for Amazon Linux 2023 AMI (5 points)
  ✅ Data source 'aws_ami' found
  ✅ most_recent = true

Requirement 6: Required Tags on Resources (5 points)
  ✅ Most required tags present (15/15)

================================================
Validation Summary
================================================
Errors found: 0
Points earned: 50/50

✅ ALL CHECKS PASSED! Excellent work!
```

## Validator Logic Flow

1. **Check plan file exists** - Fail fast if no plan provided
2. **Key Pair** - Verify resource and attributes
3. **Security Group** - Check SSH rules and restrictions
4. **EC2 Instance** - Validate configuration and references
5. **IMDSv2** - CRITICAL security check (most points)
6. **Data Source** - Verify dynamic AMI lookup
7. **Tags** - Check all resources for required tags
8. **Calculate Score** - Sum points and determine pass/fail

## Integration with Grading Workflow

The validator is called from `.github/workflows/grading.yml`:

```yaml
- name: Run lab-specific validation
  run: |
    VALIDATOR_SCRIPT="${{ steps.lab-info.outputs.lab_dir }}/.validator/validate.sh"
    if [ -f "$VALIDATOR_SCRIPT" ]; then
      bash "$VALIDATOR_SCRIPT" /tmp/plan.json
    fi
```

The exit code determines if the validation passed:
- Exit 0: Validation passed (≥70% score)
- Exit 1: Validation failed (<70% score)

## Customization

To adjust point values or add new checks:

1. Edit `validate.sh`
2. Modify the `MAX_POINTS` variable
3. Add new check functions following the pattern
4. Update this README with new criteria
5. Test with sample student code

## Questions?

For issues with the validator:
1. Check that the plan JSON is valid: `jq . /tmp/plan.json`
2. Verify resources exist: `jq '.planned_values.root_module.resources' /tmp/plan.json`
3. Check specific attributes: `jq '.planned_values.root_module.resources[] | select(.type == "aws_instance")' /tmp/plan.json`
4. Review validator output for specific failures

---

**Last Updated:** 2025-11-13
**Maintained By:** Course Instructor
