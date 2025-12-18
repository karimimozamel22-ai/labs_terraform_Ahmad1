# Week 00 Discovery Quiz: Documentation Exploration

## Overview

This quiz helps you practice navigating Terraform and AWS documentation - a critical skill for both the certification exam and real-world work. You won't find answers by searching Google; you'll need to explore the official documentation.

**Time**: 30-45 minutes  
**Format**: Open-book (documentation only)  
**Purpose**: Build research skills, not memorization

---

## Part 1: Terraform CLI Documentation

Navigate to the [Terraform CLI Documentation](https://developer.hashicorp.com/terraform/cli).

### Question 1.1
What environment variable can you set to specify an alternate location for the `.terraform` directory?

**Your Answer**: _________________

**Where to look**: CLI > Configuration > Environment Variables

---

### Question 1.2
When you run `terraform init`, what flag would you use to upgrade all previously-selected plugins to the newest version that matches the version constraints?

**Your Answer**: _________________

**Where to look**: CLI > Commands > init

---

### Question 1.3
What is the default file name Terraform looks for when loading variable values automatically (without using `-var-file`)?

**Your Answer**: _________________

**Where to look**: CLI > Configuration > Variable Definitions Files

---

## Part 2: AWS Provider Documentation

Navigate to the [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).

### Question 2.1
In the `aws_s3_bucket` resource, what argument would you use to specify an AWS-managed KMS key for server-side encryption? (Not a customer-managed key)

**Your Answer**: _________________

**Where to look**: Resources > S3 > aws_s3_bucket_server_side_encryption_configuration

---

### Question 2.2
What is the name of the data source you would use to get information about the AWS account ID and user ID of the caller?

**Your Answer**: _________________

**Where to look**: Data Sources > STS

---

### Question 2.3
For the S3 backend configuration, what is the name of the argument that enables state locking using S3's native locking feature (introduced in Terraform 1.9)?

**Your Answer**: _________________

**Where to look**: Terraform Language > Backend > S3

---

## Part 3: Terraform Language Documentation

Navigate to the [Terraform Language Documentation](https://developer.hashicorp.com/terraform/language).

### Question 3.1
What are the three types of "blocks" that can appear at the top level of a Terraform configuration file? (Not including nested blocks)

**Your Answer**: 
1. _________________
2. _________________
3. _________________

**Where to look**: Language > Syntax > Configuration Syntax

---

### Question 3.2
In a `terraform` block, what argument specifies the minimum Terraform CLI version required?

**Your Answer**: _________________

**Where to look**: Language > Terraform Settings

---

### Question 3.3
What is the difference between `terraform validate` and `terraform plan` in terms of what they check?

**Your Answer**: _________________

**Where to look**: CLI > Commands > validate and plan

---

## Part 4: Practical Exploration

### Question 4.1
Find the AWS provider changelog. What was the most recent version released, and what new resources or data sources were added? (Just list 1-2)

**Your Answer**: 
- Version: _________________
- New resource/data source: _________________

**Where to look**: Provider page > Changelog or GitHub releases

---

### Question 4.2
In the Terraform Registry, find a public S3 bucket module. What is the module source path you would use to reference it?

**Your Answer**: _________________

**Where to look**: Registry > Browse Modules > Search "s3"

---

### Question 4.3
What command would you use to format all Terraform files in the current directory AND all subdirectories?

**Your Answer**: _________________

**Where to look**: CLI > Commands > fmt

---

## Part 5: Cost Awareness

### Question 5.1
Using the [AWS Pricing Calculator](https://calculator.aws/) or [Infracost](https://www.infracost.io/), estimate the monthly cost of:
- 1 S3 bucket with 10GB of Standard storage
- 100,000 GET requests and 10,000 PUT requests per month

**Your Answer**: $_________________/month (approximate)

---

### Question 5.2
What S3 storage class would be most cost-effective for data that is rarely accessed but needs to be retrieved within milliseconds when needed?

**Your Answer**: _________________

**Where to look**: AWS S3 Documentation > Storage Classes

---

## Reflection

### What documentation section was hardest to navigate?

_________________

### What's one thing you learned that wasn't covered in the lab?

_________________

### What documentation bookmark will you add for future reference?

_________________

---

## Submission

Submit your completed quiz as `week-00/DISCOVERY_QUIZ_ANSWERS.md` in your student-work directory.

**Grading**: This quiz is graded on completion and effort, not correct answers. The goal is to build your documentation navigation skills.

---

## Answer Key Location

See [DISCOVERY_QUIZ_INSTRUCTOR.md](DISCOVERY_QUIZ_INSTRUCTOR.md) (instructor access only).
