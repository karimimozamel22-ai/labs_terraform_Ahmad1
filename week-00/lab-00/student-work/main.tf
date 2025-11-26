# Terraform block - defines version requirements
terraform {
  required_version = ">= 1.9.0" # Minimum version needed for S3 native locking

  required_providers {
    aws = {
      source  = "hashicorp/aws" # Where to download the AWS provider
      version = "~> 5.0"        # Use any 5.x version (but not 6.0)
    }
  }
}

# Provider block - configures AWS
provider "aws" {
  region = "us-east-1" # AWS region where resources will be created
}

# Resource block - creates an S3 bucket
resource "aws_s3_bucket" "test_bucket" {
  bucket = "terraform-lab-00-${var.student_name}" # Replace with your GitHub username
  tags = {
    Name         = "Lab 0 Test Bucket"
    Environment  = "Learning"
    ManagedBy    = "Terraform"
    Student      = "var.student_name" # Replace with your GitHub username
    AutoTeardown = "8h"
  }
}

# Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "test_bucket_versioning" {
  bucket = aws_s3_bucket.test_bucket.id  # Reference to our bucket

  versioning_configuration {
    status = "Enabled"
  }
}
