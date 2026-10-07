output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet (route to the IGW)."
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet (no internet route)."
  value       = aws_subnet.private.id
}

output "availability_zone" {
  description = "AZ both subnets were placed in."
  value       = aws_subnet.public.availability_zone
}

output "internet_gateway_id" {
  description = "Internet gateway attached to the VPC."
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "Route table with the 0.0.0.0/0 -> IGW route."
  value       = aws_route_table.public.id
}

output "security_group_id" {
  description = "Security group on the web instance."
  value       = aws_security_group.web.id
}

output "ami_id" {
  description = "AMI the instance was launched from."
  value       = aws_instance.web.ami
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP (changes on stop/start - use an Elastic IP for a fixed one)."
  value       = aws_instance.web.public_ip
}

output "instance_private_ip" {
  description = "Private IP inside the public subnet."
  value       = aws_instance.web.private_ip
}

output "web_url" {
  description = "Where nginx answers once user_data has finished."
  value       = "http://${aws_instance.web.public_ip}/"
}

output "artifacts_bucket" {
  description = "Name of the artifacts bucket."
  value       = aws_s3_bucket.artifacts.bucket
}

output "instance_role_arn" {
  description = "IAM role the instance runs as."
  value       = aws_iam_role.web.arn
}
