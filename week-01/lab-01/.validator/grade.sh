#!/bin/bash
#
# Lab 01 (Week 01) Grading Script
# Static Blog with Hugo and CloudFront
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
echo "Lab 01 (Week 01) Grading - Static Blog" >&2
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
if [ -d "../../../modules/s3-bucket" ] && [ -f "../../../modules/s3-bucket/main.tf" ]; then
    CODE_QUALITY=$((CODE_QUALITY + 5))
    add_check "code_quality" "Module Structure" 5 5 "pass" "S3 module exists at project root"
    echo "  ✅ Module structure: PASS" >&2
else
    add_check "code_quality" "Module Structure" 0 5 "fail" "S3 module not found at project root (../../../modules/s3-bucket)"
    ERRORS+=("Module structure missing at project root")
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

if [ -f "$PLAN_FILE" ]; then
    # Check 1: S3 bucket with website hosting (8 points)
    S3_BUCKET=$(jq '[.planned_values.root_module.child_modules[]?.resources[]? | select(.type == "aws_s3_bucket")] | length' "$PLAN_FILE" 2>/dev/null || echo "0")
    S3_WEBSITE=$(jq '[.planned_values.root_module.child_modules[]?.resources[]? | select(.type == "aws_s3_bucket_website_configuration")] | length' "$PLAN_FILE" 2>/dev/null || echo "0")

    if [ "$S3_BUCKET" -gt 0 ] && [ "$S3_WEBSITE" -gt 0 ]; then
        FUNCTIONALITY=$((FUNCTIONALITY + 8))
        add_check "functionality" "S3 Website Hosting" 8 8 "pass" "S3 bucket with website hosting configured"
        echo "  ✅ S3 website hosting: PASS" >&2
    elif [ "$S3_BUCKET" -gt 0 ]; then
        FUNCTIONALITY=$((FUNCTIONALITY + 4))
        add_check "functionality" "S3 Website Hosting" 4 8 "partial" "S3 bucket exists but website hosting not configured"
        echo "  ⚠️  S3 website hosting: PARTIAL" >&2
    else
        add_check "functionality" "S3 Website Hosting" 0 8 "fail" "S3 bucket not found"
        ERRORS+=("S3 bucket not configured")
        echo "  ❌ S3 website hosting: FAIL" >&2
    fi

    # Check 2: CloudFront distribution (10 points)
    CF_DIST=$(jq '[.planned_values.root_module.resources[]? | select(.type == "aws_cloudfront_distribution")] | length' "$PLAN_FILE" 2>/dev/null || echo "0")

    if [ "$CF_DIST" -gt 0 ]; then
        FUNCTIONALITY=$((FUNCTIONALITY + 10))
        add_check "functionality" "CloudFront Distribution" 10 10 "pass" "CloudFront distribution configured"
        echo "  ✅ CloudFront distribution: PASS" >&2
    else
        add_check "functionality" "CloudFront Distribution" 0 10 "fail" "CloudFront distribution not found"
        ERRORS+=("CloudFront not configured")
        echo "  ❌ CloudFront distribution: FAIL" >&2
    fi

    # Check 3: Origin Access Control (5 points)
    OAC=$(jq '[.planned_values.root_module.resources[]? | select(.type == "aws_cloudfront_origin_access_control")] | length' "$PLAN_FILE" 2>/dev/null || echo "0")

    if [ "$OAC" -gt 0 ]; then
        FUNCTIONALITY=$((FUNCTIONALITY + 5))
        add_check "functionality" "Origin Access Control" 5 5 "pass" "OAC configured for secure S3 access"
        echo "  ✅ Origin Access Control: PASS" >&2
    else
        add_check "functionality" "Origin Access Control" 0 5 "fail" "OAC not configured"
        WARNINGS+=("Consider using OAC for secure S3 access")
        echo "  ❌ Origin Access Control: FAIL" >&2
    fi

    # Check 4: S3 Bucket Policy (5 points)
    BUCKET_POLICY=$(jq '[.planned_values.root_module.resources[]? | select(.type == "aws_s3_bucket_policy")] | length' "$PLAN_FILE" 2>/dev/null || echo "0")

    if [ "$BUCKET_POLICY" -gt 0 ]; then
        FUNCTIONALITY=$((FUNCTIONALITY + 5))
        add_check "functionality" "S3 Bucket Policy" 5 5 "pass" "Bucket policy configured"
        echo "  ✅ S3 Bucket Policy: PASS" >&2
    else
        add_check "functionality" "S3 Bucket Policy" 0 5 "fail" "Bucket policy not found"
        echo "  ❌ S3 Bucket Policy: FAIL" >&2
    fi

    # Check 5: Outputs defined (2 points)
    if [ -f "outputs.tf" ] && grep -q 'output.*"cloudfront' outputs.tf 2>/dev/null; then
        FUNCTIONALITY=$((FUNCTIONALITY + 2))
        add_check "functionality" "CloudFront Outputs" 2 2 "pass" "CloudFront outputs defined"
        echo "  ✅ CloudFront outputs: PASS" >&2
    else
        add_check "functionality" "CloudFront Outputs" 0 2 "fail" "CloudFront outputs not defined"
        echo "  ❌ CloudFront outputs: FAIL" >&2
    fi
else
    add_check "functionality" "Terraform Plan" 0 30 "fail" "Plan file not found"
    ERRORS+=("Terraform plan failed")
    echo "  ❌ Plan file not found" >&2
fi

# Check 6: Hugo site exists (bonus check, no points deducted if missing)
if [ -d "blog" ] && [ -f "blog/hugo.toml" ]; then
    echo "  ✅ Hugo site: FOUND" >&2
else
    WARNINGS+=("Hugo site not found in blog/ directory")
    echo "  ⚠️  Hugo site: NOT FOUND (optional)" >&2
fi

echo "" >&2

# ==================== COST MANAGEMENT (20 points) ====================
echo "📋 Checking Cost Management..." >&2

# Check 1: Infracost analysis (5 points)
if [ -f "$INFRACOST_FILE" ]; then
    COST_MGMT=$((COST_MGMT + 5))
    add_check "cost_mgmt" "Infracost Analysis" 5 5 "pass" "Cost analysis completed"
    echo "  ✅ Infracost analysis: PASS" >&2

    # Check 2: Within budget (10 points) - $10 limit for CloudFront setup
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
    HAS_TEARDOWN=$(jq -r '[.planned_values.root_module.resources[]? | select(.values.tags.AutoTeardown != null)] | length' "$PLAN_FILE" 2>/dev/null || echo "0")
    HAS_TEARDOWN_MODULE=$(jq -r '[.planned_values.root_module.child_modules[]?.resources[]? | select(.values.tags.AutoTeardown != null)] | length' "$PLAN_FILE" 2>/dev/null || echo "0")
    TOTAL_TEARDOWN=$((HAS_TEARDOWN + HAS_TEARDOWN_MODULE))

    if [ "$TOTAL_TEARDOWN" -gt 0 ]; then
        COST_MGMT=$((COST_MGMT + 5))
        add_check "cost_mgmt" "AutoTeardown Tag" 5 5 "pass" "AutoTeardown tag found on $TOTAL_TEARDOWN resource(s)"
        echo "  ✅ AutoTeardown tag: FOUND" >&2
    else
        add_check "cost_mgmt" "AutoTeardown Tag" 0 5 "fail" "AutoTeardown tag missing"
        WARNINGS+=("AutoTeardown tag missing")
        echo "  ❌ AutoTeardown tag: NOT FOUND" >&2
    fi
fi

echo "" >&2

# ==================== SECURITY (15 points) ====================
echo "📋 Checking Security..." >&2

# Check CloudFront uses HTTPS redirect
if [ -f "$PLAN_FILE" ]; then
    HTTPS_REDIRECT=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_cloudfront_distribution") | .values.default_cache_behavior[0].viewer_protocol_policy] | first' "$PLAN_FILE" 2>/dev/null || echo "")

    if [ "$HTTPS_REDIRECT" == "redirect-to-https" ] || [ "$HTTPS_REDIRECT" == "https-only" ]; then
        SECURITY=$((SECURITY + 5))
        add_check "security" "HTTPS Redirect" 5 5 "pass" "CloudFront redirects to HTTPS"
        echo "  ✅ HTTPS redirect: PASS" >&2
    elif [ -n "$HTTPS_REDIRECT" ]; then
        add_check "security" "HTTPS Redirect" 0 5 "fail" "CloudFront should redirect to HTTPS"
        echo "  ❌ HTTPS redirect: FAIL" >&2
    fi
fi

# Policy checks (conftest/Rego)
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
        SECURITY=$((SECURITY + 10))
        add_check "security" "Policy Checks" 10 10 "pass" "All lab-specific policies passed"
        echo "  ✅ Policy checks: PASS (10/10)" >&2
    elif [ "$FAILED_CHECKS" -le 2 ]; then
        SECURITY=$((SECURITY + 7))
        add_check "security" "Policy Checks" 7 10 "partial" "$FAILED_CHECKS policy issues"
        echo "  ⚠️  Policy checks: PARTIAL (7/10)" >&2
    elif [ "$FAILED_CHECKS" -le 4 ]; then
        SECURITY=$((SECURITY + 4))
        add_check "security" "Policy Checks" 4 10 "partial" "$FAILED_CHECKS policy issues"
        echo "  ⚠️  Policy checks: PARTIAL (4/10)" >&2
    else
        add_check "security" "Policy Checks" 0 10 "fail" "$FAILED_CHECKS policy issues found"
        ERRORS+=("Multiple policy failures detected")
        echo "  ❌ Policy checks: FAIL (0/10)" >&2
    fi
else
    add_check "security" "Policy Checks" 0 10 "skip" "Policy checks not available"
    echo "  ⚠️  Policy results not available" >&2
fi

echo "" >&2

# ==================== DOCUMENTATION (10 points) ====================
echo "📋 Checking Documentation..." >&2

# Check 1: Code comments (5 points)
COMMENT_LINES=$(grep -r "^\s*#" *.tf 2>/dev/null | wc -l || echo 0)
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

# Check 2: Hugo content exists (5 points)
if [ -d "blog/content/posts" ] && ls blog/content/posts/*.md >/dev/null 2>&1; then
    POST_COUNT=$(ls blog/content/posts/*.md 2>/dev/null | wc -l)
    DOCUMENTATION=$((DOCUMENTATION + 5))
    add_check "documentation" "Blog Content" 5 5 "pass" "$POST_COUNT blog post(s) found"
    echo "  ✅ Blog content: $POST_COUNT post(s)" >&2
else
    add_check "documentation" "Blog Content" 0 5 "fail" "No blog posts found in blog/content/posts/"
    echo "  ❌ Blog content: NOT FOUND" >&2
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
    "lab": 1,
    "name": "Static Blog with Hugo and CloudFront"
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
