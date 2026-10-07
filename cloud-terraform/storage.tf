# Private bucket for application artifacts and instance logs.

resource "aws_s3_bucket" "artifacts" {
  bucket        = var.bucket_name
  force_destroy = true # demo only: lets destroy remove a bucket that has logs in it

  tags = { Name = var.bucket_name }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# A release artifact, so the bucket has a real purpose from day one.
resource "aws_s3_object" "release_notes" {
  bucket       = aws_s3_bucket.artifacts.id
  key          = "releases/v1/RELEASE.txt"
  content_type = "text/plain"
  content      = "${var.project_name} v1 - VPC ${var.vpc_cidr}, instance type ${var.instance_type}\n"

  depends_on = [aws_s3_bucket_server_side_encryption_configuration.artifacts]
}
