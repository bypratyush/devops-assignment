# Values used for the recorded run (LocalStack). No secrets in here.

aws_region     = "ap-south-1"
use_localstack = true

project_name = "s19-web"
environment  = "dev"
owner        = "Pratyush Mohanty"
roll_no      = "24BCS10238"

vpc_cidr            = "10.20.0.0/16"
public_subnet_cidr  = "10.20.1.0/24"
private_subnet_cidr = "10.20.2.0/24"

# Documentation range (TEST-NET-3) stands in for "my IP" on LocalStack.
# On real AWS put your own public IP here as /32.
ssh_allowed_cidr = "203.0.113.10/32"

instance_type = "t3.micro"

bucket_name = "pratyush-24bcs10238-s19-artifacts"
