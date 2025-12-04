#!/bin/bash
#
# Lab 01 Validator Script
# Validates WordPress on EC2 deployment with security groups, IMDSv2, and user data
#
# Usage: validate.sh <path-to-plan.json>
#

set -e

PLAN_FILE="${1:-/tmp/plan.json}"
ERRORS=0
POINTS=0
MAX_POINTS=50  # Total points from lab-specific validation (out of 100 total)

echo "================================================"
echo "Lab 01 Validation - WordPress on EC2"
echo "================================================"
echo ""

# Check if plan file exists
if [ ! -f "$PLAN_FILE" ]; then
  echo "❌ ERROR: Plan file not found at $PLAN_FILE"
  exit 1
fi

# Helper function to check for resource in plan
check_resource() {
  local resource_type=$1
  local description=$2
  local points=$3

  COUNT=$(jq "[.planned_values.root_module.resources[]? | select(.type == \"$resource_type\")] | length" "$PLAN_FILE")

  if [ "$COUNT" -gt 0 ]; then
    echo "✅ $description found ($COUNT instance(s))"
    POINTS=$((POINTS + points))
    return 0
  else
    echo "❌ $description NOT found"
    ERRORS=$((ERRORS + 1))
    return 1
  fi
}

# Helper function to check attribute value
check_attribute() {
  local resource_type=$1
  local attribute_path=$2
  local expected_value=$3
  local description=$4
  local points=$5

  VALUE=$(jq -r "[.planned_values.root_module.resources[]? | select(.type == \"$resource_type\") | $attribute_path] | first" "$PLAN_FILE")

  if [ "$VALUE" == "$expected_value" ]; then
    echo "  ✅ $description: $VALUE"
    POINTS=$((POINTS + points))
    return 0
  else
    echo "  ❌ $description: Expected '$expected_value', got '$VALUE'"
    ERRORS=$((ERRORS + 1))
    return 1
  fi
}

# Helper function to check if attribute exists and is not null
check_attribute_exists() {
  local resource_type=$1
  local attribute_path=$2
  local description=$3
  local points=$4

  VALUE=$(jq -r "[.planned_values.root_module.resources[]? | select(.type == \"$resource_type\") | $attribute_path] | first" "$PLAN_FILE")

  if [ "$VALUE" != "null" ] && [ -n "$VALUE" ]; then
    echo "  ✅ $description: configured"
    POINTS=$((POINTS + points))
    return 0
  else
    echo "  ❌ $description is missing or null"
    ERRORS=$((ERRORS + 1))
    return 1
  fi
}

echo "🔍 Checking Lab Requirements..."
echo ""

# ==================== REQUIREMENT 1: AWS Key Pair (5 points) ====================
echo "Requirement 1: AWS Key Pair Resource (5 points)"
if check_resource "aws_key_pair" "AWS Key Pair" 3; then
  # Check key_name is set
  check_attribute_exists "aws_key_pair" ".values.key_name" "Key name" 1
  # Check public_key is set
  check_attribute_exists "aws_key_pair" ".values.public_key" "Public key" 1
fi
echo ""

# ==================== REQUIREMENT 2: Security Group (15 points) ====================
echo "Requirement 2: Security Group with WordPress Rules (15 points)"
if check_resource "aws_security_group" "Security Group" 3; then

  # Check ingress rules exist
  INGRESS_COUNT=$(jq '[.planned_values.root_module.resources[]? | select(.type == "aws_security_group") | .values.ingress[]?] | length' "$PLAN_FILE")

  if [ "$INGRESS_COUNT" -gt 0 ]; then
    echo "  ✅ Ingress rules defined ($INGRESS_COUNT rule(s))"

    # Check for SSH port 22
    SSH_RULE=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_security_group") | .values.ingress[]? | select(.from_port == 22)] | length' "$PLAN_FILE")

    if [ "$SSH_RULE" -gt 0 ]; then
      echo "  ✅ SSH (port 22) ingress rule found"
      POINTS=$((POINTS + 2))

      # Check that SSH is NOT from 0.0.0.0/0 (security requirement)
      SSH_CIDR=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_security_group") | .values.ingress[]? | select(.from_port == 22) | .cidr_blocks[]?] | first' "$PLAN_FILE")

      if [ "$SSH_CIDR" != "0.0.0.0/0" ] && [ "$SSH_CIDR" != "null" ] && [ -n "$SSH_CIDR" ]; then
        echo "  ✅ SSH restricted to specific IP (not 0.0.0.0/0): $SSH_CIDR"
        POINTS=$((POINTS + 2))
      else
        echo "  ❌ SSH should be restricted to specific IP, not 0.0.0.0/0"
        ERRORS=$((ERRORS + 1))
      fi
    else
      echo "  ❌ SSH (port 22) ingress rule not found"
      ERRORS=$((ERRORS + 1))
    fi

    # Check for HTTP port 80
    HTTP_RULE=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_security_group") | .values.ingress[]? | select(.from_port == 80)] | length' "$PLAN_FILE")

    if [ "$HTTP_RULE" -gt 0 ]; then
      echo "  ✅ HTTP (port 80) ingress rule found"
      POINTS=$((POINTS + 2))
    else
      echo "  ❌ HTTP (port 80) ingress rule not found - WordPress needs this!"
      ERRORS=$((ERRORS + 1))
    fi

    # Check for HTTPS port 443
    HTTPS_RULE=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_security_group") | .values.ingress[]? | select(.from_port == 443)] | length' "$PLAN_FILE")

    if [ "$HTTPS_RULE" -gt 0 ]; then
      echo "  ✅ HTTPS (port 443) ingress rule found"
      POINTS=$((POINTS + 1))
    else
      echo "  ⚠️  HTTPS (port 443) ingress rule not found (optional but recommended)"
    fi

  else
    echo "  ❌ No ingress rules defined"
    ERRORS=$((ERRORS + 1))
  fi

  # CRITICAL: Check egress rules exist (Terraform doesn't add default egress!)
  EGRESS_COUNT=$(jq '[.planned_values.root_module.resources[]? | select(.type == "aws_security_group") | .values.egress[]?] | length' "$PLAN_FILE")

  if [ "$EGRESS_COUNT" -gt 0 ]; then
    echo "  ✅ Egress rules defined - CRITICAL for WordPress installation!"
    POINTS=$((POINTS + 3))
  else
    echo "  ❌ NO EGRESS RULES DEFINED!"
    echo "     Terraform does NOT add default egress rules (unlike AWS Console)."
    echo "     Without egress, the instance cannot download packages or WordPress."
    ERRORS=$((ERRORS + 1))
  fi
fi
echo ""

# ==================== REQUIREMENT 3: EC2 Instance (10 points) ====================
echo "Requirement 3: EC2 Instance Resource (10 points)"
if check_resource "aws_instance" "EC2 Instance" 3; then

  # Check instance_type is cost-effective
  INSTANCE_TYPE=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.instance_type] | first' "$PLAN_FILE")

  if [[ "$INSTANCE_TYPE" =~ ^t[2-4]\.(micro|small) ]] || [[ "$INSTANCE_TYPE" =~ ^t[2-4]a\.(micro|small) ]]; then
    echo "  ✅ Instance type is cost-effective: $INSTANCE_TYPE"
    POINTS=$((POINTS + 2))
  else
    echo "  ⚠️  Instance type: $INSTANCE_TYPE (may not be cost-effective)"
    POINTS=$((POINTS + 1))
  fi

  # Check key_name references key pair
  check_attribute_exists "aws_instance" ".values.key_name" "Key pair referenced" 2

  # Check security group is referenced
  SG_COUNT=$(jq '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.vpc_security_group_ids[]?] | length' "$PLAN_FILE")

  if [ "$SG_COUNT" -gt 0 ]; then
    echo "  ✅ Security group(s) attached: $SG_COUNT"
    POINTS=$((POINTS + 2))
  else
    echo "  ❌ No security groups attached"
    ERRORS=$((ERRORS + 1))
  fi

  # Check user_data is set
  USER_DATA=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.user_data] | first' "$PLAN_FILE")

  if [ "$USER_DATA" != "null" ] && [ -n "$USER_DATA" ]; then
    echo "  ✅ User data script configured"
    POINTS=$((POINTS + 1))
  else
    echo "  ❌ User data not configured - WordPress won't install automatically"
    ERRORS=$((ERRORS + 1))
  fi
fi
echo ""

# ==================== REQUIREMENT 4: IMDSv2 Configuration (10 points) ====================
echo "Requirement 4: IMDSv2 Configuration (10 points)"

# Check if metadata_options block exists
METADATA_OPTIONS=$(jq '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[]?] | length' "$PLAN_FILE")

if [ "$METADATA_OPTIONS" -gt 0 ]; then
  echo "  ✅ metadata_options block defined"
  POINTS=$((POINTS + 1))

  # CRITICAL: Check http_tokens is "required" (IMDSv2 enforcement)
  HTTP_TOKENS=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[0].http_tokens] | first' "$PLAN_FILE")

  if [ "$HTTP_TOKENS" == "required" ]; then
    echo "  ✅ http_tokens = \"required\" (IMDSv2 enforced)"
    POINTS=$((POINTS + 4))
  else
    echo "  ❌ http_tokens should be 'required', got: $HTTP_TOKENS"
    ERRORS=$((ERRORS + 1))
  fi

  # Check http_endpoint is enabled
  HTTP_ENDPOINT=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[0].http_endpoint] | first' "$PLAN_FILE")

  if [ "$HTTP_ENDPOINT" == "enabled" ]; then
    echo "  ✅ http_endpoint = \"enabled\""
    POINTS=$((POINTS + 2))
  else
    echo "  ⚠️  http_endpoint: $HTTP_ENDPOINT"
  fi

  # Check http_put_response_hop_limit
  HOP_LIMIT=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[0].http_put_response_hop_limit] | first' "$PLAN_FILE")

  if [ "$HOP_LIMIT" == "1" ]; then
    echo "  ✅ http_put_response_hop_limit = 1"
    POINTS=$((POINTS + 2))
  else
    echo "  ⚠️  http_put_response_hop_limit: $HOP_LIMIT (recommended: 1)"
    POINTS=$((POINTS + 1))
  fi

  # Check instance_metadata_tags
  METADATA_TAGS=$(jq -r '[.planned_values.root_module.resources[]? | select(.type == "aws_instance") | .values.metadata_options[0].instance_metadata_tags] | first' "$PLAN_FILE")

  if [ "$METADATA_TAGS" == "enabled" ]; then
    echo "  ✅ instance_metadata_tags = \"enabled\""
    POINTS=$((POINTS + 1))
  else
    echo "  ⚠️  instance_metadata_tags: $METADATA_TAGS"
  fi

else
  echo "  ❌ metadata_options block NOT found - IMDSv2 not configured!"
  echo "  ℹ️  Expected: metadata_options { http_tokens = \"required\" ... }"
  ERRORS=$((ERRORS + 1))
fi
echo ""

# ==================== REQUIREMENT 5: Data Source for AMI (5 points) ====================
echo "Requirement 5: Data Source for Amazon Linux 2023 AMI (5 points)"

# Check if data source exists in configuration
DATA_AMI=$(jq -r '.configuration.root_module.data[]? | select(.type == "aws_ami") | .type' "$PLAN_FILE")

if [ "$DATA_AMI" == "aws_ami" ]; then
  echo "  ✅ Data source 'aws_ami' found"
  POINTS=$((POINTS + 3))

  # Check most_recent is true
  MOST_RECENT=$(jq -r '[.configuration.root_module.data[]? | select(.type == "aws_ami") | .expressions.most_recent.constant_value] | first' "$PLAN_FILE")

  if [ "$MOST_RECENT" == "true" ]; then
    echo "  ✅ most_recent = true"
    POINTS=$((POINTS + 2))
  else
    echo "  ⚠️  most_recent: $MOST_RECENT (recommended: true)"
    POINTS=$((POINTS + 1))
  fi
else
  echo "  ❌ Data source 'aws_ami' NOT found"
  echo "  ℹ️  Expected: data \"aws_ami\" { ... }"
  echo "  ℹ️  Hardcoding AMI IDs is not recommended"
  ERRORS=$((ERRORS + 1))
fi
echo ""

# ==================== REQUIREMENT 6: Required Tags (5 points) ====================
echo "Requirement 6: Required Tags on Resources (5 points)"

REQUIRED_TAGS=("Name" "Environment" "ManagedBy" "Student" "AutoTeardown")
TAG_POINTS=0
TOTAL_TAG_CHECKS=0

# Check tags on all taggable resources
for RESOURCE_TYPE in "aws_instance" "aws_security_group" "aws_key_pair"; do
  RESOURCE_EXISTS=$(jq "[.planned_values.root_module.resources[]? | select(.type == \"$RESOURCE_TYPE\")] | length" "$PLAN_FILE")

  if [ "$RESOURCE_EXISTS" -gt 0 ]; then
    for TAG in "${REQUIRED_TAGS[@]}"; do
      TAG_VALUE=$(jq -r "[.planned_values.root_module.resources[]? | select(.type == \"$RESOURCE_TYPE\") | .values.tags.\"$TAG\"] | first" "$PLAN_FILE")

      if [ "$TAG_VALUE" != "null" ] && [ -n "$TAG_VALUE" ]; then
        TAG_POINTS=$((TAG_POINTS + 1))
      fi
      TOTAL_TAG_CHECKS=$((TOTAL_TAG_CHECKS + 1))
    done
  fi
done

# Award points based on percentage of tags found
if [ $TOTAL_TAG_CHECKS -gt 0 ]; then
  TAG_PERCENTAGE=$((TAG_POINTS * 100 / TOTAL_TAG_CHECKS))

  if [ $TAG_PERCENTAGE -ge 80 ]; then
    POINTS=$((POINTS + 5))
    echo "  ✅ Most required tags present ($TAG_POINTS/$TOTAL_TAG_CHECKS)"
  elif [ $TAG_PERCENTAGE -ge 60 ]; then
    POINTS=$((POINTS + 3))
    echo "  ⚠️  Some tags missing ($TAG_POINTS/$TOTAL_TAG_CHECKS)"
  else
    POINTS=$((POINTS + 1))
    echo "  ❌ Many tags missing ($TAG_POINTS/$TOTAL_TAG_CHECKS)"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  ❌ No taggable resources found"
  ERRORS=$((ERRORS + 1))
fi
echo ""

# ==================== SUMMARY ====================
echo "================================================"
echo "Validation Summary"
echo "================================================"
echo "Errors found: $ERRORS"
echo "Points earned: $POINTS/$MAX_POINTS"
echo ""

# Calculate percentage
PERCENTAGE=$((POINTS * 100 / MAX_POINTS))

if [ $ERRORS -eq 0 ]; then
  echo "✅ ALL CHECKS PASSED! Excellent work!"
  echo ""
  exit 0
elif [ $PERCENTAGE -ge 70 ]; then
  echo "⚠️  MOSTLY PASSED - Minor issues found ($PERCENTAGE%)"
  echo ""
  exit 0
else
  echo "❌ VALIDATION FAILED - Please fix the errors above ($PERCENTAGE%)"
  echo ""
  echo "💡 Key Requirements:"
  echo "  - Security group MUST have egress rule (Terraform doesn't add default)"
  echo "  - IMDSv2 must be REQUIRED (http_tokens = \"required\")"
  echo "  - SSH must be restricted to specific IP (not 0.0.0.0/0)"
  echo "  - HTTP (port 80) must be open for WordPress"
  echo "  - Use data source for AMI (not hardcoded)"
  echo ""
  exit 1
fi
