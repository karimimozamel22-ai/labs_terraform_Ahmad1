# Terraform Tests for S3 Bucket Module
# Run with: terraform test

# Variables for testing
variables {
  student_name = "test-student"
  environment  = "dev"
}

# Test 1: Bucket creates with correct name (10 points)
run "bucket_has_correct_name" {
  command = plan

  # TODO: Add assertion to verify bucket name contains expected prefix
  # Hint: Use can(regex(...)) or strcontains()
  #
  # assert {
  #   condition     = strcontains(module.lab_bucket.bucket_id, "test-student")
  #   error_message = "Bucket name should contain the student name"
  # }
}

# Test 2: Versioning is enabled (10 points)
run "versioning_is_enabled" {
  command = plan

  # TODO: Add assertion to verify versioning is enabled
  # Hint: Check the versioning_configuration status
  #
  # assert {
  #   condition     = # your condition here
  #   error_message = "Versioning should be enabled by default"
  # }
}

# Test 3: Encryption is configured (10 points)
run "encryption_is_configured" {
  command = plan

  # TODO: Add assertion to verify AES256 encryption
  #
  # assert {
  #   condition     = # your condition here
  #   error_message = "Server-side encryption should be AES256"
  # }
}

# Test 4: Required tags are present (10 points)
run "required_tags_present" {
  command = plan

  # TODO: Add assertions to verify required tags exist
  # Required tags: Name, Environment, ManagedBy, Module
  #
  # assert {
  #   condition     = # your condition here
  #   error_message = "Required tags should be present on the bucket"
  # }
}
