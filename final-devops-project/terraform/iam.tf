# Two roles, each trusted by exactly one AWS service, with only AWS managed
# policies attached. They are created even with enable_eks = false: IAM is
# free and a role that already exists makes the later EKS apply quicker.

data "aws_iam_policy_document" "eks_assume" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ---- control plane ---------------------------------------------------------

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.project_name}-eks-cluster"
  description        = "Assumed by the EKS control plane"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ---- worker nodes ----------------------------------------------------------

resource "aws_iam_role" "eks_nodes" {
  name               = "${var.project_name}-eks-nodes"
  description        = "Instance role of the managed node group"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "eks_nodes" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",          # join the cluster
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",               # VPC CNI assigns pod IPs
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", # pull add-on images from ECR
  ])
  role       = aws_iam_role.eks_nodes.name
  policy_arn = each.value
}
