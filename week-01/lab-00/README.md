# Week 01 - Lab 00: Terraform Modules and Testing

## Overview

In this lab, you'll take the S3 bucket code you wrote in Week 00 and refactor it into a **reusable Terraform module**. You'll then write **Terraform native tests** to validate your module works correctly.

## Learning Objectives

By the end of this lab, you will be able to:

- Understand the DRY (Don't Repeat Yourself) principle in Infrastructure as Code
- Create a reusable Terraform module with proper structure
- Define module inputs (variables) and outputs
- Write Terraform native tests using `.tftest.hcl` files
- Run tests with `terraform test`
- Understand the difference between unit tests and integration tests

## Prerequisites

- Completed Week 00 labs
- Terraform >= 1.9.0 (includes native testing support)
- AWS credentials configured
- GitHub Codespace or local development environment

## Background: Why Modules?

In Week 00, you created an S3 bucket with versioning and encryption. What if you need to create 10 more buckets with the same configuration? Copy-paste leads to:

- **Maintenance nightmare**: Change one thing, update 10 files
- **Inconsistency**: Each copy might drift slightly
- **Bugs**: Easy to miss updates in some copies

**Modules solve this** by packaging your Terraform code into a reusable unit:

```hcl
# Instead of copying 50 lines of S3 configuration...
module "logs_bucket" {
  source      = "../../../modules/s3-bucket"  # Path to shared module
  bucket_name = "my-app-logs"
  environment = "prod"
}

module "assets_bucket" {
  source      = "../../../modules/s3-bucket"
  bucket_name = "my-app-assets"
  environment = "prod"
}
```

> **In this course:** All modules live in the project root at `terraform-course/modules/`. From your lab's `student-work/` directory, you'll reference them with `../../../modules/module-name`.

---

## Terraform Module Structure Deep Dive

### What is a Module?

A Terraform module is simply a directory containing `.tf` files. Every Terraform configuration is technically a module:

- **Root Module**: The directory where you run `terraform apply`
- **Child Module**: A module called by another module using a `module` block

### Standard Module File Structure

Terraform expects modules to follow this convention:

```
modules/
└── s3-bucket/
    ├── main.tf          # Primary resources
    ├── variables.tf     # Input variables
    ├── outputs.tf       # Output values
    ├── versions.tf      # Provider/Terraform version constraints (optional)
    ├── locals.tf        # Local values (optional)
    └── README.md        # Documentation (optional but recommended)
```

### Required Files

#### `variables.tf` - Module Inputs

Define what users can pass INTO your module:

```hcl
# variables.tf

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters"
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true  # Optional variables need defaults
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}
```

**Key Points:**
- Always include `description` - it shows up in docs and `terraform plan`
- Always specify `type` - catches errors early
- Use `validation` blocks for input validation
- Optional variables must have a `default`

#### `main.tf` - Resources

Define the actual infrastructure:

```hcl
# main.tf

# Use locals to compute values used in multiple places
locals {
  default_tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "s3-bucket"
  }

  # Merge default tags with user-provided tags
  all_tags = merge(local.default_tags, var.tags)
}

# The S3 bucket resource
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = local.all_tags
}

# Versioning configuration
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

**Key Points:**
- Use `this` as the resource name when there's only one of that type
- Use `locals` to avoid repeating calculations
- Reference variables with `var.variable_name`
- Reference other resources with `resource_type.resource_name.attribute`

#### `outputs.tf` - Module Outputs

Define what information your module exposes to callers:

```hcl
# outputs.tf

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_region" {
  description = "The region of the bucket"
  value       = aws_s3_bucket.this.region
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.this.bucket_domain_name
}
```

**Key Points:**
- Always include `description`
- Output useful values that callers might need
- Outputs are accessed as `module.module_name.output_name`

### Using a Module

From your working directory, call your module:

```hcl
# week-01/lab-00/student-work/main.tf

module "my_bucket" {
  source = "../../../modules/s3-bucket"  # Path to project root modules

  # Required variables (no defaults)
  bucket_name = "my-app-data"
  environment = "dev"

  # Optional variables (have defaults)
  enable_versioning = true

  tags = {
    Team    = "platform"
    Project = "my-app"
  }
}

# Access module outputs
output "bucket_arn" {
  value = module.my_bucket.bucket_arn
}
```

### Module Sources

Modules can come from various sources:

```hcl
# Local path
module "local" {
  source = "./modules/s3-bucket"
}

# GitHub
module "github" {
  source = "github.com/org/repo//modules/s3-bucket"
}

# Terraform Registry
module "registry" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.0.0"
}

# S3 bucket
module "s3" {
  source = "s3::https://s3-eu-west-1.amazonaws.com/bucket/module.zip"
}
```

### Variable Types Reference

```hcl
# String
variable "name" {
  type = string
}

# Number
variable "count" {
  type = number
}

# Boolean
variable "enabled" {
  type = bool
}

# List of strings
variable "availability_zones" {
  type = list(string)
}

# Map of strings
variable "tags" {
  type = map(string)
}

# Object with specific structure
variable "config" {
  type = object({
    name    = string
    enabled = bool
    count   = number
  })
}

# Any type (avoid if possible)
variable "flexible" {
  type = any
}
```

### Best Practices

1. **Keep modules focused** - One module = one logical component

2. **Use consistent naming** - `variables.tf`, `outputs.tf`, `main.tf`

3. **Document everything** - Descriptions on all variables and outputs

4. **Validate inputs** - Use `validation` blocks to catch errors early

5. **Use `locals` for computed values** - Don't repeat calculations

6. **Version your modules** - Use git tags or registry versions

7. **Don't hardcode values** - Everything configurable should be a variable

8. **Output useful values** - Think about what callers will need

---

## Step-by-Step Walkthrough: Building the S3 Module

This section walks you through building the S3 bucket module from scratch, file by file, block by block.

### Step 1: Set Up Your Project Structure

**Important:** All modules in this course live in the **project root's `modules/` directory**, not inside each lab. This mirrors real-world projects where modules are shared across multiple configurations.

```bash
# From the terraform-course root directory
cd /workspaces/terraform-course  # or wherever your project root is

# Create the s3-bucket module directory (modules/ already exists)
mkdir -p modules/s3-bucket

# Verify the structure
ls modules/
```

You should see:
```
modules/
├── compute/      # (for future weeks)
├── database/     # (for future weeks)
├── s3-bucket/    # NEW - you'll build this!
└── vpc/          # (for future weeks)
```

Now set up your lab working directory:

```bash
# Navigate to your student-work directory
cd week-01/lab-00/student-work

# Create the test directory
mkdir -p tests

# Verify your structure
tree .
```

Your student-work directory should have:
```
student-work/
├── main.tf           # (from starter - we'll update this)
├── variables.tf      # (from starter)
├── outputs.tf        # (from starter)
├── providers.tf      # (from starter)
└── tests/            # Empty - we'll add tests later
```

> **Why modules at the project root?** In real projects, modules are reusable across multiple environments and configurations. By placing modules at `terraform-course/modules/`, you can use the same `s3-bucket` module in Lab 00, Lab 01, and beyond without copying code. This is the DRY principle in action!

---

### Step 2: Create the Module Variables (`variables.tf`)

Let's build the module's `variables.tf` step by step. We'll add one variable at a time.

#### 2.1: Start with the required `bucket_name` variable

Create the file at `terraform-course/modules/s3-bucket/variables.tf` and add:

```hcl
# modules/s3-bucket/variables.tf

variable "bucket_name" {
  description = "Base name for the S3 bucket"
  type        = string
}
```

This is the simplest valid variable - a required string with a description.

#### 2.2: Add validation to `bucket_name`

S3 bucket names must be 3-63 characters. Let's enforce that:

```hcl
# modules/s3-bucket/variables.tf

variable "bucket_name" {
  description = "Base name for the S3 bucket"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }
}
```

> **Why validate?** Validation catches errors at `terraform plan` time, not when AWS rejects your request. Better to fail fast with a clear message!

#### 2.3: Add the `environment` variable

```hcl
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

#### 2.4: Add the optional `enable_versioning` variable

This shows how to make a variable optional with a default value:

```hcl
variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true  # Optional - has a default
}
```

> **Required vs Optional:** If a variable has no `default`, it's required. If it has a `default`, it's optional.

#### 2.5: Add the optional `tags` variable

```hcl
variable "tags" {
  description = "Additional tags to apply to the bucket"
  type        = map(string)
  default     = {}  # Empty map - users can optionally add tags
}
```

#### Complete `variables.tf`

Your final `modules/s3-bucket/variables.tf` should look like this:

```hcl
# modules/s3-bucket/variables.tf
# Input variables for the S3 bucket module

variable "bucket_name" {
  description = "Base name for the S3 bucket"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
```

---

### Step 3: Create the Module Resources (`main.tf`)

Now let's build `modules/s3-bucket/main.tf`. This is where the actual AWS resources are defined.

#### 3.1: Start with locals for tag management

Before creating resources, set up a `locals` block to handle tag merging:

```hcl
# modules/s3-bucket/main.tf

locals {
  # Default tags that every bucket should have
  default_tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "s3-bucket"
  }

  # Merge default tags with any user-provided tags
  # User tags override defaults if there's a conflict
  all_tags = merge(local.default_tags, var.tags)
}
```

> **Why use locals?** We calculate `all_tags` once and use it everywhere. If we need to add more default tags later, we change one place, not every resource.

#### 3.2: Add the S3 bucket resource

```hcl
# The main S3 bucket
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = local.all_tags
}
```

> **Why name it "this"?** When a module has only one resource of a type, `this` is a common convention. It keeps references short: `aws_s3_bucket.this` instead of `aws_s3_bucket.my_bucket`.

#### 3.3: Add versioning configuration

```hcl
# Versioning configuration
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}
```

Notice two things:
1. `bucket = aws_s3_bucket.this.id` - References our bucket resource
2. `var.enable_versioning ? "Enabled" : "Suspended"` - Ternary expression based on variable

#### 3.4: Add server-side encryption

```hcl
# Server-side encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

#### Complete `main.tf`

Your final `modules/s3-bucket/main.tf`:

```hcl
# modules/s3-bucket/main.tf
# S3 bucket with versioning and encryption

locals {
  default_tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "s3-bucket"
  }

  all_tags = merge(local.default_tags, var.tags)
}

# The main S3 bucket
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = local.all_tags
}

# Versioning configuration
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Server-side encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

---

### Step 4: Create the Module Outputs (`outputs.tf`)

Outputs expose values from your module so the caller can use them.

Create `modules/s3-bucket/outputs.tf`:

#### 4.1: Output the bucket ID

```hcl
# modules/s3-bucket/outputs.tf

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}
```

#### 4.2: Output the bucket ARN

```hcl
output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}
```

> **What's an ARN?** Amazon Resource Name - a unique identifier for AWS resources. You'll need this for IAM policies and other AWS integrations.

#### 4.3: Output the bucket region

```hcl
output "bucket_region" {
  description = "The AWS region of the bucket"
  value       = aws_s3_bucket.this.region
}
```

#### Complete `outputs.tf`

```hcl
# modules/s3-bucket/outputs.tf
# Values exposed by this module

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_region" {
  description = "The AWS region of the bucket"
  value       = aws_s3_bucket.this.region
}
```

---

### Step 5: Use Your Module (Root `main.tf`)

Now let's use the module you just created! Update your `student-work/main.tf`:

```hcl
# week-01/lab-00/student-work/main.tf
# Root module - uses the S3 bucket module from project root

module "lab_bucket" {
  source = "../../../modules/s3-bucket"  # Path to shared module at project root

  # Required variables
  bucket_name = "${var.student_name}-week01-lab00"
  environment = var.environment

  # Optional variables (showing explicit values, could omit for defaults)
  enable_versioning = true

  # Additional tags
  tags = {
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}
```

Let's break this down:
- `source = "../../../modules/s3-bucket"` - Relative path from `student-work/` up to project root, then into `modules/s3-bucket/`
- `bucket_name` - Uses string interpolation to include your name
- `environment` - Passes through from root variable
- `enable_versioning` - Explicitly set (could omit since `true` is the default)
- `tags` - Additional tags merged with module defaults

> **Understanding the path:** From `week-01/lab-00/student-work/`, we go up three levels (`../../../`) to reach the project root, then down into `modules/s3-bucket/`.

---

### Step 6: Wire Up Root Outputs (`outputs.tf`)

Update your root `student-work/outputs.tf` to expose the module outputs:

```hcl
# student-work/outputs.tf
# Root outputs - expose module values

output "bucket_id" {
  description = "The name of the created bucket"
  value       = module.lab_bucket.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the created bucket"
  value       = module.lab_bucket.bucket_arn
}

output "bucket_region" {
  description = "The region of the created bucket"
  value       = module.lab_bucket.bucket_region
}
```

Notice the syntax: `module.lab_bucket.bucket_id` - that's `module.<module_name>.<output_name>`.

---

### Step 7: Verify Your Module Works

Let's test that everything is wired up correctly:

```bash
# Initialize Terraform (downloads providers, discovers modules)
terraform init

# Validate the configuration syntax
terraform validate

# See what Terraform would create
terraform plan -var="student_name=yourname"
```

You should see Terraform planning to create:
- 1 `aws_s3_bucket`
- 1 `aws_s3_bucket_versioning`
- 1 `aws_s3_bucket_server_side_encryption_configuration`

**Congratulations!** You've built a reusable Terraform module. The same module can now be used multiple times - in this lab, in Lab 01, and beyond:

```hcl
# Example: Create multiple buckets with one module
module "logs_bucket" {
  source      = "../../../modules/s3-bucket"
  bucket_name = "myapp-logs"
  environment = "prod"
}

module "assets_bucket" {
  source      = "../../../modules/s3-bucket"
  bucket_name = "myapp-assets"
  environment = "prod"
}

module "backups_bucket" {
  source      = "../../../modules/s3-bucket"
  bucket_name = "myapp-backups"
  environment = "prod"
}
```

Three buckets, all with consistent versioning, encryption, and tagging - from one shared module!

> **Reusability in action:** In Lab 01, you'll use this same module (with some enhancements) to deploy a Hugo blog. No copying required - just reference `../../../modules/s3-bucket` from the Lab 01 student-work directory.

---

## Background: Why Testing?

You wouldn't deploy application code without tests. Why deploy infrastructure without them?

Terraform 1.6+ includes **native testing** with `.tftest.hcl` files:

```hcl
# tests/s3_bucket.tftest.hcl
run "bucket_creates_successfully" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket != ""
    error_message = "Bucket name should not be empty"
  }
}
```

---

## Terraform Testing Deep Dive

### Test File Structure

Test files use HCL syntax and live in a `tests/` directory:

```
your-project/
├── main.tf
├── variables.tf
├── outputs.tf
└── tests/
    ├── basic.tftest.hcl
    └── validation.tftest.hcl
```

### Anatomy of a Test File

```hcl
# tests/example.tftest.hcl

# Optional: Override variables for all tests in this file
variables {
  bucket_name = "test-bucket"
  environment = "test"
}

# A test run block - each "run" is one test case
run "descriptive_test_name" {
  # Command: plan (default) or apply
  command = plan

  # One or more assertions
  assert {
    condition     = <boolean expression>
    error_message = "Message shown if condition is false"
  }
}
```

### The `run` Block

Each `run` block is a single test case:

```hcl
run "test_name" {
  command = plan  # or "apply"

  # Optional: override variables for this specific test
  variables {
    enable_versioning = false
  }

  # Required: at least one assertion
  assert {
    condition     = true
    error_message = "This will never fail"
  }
}
```

#### Command Options

| Command | What it does | Use when |
|---------|--------------|----------|
| `plan` | Runs `terraform plan` only | Testing configuration logic, no resources created |
| `apply` | Runs `terraform apply` | Integration tests, verifying real resources |

**Recommendation:** Start with `plan` for fast, safe tests. Use `apply` only when you need to verify actual AWS behavior.

### The `assert` Block

Assertions are the heart of Terraform tests. Each assertion has:

1. **`condition`** - A boolean expression that must be `true` for the test to pass
2. **`error_message`** - Displayed when the condition is `false`

```hcl
assert {
  condition     = aws_s3_bucket.this.bucket != ""
  error_message = "Bucket name should not be empty"
}
```

You can have **multiple assertions** in a single `run` block:

```hcl
run "bucket_is_configured_correctly" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket != ""
    error_message = "Bucket name should not be empty"
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Environment"] == "dev"
    error_message = "Environment tag should be 'dev'"
  }
}
```

### Writing Conditions

#### Accessing Resource Attributes

Reference resources directly by their type and name:

```hcl
# Direct attribute access
condition = aws_s3_bucket.this.bucket == "expected-name"

# Nested attributes (use index for lists)
condition = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"

# Accessing tags
condition = aws_s3_bucket.this.tags["Environment"] == "dev"
```

#### Accessing Module Outputs

When testing a root module that uses child modules:

```hcl
run "test_module_outputs" {
  command = plan

  assert {
    condition     = module.my_bucket.bucket_arn != ""
    error_message = "Module should output bucket ARN"
  }
}
```

### Common Condition Patterns

#### Check if a value equals something
```hcl
condition = aws_s3_bucket.this.bucket == "my-bucket"
```

#### Check if a value is not empty
```hcl
condition = aws_s3_bucket.this.bucket != ""
condition = length(aws_s3_bucket.this.bucket) > 0
```

#### Check if a string contains a substring
```hcl
# Using strcontains (Terraform 1.5+)
condition = strcontains(aws_s3_bucket.this.bucket, "prod")

# Using regex with can()
condition = can(regex("prod", aws_s3_bucket.this.bucket))
```

#### Check if a string starts or ends with something
```hcl
condition = startswith(aws_s3_bucket.this.bucket, "company-")
condition = endswith(aws_s3_bucket.this.bucket, "-bucket")
```

#### Check if a key exists in a map (like tags)
```hcl
condition = contains(keys(aws_s3_bucket.this.tags), "Environment")
```

#### Check if a value is in a list
```hcl
condition = contains(["dev", "staging", "prod"], var.environment)
```

#### Check list/array length
```hcl
condition = length(aws_security_group.this.ingress) > 0
```

#### Combine multiple conditions
```hcl
# AND - all must be true
condition = aws_s3_bucket.this.bucket != "" && aws_s3_bucket.this.tags["Environment"] == "dev"

# OR - at least one must be true
condition = var.environment == "dev" || var.environment == "staging"
```

#### Safe navigation with `try()`
```hcl
# Safely access nested attributes that might not exist
# Returns "" if the path doesn't exist, avoiding errors
condition = try(aws_s3_bucket_versioning.this.versioning_configuration[0].status, "") == "Enabled"
```

#### Pattern matching with `can()` and `regex()`
```hcl
# can() returns true if the expression evaluates without error
condition = can(regex("^[a-z0-9-]+$", aws_s3_bucket.this.bucket))
```

### Complete Test Examples

#### Example 1: Testing S3 Bucket Creation

```hcl
# tests/s3_bucket.tftest.hcl

variables {
  bucket_name = "test-bucket-12345"
  environment = "test"
}

run "bucket_is_created" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket == "test-bucket-12345"
    error_message = "Bucket should be created with the specified name"
  }
}

run "bucket_has_required_tags" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.tags["Environment"] == "test"
    error_message = "Bucket should have Environment tag"
  }

  assert {
    condition     = contains(keys(aws_s3_bucket.this.tags), "ManagedBy")
    error_message = "Bucket should have ManagedBy tag"
  }
}
```

#### Example 2: Testing Versioning Configuration

```hcl
run "versioning_enabled_by_default" {
  command = plan

  # Don't override enable_versioning - test the default behavior
  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning should be enabled by default"
  }
}

run "versioning_can_be_disabled" {
  command = plan

  variables {
    enable_versioning = false
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Suspended"
    error_message = "Versioning should be suspended when disabled"
  }
}
```

#### Example 3: Testing Encryption

```hcl
run "encryption_is_aes256" {
  command = plan

  assert {
    condition = (
      aws_s3_bucket_server_side_encryption_configuration.this.rule[0]
      .apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    )
    error_message = "Bucket should use AES256 encryption"
  }
}
```

#### Example 4: Testing Module Outputs

```hcl
run "module_outputs_are_valid" {
  command = plan

  assert {
    condition     = module.lab_bucket.bucket_id != ""
    error_message = "Module should output bucket_id"
  }

  assert {
    condition     = can(regex("^arn:aws:s3:::", module.lab_bucket.bucket_arn))
    error_message = "Module should output a valid S3 ARN"
  }
}
```

### Tips and Best Practices

1. **Start with `plan` tests** - They're fast and don't create real resources

2. **Test one thing per `run` block** - Makes failures easier to diagnose

3. **Use descriptive test names** - `run "bucket_has_encryption"` not `run "test1"`

4. **Test the defaults** - Verify your module works without optional variables

5. **Use `try()` for safety** - Avoid test crashes from missing attributes:
   ```hcl
   # Instead of this (might crash):
   condition = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"

   # Use this (safe):
   condition = try(aws_s3_bucket_versioning.this.versioning_configuration[0].status, "") == "Enabled"
   ```

6. **Group related assertions** - Multiple `assert` blocks in one `run` is fine when testing related things

---

## Lab Tasks

### Part 1: Create the Module Structure (40 points)

Create a reusable S3 bucket module in the **project root** at `terraform-course/modules/s3-bucket/`:

```
terraform-course/                    # Project root
├── modules/
│   └── s3-bucket/                   # YOUR MODULE - create this!
│       ├── main.tf                  # S3 resources
│       ├── variables.tf             # Module inputs
│       └── outputs.tf               # Module outputs
│
└── week-01/
    └── lab-00/
        └── student-work/            # Your working directory
            ├── main.tf              # Uses your module
            ├── outputs.tf           # Root outputs
            ├── variables.tf         # Root variables
            ├── providers.tf         # AWS provider config
            └── tests/
                └── s3_bucket.tftest.hcl
```

#### Module Requirements

Your `modules/s3-bucket/` module (at the project root) must:

1. **Accept these input variables:**
   - `bucket_name` (string, required) - Base name for the bucket
   - `environment` (string, required) - Environment tag (dev/staging/prod)
   - `enable_versioning` (bool, optional, default: true)
   - `tags` (map(string), optional) - Additional tags to merge

2. **Create these resources:**
   - `aws_s3_bucket` - The bucket itself
   - `aws_s3_bucket_versioning` - Versioning configuration
   - `aws_s3_bucket_server_side_encryption_configuration` - AES256 encryption

3. **Output these values:**
   - `bucket_id` - The bucket name
   - `bucket_arn` - The bucket ARN
   - `bucket_region` - The bucket region

4. **Apply these tags to all resources:**
   - `Name` - The bucket name
   - `Environment` - From variable
   - `ManagedBy` - "terraform"
   - `Module` - "s3-bucket"
   - Plus any additional tags passed in

### Part 2: Use the Module (20 points)

In your `student-work/main.tf`, use your module to create a bucket:

```hcl
module "lab_bucket" {
  source = "../../../modules/s3-bucket"  # Path to project root modules

  bucket_name = "yourname-week01-lab00"
  environment = "dev"

  tags = {
    Student      = "your-github-username"
    AutoTeardown = "8h"
  }
}
```

> **Path explanation:** From `week-01/lab-00/student-work/`, go up 3 directories (`../../../`) to reach the project root, then into `modules/s3-bucket/`.

### Part 3: Write Terraform Tests (40 points)

Create `tests/s3_bucket.tftest.hcl` with the following tests:

#### Test 1: Bucket Creates with Correct Name (10 points)

```hcl
run "bucket_has_correct_name" {
  command = plan

  assert {
    condition     = # Your condition here
    error_message = "Bucket name should contain the expected prefix"
  }
}
```

#### Test 2: Versioning is Enabled (10 points)

```hcl
run "versioning_is_enabled" {
  command = plan

  assert {
    condition     = # Your condition here
    error_message = "Versioning should be enabled by default"
  }
}
```

#### Test 3: Encryption is Configured (10 points)

```hcl
run "encryption_is_configured" {
  command = plan

  assert {
    condition     = # Your condition here
    error_message = "Server-side encryption should be AES256"
  }
}
```

#### Test 4: Required Tags are Present (10 points)

```hcl
run "required_tags_present" {
  command = plan

  assert {
    condition     = # Your condition here
    error_message = "Required tags should be present"
  }
}
```

## Running Tests

```bash
# Initialize Terraform
terraform init

# Run all tests
terraform test

# Run tests with verbose output
terraform test -verbose

# Run a specific test file
terraform test -filter=tests/s3_bucket.tftest.hcl
```

### Expected Output

```
tests/s3_bucket.tftest.hcl... in progress
  run "bucket_has_correct_name"... pass
  run "versioning_is_enabled"... pass
  run "encryption_is_configured"... pass
  run "required_tags_present"... pass
tests/s3_bucket.tftest.hcl... tearing down
tests/s3_bucket.tftest.hcl... pass

Success! 4 passed, 0 failed.
```

## Hints

### Module Variable Definition

```hcl
# modules/s3-bucket/variables.tf
variable "bucket_name" {
  description = "Base name for the S3 bucket"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3
    error_message = "Bucket name must be at least 3 characters"
  }
}

variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true
}
```

### Merging Tags

```hcl
locals {
  default_tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "s3-bucket"
  }

  all_tags = merge(local.default_tags, var.tags)
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = local.all_tags
}
```

### Test Assertions

```hcl
# Check a string contains something
condition = can(regex("expected", module.lab_bucket.bucket_id))

# Check a boolean
condition = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"

# Check a map contains a key
condition = contains(keys(aws_s3_bucket.this.tags), "Environment")
```

## Submission

1. Ensure all tests pass: `terraform test`
2. Commit your code to your fork
3. Create a Pull Request with title: `Week 01 Lab 00 - [Your Name]`
4. Wait for the grading workflow to run

## Grading Criteria

| Category | Points | Criteria |
|----------|--------|----------|
| Code Quality | 25 | Formatting, validation, no hardcoded values |
| Module Structure | 20 | Proper variables, outputs, resource organization |
| Module Functionality | 20 | Creates S3 with versioning, encryption, tags |
| Test Coverage | 25 | All 4 required tests pass |
| Documentation | 10 | Comments explaining module usage |
| **Total** | **100** | |

## Resources

- [Terraform Modules Documentation](https://developer.hashicorp.com/terraform/language/modules)
- [Terraform Test Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Module Best Practices](https://developer.hashicorp.com/terraform/language/modules/develop)

## Estimated Time

2-3 hours

## Next Steps

In Lab 01, you'll use this S3 module to create a static website bucket and deploy a Hugo blog with CloudFront CDN!
