# Type Scavenger Hunt Answers

**Student Name**: _____________________  
**Date**: _____________________

---

## Hunt 1: EC2 Instance Arguments

Navigate to: **Resources > EC2 > aws_instance**

| Argument | Type | Your Answer |
|----------|------|-------------|
| `ami` | | |
| `instance_type` | | |
| `associate_public_ip_address` | | |
| `vpc_security_group_ids` | | |
| `tags` | | |
| `user_data` | | |

---

## Hunt 2: Security Group Arguments

Navigate to: **Resources > VPC > aws_security_group**

| Argument | Type | Your Answer |
|----------|------|-------------|
| `name` | | |
| `description` | | |
| `ingress` | | |
| `ingress.from_port` | | |
| `ingress.cidr_blocks` | | |

**Question**: The `ingress` argument is a special type. What makes it different from a simple `list`?

**Your answer**: 


---

## Hunt 3: Data Source Return Types

Navigate to: **Data Sources > EC2 > aws_ami**

| Attribute | Type | Your Answer |
|-----------|------|-------------|
| `id` | | |
| `name` | | |
| `architecture` | | |
| `block_device_mappings` | | |

**Question**: Why is understanding return types important when you reference data sources?

**Your answer**: 


---

## Hunt 4: Metadata Options Block

Navigate to: **Resources > EC2 > aws_instance** → `metadata_options`

| Argument | Type | Valid Values |
|----------|------|--------------|
| `http_endpoint` | | |
| `http_tokens` | | |
| `http_put_response_hop_limit` | | |
| `instance_metadata_tags` | | |

**Question**: The `metadata_options` block is an example of which structural type?

**Your answer**: 


---

## Hunt 5: Type Conversion Functions

Navigate to: [Terraform Functions Documentation](https://developer.hashicorp.com/terraform/language/functions)

| Conversion Needed | Function Name |
|-------------------|---------------|
| String to number | |
| List to set | |
| Number to string | |

---

## Reflection Questions

### What documentation section was hardest to navigate?



### What's one thing you learned about types that surprised you?



### How will understanding types help you debug Terraform errors?



---

## Bonus: Find a Type Bug

Look at this code snippet. What's wrong with it?

```hcl
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  vpc_security_group_ids = aws_security_group.web.id
  
  tags = {
    Name = "web-server"
    Port = 80
  }
}
```

**Issues found**:
1. 
2. 

**How to fix them**:
1. 
2. 
