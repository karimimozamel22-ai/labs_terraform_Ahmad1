# Main configuration for Week 01 Lab 01
# Static Blog with Hugo and CloudFront

# Your S3 module is at the PROJECT ROOT: terraform-course/modules/s3-bucket/
# Update it to support website hosting (see README), then use it here.

# TODO: Use your module to create a blog bucket
# module "blog_bucket" {
#   source = "../../../modules/s3-bucket"  # Path to project root modules
#
#   bucket_name    = "${var.student_name}-blog"
#   environment    = var.environment
#   enable_website = true  # NEW in Lab 01!
#
#   tags = {
#     Student      = var.student_name
#     AutoTeardown = "8h"
#   }
# }

# TODO: Create CloudFront distribution in cloudfront.tf
# See README for CloudFront configuration details
