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
  default     = "http://localhost:4567"
}

# ---- naming and tags -------------------------------------------------------

variable "project_name" {
  description = "Prefix for resource names and the Project tag."
  type        = string
  default     = "lostfound"
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Owner tag."
  type        = string
}

variable "roll_no" {
  description = "Roll number tag; also keeps the bucket name globally unique."
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

variable "availability_zones" {
  description = "Two AZs. EKS refuses a cluster whose subnets sit in only one AZ."
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "EKS needs subnets in at least two availability zones."
  }
}

variable "public_subnet_cidrs" {
  description = "One public subnet per AZ (load balancers, NAT gateway)."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "One private subnet per AZ (worker nodes, no public IPs)."
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

# ---- EKS -------------------------------------------------------------------

variable "enable_eks" {
  description = "Create the EKS cluster, node group and NAT gateway. LocalStack Community has no EKS API, so the recorded apply uses false."
  type        = bool
  default     = false
}

variable "eks_version" {
  description = "Kubernetes version for the control plane."
  type        = string
  default     = "1.35"
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_scaling" {
  description = "Managed node group size."
  type = object({
    min     = number
    desired = number
    max     = number
  })
  default = { min = 1, desired = 2, max = 3 }

  validation {
    condition     = var.node_scaling.min <= var.node_scaling.desired && var.node_scaling.desired <= var.node_scaling.max
    error_message = "node_scaling must satisfy min <= desired <= max."
  }
}

# ---- storage ---------------------------------------------------------------

variable "backup_bucket_name" {
  description = "Globally unique name for the Postgres backup bucket."
  type        = string
}

variable "backup_noncurrent_days" {
  description = "Old (overwritten or deleted) backup versions are kept this many days."
  type        = number
  default     = 30
}
