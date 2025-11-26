# Terraform block - defines version requirements
terraform {
  required_version = ">= 1.9.0"  # Minimum version needed for S3 native locking
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Where to download the AWS provider
      version = "~> 5.0"         # Use any 5.x version (but not 6.0)
    }
  }
}

# Provider block - configures AWS
provider "aws" {
  region = "us-east-1"  # AWS region where resources will be created
}


