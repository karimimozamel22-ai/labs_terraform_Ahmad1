#!/bin/bash
#
# Lab 01 Grading Script
# Complete grading for WordPress on EC2 lab
#
# Usage: grade.sh <student-work-dir>
# Output: JSON grading results to stdout
#
# Grading Categories:
#   - Code Quality (25 points)
#   - Functionality (30 points)
#   - Cost Management (15 points)
#   - Security (15 points)
#   - IMDSv2 Configuration (10 points)
#   - Documentation (5 points)
#

set -e

WORK_DIR="${1:-.}"
PLAN_FILE="${2:-/tmp/plan.json}"
INFRACOST_FILE="${3:-/tmp/infracost.json}"
POLICY_FILE="${4:-/tmp/policy-results.json}"  # conftest or checkov results

# Initialize scores
CODE_QUALITY=0
CODE_QUALITY_MAX=25
FUNCTIONALITY=0
FUNCTIONALITY_MAX=30
COST_MGMT=0
COST_MGMT_MAX=15
SECURITY=0
SECURITY_MAX=15
IMDSV2=0
IMDSV2_MAX=10
DOCUMENTATION=0
DOCUMENTATION_MAX=5

# Initialize check results arrays
declare -a CODE_QUALITY_CHECKS=()
declare -a FUNCTIONALITY_CHECKS=()
declare -a COST_MGMT_CHECKS=()
declare -a SECURITY_CHECKS=()
declare -a IMDSV2_CHECKS=()
declare -a DOCUMENTATION_CHECKS=()
declare -a ERRORS=()
declare -a WARNINGS=()

# Helper to add check result
add_check() {
    local category=$1
    local name=$2
    local points=$3
    local max_points=$4
    local status=$5
    local message=$6

    local check="{\"name\":\"$name\",\"points\":$points,\"max_points\":$max_points,\"status\":\"$status\",\"message\":\"$message\"}"

    case $category in
        "code_quality") CODE_QUALITY_CHECKS+=("$check") ;;
        "functionality") FUNCTIONALITY_CHECKS+=("$check") ;;
        "cost_mgmt") COST_MGMT_CHECKS+=("$check") ;;
        "security") SECURITY_CHECKS+=("$check") ;;
        "imdsv2") IMDSV2_CHECKS+=("$check") ;;
        "documentation") DOCUMENTATION_CHECKS+=("$check") ;;
    esac
}

echo "================================================" >&2
echo "Lab 01 Grading - WordPress on EC2" >&2
echo "================================================" >&2
echo "" >&2

cd "$WORK_DIR"

# ==================== CODE QUALITY (25 points) ====================
echo "📋 Checking Code Quality..." >&2

# Check 1: Terraform formatting (5 points)
if terraform fmt -check -recursive . >/dev/null 2>&1; then
    CODE_QUALITY=$((CODE_QUALITY + 5))
    add_check "code_quality" "Terraform Formatting" 5 5 "pass" "Code is properly formatted"
    echo "  ✅ Terraform formatting: PASS" >&2
else
    add_check "code_quality" "Terraform Formatting" 0 5 "fail" "Run 'terraform fmt' to fix formatting"
    echo "  ❌ Terraform formatting: FAIL" >&2
fi

# Check 2: Terraform validation (5 points)
if terraform validate >/dev/null 2>&1; then
    CODE_QUALITY=$((CODE_QUALITY + 5))
    add_check "code_quality" "Terraform Validation" 5 5 "pass" "Configuration is valid"
    echo "  ✅ Terraform validation: PASS" >&2
else
    add_check "code_quality" "Terraform Validation" 0 5 "fail" "Configuration has errors"
    ERRORS+=("Terraform validation failed")
    echo "  ❌ Terraform validation: FAIL" >&2
fi

# Check 3: No hardcoded credentials (5 points)
CRED_ISSUES=0
if grep -r "aws_access_key_id\s*=\s*\"[A-Z0-9]" . 2>/dev/null; then
    CRED_ISSUES=$((CRED_ISSUES + 1))
fi
if grep -r "aws_secret_access_key\s*=\s*\"" . 2>/dev/null; then
    CRED_ISSUES=$((CRED_ISSUES + 1))
fi

if [ $CRED_ISSUES -eq 0 ]; then
    CODE_QUALITY=$((CODE_QUALITY + 5))
    add_check "code_quality" "No Hardcoded Credentials" 5 5 "pass" "No credentials found in code"
    echo "  ✅ No hardcoded credentials: PASS" >&2
else
    add_check "code_quality" "No Hardcoded Credentials" 0 5 "fail" "Found $CRED_ISSUES credential issues"
    ERRORS+=("Hardcoded credentials detected")
    echo "  ❌ No hardcoded credentials: FAIL" >&2
fi

# Check 4: Required files exist (5 points)
FILES_POINTS=0
if [ -f "main.tf" ]; then
    FILES_POINTS=$((FILES_POINTS + 2))
fi
if [ -f "variables.tf" ]; then
    FILES_POINTS=$((FILES_POINTS + 1))
fi
if [ -f "outputs.tf" ]; then
    FILES_POINTS=$((FILES_POINTS + 1))
fi
if [ -f "user_data.sh" ]; then
    FILES_POINTS=$((FILES_POINTS + 1))
fi

CODE_QUALITY=$((CODE_QUALITY + FILES_POINTS))
if [ $FILES_POINTS -eq 5 ]; then
    add_check "code_quality" "Required Files" 5 5 "pass" "All required files present"
    echo "  ✅ Required files: PASS" >&2
else
    add_check "code_quality" "Required Files" $FILES_POINTS 5 "partial" "Missing some required files"
    echo "  ⚠️  Required files: PARTIAL ($FILES_POINTS/5)" >&2
fi

# Check 5: Uses data source for AMI (5 points)
if [ -f "$PLAN_FILE" ]; then
    DATA_AMI=$(jq -r '.configuration.root_module.data[]? | select(.type == "aws_ami") | .type' "$PLAN_FILE" 2>/dev/null)
    if [ "$DATA_AMI" == "aws_ami" ]; then
        CODE_QUALITY=$((CODE_QUALITY + 5))
        add_check "code_quality" "AMI Data Source" 5 5 "pass" "Uses data source for AMI lookup"
        echo "  ✅ AMI data source: PASS" >&2
    else
        add_check "code_quality" "AMI Data Source" 0 5 "fail" "Should use data source instead of hardcoded AMI"
        WARNINGS+=("Using hardcoded AMI instead of data source")
        echo "  ❌ AMI data source: FAIL" >&2
    fi
else
    add_check "code_quality" "AMI Data Source" 0 5 "skip" "Plan file not available"
fi

echo "" >&2

# ==================== FUNCTIONALITY (30 points) ====================
echo "📋 Checking Functionality..." >&2

if [ -f "$PLAN_FILE" ]; then
    # Check 1: AWS Key Pair (5 points)
    KEY_PAIR_COUNT=$(jq "[.planned_values.root_module.resources[]? | select(.type == \"aws_key_pair\")] | length" "$PLAN_FILE")
    if [ "$KEY_PAIR_COUNT" -gt 0 ]; then
        FUNCTIONALITY=$((FUNCTIONALITY + 5))
        add_check "functionality" "AWS Key Pair" 5 5 "pass" "Key pair resource configured"
        echo "  ✅ AWS Key Pair: PASS" >&2
    else
        add_check "functionality" "AWS Key Pair" 0 5 "fail" "aws_key_pair resource not found"
        ERRORS+=("Key pair not configured")
        echo "  ❌ AWS Key Pair: NOT FOUND" >&2
    fi

    # Check 2: Security Group with required rules (10 points)
    SG_COUNT=$(jq "[.planned_values.root_module.resources[]? | select(.type == \"aws_security_group\")] | length" "$PLAN_FILE")
    if [ "$SG_COUNT" -gt 0 ]; then
        SG_POINTS=2

        # Check SSH rule
        SSH_RULE=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_security_group") | .values.ingress[]? | select(.from_port == 22)] | length' "$PLAN_FILE")
        if [ "$SSH_RULE" -gt 0 ]; then
            SG_POINTS=$((SG_POINTS + 2))
        fi

        # Check HTTP rule
        HTTP_RULE=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_security_group") | .values.ingress[]? | select(.from_port == 80)] | length' "$PLAN_FILE")
        if [ "$HTTP_RULE" -gt 0 ]; then
            SG_POINTS=$((SG_POINTS + 2))
        else
            ERRORS+=("HTTP port 80 not open - WordPress needs this!")
        fi

        # CRITICAL: Check egress rules
        EGRESS_COUNT=$(jq '[.planned_values.root_module.resources[]? | select(.type == "aws_security_group") | .values.egress[]?] | length' "$PLAN_FILE")
        if [ "$EGRESS_COUNT" -gt 0 ]; then
            SG_POINTS=$((SG_POINTS + 4))
            echo "  ✅ Security group egress rule: PRESENT" >&2
        else
            ERRORS+=("NO EGRESS RULE - Instance cannot download packages!")
            echo "  ❌ Security group egress rule: MISSING (CRITICAL!)" >&2
        fi

        FUNCTIONALITY=$((FUNCTIONALITY + SG_POINTS))
        add_check "functionality" "Security Group" $SG_POINTS 10 "$([ $SG_POINTS -ge 8 ] && echo 'pass' || echo 'partial')" "Security group with rules"
        echo "  ✅ Security Group: $SG_POINTS/10 points" >&2
    else
        add_check "functionality" "Security Group" 0 10 "fail" "aws_security_group resource not found"
        ERRORS+=("Security group not configured")
        echo "  ❌ Security Group: NOT FOUND" >&2
    fi

    # Check 3: EC2 Instance (10 points)
    EC2_COUNT=$(jq "[.planned_values.root_module.resources[]? | select(.type == \"aws_instance\")] | length" "$PLAN_FILE")
    if [ "$EC2_COUNT" -gt 0 ]; then
        EC2_POINTS=3

        # Check instance type
        INSTANCE_TYPE=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.instance_type] | first' "$PLAN_FILE")
        if [[ "$INSTANCE_TYPE" =~ ^t[2-4] ]]; then
            EC2_POINTS=$((EC2_POINTS + 2))
        fi

        # Check key reference
        KEY_REF=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.key_name] | first' "$PLAN_FILE")
        if [ "$KEY_REF" != "null" ] && [ -n "$KEY_REF" ]; then
            EC2_POINTS=$((EC2_POINTS + 2))
        fi

        # Check user_data
        USER_DATA=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.user_data] | first' "$PLAN_FILE")
        if [ "$USER_DATA" != "null" ] && [ -n "$USER_DATA" ]; then
            EC2_POINTS=$((EC2_POINTS + 3))
        else
            WARNINGS+=("User data not configured - WordPress won't auto-install")
        fi

        FUNCTIONALITY=$((FUNCTIONALITY + EC2_POINTS))
        add_check "functionality" "EC2 Instance" $EC2_POINTS 10 "pass" "Instance type: $INSTANCE_TYPE"
        echo "  ✅ EC2 Instance: $EC2_POINTS/10 points" >&2
    else
        add_check "functionality" "EC2 Instance" 0 10 "fail" "aws_instance resource not found"
        ERRORS+=("EC2 instance not configured")
        echo "  ❌ EC2 Instance: NOT FOUND" >&2
    fi

    # Check 4: Outputs defined (5 points)
    if [ -f "outputs.tf" ] && [ -s "outputs.tf" ]; then
        OUTPUT_COUNT=$(grep -c "^output " outputs.tf 2>/dev/null || echo 0)
        if [ "$OUTPUT_COUNT" -ge 5 ]; then
            FUNCTIONALITY=$((FUNCTIONALITY + 5))
            add_check "functionality" "Outputs Defined" 5 5 "pass" "$OUTPUT_COUNT outputs defined"
            echo "  ✅ Outputs: $OUTPUT_COUNT defined" >&2
        elif [ "$OUTPUT_COUNT" -gt 0 ]; then
            FUNCTIONALITY=$((FUNCTIONALITY + 3))
            add_check "functionality" "Outputs Defined" 3 5 "partial" "$OUTPUT_COUNT outputs (need 5+)"
            echo "  ⚠️  Outputs: $OUTPUT_COUNT defined (need 5+)" >&2
        else
            add_check "functionality" "Outputs Defined" 0 5 "fail" "No outputs defined"
            echo "  ❌ Outputs: NONE" >&2
        fi
    else
        add_check "functionality" "Outputs Defined" 0 5 "fail" "outputs.tf not found"
        echo "  ❌ Outputs: NOT FOUND" >&2
    fi
else
    add_check "functionality" "Terraform Plan" 0 30 "fail" "Plan file not found"
    ERRORS+=("Terraform plan failed")
    echo "  ❌ Plan file not found" >&2
fi

echo "" >&2

# ==================== IMDSv2 CONFIGURATION (10 points) ====================
echo "📋 Checking IMDSv2 Configuration..." >&2

if [ -f "$PLAN_FILE" ]; then
    METADATA_OPTIONS=$(jq '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[]?] | length' "$PLAN_FILE")

    if [ "$METADATA_OPTIONS" -gt 0 ]; then
        # Check http_tokens = required (5 points)
        HTTP_TOKENS=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[0].http_tokens] | first' "$PLAN_FILE")
        if [ "$HTTP_TOKENS" == "required" ]; then
            IMDSV2=$((IMDSV2 + 5))
            add_check "imdsv2" "http_tokens = required" 5 5 "pass" "IMDSv2 enforced"
            echo "  ✅ http_tokens = required: PASS" >&2
        else
            add_check "imdsv2" "http_tokens = required" 0 5 "fail" "Must be 'required', got: $HTTP_TOKENS"
            ERRORS+=("IMDSv2 not enforced")
            echo "  ❌ http_tokens = required: FAIL (got: $HTTP_TOKENS)" >&2
        fi

        # Check http_endpoint = enabled (2 points)
        HTTP_ENDPOINT=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[0].http_endpoint] | first' "$PLAN_FILE")
        if [ "$HTTP_ENDPOINT" == "enabled" ]; then
            IMDSV2=$((IMDSV2 + 2))
            add_check "imdsv2" "http_endpoint = enabled" 2 2 "pass" "IMDS enabled"
            echo "  ✅ http_endpoint = enabled: PASS" >&2
        else
            add_check "imdsv2" "http_endpoint = enabled" 0 2 "fail" "Got: $HTTP_ENDPOINT"
            echo "  ❌ http_endpoint = enabled: FAIL" >&2
        fi

        # Check hop limit = 1 (2 points)
        HOP_LIMIT=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[0].http_put_response_hop_limit] | first' "$PLAN_FILE")
        if [ "$HOP_LIMIT" == "1" ]; then
            IMDSV2=$((IMDSV2 + 2))
            add_check "imdsv2" "hop_limit = 1" 2 2 "pass" "Hop limit secured"
            echo "  ✅ hop_limit = 1: PASS" >&2
        else
            add_check "imdsv2" "hop_limit = 1" 1 2 "partial" "Got: $HOP_LIMIT (recommended: 1)"
            IMDSV2=$((IMDSV2 + 1))
            echo "  ⚠️  hop_limit = 1: PARTIAL (got: $HOP_LIMIT)" >&2
        fi

        # Check metadata tags enabled (1 point)
        METADATA_TAGS=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[0].instance_metadata_tags] | first' "$PLAN_FILE")
        if [ "$METADATA_TAGS" == "enabled" ]; then
            IMDSV2=$((IMDSV2 + 1))
            add_check "imdsv2" "instance_metadata_tags" 1 1 "pass" "Tags accessible via IMDS"
            echo "  ✅ instance_metadata_tags = enabled: PASS" >&2
        else
            add_check "imdsv2" "instance_metadata_tags" 0 1 "fail" "Got: $METADATA_TAGS"
            echo "  ⚠️  instance_metadata_tags: $METADATA_TAGS" >&2
        fi
    else
        add_check "imdsv2" "IMDSv2 Configuration" 0 10 "fail" "metadata_options block not found"
        ERRORS+=("IMDSv2 not configured - critical security requirement")
        echo "  ❌ IMDSv2: NOT CONFIGURED" >&2
    fi
else
    add_check "imdsv2" "IMDSv2 Configuration" 0 10 "skip" "Plan file not available"
fi

echo "" >&2

# ==================== COST MANAGEMENT (15 points) ====================
echo "📋 Checking Cost Management..." >&2

# Check 1: Infracost analysis (5 points)
if [ -f "$INFRACOST_FILE" ]; then
    COST_MGMT=$((COST_MGMT + 5))
    add_check "cost_mgmt" "Infracost Analysis" 5 5 "pass" "Cost analysis completed"
    echo "  ✅ Infracost analysis: PASS" >&2

    # Check 2: Within budget (5 points)
    MONTHLY_COST=$(jq -r '.totalMonthlyCost // "0"' "$INFRACOST_FILE")
    COST_LIMIT=15.00

    if awk "BEGIN {exit !($MONTHLY_COST <= $COST_LIMIT)}"; then
        COST_MGMT=$((COST_MGMT + 5))
        add_check "cost_mgmt" "Within Budget" 5 5 "pass" "Estimated cost: \$$MONTHLY_COST/month (limit: \$$COST_LIMIT)"
        echo "  ✅ Within budget: \$$MONTHLY_COST/month" >&2
    else
        add_check "cost_mgmt" "Within Budget" 0 5 "fail" "Cost \$$MONTHLY_COST exceeds \$$COST_LIMIT/month"
        WARNINGS+=("Cost exceeds budget")
        echo "  ❌ Over budget: \$$MONTHLY_COST/month" >&2
    fi
else
    add_check "cost_mgmt" "Infracost Analysis" 0 5 "fail" "Infracost analysis not available"
    add_check "cost_mgmt" "Within Budget" 0 5 "skip" "Cannot check without Infracost"
    echo "  ⚠️  Infracost not available" >&2
fi

# Check 3: AutoTeardown tag (5 points)
if [ -f "$PLAN_FILE" ]; then
    HAS_TEARDOWN=$(jq -r '[.planned_values.root_module.resources[]? | select(.values.tags.AutoTeardown != null)] | length' "$PLAN_FILE")
    if [ "$HAS_TEARDOWN" -gt 0 ]; then
        COST_MGMT=$((COST_MGMT + 5))
        add_check "cost_mgmt" "AutoTeardown Tag" 5 5 "pass" "AutoTeardown tag found on $HAS_TEARDOWN resource(s)"
        echo "  ✅ AutoTeardown tag: FOUND" >&2
    else
        add_check "cost_mgmt" "AutoTeardown Tag" 0 5 "fail" "AutoTeardown tag missing from resources"
        WARNINGS+=("AutoTeardown tag missing")
        echo "  ❌ AutoTeardown tag: NOT FOUND" >&2
    fi
fi

echo "" >&2

# ==================== SECURITY (15 points) ====================
echo "📋 Checking Security..." >&2

# Check SSH restriction (5 points)
if [ -f "$PLAN_FILE" ]; then
    SSH_CIDR=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_security_group") | .values.ingress[]? | select(.from_port == 22) | .cidr_blocks[]?] | first' "$PLAN_FILE")

    if [ "$SSH_CIDR" != "0.0.0.0/0" ] && [ "$SSH_CIDR" != "null" ] && [ -n "$SSH_CIDR" ]; then
        SECURITY=$((SECURITY + 5))
        add_check "security" "SSH Restricted" 5 5 "pass" "SSH restricted to: $SSH_CIDR"
        echo "  ✅ SSH restricted: $SSH_CIDR" >&2
    else
        add_check "security" "SSH Restricted" 0 5 "fail" "SSH open to 0.0.0.0/0 - security risk!"
        ERRORS+=("SSH open to world - security risk!")
        echo "  ❌ SSH restricted: FAIL (open to 0.0.0.0/0)" >&2
    fi

    # Check EBS encryption (3 points)
    EBS_ENCRYPTED=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.root_block_device[0].encrypted] | first' "$PLAN_FILE")
    if [ "$EBS_ENCRYPTED" == "true" ]; then
        SECURITY=$((SECURITY + 3))
        add_check "security" "EBS Encryption" 3 3 "pass" "Root volume encrypted"
        echo "  ✅ EBS encryption: ENABLED" >&2
    else
        add_check "security" "EBS Encryption" 0 3 "fail" "Root volume not encrypted"
        echo "  ❌ EBS encryption: DISABLED" >&2
    fi
fi

# Policy scan (7 points)
if [ -f "$POLICY_FILE" ]; then
    FAILED_CHECKS=$(jq '.results.failed_checks | length // 0' "$POLICY_FILE" 2>/dev/null || echo "0")
    PASSED_CHECKS=$(jq '.results.passed_checks | length // 0' "$POLICY_FILE" 2>/dev/null || echo "0")
    WARNING_CHECKS=$(jq '.results.warnings | length // 0' "$POLICY_FILE" 2>/dev/null || echo "0")

    echo "  Policy checks: $PASSED_CHECKS passed, $FAILED_CHECKS failed, $WARNING_CHECKS warnings" >&2

    # Show failed checks for debugging
    if [ "$FAILED_CHECKS" -gt 0 ]; then
        echo "  Failed checks:" >&2
        jq -r '.results.failed_checks[]? | "    - " + (.resource // .check_id // "unknown")' "$POLICY_FILE" 2>/dev/null >&2 || true
    fi

    if [ "$FAILED_CHECKS" -eq 0 ]; then
        SECURITY=$((SECURITY + 7))
        add_check "security" "Policy Checks" 7 7 "pass" "All lab-specific policies passed"
        echo "  ✅ Policy checks: PASS (7/7)" >&2
    elif [ "$FAILED_CHECKS" -le 2 ]; then
        SECURITY=$((SECURITY + 5))
        add_check "security" "Policy Checks" 5 7 "partial" "$FAILED_CHECKS policy issues"
        echo "  ⚠️  Policy checks: PARTIAL (5/7)" >&2
    elif [ "$FAILED_CHECKS" -le 4 ]; then
        SECURITY=$((SECURITY + 3))
        add_check "security" "Policy Checks" 3 7 "partial" "$FAILED_CHECKS policy issues"
        echo "  ⚠️  Policy checks: PARTIAL (3/7)" >&2
    else
        add_check "security" "Policy Checks" 0 7 "fail" "$FAILED_CHECKS policy issues found"
        ERRORS+=("Multiple policy failures detected")
        echo "  ❌ Policy checks: FAIL (0/7)" >&2
    fi
else
    add_check "security" "Policy Checks" 0 7 "skip" "Policy checks not available"
    echo "  ⚠️  Policy results not available" >&2
fi

echo "" >&2

# ==================== DOCUMENTATION (5 points) ====================
echo "📋 Checking Documentation..." >&2

# Check 1: Code comments (3 points)
COMMENT_LINES=$(grep -r "^\s*#" *.tf 2>/dev/null | wc -l || echo 0)
if [ "$COMMENT_LINES" -ge 5 ]; then
    DOCUMENTATION=$((DOCUMENTATION + 3))
    add_check "documentation" "Code Comments" 3 3 "pass" "$COMMENT_LINES comment lines found"
    echo "  ✅ Code comments: $COMMENT_LINES lines" >&2
elif [ "$COMMENT_LINES" -ge 2 ]; then
    DOCUMENTATION=$((DOCUMENTATION + 2))
    add_check "documentation" "Code Comments" 2 3 "partial" "$COMMENT_LINES comment lines (need 5+)"
    echo "  ⚠️  Code comments: $COMMENT_LINES lines (need more)" >&2
else
    add_check "documentation" "Code Comments" 0 3 "fail" "Insufficient comments"
    echo "  ❌ Code comments: NOT ENOUGH" >&2
fi

# Check 2: Variable descriptions (2 points)
if [ -f "variables.tf" ]; then
    DESC_COUNT=$(grep -c "description" variables.tf 2>/dev/null || echo 0)
    VAR_COUNT=$(grep -c "^variable" variables.tf 2>/dev/null || echo 0)

    if [ "$VAR_COUNT" -gt 0 ] && [ "$DESC_COUNT" -ge "$VAR_COUNT" ]; then
        DOCUMENTATION=$((DOCUMENTATION + 2))
        add_check "documentation" "Variable Descriptions" 2 2 "pass" "All variables have descriptions"
        echo "  ✅ Variable descriptions: PASS" >&2
    elif [ "$DESC_COUNT" -gt 0 ]; then
        DOCUMENTATION=$((DOCUMENTATION + 1))
        add_check "documentation" "Variable Descriptions" 1 2 "partial" "$DESC_COUNT of $VAR_COUNT variables have descriptions"
        echo "  ⚠️  Variable descriptions: PARTIAL" >&2
    else
        add_check "documentation" "Variable Descriptions" 0 2 "fail" "No variable descriptions"
        echo "  ❌ Variable descriptions: MISSING" >&2
    fi
else
    add_check "documentation" "Variable Descriptions" 0 2 "fail" "variables.tf not found"
fi

echo "" >&2

# ==================== CALCULATE FINAL GRADE ====================
TOTAL=$((CODE_QUALITY + FUNCTIONALITY + COST_MGMT + SECURITY + IMDSV2 + DOCUMENTATION))
TOTAL_MAX=$((CODE_QUALITY_MAX + FUNCTIONALITY_MAX + COST_MGMT_MAX + SECURITY_MAX + IMDSV2_MAX + DOCUMENTATION_MAX))

if [ $TOTAL -ge 90 ]; then
    LETTER="A"
elif [ $TOTAL -ge 80 ]; then
    LETTER="B"
elif [ $TOTAL -ge 70 ]; then
    LETTER="C"
elif [ $TOTAL -ge 60 ]; then
    LETTER="D"
else
    LETTER="F"
fi

echo "================================================" >&2
echo "Final Grade: $TOTAL/$TOTAL_MAX ($LETTER)" >&2
echo "================================================" >&2
echo "" >&2
echo "Breakdown:" >&2
echo "  Code Quality:    $CODE_QUALITY/$CODE_QUALITY_MAX" >&2
echo "  Functionality:   $FUNCTIONALITY/$FUNCTIONALITY_MAX" >&2
echo "  IMDSv2:          $IMDSV2/$IMDSV2_MAX" >&2
echo "  Cost Management: $COST_MGMT/$COST_MGMT_MAX" >&2
echo "  Security:        $SECURITY/$SECURITY_MAX" >&2
echo "  Documentation:   $DOCUMENTATION/$DOCUMENTATION_MAX" >&2
echo "" >&2

# ==================== OUTPUT JSON ====================

# Helper to join array elements
join_array() {
    local IFS=','
    echo "$*"
}

cat <<EOF
{
  "lab": {
    "week": 0,
    "lab": 1,
    "name": "WordPress on EC2"
  },
  "scores": {
    "code_quality": {"earned": $CODE_QUALITY, "max": $CODE_QUALITY_MAX},
    "functionality": {"earned": $FUNCTIONALITY, "max": $FUNCTIONALITY_MAX},
    "imdsv2": {"earned": $IMDSV2, "max": $IMDSV2_MAX},
    "cost_management": {"earned": $COST_MGMT, "max": $COST_MGMT_MAX},
    "security": {"earned": $SECURITY, "max": $SECURITY_MAX},
    "documentation": {"earned": $DOCUMENTATION, "max": $DOCUMENTATION_MAX}
  },
  "total": {"earned": $TOTAL, "max": $TOTAL_MAX},
  "letter_grade": "$LETTER",
  "checks": {
    "code_quality": [$(join_array "${CODE_QUALITY_CHECKS[@]}")],
    "functionality": [$(join_array "${FUNCTIONALITY_CHECKS[@]}")],
    "imdsv2": [$(join_array "${IMDSV2_CHECKS[@]}")],
    "cost_management": [$(join_array "${COST_MGMT_CHECKS[@]}")],
    "security": [$(join_array "${SECURITY_CHECKS[@]}")],
    "documentation": [$(join_array "${DOCUMENTATION_CHECKS[@]}")]
  },
  "errors": [$(printf '"%s",' "${ERRORS[@]}" | sed 's/,$//')]$( [ ${#ERRORS[@]} -eq 0 ] && echo "" ),
  "warnings": [$(printf '"%s",' "${WARNINGS[@]}" | sed 's/,$//')]$( [ ${#WARNINGS[@]} -eq 0 ] && echo "" )
}
EOF
