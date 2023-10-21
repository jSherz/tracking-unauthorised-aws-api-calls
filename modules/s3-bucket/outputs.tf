output "name" {
  description = "Bucket name."
  value       = aws_s3_bucket.this.bucket
}

output "arn" {
  description = "Bucket ARN."
  value       = aws_s3_bucket.this.arn
}

output "domain_name" {
  value = aws_s3_bucket.this.bucket_domain_name
}

output "regional_domain_name" {
  value = aws_s3_bucket.this.bucket_regional_domain_name
}
