# Provider configuration for Week 01 Lab 01
# Static Blog with Hugo and CloudFront

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "terraform-course"
      Week    = "01"
      Lab     = "01"
    }
  }
}
