# EKS control plane + one managed node group, both behind enable_eks.
# LocalStack Community has no EKS API, so the recorded apply runs with
# enable_eks = false; `terraform plan -var enable_eks=true` shows what a real
# account would get.

resource "aws_eks_cluster" "main" {
  count    = var.enable_eks ? 1 : 0
  name     = "${var.project_name}-eks"
  version  = var.eks_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    # control plane ENIs go in all four subnets; nodes only in the private ones
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

# A launch template is the only way to give managed nodes our own security
# group. Once it sets security groups EKS stops adding the cluster SG by
# itself, so both are listed.
resource "aws_launch_template" "nodes" {
  count       = var.enable_eks ? 1 : 0
  name_prefix = "${var.project_name}-nodes-"

  vpc_security_group_ids = [
    aws_security_group.nodes.id,
    aws_eks_cluster.main[0].vpc_config[0].cluster_security_group_id,
  ]

  metadata_options {
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 2          # pods on the node still reach IMDS
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-eks-node" }
  }
}

resource "aws_eks_node_group" "main" {
  count           = var.enable_eks ? 1 : 0
  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${var.project_name}-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  instance_types = var.node_instance_types

  scaling_config {
    min_size     = var.node_scaling.min
    desired_size = var.node_scaling.desired
    max_size     = var.node_scaling.max
  }

  update_config {
    max_unavailable = 1 # rolling node upgrades, one at a time
  }

  launch_template {
    id      = aws_launch_template.nodes[0].id
    version = aws_launch_template.nodes[0].latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes,
    aws_route.private_nat, # nodes must reach the internet before they join
  ]
}
