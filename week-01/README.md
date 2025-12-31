# Week 01: Terraform Modules and Testing

## Exam Objectives Covered

This week covers objectives from the [Terraform Associate 004 Exam](https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-review-004):

| Domain | Objective | Description |
|--------|-----------|-------------|
| 4 | 4a | Differentiate between resource and data blocks |
| 4 | 4b | Use resource addressing and references |
| 4 | 4c | Use input variables and outputs |
| 4 | 4f | Describe resource dependencies |
| 4 | 4g | Use custom conditions and validation |
| 5 | 5a | Source modules from different locations |
| 5 | 5b | Describe variable scope within modules |
| 5 | 5c | Use modules in configuration |

---

## Required Reading (Before Labs)

Complete these readings before starting the labs. Estimated time: **60-75 minutes**.

### Module Fundamentals (Exam Domain 5)
| Reading | Time | Focus |
|---------|------|-------|
| [Modules Overview](https://developer.hashicorp.com/terraform/language/modules) | 15 min | What modules are and why |
| [Module Sources](https://developer.hashicorp.com/terraform/language/modules/sources) | 10 min | Local, registry, git sources |
| [Module Composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition) | 10 min | Structuring modules |

### Input Validation (Exam Domain 4)
| Reading | Time | Focus |
|---------|------|-------|
| [Variable Validation](https://developer.hashicorp.com/terraform/language/values/variables#custom-validation-rules) | 10 min | Custom validation rules |
| [Preconditions and Postconditions](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions) | 10 min | Resource-level validation |

### Terraform Testing
| Reading | Time | Focus |
|---------|------|-------|
| [Terraform Test Framework](https://developer.hashicorp.com/terraform/language/tests) | 15 min | Native testing with .tftest.hcl |
| [Test Assertions](https://developer.hashicorp.com/terraform/language/tests#assertions) | 10 min | Writing test assertions |

### AWS Resources for This Week
| Reading | Time | Focus |
|---------|------|-------|
| [aws_s3_bucket_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | 5 min | Versioning resource |
| [aws_cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | Browse | CloudFront reference |
| [CloudFront OAC](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | 5 min | Origin Access Control |

---

## Learning Outcomes

By the end of this week, you will be able to:

- Create reusable Terraform modules with proper structure
- Define module inputs with validation rules
- Write Terraform native tests (`.tftest.hcl`)
- Configure S3 for static website hosting
- Deploy CloudFront CDN with Origin Access Control
- Understand implicit vs explicit resource dependencies
- Build and deploy a Hugo static site

---

## Overview

This week builds on your Week 00 foundation by introducing **reusable modules** and **Terraform native testing**. You'll learn the DRY (Don't Repeat Yourself) principle and how to validate your infrastructure code before deployment.

Modules are the primary way to package and reuse Terraform configurations. Understanding modules is essential for the certification exam (Domain 5 is 15% of the exam).

---

## Prerequisites

- Completed Week 00 labs
- Terraform >= 1.9.0
- AWS credentials configured
- GitHub Codespace or local environment ready

---

## Labs

| Lab | Time | Description |
|-----|------|-------------|
| [Lab 00: S3 Module + Testing](lab-00/README.md) | 2-3 hrs | Refactor S3 into module, write tests |
| [Lab 01: Hugo + CloudFront](lab-01/README.md) | 3-4 hrs | Static site with CDN |

### Lab 00: S3 Module + Terraform Testing

Take your Week 00 S3 bucket code and refactor it into a reusable module. Then write Terraform tests to validate your module works correctly.

**Key Concepts:**
- Module structure (main.tf, variables.tf, outputs.tf)
- Input validation with custom rules
- Terraform test framework (`.tftest.hcl`)
- Test assertions and mocking

### Lab 01: Static Blog with Hugo and CloudFront

Use your S3 module to deploy a static blog built with Hugo. Add CloudFront for HTTPS and global CDN distribution.

**Key Concepts:**
- S3 static website hosting configuration
- CloudFront distributions and behaviors
- Origin Access Control (OAC) - the modern replacement for OAI
- Complex resource dependencies
- Hugo static site generator basics

---

## Gym Practice (Recommended)

After completing the labs, reinforce your learning with these focused exercises from the [Terraform Gym](https://github.com/shart-cloud/terraform-gym):

### Foundation Exercises
| Exercise | Time | Reinforces |
|----------|------|------------|
| [Foundations Ex 03: Data Sources](https://github.com/shart-cloud/terraform-gym/tree/main/exercises/foundations/exercise-03-data-sources) | 25 min | Data sources vs resources (4a) |
| [Foundations Ex 04: Locals & Functions](https://github.com/shart-cloud/terraform-gym/tree/main/exercises/foundations/exercise-04-locals-functions) | 30 min | Expressions and functions (4e) |

### S3 Exercises
| Exercise | Time | Reinforces |
|----------|------|------------|
| [S3 Ex 03: Bucket Policies](https://github.com/shart-cloud/terraform-gym/tree/main/exercises/s3/exercise-03-bucket-policies) | 25 min | jsonencode, policies |
| [S3 Ex 04: Lifecycle Rules](https://github.com/shart-cloud/terraform-gym/tree/main/exercises/s3/exercise-04-lifecycle-rules) | 25 min | Cost optimization |

### Challenge (If Time Permits)
| Exercise | Time | Reinforces |
|----------|------|------------|
| [Foundations Challenge](https://github.com/shart-cloud/terraform-gym/tree/main/exercises/foundations/challenge-complete-config) | 60 min | All foundation concepts + count/for_each |
| [S3 Challenge](https://github.com/shart-cloud/terraform-gym/tree/main/exercises/s3/challenge-complete-s3) | 60 min | Production S3 configuration |

**Total Gym Time**: ~105 minutes (exercises) + 120 minutes (challenges)

---

## Discovery Quiz

Complete the [Discovery Quiz](DISCOVERY_QUIZ.md) to practice navigating module documentation. This quiz focuses on:
- Finding module inputs and outputs
- Reading module source code
- Evaluating module quality in the registry
- Understanding version constraints

---

## Grading

Each lab is worth 100 points:

| Category | Points | Checks |
|----------|--------|--------|
| Code Quality | 25 | `terraform fmt`, `validate`, naming conventions |
| Functionality | 30 | Required resources, proper configuration |
| Cost Management | 20 | Budget thresholds, Infracost analysis |
| Security | 15 | No hardcoded secrets, proper access controls |
| Documentation | 10 | README updates, variable descriptions |

---

## Resources

### Module Development
- [Creating Modules](https://developer.hashicorp.com/terraform/language/modules/develop)
- [Module Best Practices](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
- [Publishing Modules](https://developer.hashicorp.com/terraform/registry/modules/publish)

### Testing
- [Terraform Test Command](https://developer.hashicorp.com/terraform/cli/commands/test)
- [Test File Structure](https://developer.hashicorp.com/terraform/language/tests)

### AWS Services
- [S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)
- [CloudFront with S3 Origins](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistS3AndCustomOrigins.html)

### Hugo (Lab 01)
- [Hugo Quick Start](https://gohugo.io/getting-started/quick-start/)
- [Hugo Themes](https://themes.gohugo.io/)

### Certification Prep
- [Exam Domain 4: Terraform Configuration](https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-review-004#4-use-terraform-outside-of-core-workflow)
- [Exam Domain 5: Terraform Modules](https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-review-004#5-interact-with-terraform-modules)

---

## Checklist

Before moving to Week 02, ensure you can:

- [ ] Explain the standard module structure (main.tf, variables.tf, outputs.tf)
- [ ] Create a module with input validation
- [ ] Write and run Terraform tests
- [ ] Explain implicit vs explicit dependencies
- [ ] Configure S3 for static website hosting
- [ ] Explain what CloudFront OAC does and why it's used

---

## Next Week

[Week 02: State Management Deep Dive](../week-02/README.md) - Master state operations, locking, drift detection, and the `moved`/`removed` blocks.
