# Week 01: Terraform Modules and Testing

## Overview

This week builds on your Week 00 foundation by introducing **reusable modules** and **Terraform native testing**. You'll learn the DRY (Don't Repeat Yourself) principle and how to validate your infrastructure code.

## Learning Objectives

- Create reusable Terraform modules
- Write Terraform native tests (`.tftest.hcl`)
- Configure S3 for static website hosting
- Deploy CloudFront CDN with Origin Access Control
- Build and deploy a Hugo static site

## Labs

### Lab 00: S3 Module + Terraform Testing
**Time:** 2-3 hours

Take your Week 00 S3 bucket code and refactor it into a reusable module. Then write Terraform tests to validate your module works correctly.

**Key Concepts:**
- Module structure (variables, resources, outputs)
- Input validation
- Terraform test framework
- DRY principle

[Start Lab 00 →](lab-00/README.md)

### Lab 01: Static Blog with Hugo and CloudFront
**Time:** 3-4 hours

Use your S3 module to deploy a static blog built with Hugo. Add CloudFront for HTTPS and global CDN distribution.

**Key Concepts:**
- S3 static website hosting
- CloudFront distributions
- Origin Access Control (OAC)
- Hugo static site generator

[Start Lab 01 →](lab-01/README.md)

## Prerequisites

- Completed Week 00 labs
- Terraform >= 1.9.0
- AWS credentials configured
- GitHub Codespace (recommended)

## Getting Started

1. Open your GitHub Codespace
2. Navigate to `week-01/lab-00/`
3. Copy starter files: `cp -r starter/* student-work/`
4. Follow the README instructions

## Grading

Each lab is worth 100 points:

| Category | Points |
|----------|--------|
| Code Quality | 25 |
| Functionality | 30 |
| Cost Management | 20 |
| Security | 15 |
| Documentation | 10 |

## Resources

- [Terraform Modules](https://developer.hashicorp.com/terraform/language/modules)
- [Terraform Testing](https://developer.hashicorp.com/terraform/language/tests)
- [Hugo Quick Start](https://gohugo.io/getting-started/quick-start/)
- [CloudFront with S3](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistS3AndCustomOrigins.html)
