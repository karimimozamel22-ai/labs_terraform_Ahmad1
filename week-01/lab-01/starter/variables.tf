# Root module variables for Week 01 Lab 01
# Static Blog with Hugo and CloudFront

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "student_name" {
  description = "Your name or GitHub username (used in resource naming)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}
