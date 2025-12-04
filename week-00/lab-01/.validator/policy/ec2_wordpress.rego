# Lab 01 Policy: WordPress on EC2
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
# REQUIRED: EC2 Instance exists
# =============================================================================
deny contains msg if {
    count(resources_by_type("aws_instance")) == 0
    msg := "FAIL: No EC2 instance resource found. Create an aws_instance resource."
}

pass contains msg if {
    count(resources_by_type("aws_instance")) > 0
    msg := "PASS: EC2 instance resource exists."
}

# =============================================================================
# REQUIRED: IMDSv2 is enforced (http_tokens = "required")
# =============================================================================
deny contains msg if {
    instance := resources_by_type("aws_instance")[_]
    not instance.values.metadata_options
    msg := "FAIL: metadata_options block missing. IMDSv2 must be configured."
}

deny contains msg if {
    instance := resources_by_type("aws_instance")[_]
    instance.values.metadata_options
    instance.values.metadata_options[0].http_tokens != "required"
    msg := "FAIL: http_tokens must be 'required' to enforce IMDSv2."
}

pass contains msg if {
    instance := resources_by_type("aws_instance")[_]
    instance.values.metadata_options[0].http_tokens == "required"
    msg := "PASS: IMDSv2 is enforced (http_tokens = required)."
}

# =============================================================================
# REQUIRED: Security Group exists
# =============================================================================
deny contains msg if {
    count(resources_by_type("aws_security_group")) == 0
    msg := "FAIL: No security group found. Create an aws_security_group resource."
}

pass contains msg if {
    count(resources_by_type("aws_security_group")) > 0
    msg := "PASS: Security group exists."
}

# =============================================================================
# REQUIRED: SSH not open to 0.0.0.0/0
# =============================================================================
deny contains msg if {
    sg := resources_by_type("aws_security_group")[_]
    rule := sg.values.ingress[_]
    rule.from_port <= 22
    rule.to_port >= 22
    cidr := rule.cidr_blocks[_]
    cidr == "0.0.0.0/0"
    msg := "FAIL: SSH (port 22) is open to 0.0.0.0/0. Restrict to your IP address."
}

pass contains msg if {
    sg := resources_by_type("aws_security_group")[_]
    rule := sg.values.ingress[_]
    rule.from_port <= 22
    rule.to_port >= 22
    cidr := rule.cidr_blocks[_]
    cidr != "0.0.0.0/0"
    msg := sprintf("PASS: SSH restricted to %s.", [cidr])
}

# =============================================================================
# REQUIRED: HTTP port 80 is open (WordPress needs this)
# =============================================================================
deny contains msg if {
    sg := resources_by_type("aws_security_group")[_]
    not has_http_rule(sg)
    msg := "FAIL: HTTP port 80 must be open for WordPress access."
}

has_http_rule(sg) if {
    rule := sg.values.ingress[_]
    rule.from_port <= 80
    rule.to_port >= 80
}

pass contains msg if {
    sg := resources_by_type("aws_security_group")[_]
    has_http_rule(sg)
    msg := "PASS: HTTP port 80 is open."
}

# =============================================================================
# REQUIRED: Egress rules exist (instance needs internet access)
# =============================================================================
deny contains msg if {
    sg := resources_by_type("aws_security_group")[_]
    count(sg.values.egress) == 0
    msg := "FAIL: No egress rules. Instance cannot download packages without egress!"
}

pass contains msg if {
    sg := resources_by_type("aws_security_group")[_]
    count(sg.values.egress) > 0
    msg := "PASS: Egress rules configured."
}

# =============================================================================
# REQUIRED: Key pair for SSH access
# =============================================================================
deny contains msg if {
    count(resources_by_type("aws_key_pair")) == 0
    msg := "FAIL: No SSH key pair found. Create an aws_key_pair resource."
}

pass contains msg if {
    count(resources_by_type("aws_key_pair")) > 0
    msg := "PASS: SSH key pair configured."
}

# =============================================================================
# REQUIRED: User data configured (for WordPress installation)
# =============================================================================
deny contains msg if {
    instance := resources_by_type("aws_instance")[_]
    not instance.values.user_data
    msg := "FAIL: user_data not configured. WordPress won't auto-install."
}

pass contains msg if {
    instance := resources_by_type("aws_instance")[_]
    instance.values.user_data
    msg := "PASS: user_data configured for WordPress installation."
}

# =============================================================================
# REQUIRED: AutoTeardown tag for cost management
# =============================================================================
deny contains msg if {
    instance := resources_by_type("aws_instance")[_]
    not instance.values.tags.AutoTeardown
    msg := "FAIL: EC2 instance missing 'AutoTeardown' tag for cost management."
}

pass contains msg if {
    instance := resources_by_type("aws_instance")[_]
    instance.values.tags.AutoTeardown
    msg := sprintf("PASS: AutoTeardown tag set to '%s'.", [instance.values.tags.AutoTeardown])
}

# =============================================================================
# RECOMMENDED: EBS encryption (warn, not fail for intro lab)
# =============================================================================
warn contains msg if {
    instance := resources_by_type("aws_instance")[_]
    not instance.values.root_block_device[0].encrypted
    msg := "WARN: Consider enabling EBS encryption for better security."
}

pass contains msg if {
    instance := resources_by_type("aws_instance")[_]
    instance.values.root_block_device[0].encrypted == true
    msg := "PASS: EBS encryption enabled (bonus)."
}

# =============================================================================
# RECOMMENDED: Hop limit = 1 for IMDSv2 (warn, not fail)
# =============================================================================
warn contains msg if {
    instance := resources_by_type("aws_instance")[_]
    instance.values.metadata_options[0].http_put_response_hop_limit != 1
    msg := "WARN: Consider setting http_put_response_hop_limit to 1 for better IMDSv2 security."
}

pass contains msg if {
    instance := resources_by_type("aws_instance")[_]
    instance.values.metadata_options[0].http_put_response_hop_limit == 1
    msg := "PASS: IMDSv2 hop limit set to 1 (bonus)."
}
