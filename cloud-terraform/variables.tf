# ---- where to deploy ------------------------------------------------------

variable "aws_region" {
  description = "AWS region for every resource."
  type        = string
  default     = "ap-south-1"
}

variable "use_localstack" {
  description = "true = LocalStack on localhost, false = real AWS."
  type        = bool
  default     = true
}

variable "localstack_endpoint" {
  description = "LocalStack edge URL (ignored when use_localstack = false)."
  type        = string
  default     = "http://localhost:4566"
}

# ---- naming and tags -------------------------------------------------------

variable "project_name" {
  description = "Prefix for resource names and the Project tag."
  type        = string
  default     = "s19-web"
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag."
  type        = string
}

variable "roll_no" {
  description = "Roll number tag; also makes the bucket name unique."
  type        = string
}

# ---- network ---------------------------------------------------------------

variable "vpc_cidr" {
  description = "Address space for the whole VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block, e.g. 10.20.0.0/16."
  }
}

variable "public_subnet_cidr" {
  description = "Public subnet (has a route to the internet gateway)."
  type        = string
  default     = "10.20.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Private subnet (no route to the internet)."
  type        = string
  default     = "10.20.2.0/24"
}

variable "ssh_allowed_cidr" {
  description = "Only this CIDR may SSH to the instance. Use your own IP as x.x.x.x/32."
  type        = string

  validation {
    condition     = var.ssh_allowed_cidr != "0.0.0.0/0"
    error_message = "Refusing to open SSH to the whole internet - use your own IP/32."
  }
}

# ---- compute ---------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance size. t3.micro is free-tier eligible in ap-south-1."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Pin a specific AMI. Leave null to use the latest Amazon Linux 2023."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Existing EC2 key pair for SSH. null = no key (use SSM Session Manager)."
  type        = string
  default     = null
}

# ---- storage ---------------------------------------------------------------

variable "bucket_name" {
  description = "Globally unique name for the artifacts bucket."
  type        = string
}
