# use_localstack = true  -> all API calls go to LocalStack (localhost:4566)
# use_localstack = false -> real AWS, using the normal credential chain
provider "aws" {
  region = var.aws_region

  # Dummy keys for LocalStack only. On real AWS these stay null and the
  # provider uses env vars / ~/.aws/credentials / SSO instead.
  access_key = var.use_localstack ? "test" : null
  secret_key = var.use_localstack ? "test" : null

  skip_metadata_api_check = var.use_localstack
  s3_use_path_style       = var.use_localstack

  # Each service the provider calls needs its own override. Anything missing
  # here would silently go to the real AWS endpoint instead.
  dynamic "endpoints" {
    for_each = var.use_localstack ? [var.localstack_endpoint] : []
    content {
      ec2       = endpoints.value
      iam       = endpoints.value
      s3        = endpoints.value
      s3control = endpoints.value
      ssm       = endpoints.value
      sts       = endpoints.value
    }
  }

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner
      RollNo      = var.roll_no
      ManagedBy   = "Terraform"
    }
  }
}
