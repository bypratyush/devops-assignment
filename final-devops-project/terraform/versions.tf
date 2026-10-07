terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Local state for the LocalStack run. For the real account this would move to
  # an S3 backend with a lock file, e.g.:
  #
  # backend "s3" {
  #   bucket       = "pratyush-24bcs10238-tfstate"
  #   key          = "final-project/terraform.tfstate"
  #   region       = "ap-south-1"
  #   use_lockfile = true
  # }
}
