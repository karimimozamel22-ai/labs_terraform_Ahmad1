# Lab 00 (Week 01) Policy: S3 Module + Terraform Testing
# Checks that the student created a reusable S3 module with proper structure

package main

import future.keywords.in
import future.keywords.contains
import future.keywords.if

# Helper to get all resources from plan (including child modules)
resources := input.planned_values.root_module.resources

# Get resources from child modules (the S3 module)
child_module_resources := [r |
    m := input.planned_values.root_module.child_modules[_]
    r := m.resources[_]
]

# All resources combined
all_resources := array.concat(resources, child_module_resources)

# Helper to get resources by type from all sources
resources_by_type(t) := [r | r := all_resources[_]; r.type == t]

# =============================================================================
# REQUIRED: Module is being used (child modules exist)
# =============================================================================
deny contains msg if {
    count(input.planned_values.root_module.child_modules) == 0
    msg := "FAIL: No module usage detected. You should use the S3 module with 'module \"...\" { source = \"../../../modules/s3-bucket\" }'"
}

pass contains msg if {
    count(input.planned_values.root_module.child_modules) > 0
    msg := "PASS: Module is being used in the configuration."
}

# =============================================================================
# REQUIRED: S3 Bucket exists (from module)
# =============================================================================
deny contains msg if {
    count(resources_by_type("aws_s3_bucket")) == 0
    msg := "FAIL: No S3 bucket resource found. The module should create an aws_s3_bucket."
}

pass contains msg if {
    count(resources_by_type("aws_s3_bucket")) > 0
    msg := "PASS: S3 bucket resource exists."
}

# =============================================================================
# REQUIRED: Versioning is configured
# =============================================================================
deny contains msg if {
    count(resources_by_type("aws_s3_bucket_versioning")) == 0
    msg := "FAIL: S3 versioning not configured. Add aws_s3_bucket_versioning to your module."
}

pass contains msg if {
    versioning := resources_by_type("aws_s3_bucket_versioning")[_]
    versioning.values.versioning_configuration[0].status == "Enabled"
    msg := "PASS: S3 versioning is enabled."
}

# =============================================================================
# REQUIRED: Encryption is configured
# =============================================================================
deny contains msg if {
    count(resources_by_type("aws_s3_bucket_server_side_encryption_configuration")) == 0
    msg := "FAIL: S3 encryption not configured. Add server-side encryption to your module."
}

pass contains msg if {
    encryption := resources_by_type("aws_s3_bucket_server_side_encryption_configuration")[_]
    algo := encryption.values.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm
    algo in ["AES256", "aws:kms"]
    msg := sprintf("PASS: S3 encryption configured with %s.", [algo])
}

# =============================================================================
# REQUIRED: AutoTeardown tag for cost management
# =============================================================================
deny contains msg if {
    bucket := resources_by_type("aws_s3_bucket")[_]
    not bucket.values.tags.AutoTeardown
    msg := "FAIL: S3 bucket missing 'AutoTeardown' tag for cost management."
}

pass contains msg if {
    bucket := resources_by_type("aws_s3_bucket")[_]
    bucket.values.tags.AutoTeardown
    msg := sprintf("PASS: AutoTeardown tag set to '%s'.", [bucket.values.tags.AutoTeardown])
}

# =============================================================================
# REQUIRED: Environment tag exists
# =============================================================================
deny contains msg if {
    bucket := resources_by_type("aws_s3_bucket")[_]
    not bucket.values.tags.Environment
    msg := "FAIL: S3 bucket missing 'Environment' tag."
}

pass contains msg if {
    bucket := resources_by_type("aws_s3_bucket")[_]
    bucket.values.tags.Environment
    msg := sprintf("PASS: Environment tag set to '%s'.", [bucket.values.tags.Environment])
}

# =============================================================================
# REQUIRED: ManagedBy tag shows Terraform management
# =============================================================================
warn contains msg if {
    bucket := resources_by_type("aws_s3_bucket")[_]
    not bucket.values.tags.ManagedBy
    msg := "WARN: Consider adding 'ManagedBy' tag to indicate Terraform management."
}

pass contains msg if {
    bucket := resources_by_type("aws_s3_bucket")[_]
    bucket.values.tags.ManagedBy == "terraform"
    msg := "PASS: ManagedBy tag indicates Terraform management."
}

# =============================================================================
# RECOMMENDED: Public access block (warn, not fail)
# =============================================================================
warn contains msg if {
    count(resources_by_type("aws_s3_bucket_public_access_block")) == 0
    msg := "WARN: Consider adding aws_s3_bucket_public_access_block for better security."
}

pass contains msg if {
    count(resources_by_type("aws_s3_bucket_public_access_block")) > 0
    msg := "PASS: S3 public access block configured (bonus)."
}
