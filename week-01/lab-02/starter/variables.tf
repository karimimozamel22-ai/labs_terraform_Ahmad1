# week-01/lab-02/starter/variables.tf
# Root Module Variables

variable "student_name" {
  description = "Your GitHub username or student ID"
  type        = string

  validation {
    condition     = length(var.student_name) > 0
    error_message = "Student name cannot be empty."
  }
}

# TODO: Add any additional variables you need
# THINK: What should be configurable at the root level vs. hardcoded?

# Examples of variables you might want:
# - AWS region
# - Environment name
# - Instance types for different environments
# - Key pair name
# - Project name prefix