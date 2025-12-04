# Lab 00 Policy: S3 Bucket with Versioning
# These policies check for exactly what's required in this lab

package main

import future.keywords.in
import future.keywords.contains
import future.keywords.if

# Helper to get all resources from plan
resources := input.planned_values.root_module.resources

# Helper to get resources by type
resources_by_type(t) := [r | r := resources[_]; r.type == t]

# =============================================================================
# REQUIRED: S3 Bucket exists
# =============================================================================
deny contains msg if {
    count(resources_by_type("aws_s3_bucket")) == 0
    msg := "FAIL: No S3 bucket resource found. Create an aws_s3_bucket resource."
}

pass contains msg if {
    count(resources_by_type("aws_s3_bucket")) > 0
    msg := "PASS: S3 bucket resource exists."
}

# =============================================================================
# REQUIRED: Versioning is enabled
# =============================================================================
deny contains msg if {
    count(resources_by_type("aws_s3_bucket_versioning")) == 0
    msg := "FAIL: S3 versioning not configured. Add an aws_s3_bucket_versioning resource."
}

deny contains msg if {
    versioning := resources_by_type("aws_s3_bucket_versioning")[_]
    versioning.values.versioning_configuration[0].status != "Enabled"
    msg := "FAIL: S3 versioning status must be 'Enabled'."
}

pass contains msg if {
    versioning := resources_by_type("aws_s3_bucket_versioning")[_]
    versioning.values.versioning_configuration[0].status == "Enabled"
    msg := "PASS: S3 versioning is enabled."
}

# =============================================================================
# REQUIRED: Encryption is configured (AES256 or KMS - either is acceptable)
# =============================================================================
deny contains msg if {
    count(resources_by_type("aws_s3_bucket_server_side_encryption_configuration")) == 0
    msg := "FAIL: S3 encryption not configured. Add server-side encryption."
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
