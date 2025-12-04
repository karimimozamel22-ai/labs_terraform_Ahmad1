#!/bin/bash
#
# Lab 00 Grading Script
# Complete grading for S3 Bucket with Versioning lab
#
# Usage: grade.sh <student-work-dir>
# Output: JSON grading results to stdout
#
# Grading Categories:
#   - Code Quality (25 points)
#   - Functionality (30 points)
#   - Cost Management (20 points)
#   - Security (15 points)
#   - Documentation (10 points)
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
COST_MGMT_MAX=20
SECURITY=0
SECURITY_MAX=15
DOCUMENTATION=0
DOCUMENTATION_MAX=10

# Initialize check results arrays
declare -a CODE_QUALITY_CHECKS=()
declare -a FUNCTIONALITY_CHECKS=()
declare -a COST_MGMT_CHECKS=()
declare -a SECURITY_CHECKS=()
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
        "documentation") DOCUMENTATION_CHECKS+=("$check") ;;
    esac
}

echo "================================================" >&2
echo "Lab 00 Grading - S3 Bucket with Versioning" >&2
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

# Check 4: main.tf exists (5 points)
if [ -f "main.tf" ]; then
    CODE_QUALITY=$((CODE_QUALITY + 5))
    add_check "code_quality" "File Structure" 5 5 "pass" "main.tf exists"
    echo "  ✅ File structure: PASS" >&2
else
    add_check "code_quality" "File Structure" 0 5 "fail" "main.tf not found"
    ERRORS+=("main.tf not found")
    echo "  ❌ File structure: FAIL" >&2
fi

# Check 5: Terraform version requirement (5 points)
if grep -qE 'required_version.*[">]=.*(1\.(9|[1-9][0-9])|[2-9]\.)' *.tf 2>/dev/null; then
    CODE_QUALITY=$((CODE_QUALITY + 5))
    add_check "code_quality" "Terraform Version" 5 5 "pass" "Version >= 1.9.0 required"
    echo "  ✅ Terraform version requirement: PASS" >&2
else
    add_check "code_quality" "Terraform Version" 0 5 "fail" "Missing required_version >= 1.9.0"
    WARNINGS+=("Missing Terraform version requirement")
    echo "  ❌ Terraform version requirement: FAIL" >&2
fi

echo "" >&2

# ==================== FUNCTIONALITY (30 points) ====================
echo "📋 Checking Functionality..." >&2

if [ -f "$PLAN_FILE" ]; then
    # Check 1: S3 Bucket exists (7 points)
    S3_COUNT=$(jq "[.planned_values.root_module.resources[]? | select(.type == \"aws_s3_bucket\")] | length" "$PLAN_FILE")
    if [ "$S3_COUNT" -gt 0 ]; then
        FUNCTIONALITY=$((FUNCTIONALITY + 5))

        # Bonus: bucket name includes lab identifier
        BUCKET_NAME=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_s3_bucket") | .values.bucket] | first' "$PLAN_FILE")
        if [[ "$BUCKET_NAME" =~ lab-00 ]] || [[ "$BUCKET_NAME" =~ terraform ]]; then
            FUNCTIONALITY=$((FUNCTIONALITY + 2))
            add_check "functionality" "S3 Bucket Resource" 7 7 "pass" "S3 bucket with proper naming: $BUCKET_NAME"
        else
            add_check "functionality" "S3 Bucket Resource" 5 7 "partial" "S3 bucket exists but name should include 'lab-00' or 'terraform'"
        fi
        echo "  ✅ S3 Bucket: FOUND" >&2
    else
        add_check "functionality" "S3 Bucket Resource" 0 7 "fail" "aws_s3_bucket resource not found"
        ERRORS+=("S3 bucket resource not found")
        echo "  ❌ S3 Bucket: NOT FOUND" >&2
    fi

    # Check 2: Versioning enabled (8 points)
    VERSIONING_COUNT=$(jq "[.planned_values.root_module.resources[]? | select(.type == \"aws_s3_bucket_versioning\")] | length" "$PLAN_FILE")
    if [ "$VERSIONING_COUNT" -gt 0 ]; then
        FUNCTIONALITY=$((FUNCTIONALITY + 5))

        VERSIONING_STATUS=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_s3_bucket_versioning") | .values.versioning_configuration[0].status] | first' "$PLAN_FILE")
        if [ "$VERSIONING_STATUS" == "Enabled" ]; then
            FUNCTIONALITY=$((FUNCTIONALITY + 3))
            add_check "functionality" "S3 Versioning" 8 8 "pass" "Versioning enabled"
        else
            add_check "functionality" "S3 Versioning" 5 8 "partial" "Versioning resource exists but status is not 'Enabled'"
        fi
        echo "  ✅ S3 Versioning: FOUND" >&2
    else
        add_check "functionality" "S3 Versioning" 0 8 "fail" "aws_s3_bucket_versioning resource not found"
        ERRORS+=("S3 versioning not configured")
        echo "  ❌ S3 Versioning: NOT FOUND" >&2
    fi

    # Check 3: Encryption configured (7 points)
    ENCRYPTION_COUNT=$(jq "[.planned_values.root_module.resources[]? | select(.type == \"aws_s3_bucket_server_side_encryption_configuration\")] | length" "$PLAN_FILE")
    if [ "$ENCRYPTION_COUNT" -gt 0 ]; then
        FUNCTIONALITY=$((FUNCTIONALITY + 5))

        ENCRYPTION_ALGO=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_s3_bucket_server_side_encryption_configuration") | .values.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm] | first' "$PLAN_FILE")
        if [ "$ENCRYPTION_ALGO" == "AES256" ] || [ "$ENCRYPTION_ALGO" == "aws:kms" ]; then
            FUNCTIONALITY=$((FUNCTIONALITY + 2))
            add_check "functionality" "S3 Encryption" 7 7 "pass" "Encryption configured: $ENCRYPTION_ALGO"
        else
            add_check "functionality" "S3 Encryption" 5 7 "partial" "Encryption resource exists"
        fi
        echo "  ✅ S3 Encryption: FOUND" >&2
    else
        add_check "functionality" "S3 Encryption" 0 7 "fail" "Encryption not configured"
        WARNINGS+=("S3 encryption not configured")
        echo "  ❌ S3 Encryption: NOT FOUND" >&2
    fi

    # Check 4: Outputs defined (5 points)
    if [ -f "outputs.tf" ] && [ -s "outputs.tf" ]; then
        OUTPUT_COUNT=$(grep -c "^output " outputs.tf 2>/dev/null || echo 0)
        if [ "$OUTPUT_COUNT" -gt 0 ]; then
            FUNCTIONALITY=$((FUNCTIONALITY + 5))
            add_check "functionality" "Outputs Defined" 5 5 "pass" "$OUTPUT_COUNT outputs defined"
            echo "  ✅ Outputs: $OUTPUT_COUNT defined" >&2
        else
            add_check "functionality" "Outputs Defined" 0 5 "fail" "No outputs defined in outputs.tf"
            echo "  ❌ Outputs: NONE" >&2
        fi
    else
        add_check "functionality" "Outputs Defined" 0 5 "fail" "outputs.tf not found or empty"
        echo "  ❌ Outputs: NOT FOUND" >&2
    fi

    # Check 5: Resources in plan (3 points)
    RESOURCES_TO_ADD=$(jq '[.resource_changes[]? | select(.change.actions[] == "create")] | length' "$PLAN_FILE")
    if [ "$RESOURCES_TO_ADD" -gt 0 ]; then
        FUNCTIONALITY=$((FUNCTIONALITY + 3))
        add_check "functionality" "Resources in Plan" 3 3 "pass" "$RESOURCES_TO_ADD resources to create"
        echo "  ✅ Resources to create: $RESOURCES_TO_ADD" >&2
    else
        add_check "functionality" "Resources in Plan" 0 3 "fail" "No resources to create"
        echo "  ❌ Resources to create: NONE" >&2
    fi
else
    add_check "functionality" "Terraform Plan" 0 30 "fail" "Plan file not found"
    ERRORS+=("Terraform plan failed")
    echo "  ❌ Plan file not found" >&2
fi

echo "" >&2

# ==================== COST MANAGEMENT (20 points) ====================
echo "📋 Checking Cost Management..." >&2

# Check 1: Infracost analysis (5 points)
if [ -f "$INFRACOST_FILE" ]; then
    COST_MGMT=$((COST_MGMT + 5))
    add_check "cost_mgmt" "Infracost Analysis" 5 5 "pass" "Cost analysis completed"
    echo "  ✅ Infracost analysis: PASS" >&2

    # Check 2: Within budget (10 points)
    MONTHLY_COST=$(jq -r '.totalMonthlyCost // "0"' "$INFRACOST_FILE")
    COST_LIMIT=10.00

    if awk "BEGIN {exit !($MONTHLY_COST <= $COST_LIMIT)}"; then
        COST_MGMT=$((COST_MGMT + 10))
        add_check "cost_mgmt" "Within Budget" 10 10 "pass" "Estimated cost: \$$MONTHLY_COST/month (limit: \$$COST_LIMIT)"
        echo "  ✅ Within budget: \$$MONTHLY_COST/month" >&2
    else
        add_check "cost_mgmt" "Within Budget" 0 10 "fail" "Cost \$$MONTHLY_COST exceeds \$$COST_LIMIT/month"
        WARNINGS+=("Cost exceeds budget")
        echo "  ❌ Over budget: \$$MONTHLY_COST/month" >&2
    fi
else
    add_check "cost_mgmt" "Infracost Analysis" 0 5 "fail" "Infracost analysis not available"
    add_check "cost_mgmt" "Within Budget" 0 10 "skip" "Cannot check without Infracost"
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
echo "📋 Checking Security/Policy..." >&2

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
        SECURITY=$((SECURITY + 15))
        add_check "security" "Policy Checks" 15 15 "pass" "All required policies passed"
        echo "  ✅ Policy checks: PASS (15/15)" >&2
    elif [ "$FAILED_CHECKS" -le 2 ]; then
        SECURITY=$((SECURITY + 10))
        add_check "security" "Policy Checks" 10 15 "partial" "$FAILED_CHECKS policy issues"
        echo "  ⚠️  Policy checks: PARTIAL (10/15)" >&2
    elif [ "$FAILED_CHECKS" -le 4 ]; then
        SECURITY=$((SECURITY + 5))
        add_check "security" "Policy Checks" 5 15 "partial" "$FAILED_CHECKS policy issues"
        echo "  ⚠️  Policy checks: PARTIAL (5/15)" >&2
    else
        add_check "security" "Policy Checks" 0 15 "fail" "$FAILED_CHECKS policy issues found"
        ERRORS+=("Multiple policy failures detected")
        echo "  ❌ Policy checks: FAIL (0/15)" >&2
    fi
else
    add_check "security" "Policy Checks" 0 15 "skip" "Policy checks not available"
    echo "  ⚠️  Policy results not available" >&2
fi

echo "" >&2

# ==================== DOCUMENTATION (10 points) ====================
echo "📋 Checking Documentation..." >&2

# Check 1: Code comments (5 points)
COMMENT_LINES=$(grep -r "^\s*#" *.tf 2>/dev/null | wc -l || echo 0)
if [ "$COMMENT_LINES" -ge 5 ]; then
    DOCUMENTATION=$((DOCUMENTATION + 5))
    add_check "documentation" "Code Comments" 5 5 "pass" "$COMMENT_LINES comment lines found"
    echo "  ✅ Code comments: $COMMENT_LINES lines" >&2
elif [ "$COMMENT_LINES" -ge 2 ]; then
    DOCUMENTATION=$((DOCUMENTATION + 3))
    add_check "documentation" "Code Comments" 3 5 "partial" "$COMMENT_LINES comment lines (need 5+)"
    echo "  ⚠️  Code comments: $COMMENT_LINES lines (need more)" >&2
else
    add_check "documentation" "Code Comments" 0 5 "fail" "Insufficient comments"
    echo "  ❌ Code comments: NOT ENOUGH" >&2
fi

# Check 2: README exists (5 points)
if [ -f "README.md" ] && [ -s "README.md" ]; then
    DOCUMENTATION=$((DOCUMENTATION + 5))
    add_check "documentation" "README" 5 5 "pass" "README.md exists"
    echo "  ✅ README.md: FOUND" >&2
else
    add_check "documentation" "README" 0 5 "fail" "README.md not found or empty"
    echo "  ❌ README.md: NOT FOUND" >&2
fi

echo "" >&2

# ==================== CALCULATE FINAL GRADE ====================
TOTAL=$((CODE_QUALITY + FUNCTIONALITY + COST_MGMT + SECURITY + DOCUMENTATION))
TOTAL_MAX=$((CODE_QUALITY_MAX + FUNCTIONALITY_MAX + COST_MGMT_MAX + SECURITY_MAX + DOCUMENTATION_MAX))

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
    "lab": 0,
    "name": "S3 Bucket with Versioning"
  },
  "scores": {
    "code_quality": {"earned": $CODE_QUALITY, "max": $CODE_QUALITY_MAX},
    "functionality": {"earned": $FUNCTIONALITY, "max": $FUNCTIONALITY_MAX},
    "cost_management": {"earned": $COST_MGMT, "max": $COST_MGMT_MAX},
    "security": {"earned": $SECURITY, "max": $SECURITY_MAX},
    "documentation": {"earned": $DOCUMENTATION, "max": $DOCUMENTATION_MAX}
  },
  "total": {"earned": $TOTAL, "max": $TOTAL_MAX},
  "letter_grade": "$LETTER",
  "checks": {
    "code_quality": [$(join_array "${CODE_QUALITY_CHECKS[@]}")],
    "functionality": [$(join_array "${FUNCTIONALITY_CHECKS[@]}")],
    "cost_management": [$(join_array "${COST_MGMT_CHECKS[@]}")],
    "security": [$(join_array "${SECURITY_CHECKS[@]}")],
    "documentation": [$(join_array "${DOCUMENTATION_CHECKS[@]}")]
  },
  "errors": [$(printf '"%s",' "${ERRORS[@]}" | sed 's/,$//')]$( [ ${#ERRORS[@]} -eq 0 ] && echo "" ),
  "warnings": [$(printf '"%s",' "${WARNINGS[@]}" | sed 's/,$//')]$( [ ${#WARNINGS[@]} -eq 0 ] && echo "" )
}
EOF
