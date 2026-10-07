terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# One switch decides where this runs:
#   use_localstack = true  -> every API call goes to LocalStack on localhost:4566
#   use_localstack = false -> normal AWS credential chain (env vars, ~/.aws, SSO)
provider "aws" {
  region = var.aws_region

  # LocalStack accepts any key pair. On real AWS these stay null so the
  # provider falls back to the usual credential chain - no keys in code.
  access_key = var.use_localstack ? "test" : null
  secret_key = var.use_localstack ? "test" : null

  # No EC2 instance metadata service on a laptop, so don't wait for it.
  skip_metadata_api_check = var.use_localstack

  # LocalStack serves S3 on one host, so use http://host/bucket/key URLs
  # instead of http://bucket.host/key (virtual-hosted style).
  s3_use_path_style = var.use_localstack

  # Every service the provider talks to needs an override, or that call
  # silently goes to real AWS. Provider 6.x reads bucket tags through the
  # S3 Control API, which is why s3control is here (see README notes).
  dynamic "endpoints" {
    for_each = var.use_localstack ? [var.localstack_endpoint] : []
    content {
      s3        = endpoints.value
      s3control = endpoints.value
      sts       = endpoints.value
    }
  }

  # Added to every resource that supports tags.
  default_tags {
    tags = {
      Owner     = var.owner
      RollNo    = var.roll_no
      ManagedBy = "Terraform"
      Project   = "session18-terraform-s3-demo"
    }
  }
}
