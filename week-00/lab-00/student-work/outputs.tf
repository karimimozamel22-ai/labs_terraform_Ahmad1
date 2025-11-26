# Output the bucket name
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.test_bucket.id
}
# Output the bucket ARN
output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.test_bucket.arn
}
