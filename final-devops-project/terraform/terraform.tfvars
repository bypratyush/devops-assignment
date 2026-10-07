# Values used for the recorded run (LocalStack). No secrets in here.

aws_region     = "ap-south-1"
use_localstack = true

project_name = "lostfound"
environment  = "prod"
owner        = "Pratyush Mohanty"
roll_no      = "24BCS10238"

vpc_cidr             = "10.20.0.0/16"
availability_zones   = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]

enable_eks = false

backup_bucket_name = "pratyush-24bcs10238-lostfound-db-backups"
