# Values for this run. No secrets here - credentials never go in tfvars.
# To deploy to a real AWS account: set use_localstack = false and make sure
# `aws sts get-caller-identity` works in the same shell.

aws_region     = "ap-south-1"
use_localstack = true

bucket_name = "pratyush-24bcs10238-tf-s3-demo"
environment = "dev"
owner       = "Pratyush Mohanty"
roll_no     = "24BCS10238"

noncurrent_version_days = 30
logs_to_ia_days         = 30
