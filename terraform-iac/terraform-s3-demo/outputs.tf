output "bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "ARN of the bucket (used in IAM policies)."
  value       = aws_s3_bucket.demo.arn
}

output "bucket_region" {
  description = "Region the bucket lives in."
  value       = aws_s3_bucket.demo.region
}

output "versioning_status" {
  description = "Versioning state as reported back by the API."
  value       = aws_s3_bucket_versioning.demo.versioning_configuration[0].status
}

output "welcome_object_uri" {
  description = "S3 URI of the uploaded object."
  value       = "s3://${aws_s3_bucket.demo.bucket}/${aws_s3_object.welcome.key}"
}

output "welcome_object_etag" {
  description = "ETag (MD5 for a simple upload) of the uploaded object."
  value       = aws_s3_object.welcome.etag
}
