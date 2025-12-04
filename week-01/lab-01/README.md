# Week 01 - Lab 01: Static Blog with Hugo and CloudFront

## Overview

In this lab, you'll build on your S3 module from Lab 00 to deploy a static blog using **Hugo** (a fast static site generator) and **CloudFront** (AWS's CDN). You'll learn how to configure S3 for static website hosting and use CloudFront for HTTPS and global distribution.

## Learning Objectives

By the end of this lab, you will be able to:

- Configure S3 buckets for static website hosting
- Create S3 bucket policies for public read access
- Deploy a CloudFront distribution for CDN
- Use Hugo to generate static site content
- Understand Origin Access Control (OAC) for secure S3 access
- Compare costs with and without CloudFront using Infracost

## Prerequisites

- Completed Week 01 Lab 00 (S3 Module)
- Terraform >= 1.9.0
- Hugo installed (available in Codespace)
- AWS credentials configured

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    User     │────▶│  CloudFront │────▶│  S3 Bucket  │
│  (Browser)  │     │    (CDN)    │     │   (Hugo)    │
└─────────────┘     └─────────────┘     └─────────────┘
                          │
                    HTTPS + Cache
                    Global Edge Locations
```

## Lab Tasks

### Part 1: Create Hugo Site (10 points)

First, generate a Hugo site with starter content:

```bash
# Navigate to student-work directory
cd week-01/lab-01/student-work

# Create new Hugo site
hugo new site blog
cd blog

# Add a theme (we'll use a simple one)
git init
git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke

# Configure the site
cat > hugo.toml <<EOF
baseURL = 'https://YOUR_CLOUDFRONT_DOMAIN/'
languageCode = 'en-us'
title = 'My Terraform Blog'
theme = 'ananke'
EOF

# Create your first post
hugo new content posts/hello-terraform.md
```

Edit `content/posts/hello-terraform.md`:

```markdown
---
title: "Hello Terraform"
date: 2024-01-15
draft: false
---

# Welcome to My Terraform Blog!

This site is deployed using:
- **Hugo** for static site generation
- **S3** for storage
- **CloudFront** for CDN
- **Terraform** for infrastructure as code

## What I Learned

In this lab, I learned how to...
```

Build the site:

```bash
hugo  # Outputs to public/ directory
```

### Part 2: Extend Your S3 Module (20 points)

Update the S3 module you created in Lab 00 (at the **project root**: `terraform-course/modules/s3-bucket/`) to support static website hosting.

> **No copying needed!** Since all modules live at the project root, you simply edit the same module. Lab 01's `student-work/main.tf` will reference `../../../modules/s3-bucket` - the exact same module Lab 00 uses.

Add these new variables to `terraform-course/modules/s3-bucket/variables.tf`:

```hcl
variable "enable_website" {
  description = "Enable static website hosting"
  type        = bool
  default     = false
}

variable "index_document" {
  description = "Index document for website"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for website"
  type        = string
  default     = "404.html"
}
```

Add conditional website configuration to your module:

```hcl
resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}
```

Add new outputs to `terraform-course/modules/s3-bucket/outputs.tf`:

```hcl
output "website_endpoint" {
  description = "Website endpoint (if enabled)"
  value       = var.enable_website ? aws_s3_bucket_website_configuration.this[0].website_endpoint : null
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket (for CloudFront)"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
```

Now set up your `student-work/main.tf` to use the module with website hosting enabled:

```hcl
# week-01/lab-01/student-work/main.tf

module "blog_bucket" {
  source = "../../../modules/s3-bucket"  # Same module from Lab 00

  bucket_name    = "${var.student_name}-blog"
  environment    = var.environment
  enable_website = true  # NEW: Enable static website hosting

  tags = {
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}
```

### Part 3: Create CloudFront Distribution (30 points)

Create `cloudfront.tf` in your student-work directory:

```hcl
# Origin Access Control for secure S3 access
resource "aws_cloudfront_origin_access_control" "blog" {
  name                              = "${var.student_name}-blog-oac"
  description                       = "OAC for blog S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "blog" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "${var.student_name} Terraform Blog"

  origin {
    domain_name              = module.blog_bucket.bucket_regional_domain_name
    origin_id                = "S3-${module.blog_bucket.bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.blog.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${module.blog_bucket.bucket_id}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Custom error response for SPA-style routing
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name         = "${var.student_name}-blog-cdn"
    Environment  = var.environment
    Student      = var.student_name
    AutoTeardown = "8h"
  }
}
```

### Part 4: S3 Bucket Policy for CloudFront (10 points)

Create a bucket policy that allows CloudFront to access your S3 bucket:

```hcl
resource "aws_s3_bucket_policy" "blog" {
  bucket = module.blog_bucket.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.blog_bucket.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.blog.arn
          }
        }
      }
    ]
  })
}
```

### Part 5: Upload Hugo Content (10 points)

Use Terraform to upload your Hugo site, or use the AWS CLI:

```bash
# Option 1: AWS CLI (simpler)
aws s3 sync blog/public/ s3://YOUR_BUCKET_NAME/ --delete

# Option 2: Terraform aws_s3_object resources (more declarative)
```

For Terraform, you can use a `null_resource` with a local-exec provisioner:

```hcl
resource "null_resource" "upload_blog" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "aws s3 sync ${path.module}/blog/public/ s3://${module.blog_bucket.bucket_id}/ --delete"
  }

  depends_on = [module.blog_bucket, aws_s3_bucket_policy.blog]
}
```

### Part 6: Outputs and Testing (10 points)

Add outputs to see your deployed blog:

```hcl
output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = aws_cloudfront_distribution.blog.domain_name
}

output "cloudfront_url" {
  description = "Full URL to access the blog"
  value       = "https://${aws_cloudfront_distribution.blog.domain_name}"
}

output "s3_website_url" {
  description = "Direct S3 website URL (HTTP only)"
  value       = module.blog_bucket.website_endpoint
}
```

### Part 7: Write Tests (10 points)

Add tests for the CloudFront configuration:

```hcl
# tests/cloudfront.tftest.hcl

run "cloudfront_uses_https" {
  command = plan

  assert {
    condition     = aws_cloudfront_distribution.blog.viewer_certificate[0].cloudfront_default_certificate == true
    error_message = "CloudFront should use HTTPS"
  }
}

run "cloudfront_has_oac" {
  command = plan

  assert {
    condition     = aws_cloudfront_origin_access_control.blog.signing_behavior == "always"
    error_message = "CloudFront should use Origin Access Control"
  }
}
```

## Expected Directory Structure

```
terraform-course/                        # Project root
├── modules/
│   └── s3-bucket/                       # Shared module (updated in Lab 00, extended here)
│       ├── main.tf                      # Now includes website config
│       ├── variables.tf                 # Now includes enable_website, etc.
│       └── outputs.tf                   # Now includes website_endpoint
│
└── week-01/
    └── lab-01/
        └── student-work/                # Your working directory
            ├── main.tf                  # Module usage (source = "../../../modules/s3-bucket")
            ├── cloudfront.tf            # CloudFront resources
            ├── variables.tf             # Root variables
            ├── outputs.tf               # Root outputs
            ├── providers.tf             # AWS provider
            ├── tests/
            │   ├── s3_bucket.tftest.hcl
            │   └── cloudfront.tftest.hcl
            └── blog/                    # Hugo site
                ├── hugo.toml
                ├── content/
                │   └── posts/
                │       └── hello-terraform.md
                ├── themes/
                └── public/              # Generated static files
```

## Cost Comparison Exercise

Run Infracost to compare costs:

```bash
# Cost with CloudFront
infracost breakdown --path .

# You should see:
# - S3: ~$0.50/month (storage)
# - CloudFront: ~$1-2/month (depending on traffic)
# Total: ~$1.50-2.50/month
```

**Discussion Questions:**
1. When would the extra cost of CloudFront be worth it?
2. What are the benefits beyond cost (latency, HTTPS, caching)?
3. How would costs change with more traffic?

## Submission

1. Build your Hugo site: `hugo`
2. Apply your Terraform: `terraform apply`
3. Verify your blog loads at the CloudFront URL
4. Run tests: `terraform test`
5. Create a Pull Request with title: `Week 01 Lab 01 - [Your Name]`
6. Include a screenshot of your live blog in the PR description

## Grading Criteria

| Category | Points | Criteria |
|----------|--------|----------|
| Code Quality | 25 | Formatting, validation, no hardcoded values |
| Hugo Site | 10 | Site builds, has custom content |
| S3 Module Updates | 20 | Website hosting enabled, proper outputs |
| CloudFront Config | 25 | OAC, HTTPS redirect, proper caching |
| Tests | 10 | CloudFront tests pass |
| Documentation | 10 | Comments, PR description |
| **Total** | **100** | |

## Cleanup

**Important:** CloudFront distributions can take 15-20 minutes to delete.

```bash
# First, disable the distribution
# Then run destroy
terraform destroy

# Or wait for AutoTeardown tag to trigger cleanup
```

## Resources

- [Hugo Quick Start](https://gohugo.io/getting-started/quick-start/)
- [S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront with S3 Origin](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistS3AndCustomOrigins.html)
- [Origin Access Control](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)

## Estimated Time

3-4 hours

## Next Steps

In Week 02, you'll add a custom domain with Route 53 and an SSL certificate with ACM!
