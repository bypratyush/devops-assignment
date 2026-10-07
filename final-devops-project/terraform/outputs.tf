output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnets, one per AZ."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnets, one per AZ (worker nodes)."
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "Internet gateway of the public route table."
  value       = aws_internet_gateway.main.id
}

output "node_security_group_id" {
  description = "Security group of the EKS worker nodes."
  value       = aws_security_group.nodes.id
}

output "eks_cluster_role_arn" {
  description = "IAM role assumed by the EKS control plane."
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "IAM role of the worker nodes."
  value       = aws_iam_role.eks_nodes.arn
}

output "backup_bucket" {
  description = "S3 bucket for Postgres backups."
  value       = aws_s3_bucket.backups.bucket
}

output "eks_cluster_name" {
  description = "EKS cluster name (null while enable_eks = false)."
  value       = one(aws_eks_cluster.main[*].name)
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API endpoint (null while enable_eks = false)."
  value       = one(aws_eks_cluster.main[*].endpoint)
}

output "kubeconfig_command" {
  description = "Run this after a real apply to point kubectl at the cluster."
  value       = var.enable_eks ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main[0].name}" : "enable_eks = false - no cluster created"
}
