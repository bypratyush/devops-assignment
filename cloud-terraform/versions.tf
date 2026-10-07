terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State stays local (terraform.tfstate next to this file). For a team you
  # would move it to S3 with locking, e.g.:
  #
  # backend "s3" {
  #   bucket       = "pratyush-24bcs10238-tfstate"
  #   key          = "session19/terraform.tfstate"
  #   region       = "ap-south-1"
  #   use_lockfile = true
  # }
}
