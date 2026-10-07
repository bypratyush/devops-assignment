variable "aws_region" {
  description = "AWS region for the bucket."
  type        = string
  default     = "ap-south-1"
}

variable "use_localstack" {
  description = "true = send all API calls to LocalStack, false = real AWS."
  type        = bool
  default     = true
}

variable "localstack_endpoint" {
  description = "LocalStack edge URL (only used when use_localstack = true)."
  type        = string
  default     = "http://localhost:4566"
}

variable "bucket_name" {
  description = "Globally unique bucket name: 3-63 chars, lowercase, digits, hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket names must be 3-63 characters of lowercase letters, digits and hyphens, and must not start or end with a hyphen."
  }
}

variable "environment" {
  description = "Environment label used in tags."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Who owns these resources (tag)."
  type        = string
}

variable "roll_no" {
  description = "Roll number (tag, and part of the bucket name)."
  type        = string
}

variable "noncurrent_version_days" {
  description = "Delete old (noncurrent) object versions after this many days."
  type        = number
  default     = 30
}

variable "logs_to_ia_days" {
  description = "Move objects under logs/ to STANDARD_IA after this many days (minimum 30)."
  type        = number
  default     = 30
}
