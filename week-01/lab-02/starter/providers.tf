# week-01/lab-02/starter/providers.tf
# Provider Configuration

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # TODO: Add other providers if needed
    # http = {
    #   source  = "hashicorp/http"
    #   version = "~> 3.0"
    # }
    # random = {
    #   source  = "hashicorp/random"
    #   version = "~> 3.0"
    # }
  }

  # TODO: Configure backend for remote state storage
  # REFERENCE: Use the pattern from previous labs
  # backend "s3" {
  #   bucket = "terraform-state-YOUR-ACCOUNT-ID"
  #   key    = "week-01/lab-02/terraform.tfstate"
  #   region = "us-east-1"
  #   encrypt = true
  # }
}

provider "aws" {
  region = "us-east-1"

  # TODO: Add default tags if desired
  # default_tags {
  #   tags = {
  #     ManagedBy = "terraform"
  #     Student   = var.student_name
  #     Lab       = "week-01-lab-02"
  #   }
  # }
}