#!/bin/bash
#
# Lab 00 (Week 01) Grading Script
# S3 Module + Terraform Testing
#
# Usage: grade.sh <student-work-dir>
# Output: JSON grading results to stdout
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
echo "Lab 00 (Week 01) Grading - S3 Module + Testing" >&2
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

# Check 4: Module structure exists at project root (5 points)
# Module should be at terraform-course/modules/s3-bucket/ (../../../modules/s3-bucket from student-work)
MODULE_PATH="../../../modules/s3-bucket"
if [ -d "$MODULE_PATH" ] && [ -f "$MODULE_PATH/main.tf" ] && [ -f "$MODULE_PATH/variables.tf" ] && [ -f "$MODULE_PATH/outputs.tf" ]; then
    CODE_QUALITY=$((CODE_QUALITY + 5))
    add_check "code_quality" "Module Structure" 5 5 "pass" "Module has proper structure at project root"
    echo "  ✅ Module structure: PASS" >&2
else
    add_check "code_quality" "Module Structure" 0 5 "fail" "Module missing at project root ($MODULE_PATH)"
    ERRORS+=("Module structure incomplete at project root")
    echo "  ❌ Module structure: FAIL" >&2
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

# Check 1: Module is used in main.tf (5 points)
# Module source should reference project root: ../../../modules/s3-bucket
if grep -q 'module.*".*"' main.tf 2>/dev/null && grep -q 'source.*=.*"\.\./\.\./\.\./modules/s3-bucket"' main.tf 2>/dev/null; then
    FUNCTIONALITY=$((FUNCTIONALITY + 5))
    add_check "functionality" "Module Usage" 5 5 "pass" "S3 module is used in main.tf with correct path"
    echo "  ✅ Module usage: PASS" >&2
else
    add_check "functionality" "Module Usage" 0 5 "fail" "Module not properly used in main.tf (should use source = \"../../../modules/s3-bucket\")"
    echo "  ❌ Module usage: FAIL" >&2
fi

# Check 2: Module has required variables (5 points)
MODULE_VARS=0
if grep -q 'variable.*"bucket_name"' "$MODULE_PATH/variables.tf" 2>/dev/null; then
    MODULE_VARS=$((MODULE_VARS + 1))
fi
if grep -q 'variable.*"environment"' "$MODULE_PATH/variables.tf" 2>/dev/null; then
    MODULE_VARS=$((MODULE_VARS + 1))
fi
if grep -q 'variable.*"enable_versioning"' "$MODULE_PATH/variables.tf" 2>/dev/null; then
    MODULE_VARS=$((MODULE_VARS + 1))
fi
if grep -q 'variable.*"tags"' "$MODULE_PATH/variables.tf" 2>/dev/null; then
    MODULE_VARS=$((MODULE_VARS + 1))
fi

if [ $MODULE_VARS -ge 4 ]; then
    FUNCTIONALITY=$((FUNCTIONALITY + 5))
    add_check "functionality" "Module Variables" 5 5 "pass" "All required variables defined"
    echo "  ✅ Module variables: PASS ($MODULE_VARS/4)" >&2
elif [ $MODULE_VARS -ge 2 ]; then
    FUNCTIONALITY=$((FUNCTIONALITY + 3))
    add_check "functionality" "Module Variables" 3 5 "partial" "$MODULE_VARS/4 required variables defined"
    echo "  ⚠️  Module variables: PARTIAL ($MODULE_VARS/4)" >&2
else
    add_check "functionality" "Module Variables" 0 5 "fail" "Missing required variables"
    echo "  ❌ Module variables: FAIL ($MODULE_VARS/4)" >&2
fi

# Check 3: Module has required outputs (5 points)
MODULE_OUTPUTS=0
if grep -q 'output.*"bucket_id"' "$MODULE_PATH/outputs.tf" 2>/dev/null; then
    MODULE_OUTPUTS=$((MODULE_OUTPUTS + 1))
fi
if grep -q 'output.*"bucket_arn"' "$MODULE_PATH/outputs.tf" 2>/dev/null; then
    MODULE_OUTPUTS=$((MODULE_OUTPUTS + 1))
fi
if grep -q 'output.*"bucket_region"' "$MODULE_PATH/outputs.tf" 2>/dev/null; then
    MODULE_OUTPUTS=$((MODULE_OUTPUTS + 1))
fi

if [ $MODULE_OUTPUTS -ge 3 ]; then
    FUNCTIONALITY=$((FUNCTIONALITY + 5))
    add_check "functionality" "Module Outputs" 5 5 "pass" "All required outputs defined"
    echo "  ✅ Module outputs: PASS ($MODULE_OUTPUTS/3)" >&2
elif [ $MODULE_OUTPUTS -ge 2 ]; then
    FUNCTIONALITY=$((FUNCTIONALITY + 3))
    add_check "functionality" "Module Outputs" 3 5 "partial" "$MODULE_OUTPUTS/3 required outputs defined"
    echo "  ⚠️  Module outputs: PARTIAL ($MODULE_OUTPUTS/3)" >&2
else
    add_check "functionality" "Module Outputs" 0 5 "fail" "Missing required outputs"
    echo "  ❌ Module outputs: FAIL ($MODULE_OUTPUTS/3)" >&2
fi

# Check 4: Tests exist (5 points)
if [ -d "tests" ] && ls tests/*.tftest.hcl >/dev/null 2>&1; then
    FUNCTIONALITY=$((FUNCTIONALITY + 5))
    TEST_COUNT=$(ls tests/*.tftest.hcl 2>/dev/null | wc -l)
    add_check "functionality" "Test Files Exist" 5 5 "pass" "$TEST_COUNT test file(s) found"
    echo "  ✅ Test files: PASS ($TEST_COUNT found)" >&2
else
    add_check "functionality" "Test Files Exist" 0 5 "fail" "No .tftest.hcl files found in tests/"
    ERRORS+=("No test files found")
    echo "  ❌ Test files: FAIL" >&2
fi

# Check 5: Tests pass (10 points)
echo "  Running terraform test..." >&2
TEST_OUTPUT=$(terraform test -no-color 2>&1) || true
TEST_RESULT=$?

if echo "$TEST_OUTPUT" | grep -q "Success!"; then
    PASSED_TESTS=$(echo "$TEST_OUTPUT" | grep -oP '\d+(?= passed)' || echo "0")
    FUNCTIONALITY=$((FUNCTIONALITY + 10))
    add_check "functionality" "Tests Pass" 10 10 "pass" "$PASSED_TESTS test(s) passed"
    echo "  ✅ Tests: PASS ($PASSED_TESTS passed)" >&2
elif echo "$TEST_OUTPUT" | grep -q "passed"; then
    PASSED_TESTS=$(echo "$TEST_OUTPUT" | grep -oP '\d+(?= passed)' || echo "0")
    FAILED_TESTS=$(echo "$TEST_OUTPUT" | grep -oP '\d+(?= failed)' || echo "0")
    PARTIAL_POINTS=$((PASSED_TESTS * 10 / (PASSED_TESTS + FAILED_TESTS)))
    FUNCTIONALITY=$((FUNCTIONALITY + PARTIAL_POINTS))
    add_check "functionality" "Tests Pass" $PARTIAL_POINTS 10 "partial" "$PASSED_TESTS passed, $FAILED_TESTS failed"
    echo "  ⚠️  Tests: PARTIAL ($PASSED_TESTS passed, $FAILED_TESTS failed)" >&2
else
    add_check "functionality" "Tests Pass" 0 10 "fail" "Tests failed to run or all failed"
    ERRORS+=("Terraform tests failed")
    echo "  ❌ Tests: FAIL" >&2
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
    COST_LIMIT=5.00

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
    HAS_TEARDOWN=$(jq -r '[.planned_values.root_module.child_modules[]?.resources[]? | select(.values.tags.AutoTeardown != null)] | length' "$PLAN_FILE" 2>/dev/null || echo "0")
    if [ "$HAS_TEARDOWN" -gt 0 ]; then
        COST_MGMT=$((COST_MGMT + 5))
        add_check "cost_mgmt" "AutoTeardown Tag" 5 5 "pass" "AutoTeardown tag found"
        echo "  ✅ AutoTeardown tag: FOUND" >&2
    else
        add_check "cost_mgmt" "AutoTeardown Tag" 0 5 "fail" "AutoTeardown tag missing"
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
        add_check "security" "Policy Checks" 15 15 "pass" "All lab-specific policies passed"
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
COMMENT_LINES=$(grep -r "^\s*#" *.tf modules/**/*.tf 2>/dev/null | wc -l || echo 0)
if [ "$COMMENT_LINES" -ge 10 ]; then
    DOCUMENTATION=$((DOCUMENTATION + 5))
    add_check "documentation" "Code Comments" 5 5 "pass" "$COMMENT_LINES comment lines found"
    echo "  ✅ Code comments: $COMMENT_LINES lines" >&2
elif [ "$COMMENT_LINES" -ge 5 ]; then
    DOCUMENTATION=$((DOCUMENTATION + 3))
    add_check "documentation" "Code Comments" 3 5 "partial" "$COMMENT_LINES comment lines (need 10+)"
    echo "  ⚠️  Code comments: $COMMENT_LINES lines (need more)" >&2
else
    add_check "documentation" "Code Comments" 0 5 "fail" "Insufficient comments"
    echo "  ❌ Code comments: NOT ENOUGH" >&2
fi

# Check 2: Variable descriptions (5 points)
VAR_DESCRIPTIONS=$(grep -c 'description\s*=' "$MODULE_PATH/variables.tf" 2>/dev/null || echo 0)
TOTAL_VARS=$(grep -c 'variable\s*"' "$MODULE_PATH/variables.tf" 2>/dev/null || echo 1)

if [ "$VAR_DESCRIPTIONS" -ge "$TOTAL_VARS" ]; then
    DOCUMENTATION=$((DOCUMENTATION + 5))
    add_check "documentation" "Variable Descriptions" 5 5 "pass" "All variables have descriptions"
    echo "  ✅ Variable descriptions: PASS" >&2
elif [ "$VAR_DESCRIPTIONS" -ge 2 ]; then
    DOCUMENTATION=$((DOCUMENTATION + 3))
    add_check "documentation" "Variable Descriptions" 3 5 "partial" "$VAR_DESCRIPTIONS/$TOTAL_VARS variables documented"
    echo "  ⚠️  Variable descriptions: PARTIAL ($VAR_DESCRIPTIONS/$TOTAL_VARS)" >&2
else
    add_check "documentation" "Variable Descriptions" 0 5 "fail" "Variables missing descriptions"
    echo "  ❌ Variable descriptions: FAIL" >&2
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

join_array() {
    local IFS=','
    echo "$*"
}

cat <<EOF
{
  "lab": {
    "week": 1,
    "lab": 0,
    "name": "S3 Module + Terraform Testing"
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
    "documentation": [$(join_array "${DOCUMENTATION_CHECKS[@]}")],
  },
  "errors": [$(printf '"%s",' "${ERRORS[@]}" | sed 's/,$//')]$( [ ${#ERRORS[@]} -eq 0 ] && echo "" ),
  "warnings": [$(printf '"%s",' "${WARNINGS[@]}" | sed 's/,$//')]$( [ ${#WARNINGS[@]} -eq 0 ] && echo "" )
}
EOF
