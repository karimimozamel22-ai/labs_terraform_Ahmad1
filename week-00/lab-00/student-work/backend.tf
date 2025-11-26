# Backend configuration for remote state storage
terraform {
  backend "s3" {
    bucket         = "terraform-state-992885815587"  # Replace with your actual account ID
    key            = "week-00/lab-00/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true  # Native S3 locking (Terraform 1.9+)
  }
}
