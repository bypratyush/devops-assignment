# The bucket itself. Since AWS provider v4 each bucket setting is its own
# resource (versioning, encryption, ...), all pointing back at this one.
resource "aws_s3_bucket" "demo" {
  bucket = var.bucket_name

  # Lets `terraform destroy` empty the bucket first (including old versions).
  # Fine for a demo; on a bucket with real data you would leave this false.
  force_destroy = true

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

# Keep every version of every object - an overwrite or delete becomes recoverable.
resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt objects at rest with S3-managed keys (SSE-S3, AES-256).
resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Belt and braces: block every way of making this bucket or its objects public,
# even if someone later adds a careless ACL or bucket policy.
resource "aws_s3_bucket_public_access_block" "demo" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning without a lifecycle rule means old versions pile up and are billed
# forever, so the two go together.
resource "aws_s3_bucket_lifecycle_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {} # whole bucket

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "logs-to-infrequent-access"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    transition {
      days          = var.logs_to_ia_days
      storage_class = "STANDARD_IA"
    }
  }

  # A lifecycle rule on a versioned bucket must be applied after versioning.
  depends_on = [aws_s3_bucket_versioning.demo]
}

# One object, so there is something real to read back with the AWS CLI.
resource "aws_s3_object" "welcome" {
  bucket       = aws_s3_bucket.demo.id
  key          = "welcome.txt"
  content_type = "text/plain"
  content      = <<-EOT
    Bucket ${var.bucket_name}
    Created by Terraform for ${var.owner} (${var.roll_no}), session 18.
  EOT

  # Upload only once encryption is configured, so the object is encrypted
  # by the bucket default rather than by luck of timing.
  depends_on = [aws_s3_bucket_server_side_encryption_configuration.demo]
}
