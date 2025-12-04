# Lab 01 (Week 01) Policy: Static Blog with Hugo and CloudFront
# Checks for S3 website hosting, CloudFront distribution, OAC, and security

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

# Helper to get root module resources only
root_resources_by_type(t) := [r | r := resources[_]; r.type == t]

# =============================================================================
# REQUIRED: S3 Bucket exists
# =============================================================================
deny contains msg if {
    count(resources_by_type("aws_s3_bucket")) == 0
    msg := "FAIL: No S3 bucket found. Create an S3 bucket for hosting the Hugo site."
}

pass contains msg if {
    count(resources_by_type("aws_s3_bucket")) > 0
    msg := "PASS: S3 bucket exists."
}

# =============================================================================
# REQUIRED: S3 Website Configuration
# =============================================================================
deny contains msg if {
    count(resources_by_type("aws_s3_bucket_website_configuration")) == 0
    msg := "FAIL: S3 website hosting not configured. Add aws_s3_bucket_website_configuration."
}

pass contains msg if {
    website := resources_by_type("aws_s3_bucket_website_configuration")[_]
    website.values.index_document[0].suffix == "index.html"
    msg := "PASS: S3 website hosting configured with index.html."
}

# =============================================================================
# REQUIRED: CloudFront Distribution
# =============================================================================
deny contains msg if {
    count(root_resources_by_type("aws_cloudfront_distribution")) == 0
    msg := "FAIL: CloudFront distribution not found. Create an aws_cloudfront_distribution for CDN."
}

pass contains msg if {
    cf := root_resources_by_type("aws_cloudfront_distribution")[_]
    cf.values.enabled == true
    msg := "PASS: CloudFront distribution is enabled."
}

# =============================================================================
# REQUIRED: CloudFront Origin Access Control (OAC)
# =============================================================================
deny contains msg if {
    count(root_resources_by_type("aws_cloudfront_origin_access_control")) == 0
    msg := "FAIL: Origin Access Control not configured. Add aws_cloudfront_origin_access_control for secure S3 access."
}

pass contains msg if {
    oac := root_resources_by_type("aws_cloudfront_origin_access_control")[_]
    oac.values.signing_behavior == "always"
    msg := "PASS: Origin Access Control configured with signing."
}

# =============================================================================
# REQUIRED: S3 Bucket Policy for CloudFront
# =============================================================================
deny contains msg if {
    count(root_resources_by_type("aws_s3_bucket_policy")) == 0
    msg := "FAIL: S3 bucket policy not found. Add aws_s3_bucket_policy to allow CloudFront access."
}

pass contains msg if {
    count(root_resources_by_type("aws_s3_bucket_policy")) > 0
    msg := "PASS: S3 bucket policy configured."
}

# =============================================================================
# REQUIRED: HTTPS Redirect (Security)
# =============================================================================
deny contains msg if {
    cf := root_resources_by_type("aws_cloudfront_distribution")[_]
    policy := cf.values.default_cache_behavior[0].viewer_protocol_policy
    policy == "allow-all"
    msg := "FAIL: CloudFront allows HTTP. Set viewer_protocol_policy to 'redirect-to-https' or 'https-only'."
}

pass contains msg if {
    cf := root_resources_by_type("aws_cloudfront_distribution")[_]
    policy := cf.values.default_cache_behavior[0].viewer_protocol_policy
    policy in ["redirect-to-https", "https-only"]
    msg := sprintf("PASS: CloudFront enforces HTTPS (%s).", [policy])
}

# =============================================================================
# REQUIRED: CloudFront has default root object
# =============================================================================
deny contains msg if {
    cf := root_resources_by_type("aws_cloudfront_distribution")[_]
    not cf.values.default_root_object
    msg := "FAIL: CloudFront missing default_root_object. Set to 'index.html'."
}

pass contains msg if {
    cf := root_resources_by_type("aws_cloudfront_distribution")[_]
    cf.values.default_root_object == "index.html"
    msg := "PASS: CloudFront default_root_object set to index.html."
}

# =============================================================================
# REQUIRED: AutoTeardown tag on CloudFront
# =============================================================================
deny contains msg if {
    cf := root_resources_by_type("aws_cloudfront_distribution")[_]
    not cf.values.tags.AutoTeardown
    msg := "FAIL: CloudFront distribution missing 'AutoTeardown' tag for cost management."
}

pass contains msg if {
    cf := root_resources_by_type("aws_cloudfront_distribution")[_]
    cf.values.tags.AutoTeardown
    msg := sprintf("PASS: CloudFront AutoTeardown tag set to '%s'.", [cf.values.tags.AutoTeardown])
}

# =============================================================================
# REQUIRED: S3 Encryption (from module)
# =============================================================================
deny contains msg if {
    count(resources_by_type("aws_s3_bucket_server_side_encryption_configuration")) == 0
    msg := "FAIL: S3 encryption not configured. Ensure your S3 module includes encryption."
}

pass contains msg if {
    encryption := resources_by_type("aws_s3_bucket_server_side_encryption_configuration")[_]
    algo := encryption.values.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm
    algo in ["AES256", "aws:kms"]
    msg := sprintf("PASS: S3 encryption configured with %s.", [algo])
}

# =============================================================================
# RECOMMENDED: CloudFront uses IPv6
# =============================================================================
warn contains msg if {
    cf := root_resources_by_type("aws_cloudfront_distribution")[_]
    cf.values.is_ipv6_enabled == false
    msg := "WARN: Consider enabling IPv6 on CloudFront for broader accessibility."
}

pass contains msg if {
    cf := root_resources_by_type("aws_cloudfront_distribution")[_]
    cf.values.is_ipv6_enabled == true
    msg := "PASS: CloudFront IPv6 enabled (bonus)."
}

# =============================================================================
# RECOMMENDED: CloudFront custom error response for 404
# =============================================================================
warn contains msg if {
    cf := root_resources_by_type("aws_cloudfront_distribution")[_]
    count(cf.values.custom_error_response) == 0
    msg := "WARN: Consider adding custom_error_response for better 404 handling."
}

pass contains msg if {
    cf := root_resources_by_type("aws_cloudfront_distribution")[_]
    count(cf.values.custom_error_response) > 0
    msg := "PASS: CloudFront custom error response configured (bonus)."
}
