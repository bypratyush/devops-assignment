# Terraform - AWS Infrastructure for Campus Lost & Found - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-08.

```text

==============================================================
STEP 0 - LocalStack on http://localhost:4567 (container localstack-final)
==============================================================
localstack-final  localstack/localstack:4.14.0  Up 10 minutes (healthy)  127.0.0.1:4567->4566/tcp
LocalStack 4.14.0 community
  ec2  running
  iam  running
  s3   running
  sts  running
  eks  not in this edition

==============================================================
STEP 1 - Tools and files
==============================================================
Terraform v1.16.4
aws-cli/2.35.15 Python/3.14.6 Darwin/25.5.0 source/arm64
use_localstack = true, enable_eks = false
eks.tf
iam.tf
outputs.tf
providers.tf
storage.tf
variables.tf
versions.tf
vpc.tf

==============================================================
STEP 2 - terraform init
==============================================================
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v6.67.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

==============================================================
STEP 3 - terraform fmt -check  and  terraform validate
==============================================================
fmt: all files already in canonical format
Success! The configuration is valid.


==============================================================
STEP 4 - terraform plan -out=tfplan  (enable_eks = false: one line per resource)
==============================================================
  # aws_iam_role.eks_cluster will be created
  # aws_iam_role.eks_nodes will be created
  # aws_iam_role_policy_attachment.eks_cluster will be created
  # aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"] will be created
  # aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"] will be created
  # aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"] will be created
  # aws_internet_gateway.main will be created
  # aws_route_table.private will be created
  # aws_route_table.public will be created
  # aws_route_table_association.private[0] will be created
  # aws_route_table_association.private[1] will be created
  # aws_route_table_association.public[0] will be created
  # aws_route_table_association.public[1] will be created
  # aws_s3_bucket.backups will be created
  # aws_s3_bucket_lifecycle_configuration.backups will be created
  # aws_s3_bucket_public_access_block.backups will be created
  # aws_s3_bucket_server_side_encryption_configuration.backups will be created
  # aws_s3_bucket_versioning.backups will be created
  # aws_security_group.nodes will be created
  # aws_subnet.private[0] will be created
  # aws_subnet.private[1] will be created
  # aws_subnet.public[0] will be created
  # aws_subnet.public[1] will be created
  # aws_vpc.main will be created
  # aws_vpc_security_group_egress_rule.nodes_all will be created
  # aws_vpc_security_group_ingress_rule.nodes_kubelet will be created
  # aws_vpc_security_group_ingress_rule.nodes_self will be created
  # aws_vpc_security_group_ingress_rule.nodes_webhooks will be created
Plan: 28 to add, 0 to change, 0 to destroy.

==============================================================
STEP 5 - terraform apply tfplan
==============================================================
aws_iam_role.eks_cluster: Creating...
aws_iam_role.eks_nodes: Creating...
aws_vpc.main: Creating...
aws_s3_bucket.backups: Creating...
aws_iam_role.eks_nodes: Creation complete after 0s [id=lostfound-eks-nodes]
aws_iam_role.eks_cluster: Creation complete after 0s [id=lostfound-eks-cluster]
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"]: Creating...
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]: Creating...
aws_iam_role_policy_attachment.eks_cluster: Creating...
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"]: Creating...
aws_vpc.main: Creation complete after 0s [id=vpc-cd9d083b04edf7455]
aws_internet_gateway.main: Creating...
aws_route_table.private: Creating...
aws_subnet.public[0]: Creating...
aws_security_group.nodes: Creating...
aws_subnet.public[1]: Creating...
aws_iam_role_policy_attachment.eks_cluster: Creation complete after 0s [id=lostfound-eks-cluster/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy]
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"]: Creation complete after 0s [id=lostfound-eks-nodes/arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy]
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]: Creation complete after 0s [id=lostfound-eks-nodes/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly]
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"]: Creation complete after 0s [id=lostfound-eks-nodes/arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy]
aws_internet_gateway.main: Creation complete after 0s [id=igw-52cfa869f5ef322e9]
aws_subnet.private[0]: Creating...
aws_subnet.private[1]: Creating...
aws_route_table.public: Creating...
aws_s3_bucket.backups: Creation complete after 0s [id=pratyush-24bcs10238-lostfound-db-backups]
aws_s3_bucket_versioning.backups: Creating...
aws_s3_bucket_public_access_block.backups: Creating...
aws_s3_bucket_server_side_encryption_configuration.backups: Creating...
aws_subnet.private[1]: Creation complete after 0s [id=subnet-c1a891a4d3b234e19]
aws_subnet.private[0]: Creation complete after 0s [id=subnet-df6f0ff5fcc2cda66]
aws_s3_bucket_public_access_block.backups: Creation complete after 0s [id=pratyush-24bcs10238-lostfound-db-backups]
aws_s3_bucket_server_side_encryption_configuration.backups: Creation complete after 0s [id=pratyush-24bcs10238-lostfound-db-backups]
aws_route_table.private: Creation complete after 0s [id=rtb-9886ca5531637d138]
aws_route_table_association.private[0]: Creating...
aws_route_table_association.private[1]: Creating...
aws_route_table_association.private[0]: Creation complete after 0s [id=rtbassoc-c9e1ffd182271a332]
aws_route_table_association.private[1]: Creation complete after 0s [id=rtbassoc-78ceb3a2e1700c6d7]
aws_security_group.nodes: Creation complete after 0s [id=sg-0f65cbe4a101affb6]
aws_vpc_security_group_ingress_rule.nodes_webhooks: Creating...
aws_vpc_security_group_ingress_rule.nodes_kubelet: Creating...
aws_vpc_security_group_egress_rule.nodes_all: Creating...
aws_vpc_security_group_ingress_rule.nodes_self: Creating...
aws_vpc_security_group_ingress_rule.nodes_self: Creation complete after 0s [id=sgr-8f333b9b4c8ff5103]
aws_vpc_security_group_egress_rule.nodes_all: Creation complete after 0s [id=sgr-76bfd53f225db0428]
aws_vpc_security_group_ingress_rule.nodes_webhooks: Creation complete after 0s [id=sgr-9da6ae291c7452a78]
aws_vpc_security_group_ingress_rule.nodes_kubelet: Creation complete after 0s [id=sgr-aa0bee0d7387acd61]
aws_route_table.public: Creation complete after 0s [id=rtb-a8711a26e517ed9d1]
aws_s3_bucket_versioning.backups: Creation complete after 1s [id=pratyush-24bcs10238-lostfound-db-backups]
aws_s3_bucket_lifecycle_configuration.backups: Creating...
aws_subnet.public[1]: Still creating... [00m10s elapsed]
aws_subnet.public[0]: Still creating... [00m10s elapsed]
aws_subnet.public[0]: Creation complete after 10s [id=subnet-b80e5c05afa206880]
aws_subnet.public[1]: Creation complete after 10s [id=subnet-c5b65e76e386a14bd]
aws_route_table_association.public[1]: Creating...
aws_route_table_association.public[0]: Creating...
aws_route_table_association.public[0]: Creation complete after 0s [id=rtbassoc-24f50e9fe3ed15276]
aws_route_table_association.public[1]: Creation complete after 0s [id=rtbassoc-dd42b5350455f222a]
aws_s3_bucket_lifecycle_configuration.backups: Still creating... [00m10s elapsed]
aws_s3_bucket_lifecycle_configuration.backups: Still creating... [00m20s elapsed]
aws_s3_bucket_lifecycle_configuration.backups: Still creating... [00m30s elapsed]
aws_s3_bucket_lifecycle_configuration.backups: Still creating... [00m40s elapsed]
aws_s3_bucket_lifecycle_configuration.backups: Still creating... [00m50s elapsed]
aws_s3_bucket_lifecycle_configuration.backups: Creation complete after 55s [id=pratyush-24bcs10238-lostfound-db-backups]

Apply complete! Resources: 28 added, 0 changed, 0 destroyed.

Outputs:

backup_bucket = "pratyush-24bcs10238-lostfound-db-backups"
eks_cluster_role_arn = "arn:aws:iam::000000000000:role/lostfound-eks-cluster"
eks_node_role_arn = "arn:aws:iam::000000000000:role/lostfound-eks-nodes"
internet_gateway_id = "igw-52cfa869f5ef322e9"
kubeconfig_command = "enable_eks = false - no cluster created"
node_security_group_id = "sg-0f65cbe4a101affb6"
private_subnet_ids = [
  "subnet-df6f0ff5fcc2cda66",
  "subnet-c1a891a4d3b234e19",
]
public_subnet_ids = [
  "subnet-b80e5c05afa206880",
  "subnet-c5b65e76e386a14bd",
]
vpc_id = "vpc-cd9d083b04edf7455"

==============================================================
STEP 6 - terraform output
==============================================================
backup_bucket = "pratyush-24bcs10238-lostfound-db-backups"
eks_cluster_role_arn = "arn:aws:iam::000000000000:role/lostfound-eks-cluster"
eks_node_role_arn = "arn:aws:iam::000000000000:role/lostfound-eks-nodes"
internet_gateway_id = "igw-52cfa869f5ef322e9"
kubeconfig_command = "enable_eks = false - no cluster created"
node_security_group_id = "sg-0f65cbe4a101affb6"
private_subnet_ids = [
  "subnet-df6f0ff5fcc2cda66",
  "subnet-c1a891a4d3b234e19",
]
public_subnet_ids = [
  "subnet-b80e5c05afa206880",
  "subnet-c5b65e76e386a14bd",
]
vpc_id = "vpc-cd9d083b04edf7455"

==============================================================
STEP 7 - terraform state list
==============================================================
data.aws_iam_policy_document.ec2_assume
data.aws_iam_policy_document.eks_assume
aws_iam_role.eks_cluster
aws_iam_role.eks_nodes
aws_iam_role_policy_attachment.eks_cluster
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"]
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"]
aws_internet_gateway.main
aws_route_table.private
aws_route_table.public
aws_route_table_association.private[0]
aws_route_table_association.private[1]
aws_route_table_association.public[0]
aws_route_table_association.public[1]
aws_s3_bucket.backups
aws_s3_bucket_lifecycle_configuration.backups
aws_s3_bucket_public_access_block.backups
aws_s3_bucket_server_side_encryption_configuration.backups
aws_s3_bucket_versioning.backups
aws_security_group.nodes
aws_subnet.private[0]
aws_subnet.private[1]
aws_subnet.public[0]
aws_subnet.public[1]
aws_vpc.main
aws_vpc_security_group_egress_rule.nodes_all
aws_vpc_security_group_ingress_rule.nodes_kubelet
aws_vpc_security_group_ingress_rule.nodes_self
aws_vpc_security_group_ingress_rule.nodes_webhooks

30 addresses in state (incl. data sources)

==============================================================
STEP 8 - Verify with the AWS CLI (asking the API, not Terraform)
==============================================================
$ aws ec2 describe-vpcs
-------------------------------------------------------------------------
|                             DescribeVpcs                              |
+--------------+----------------+------------+--------------------------+
|     Cidr     |     Name       |   State    |          VpcId           |
+--------------+----------------+------------+--------------------------+
|  10.20.0.0/16|  lostfound-vpc |  available |  vpc-cd9d083b04edf7455   |
+--------------+----------------+------------+--------------------------+
$ aws ec2 describe-subnets
-------------------------------------------------------------------------------------------------
|                                        DescribeSubnets                                        |
+-------------+----------------+----------------------------+----------------------+------------+
|     AZ      |     Cidr       |            Id              |        Name          | PublicIp   |
+-------------+----------------+----------------------------+----------------------+------------+
|  ap-south-1a|  10.20.1.0/24  |  subnet-b80e5c05afa206880  |  lostfound-public-a  |  True      |
|  ap-south-1a|  10.20.11.0/24 |  subnet-df6f0ff5fcc2cda66  |  lostfound-private-a |  False     |
|  ap-south-1b|  10.20.12.0/24 |  subnet-c1a891a4d3b234e19  |  lostfound-private-b |  False     |
|  ap-south-1b|  10.20.2.0/24  |  subnet-c5b65e76e386a14bd  |  lostfound-public-b  |  True      |
+-------------+----------------+----------------------------+----------------------+------------+
$ aws ec2 describe-route-tables  (routes per table)
------------------------------------------------------------------------------------------------
|                                      DescribeRouteTables                                     |
+-----------------------+-----------------------------------------------------------+----------+
|         Name          |                          Routes                           | Subnets  |
+-----------------------+-----------------------------------------------------------+----------+
|  lostfound-private-rt |  10.20.0.0/16-> local                                     |  2       |
|  lostfound-public-rt  |  10.20.0.0/16-> local, 0.0.0.0/0-> igw-52cfa869f5ef322e9  |  2       |
+-----------------------+-----------------------------------------------------------+----------+
$ aws ec2 describe-security-group-rules  (worker node SG)
--------------------------------------------------------------------------------------------------------------------------------------
|                                                     DescribeSecurityGroupRules                                                     |
+----------------------------------------------------------------------+---------+--------+--------+-----------------------+---------+
|                                 Desc                                 | Egress  | From   | Proto  |        Source         |   To    |
+----------------------------------------------------------------------+---------+--------+--------+-----------------------+---------+
|  Image pulls, EKS API, S3 backups                                    |  True   |  -1    |  -1    |  0.0.0.0/0            |  -1     |
|  None                                                                |  False  |  -1    |  -1    |  sg-0f65cbe4a101affb6 |  -1     |
|  Admission webhooks (e.g. ingress-nginx) called by the control plane |  False  |  443   |  tcp   |  10.20.0.0/16         |  443    |
|  kubelet API from the control plane ENIs in the VPC                  |  False  |  10250 |  tcp   |  10.20.0.0/16         |  10250  |
+----------------------------------------------------------------------+---------+--------+--------+-----------------------+---------+
$ aws iam list-attached-role-policies  (both EKS roles)
lostfound-eks-cluster:
  arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
lostfound-eks-nodes:
  arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
  arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
  arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
$ aws s3api get-bucket-versioning --bucket pratyush-24bcs10238-lostfound-db-backups
{
    "Status": "Enabled"
}
$ aws s3api get-bucket-encryption --bucket pratyush-24bcs10238-lostfound-db-backups
{
    "SSEAlgorithm": "AES256"
}
$ aws s3api get-public-access-block --bucket pratyush-24bcs10238-lostfound-db-backups
{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
}
--- a backup round trip: two uploads of the same key = two versions
-------------------------------------------
|           ListObjectVersions            |
+----------------------+---------+--------+
|          Key         | Latest  | Size   |
+----------------------+---------+--------+
|  daily/lostfound.sql |  True   |  22    |
|  daily/lostfound.sql |  False  |  22    |
+----------------------+---------+--------+

==============================================================
STEP 9 - Idempotency: a second plan right after apply must be empty
==============================================================
plan exit code: 0  (0 = no changes, 2 = changes)
No changes. Your infrastructure matches the configuration.

==============================================================
STEP 10 - terraform plan -var enable_eks=true  (what a real account would get)
==============================================================
plan exit code: 0
  # aws_eip.nat[0] will be created
  # aws_eks_cluster.main[0] will be created
  # aws_eks_node_group.main[0] will be created
  # aws_launch_template.nodes[0] will be created
  # aws_nat_gateway.main[0] will be created
  # aws_route.private_nat[0] will be created
Plan: 6 to add, 0 to change, 0 to destroy.

--- aws_eks_cluster.main[0] and aws_eks_node_group.main[0], as plan prints them ---
  # aws_eks_cluster.main[0] will be created
  + resource "aws_eks_cluster" "main" {
      + arn                           = (known after apply)
      + bootstrap_self_managed_addons = true
      + certificate_authority         = (known after apply)
      + cluster_id                    = (known after apply)
      + created_at                    = (known after apply)
      + deletion_protection           = (known after apply)
      + enabled_cluster_log_types     = [
          + "api",
          + "audit",
          + "authenticator",
        ]
      + endpoint                      = (known after apply)
      + id                            = (known after apply)
      + identity                      = (known after apply)
      + name                          = "lostfound-eks"
      + platform_version              = (known after apply)
      + region                        = "ap-south-1"
      + role_arn                      = "arn:aws:iam::000000000000:role/lostfound-eks-cluster"
      + status                        = (known after apply)
      + version                       = "1.35"

      + access_config {
          + authentication_mode                         = "API"
          + bootstrap_cluster_creator_admin_permissions = true
        }

      + compute_config (known after apply)

      + control_plane_scaling_config (known after apply)

      + kube_api_server_config (known after apply)

      + kube_controller_manager_config (known after apply)

      + kube_scheduler_config (known after apply)

      + kubernetes_network_config (known after apply)

      + storage_config (known after apply)

      + upgrade_policy (known after apply)

      + vpc_config {
          + cluster_security_group_id = (known after apply)
          + control_plane_egress_mode = (known after apply)
          + endpoint_private_access   = true
          + endpoint_public_access    = true
          + public_access_cidrs       = (known after apply)
          + subnet_ids                = [
              + "subnet-b80e5c05afa206880",
              + "subnet-c1a891a4d3b234e19",
              + "subnet-c5b65e76e386a14bd",
              + "subnet-df6f0ff5fcc2cda66",
            ]
          + vpc_id                    = (known after apply)
        }
    }
  # aws_eks_node_group.main[0] will be created
  + resource "aws_eks_node_group" "main" {
      + ami_type               = "AL2023_x86_64_STANDARD"
      + arn                    = (known after apply)
      + capacity_type          = "ON_DEMAND"
      + cluster_name           = "lostfound-eks"
      + disk_size              = (known after apply)
      + id                     = (known after apply)
      + instance_types         = [
          + "t3.medium",
        ]
      + node_group_name        = "lostfound-nodes"
      + node_group_name_prefix = (known after apply)
      + node_role_arn          = "arn:aws:iam::000000000000:role/lostfound-eks-nodes"
      + region                 = "ap-south-1"
      + release_version        = (known after apply)
      + resources              = (known after apply)
      + status                 = (known after apply)
      + subnet_ids             = [
          + "subnet-c1a891a4d3b234e19",
          + "subnet-df6f0ff5fcc2cda66",
        ]
      + version                = (known after apply)

      + launch_template {
          + id      = (known after apply)
          + name    = (known after apply)
          + version = (known after apply)
        }

      + node_repair_config (known after apply)

      + scaling_config {
          + desired_size = 2
          + max_size     = 3
          + min_size     = 1
        }

      + update_config {
          + max_unavailable = 1
        }
    }

--- and why it is not applied here: LocalStack Community has no EKS API ---
$ aws eks list-clusters --endpoint-url http://localhost:4567

aws: [ERROR]: An error occurred (InternalFailure) when calling the ListClusters operation: The API for service eks is either not included in your current license plan or has not yet been emulated by LocalStack.

==============================================================
STEP 11 - terraform destroy
==============================================================
2 object versions deleted
data.aws_iam_policy_document.eks_assume: Reading...
data.aws_iam_policy_document.ec2_assume: Reading...
aws_vpc.main: Refreshing state... [id=vpc-cd9d083b04edf7455]
data.aws_iam_policy_document.ec2_assume: Read complete after 0s [id=2851119427]
data.aws_iam_policy_document.eks_assume: Read complete after 0s [id=1029077455]
aws_s3_bucket.backups: Refreshing state... [id=pratyush-24bcs10238-lostfound-db-backups]
aws_iam_role.eks_cluster: Refreshing state... [id=lostfound-eks-cluster]
aws_iam_role.eks_nodes: Refreshing state... [id=lostfound-eks-nodes]
aws_iam_role_policy_attachment.eks_cluster: Refreshing state... [id=lostfound-eks-cluster/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy]
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"]: Refreshing state... [id=lostfound-eks-nodes/arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy]
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]: Refreshing state... [id=lostfound-eks-nodes/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly]
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"]: Refreshing state... [id=lostfound-eks-nodes/arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy]
aws_internet_gateway.main: Refreshing state... [id=igw-52cfa869f5ef322e9]
aws_route_table.private: Refreshing state... [id=rtb-9886ca5531637d138]
aws_security_group.nodes: Refreshing state... [id=sg-0f65cbe4a101affb6]
aws_subnet.public[0]: Refreshing state... [id=subnet-b80e5c05afa206880]
aws_subnet.public[1]: Refreshing state... [id=subnet-c5b65e76e386a14bd]
aws_subnet.private[1]: Refreshing state... [id=subnet-c1a891a4d3b234e19]
aws_subnet.private[0]: Refreshing state... [id=subnet-df6f0ff5fcc2cda66]
aws_vpc_security_group_ingress_rule.nodes_kubelet: Refreshing state... [id=sgr-aa0bee0d7387acd61]
aws_vpc_security_group_ingress_rule.nodes_self: Refreshing state... [id=sgr-8f333b9b4c8ff5103]
aws_vpc_security_group_ingress_rule.nodes_webhooks: Refreshing state... [id=sgr-9da6ae291c7452a78]
aws_vpc_security_group_egress_rule.nodes_all: Refreshing state... [id=sgr-76bfd53f225db0428]
aws_route_table.public: Refreshing state... [id=rtb-a8711a26e517ed9d1]
aws_route_table_association.private[1]: Refreshing state... [id=rtbassoc-78ceb3a2e1700c6d7]
aws_route_table_association.private[0]: Refreshing state... [id=rtbassoc-c9e1ffd182271a332]
aws_route_table_association.public[1]: Refreshing state... [id=rtbassoc-dd42b5350455f222a]
aws_route_table_association.public[0]: Refreshing state... [id=rtbassoc-24f50e9fe3ed15276]
aws_s3_bucket_public_access_block.backups: Refreshing state... [id=pratyush-24bcs10238-lostfound-db-backups]
aws_s3_bucket_server_side_encryption_configuration.backups: Refreshing state... [id=pratyush-24bcs10238-lostfound-db-backups]
aws_s3_bucket_versioning.backups: Refreshing state... [id=pratyush-24bcs10238-lostfound-db-backups]
aws_s3_bucket_lifecycle_configuration.backups: Refreshing state... [id=pratyush-24bcs10238-lostfound-db-backups]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # aws_iam_role.eks_cluster will be destroyed
  - resource "aws_iam_role" "eks_cluster" {
      - arn                   = "arn:aws:iam::000000000000:role/lostfound-eks-cluster" -> null
      - assume_role_policy    = jsonencode(
            {
              - Statement = [
                  - {
                      - Action    = [
                          - "sts:TagSession",
                          - "sts:AssumeRole",
                        ]
                      - Effect    = "Allow"
                      - Principal = {
                          - Service = "eks.amazonaws.com"
                        }
                    },
                ]
              - Version   = "2012-10-17"
            }
        ) -> null
      - create_date           = "2026-10-07T18:56:47Z" -> null
      - description           = "Assumed by the EKS control plane" -> null
      - force_detach_policies = false -> null
      - id                    = "lostfound-eks-cluster" -> null
      - managed_policy_arns   = [
          - "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
        ] -> null
      - max_session_duration  = 3600 -> null
      - name                  = "lostfound-eks-cluster" -> null
      - path                  = "/" -> null
      - tags                  = {} -> null
      - tags_all              = {
          - "Environment" = "prod"
          - "ManagedBy"   = "Terraform"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "lostfound"
          - "RollNo"      = "24BCS10238"
        } -> null
      - unique_id             = "AROAQAAAAAAAK2W3OJFCT" -> null
        # (2 unchanged attributes hidden)
    }

  # aws_iam_role.eks_nodes will be destroyed
  - resource "aws_iam_role" "eks_nodes" {
      - arn                   = "arn:aws:iam::000000000000:role/lostfound-eks-nodes" -> null
      - assume_role_policy    = jsonencode(
            {
              - Statement = [
                  - {
                      - Action    = "sts:AssumeRole"
                      - Effect    = "Allow"
                      - Principal = {
                          - Service = "ec2.amazonaws.com"
                        }
                    },
                ]
              - Version   = "2012-10-17"
            }
        ) -> null
      - create_date           = "2026-10-07T18:56:47Z" -> null
      - description           = "Instance role of the managed node group" -> null
      - force_detach_policies = false -> null
      - id                    = "lostfound-eks-nodes" -> null
      - managed_policy_arns   = [
          - "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
          - "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
          - "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        ] -> null
      - max_session_duration  = 3600 -> null
      - name                  = "lostfound-eks-nodes" -> null
      - path                  = "/" -> null
      - tags                  = {} -> null
      - tags_all              = {
          - "Environment" = "prod"
          - "ManagedBy"   = "Terraform"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "lostfound"
          - "RollNo"      = "24BCS10238"
        } -> null
      - unique_id             = "AROAQAAAAAAAGN55ZTKAC" -> null
        # (2 unchanged attributes hidden)
    }

  # aws_iam_role_policy_attachment.eks_cluster will be destroyed
  - resource "aws_iam_role_policy_attachment" "eks_cluster" {
      - id         = "lostfound-eks-cluster/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" -> null
      - policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" -> null
      - role       = "lostfound-eks-cluster" -> null
    }

  # aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"] will be destroyed
  - resource "aws_iam_role_policy_attachment" "eks_nodes" {
      - id         = "lostfound-eks-nodes/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" -> null
      - policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" -> null
      - role       = "lostfound-eks-nodes" -> null
    }

  # aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"] will be destroyed
  - resource "aws_iam_role_policy_attachment" "eks_nodes" {
      - id         = "lostfound-eks-nodes/arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" -> null
      - policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" -> null
      - role       = "lostfound-eks-nodes" -> null
    }

  # aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"] will be destroyed
  - resource "aws_iam_role_policy_attachment" "eks_nodes" {
      - id         = "lostfound-eks-nodes/arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" -> null
      - policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" -> null
      - role       = "lostfound-eks-nodes" -> null
    }

  # aws_internet_gateway.main will be destroyed
  - resource "aws_internet_gateway" "main" {
      - arn      = "arn:aws:ec2:ap-south-1:000000000000:internet-gateway/igw-52cfa869f5ef322e9" -> null
      - id       = "igw-52cfa869f5ef322e9" -> null
      - owner_id = "000000000000" -> null
      - region   = "ap-south-1" -> null
      - tags     = {
          - "Name" = "lostfound-igw"
        } -> null
      - tags_all = {
          - "Environment" = "prod"
          - "ManagedBy"   = "Terraform"
          - "Name"        = "lostfound-igw"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "lostfound"
          - "RollNo"      = "24BCS10238"
        } -> null
      - vpc_id   = "vpc-cd9d083b04edf7455" -> null
    }

  # aws_route_table.private will be destroyed
  - resource "aws_route_table" "private" {
      - arn              = "arn:aws:ec2:ap-south-1:000000000000:route-table/rtb-9886ca5531637d138" -> null
      - id               = "rtb-9886ca5531637d138" -> null
      - owner_id         = "000000000000" -> null
      - propagating_vgws = [] -> null
      - region           = "ap-south-1" -> null
      - route            = [] -> null
      - tags             = {
          - "Name" = "lostfound-private-rt"
        } -> null
      - tags_all         = {
          - "Environment" = "prod"
          - "ManagedBy"   = "Terraform"
          - "Name"        = "lostfound-private-rt"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "lostfound"
          - "RollNo"      = "24BCS10238"
        } -> null
      - vpc_id           = "vpc-cd9d083b04edf7455" -> null
    }

  # aws_route_table.public will be destroyed
  - resource "aws_route_table" "public" {
      - arn              = "arn:aws:ec2:ap-south-1:000000000000:route-table/rtb-a8711a26e517ed9d1" -> null
      - id               = "rtb-a8711a26e517ed9d1" -> null
      - owner_id         = "000000000000" -> null
      - propagating_vgws = [] -> null
      - region           = "ap-south-1" -> null
      - route            = [
          - {
              - cidr_block                 = "0.0.0.0/0"
              - gateway_id                 = "igw-52cfa869f5ef322e9"
                # (12 unchanged attributes hidden)
            },
        ] -> null
      - tags             = {
          - "Name" = "lostfound-public-rt"
        } -> null
      - tags_all         = {
          - "Environment" = "prod"
          - "ManagedBy"   = "Terraform"
          - "Name"        = "lostfound-public-rt"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "lostfound"
          - "RollNo"      = "24BCS10238"
        } -> null
      - vpc_id           = "vpc-cd9d083b04edf7455" -> null
    }

  # aws_route_table_association.private[0] will be destroyed
  - resource "aws_route_table_association" "private" {
      - id             = "rtbassoc-c9e1ffd182271a332" -> null
      - region         = "ap-south-1" -> null
      - route_table_id = "rtb-9886ca5531637d138" -> null
      - subnet_id      = "subnet-df6f0ff5fcc2cda66" -> null
        # (1 unchanged attribute hidden)
    }

  # aws_route_table_association.private[1] will be destroyed
  - resource "aws_route_table_association" "private" {
      - id             = "rtbassoc-78ceb3a2e1700c6d7" -> null
      - region         = "ap-south-1" -> null
      - route_table_id = "rtb-9886ca5531637d138" -> null
      - subnet_id      = "subnet-c1a891a4d3b234e19" -> null
        # (1 unchanged attribute hidden)
    }

  # aws_route_table_association.public[0] will be destroyed
  - resource "aws_route_table_association" "public" {
      - id             = "rtbassoc-24f50e9fe3ed15276" -> null
      - region         = "ap-south-1" -> null
      - route_table_id = "rtb-a8711a26e517ed9d1" -> null
      - subnet_id      = "subnet-b80e5c05afa206880" -> null
        # (1 unchanged attribute hidden)
    }

  # aws_route_table_association.public[1] will be destroyed
  - resource "aws_route_table_association" "public" {
      - id             = "rtbassoc-dd42b5350455f222a" -> null
      - region         = "ap-south-1" -> null
      - route_table_id = "rtb-a8711a26e517ed9d1" -> null
      - subnet_id      = "subnet-c5b65e76e386a14bd" -> null
        # (1 unchanged attribute hidden)
    }

  # aws_s3_bucket.backups will be destroyed
  - resource "aws_s3_bucket" "backups" {
      - arn                         = "arn:aws:s3:::pratyush-24bcs10238-lostfound-db-backups" -> null
      - bucket                      = "pratyush-24bcs10238-lostfound-db-backups" -> null
      - bucket_domain_name          = "pratyush-24bcs10238-lostfound-db-backups.s3.amazonaws.com" -> null
      - bucket_namespace            = "global" -> null
      - bucket_region               = "ap-south-1" -> null
      - bucket_regional_domain_name = "pratyush-24bcs10238-lostfound-db-backups.s3.ap-south-1.amazonaws.com" -> null
      - force_destroy               = false -> null
      - hosted_zone_id              = "Z11RGJOFQNVJUP" -> null
      - id                          = "pratyush-24bcs10238-lostfound-db-backups" -> null
      - object_lock_enabled         = false -> null
      - region                      = "ap-south-1" -> null
      - request_payer               = "BucketOwner" -> null
      - tags                        = {
          - "Name"    = "pratyush-24bcs10238-lostfound-db-backups"
          - "Purpose" = "postgres-backups"
        } -> null
      - tags_all                    = {
          - "Environment" = "prod"
          - "ManagedBy"   = "Terraform"
          - "Name"        = "pratyush-24bcs10238-lostfound-db-backups"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "lostfound"
          - "Purpose"     = "postgres-backups"
          - "RollNo"      = "24BCS10238"
        } -> null
        # (3 unchanged attributes hidden)

      - grant {
          - id          = "75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a" -> null
          - permissions = [
              - "FULL_CONTROL",
            ] -> null
          - type        = "CanonicalUser" -> null
            # (1 unchanged attribute hidden)
        }

      - lifecycle_rule {
          - abort_incomplete_multipart_upload_days = 7 -> null
          - enabled                                = true -> null
          - id                                     = "expire-old-backup-versions" -> null
          - tags                                   = {} -> null
            # (1 unchanged attribute hidden)

          - noncurrent_version_expiration {
              - days = 30 -> null
            }
        }

      - server_side_encryption_configuration {
          - rule {
              - bucket_key_enabled = false -> null

              - apply_server_side_encryption_by_default {
                  - sse_algorithm     = "AES256" -> null
                    # (1 unchanged attribute hidden)
                }
            }
        }

      - versioning {
          - enabled    = true -> null
          - mfa_delete = false -> null
        }
    }

  # aws_s3_bucket_lifecycle_configuration.backups will be destroyed
  - resource "aws_s3_bucket_lifecycle_configuration" "backups" {
      - bucket                                 = "pratyush-24bcs10238-lostfound-db-backups" -> null
      - id                                     = "pratyush-24bcs10238-lostfound-db-backups" -> null
      - region                                 = "ap-south-1" -> null
      - transition_default_minimum_object_size = "all_storage_classes_128K" -> null
        # (1 unchanged attribute hidden)

      - rule {
          - id     = "expire-old-backup-versions" -> null
          - status = "Enabled" -> null
            # (1 unchanged attribute hidden)

          - abort_incomplete_multipart_upload {
              - days_after_initiation = 7 -> null
            }

          - filter {
                # (1 unchanged attribute hidden)
            }

          - noncurrent_version_expiration {
              - noncurrent_days = 30 -> null
            }
        }
    }

  # aws_s3_bucket_public_access_block.backups will be destroyed
  - resource "aws_s3_bucket_public_access_block" "backups" {
      - block_public_acls       = true -> null
      - block_public_policy     = true -> null
      - bucket                  = "pratyush-24bcs10238-lostfound-db-backups" -> null
      - id                      = "pratyush-24bcs10238-lostfound-db-backups" -> null
      - ignore_public_acls      = true -> null
      - region                  = "ap-south-1" -> null
      - restrict_public_buckets = true -> null
    }

  # aws_s3_bucket_server_side_encryption_configuration.backups will be destroyed
  - resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
      - bucket                = "pratyush-24bcs10238-lostfound-db-backups" -> null
      - id                    = "pratyush-24bcs10238-lostfound-db-backups" -> null
      - region                = "ap-south-1" -> null
        # (1 unchanged attribute hidden)

      - rule {
          - blocked_encryption_types = [] -> null
          - bucket_key_enabled       = false -> null

          - apply_server_side_encryption_by_default {
              - sse_algorithm     = "AES256" -> null
                # (1 unchanged attribute hidden)
            }
        }
    }

  # aws_s3_bucket_versioning.backups will be destroyed
  - resource "aws_s3_bucket_versioning" "backups" {
      - bucket                = "pratyush-24bcs10238-lostfound-db-backups" -> null
      - id                    = "pratyush-24bcs10238-lostfound-db-backups" -> null
      - region                = "ap-south-1" -> null
        # (1 unchanged attribute hidden)

      - versioning_configuration {
          - mfa_delete = "Disabled" -> null
          - status     = "Enabled" -> null
        }
    }

  # aws_security_group.nodes will be destroyed
  - resource "aws_security_group" "nodes" {
      - arn                    = "arn:aws:ec2:ap-south-1:000000000000:security-group/sg-0f65cbe4a101affb6" -> null
      - description            = "EKS worker nodes: node-to-node traffic and the control plane" -> null
      - egress                 = [
          - {
              - cidr_blocks      = [
                  - "0.0.0.0/0",
                ]
              - description      = "Image pulls, EKS API, S3 backups"
              - from_port        = 0
              - ipv6_cidr_blocks = []
              - prefix_list_ids  = []
              - protocol         = "-1"
              - security_groups  = []
              - self             = false
              - to_port          = 0
            },
        ] -> null
      - id                     = "sg-0f65cbe4a101affb6" -> null
      - ingress                = [
          - {
              - cidr_blocks      = [
                  - "10.20.0.0/16",
                ]
              - description      = "Admission webhooks (e.g. ingress-nginx) called by the control plane"
              - from_port        = 443
              - ipv6_cidr_blocks = []
              - prefix_list_ids  = []
              - protocol         = "tcp"
              - security_groups  = []
              - self             = false
              - to_port          = 443
            },
          - {
              - cidr_blocks      = [
                  - "10.20.0.0/16",
                ]
              - description      = "kubelet API from the control plane ENIs in the VPC"
              - from_port        = 10250
              - ipv6_cidr_blocks = []
              - prefix_list_ids  = []
              - protocol         = "tcp"
              - security_groups  = []
              - self             = false
              - to_port          = 10250
            },
          - {
              - cidr_blocks      = []
              - from_port        = 0
              - ipv6_cidr_blocks = []
              - prefix_list_ids  = []
              - protocol         = "-1"
              - security_groups  = []
              - self             = true
              - to_port          = 0
                # (1 unchanged attribute hidden)
            },
        ] -> null
      - name                   = "lostfound-eks-nodes" -> null
      - owner_id               = "000000000000" -> null
      - region                 = "ap-south-1" -> null
      - revoke_rules_on_delete = false -> null
      - tags                   = {
          - "Name" = "lostfound-eks-nodes"
        } -> null
      - tags_all               = {
          - "Environment" = "prod"
          - "ManagedBy"   = "Terraform"
          - "Name"        = "lostfound-eks-nodes"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "lostfound"
          - "RollNo"      = "24BCS10238"
        } -> null
      - vpc_id                 = "vpc-cd9d083b04edf7455" -> null
        # (1 unchanged attribute hidden)
    }

  # aws_subnet.private[0] will be destroyed
  - resource "aws_subnet" "private" {
      - arn                                            = "arn:aws:ec2:ap-south-1:000000000000:subnet/subnet-df6f0ff5fcc2cda66" -> null
      - assign_ipv6_address_on_creation                = false -> null
      - availability_zone                              = "ap-south-1a" -> null
      - availability_zone_id                           = "aps1-az1" -> null
      - cidr_block                                     = "10.20.11.0/24" -> null
      - enable_dns64                                   = false -> null
      - enable_lni_at_device_index                     = 0 -> null
      - enable_resource_name_dns_a_record_on_launch    = false -> null
      - enable_resource_name_dns_aaaa_record_on_launch = false -> null
      - id                                             = "subnet-df6f0ff5fcc2cda66" -> null
      - ipv6_native                                    = false -> null
      - map_customer_owned_ip_on_launch                = false -> null
      - map_public_ip_on_launch                        = false -> null
      - owner_id                                       = "000000000000" -> null
      - private_dns_hostname_type_on_launch            = "ip-name" -> null
      - region                                         = "ap-south-1" -> null
      - tags                                           = {
          - "Name"                            = "lostfound-private-a"
          - "kubernetes.io/role/internal-elb" = "1"
        } -> null
      - tags_all                                       = {
          - "Environment"                     = "prod"
          - "ManagedBy"                       = "Terraform"
          - "Name"                            = "lostfound-private-a"
          - "Owner"                           = "Pratyush Mohanty"
          - "Project"                         = "lostfound"
          - "RollNo"                          = "24BCS10238"
          - "kubernetes.io/role/internal-elb" = "1"
        } -> null
      - vpc_id                                         = "vpc-cd9d083b04edf7455" -> null
        # (4 unchanged attributes hidden)
    }

  # aws_subnet.private[1] will be destroyed
  - resource "aws_subnet" "private" {
      - arn                                            = "arn:aws:ec2:ap-south-1:000000000000:subnet/subnet-c1a891a4d3b234e19" -> null
      - assign_ipv6_address_on_creation                = false -> null
      - availability_zone                              = "ap-south-1b" -> null
      - availability_zone_id                           = "aps1-az3" -> null
      - cidr_block                                     = "10.20.12.0/24" -> null
      - enable_dns64                                   = false -> null
      - enable_lni_at_device_index                     = 0 -> null
      - enable_resource_name_dns_a_record_on_launch    = false -> null
      - enable_resource_name_dns_aaaa_record_on_launch = false -> null
      - id                                             = "subnet-c1a891a4d3b234e19" -> null
      - ipv6_native                                    = false -> null
      - map_customer_owned_ip_on_launch                = false -> null
      - map_public_ip_on_launch                        = false -> null
      - owner_id                                       = "000000000000" -> null
      - private_dns_hostname_type_on_launch            = "ip-name" -> null
      - region                                         = "ap-south-1" -> null
      - tags                                           = {
          - "Name"                            = "lostfound-private-b"
          - "kubernetes.io/role/internal-elb" = "1"
        } -> null
      - tags_all                                       = {
          - "Environment"                     = "prod"
          - "ManagedBy"                       = "Terraform"
          - "Name"                            = "lostfound-private-b"
          - "Owner"                           = "Pratyush Mohanty"
          - "Project"                         = "lostfound"
          - "RollNo"                          = "24BCS10238"
          - "kubernetes.io/role/internal-elb" = "1"
        } -> null
      - vpc_id                                         = "vpc-cd9d083b04edf7455" -> null
        # (4 unchanged attributes hidden)
    }

  # aws_subnet.public[0] will be destroyed
  - resource "aws_subnet" "public" {
      - arn                                            = "arn:aws:ec2:ap-south-1:000000000000:subnet/subnet-b80e5c05afa206880" -> null
      - assign_ipv6_address_on_creation                = false -> null
      - availability_zone                              = "ap-south-1a" -> null
      - availability_zone_id                           = "aps1-az1" -> null
      - cidr_block                                     = "10.20.1.0/24" -> null
      - enable_dns64                                   = false -> null
      - enable_lni_at_device_index                     = 0 -> null
      - enable_resource_name_dns_a_record_on_launch    = false -> null
      - enable_resource_name_dns_aaaa_record_on_launch = false -> null
      - id                                             = "subnet-b80e5c05afa206880" -> null
      - ipv6_native                                    = false -> null
      - map_customer_owned_ip_on_launch                = false -> null
      - map_public_ip_on_launch                        = true -> null
      - owner_id                                       = "000000000000" -> null
      - private_dns_hostname_type_on_launch            = "ip-name" -> null
      - region                                         = "ap-south-1" -> null
      - tags                                           = {
          - "Name"                   = "lostfound-public-a"
          - "kubernetes.io/role/elb" = "1"
        } -> null
      - tags_all                                       = {
          - "Environment"            = "prod"
          - "ManagedBy"              = "Terraform"
          - "Name"                   = "lostfound-public-a"
          - "Owner"                  = "Pratyush Mohanty"
          - "Project"                = "lostfound"
          - "RollNo"                 = "24BCS10238"
          - "kubernetes.io/role/elb" = "1"
        } -> null
      - vpc_id                                         = "vpc-cd9d083b04edf7455" -> null
        # (4 unchanged attributes hidden)
    }

  # aws_subnet.public[1] will be destroyed
  - resource "aws_subnet" "public" {
      - arn                                            = "arn:aws:ec2:ap-south-1:000000000000:subnet/subnet-c5b65e76e386a14bd" -> null
      - assign_ipv6_address_on_creation                = false -> null
      - availability_zone                              = "ap-south-1b" -> null
      - availability_zone_id                           = "aps1-az3" -> null
      - cidr_block                                     = "10.20.2.0/24" -> null
      - enable_dns64                                   = false -> null
      - enable_lni_at_device_index                     = 0 -> null
      - enable_resource_name_dns_a_record_on_launch    = false -> null
      - enable_resource_name_dns_aaaa_record_on_launch = false -> null
      - id                                             = "subnet-c5b65e76e386a14bd" -> null
      - ipv6_native                                    = false -> null
      - map_customer_owned_ip_on_launch                = false -> null
      - map_public_ip_on_launch                        = true -> null
      - owner_id                                       = "000000000000" -> null
      - private_dns_hostname_type_on_launch            = "ip-name" -> null
      - region                                         = "ap-south-1" -> null
      - tags                                           = {
          - "Name"                   = "lostfound-public-b"
          - "kubernetes.io/role/elb" = "1"
        } -> null
      - tags_all                                       = {
          - "Environment"            = "prod"
          - "ManagedBy"              = "Terraform"
          - "Name"                   = "lostfound-public-b"
          - "Owner"                  = "Pratyush Mohanty"
          - "Project"                = "lostfound"
          - "RollNo"                 = "24BCS10238"
          - "kubernetes.io/role/elb" = "1"
        } -> null
      - vpc_id                                         = "vpc-cd9d083b04edf7455" -> null
        # (4 unchanged attributes hidden)
    }

  # aws_vpc.main will be destroyed
  - resource "aws_vpc" "main" {
      - arn                                  = "arn:aws:ec2:ap-south-1:000000000000:vpc/vpc-cd9d083b04edf7455" -> null
      - assign_generated_ipv6_cidr_block     = false -> null
      - cidr_block                           = "10.20.0.0/16" -> null
      - default_network_acl_id               = "acl-d43efc9f16d1d6f86" -> null
      - default_route_table_id               = "rtb-7cfb20bdf2105b51a" -> null
      - default_security_group_id            = "sg-f8b1185326ac6c2ac" -> null
      - dhcp_options_id                      = "default" -> null
      - enable_dns_hostnames                 = true -> null
      - enable_dns_support                   = true -> null
      - enable_network_address_usage_metrics = false -> null
      - id                                   = "vpc-cd9d083b04edf7455" -> null
      - instance_tenancy                     = "default" -> null
      - ipv6_netmask_length                  = 0 -> null
      - main_route_table_id                  = "rtb-7cfb20bdf2105b51a" -> null
      - owner_id                             = "000000000000" -> null
      - region                               = "ap-south-1" -> null
      - tags                                 = {
          - "Name" = "lostfound-vpc"
        } -> null
      - tags_all                             = {
          - "Environment" = "prod"
          - "ManagedBy"   = "Terraform"
          - "Name"        = "lostfound-vpc"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "lostfound"
          - "RollNo"      = "24BCS10238"
        } -> null
        # (4 unchanged attributes hidden)
    }

  # aws_vpc_security_group_egress_rule.nodes_all will be destroyed
  - resource "aws_vpc_security_group_egress_rule" "nodes_all" {
      - arn                    = "arn:aws:ec2:ap-south-1:000000000000:security-group-rule/sgr-76bfd53f225db0428" -> null
      - cidr_ipv4              = "0.0.0.0/0" -> null
      - description            = "Image pulls, EKS API, S3 backups" -> null
      - id                     = "sgr-76bfd53f225db0428" -> null
      - ip_protocol            = "-1" -> null
      - region                 = "ap-south-1" -> null
      - security_group_id      = "sg-0f65cbe4a101affb6" -> null
      - security_group_rule_id = "sgr-76bfd53f225db0428" -> null
      - tags_all               = {
          - "Environment" = "prod"
          - "ManagedBy"   = "Terraform"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "lostfound"
          - "RollNo"      = "24BCS10238"
        } -> null
    }

  # aws_vpc_security_group_ingress_rule.nodes_kubelet will be destroyed
  - resource "aws_vpc_security_group_ingress_rule" "nodes_kubelet" {
      - arn                    = "arn:aws:ec2:ap-south-1:000000000000:security-group-rule/sgr-aa0bee0d7387acd61" -> null
      - cidr_ipv4              = "10.20.0.0/16" -> null
      - description            = "kubelet API from the control plane ENIs in the VPC" -> null
      - from_port              = 10250 -> null
      - id                     = "sgr-aa0bee0d7387acd61" -> null
      - ip_protocol            = "tcp" -> null
      - region                 = "ap-south-1" -> null
      - security_group_id      = "sg-0f65cbe4a101affb6" -> null
      - security_group_rule_id = "sgr-aa0bee0d7387acd61" -> null
      - tags_all               = {
          - "Environment" = "prod"
          - "ManagedBy"   = "Terraform"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "lostfound"
          - "RollNo"      = "24BCS10238"
        } -> null
      - to_port                = 10250 -> null
    }

  # aws_vpc_security_group_ingress_rule.nodes_self will be destroyed
  - resource "aws_vpc_security_group_ingress_rule" "nodes_self" {
      - arn                          = "arn:aws:ec2:ap-south-1:000000000000:security-group-rule/sgr-8f333b9b4c8ff5103" -> null
      - id                           = "sgr-8f333b9b4c8ff5103" -> null
      - ip_protocol                  = "-1" -> null
      - referenced_security_group_id = "sg-0f65cbe4a101affb6" -> null
      - region                       = "ap-south-1" -> null
      - security_group_id            = "sg-0f65cbe4a101affb6" -> null
      - security_group_rule_id       = "sgr-8f333b9b4c8ff5103" -> null
      - tags_all                     = {
          - "Environment" = "prod"
          - "ManagedBy"   = "Terraform"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "lostfound"
          - "RollNo"      = "24BCS10238"
        } -> null
    }

  # aws_vpc_security_group_ingress_rule.nodes_webhooks will be destroyed
  - resource "aws_vpc_security_group_ingress_rule" "nodes_webhooks" {
      - arn                    = "arn:aws:ec2:ap-south-1:000000000000:security-group-rule/sgr-9da6ae291c7452a78" -> null
      - cidr_ipv4              = "10.20.0.0/16" -> null
      - description            = "Admission webhooks (e.g. ingress-nginx) called by the control plane" -> null
      - from_port              = 443 -> null
      - id                     = "sgr-9da6ae291c7452a78" -> null
      - ip_protocol            = "tcp" -> null
      - region                 = "ap-south-1" -> null
      - security_group_id      = "sg-0f65cbe4a101affb6" -> null
      - security_group_rule_id = "sgr-9da6ae291c7452a78" -> null
      - tags_all               = {
          - "Environment" = "prod"
          - "ManagedBy"   = "Terraform"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "lostfound"
          - "RollNo"      = "24BCS10238"
        } -> null
      - to_port                = 443 -> null
    }

Plan: 0 to add, 0 to change, 28 to destroy.

Changes to Outputs:
  - backup_bucket          = "pratyush-24bcs10238-lostfound-db-backups" -> null
  - eks_cluster_role_arn   = "arn:aws:iam::000000000000:role/lostfound-eks-cluster" -> null
  - eks_node_role_arn      = "arn:aws:iam::000000000000:role/lostfound-eks-nodes" -> null
  - internet_gateway_id    = "igw-52cfa869f5ef322e9" -> null
  - kubeconfig_command     = "enable_eks = false - no cluster created" -> null
  - node_security_group_id = "sg-0f65cbe4a101affb6" -> null
  - private_subnet_ids     = [
      - "subnet-df6f0ff5fcc2cda66",
      - "subnet-c1a891a4d3b234e19",
    ] -> null
  - public_subnet_ids      = [
      - "subnet-b80e5c05afa206880",
      - "subnet-c5b65e76e386a14bd",
    ] -> null
  - vpc_id                 = "vpc-cd9d083b04edf7455" -> null
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"]: Destroying... [id=lostfound-eks-nodes/arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy]
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]: Destroying... [id=lostfound-eks-nodes/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly]
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"]: Destroying... [id=lostfound-eks-nodes/arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy]
aws_route_table_association.private[0]: Destroying... [id=rtbassoc-c9e1ffd182271a332]
aws_route_table_association.public[1]: Destroying... [id=rtbassoc-dd42b5350455f222a]
aws_s3_bucket_public_access_block.backups: Destroying... [id=pratyush-24bcs10238-lostfound-db-backups]
aws_vpc_security_group_ingress_rule.nodes_self: Destroying... [id=sgr-8f333b9b4c8ff5103]
aws_vpc_security_group_ingress_rule.nodes_kubelet: Destroying... [id=sgr-aa0bee0d7387acd61]
aws_route_table_association.public[0]: Destroying... [id=rtbassoc-24f50e9fe3ed15276]
aws_vpc_security_group_ingress_rule.nodes_webhooks: Destroying... [id=sgr-9da6ae291c7452a78]
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"]: Destruction complete after 0s
aws_s3_bucket_lifecycle_configuration.backups: Destroying... [id=pratyush-24bcs10238-lostfound-db-backups]
aws_vpc_security_group_ingress_rule.nodes_self: Destruction complete after 0s
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"]: Destruction complete after 0s
aws_vpc_security_group_ingress_rule.nodes_webhooks: Destruction complete after 0s
aws_s3_bucket_server_side_encryption_configuration.backups: Destroying... [id=pratyush-24bcs10238-lostfound-db-backups]
aws_vpc_security_group_ingress_rule.nodes_kubelet: Destruction complete after 0s
aws_route_table_association.public[0]: Destruction complete after 0s
aws_iam_role_policy_attachment.eks_nodes["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"]: Destruction complete after 0s
aws_route_table_association.private[0]: Destruction complete after 0s
aws_route_table_association.private[1]: Destroying... [id=rtbassoc-78ceb3a2e1700c6d7]
aws_s3_bucket_public_access_block.backups: Destruction complete after 0s
aws_s3_bucket_lifecycle_configuration.backups: Destruction complete after 0s
aws_s3_bucket_server_side_encryption_configuration.backups: Destruction complete after 0s
aws_route_table_association.public[1]: Destruction complete after 0s
aws_iam_role_policy_attachment.eks_cluster: Destroying... [id=lostfound-eks-cluster/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy]
aws_vpc_security_group_egress_rule.nodes_all: Destroying... [id=sgr-76bfd53f225db0428]
aws_route_table_association.private[1]: Destruction complete after 0s
aws_iam_role.eks_nodes: Destroying... [id=lostfound-eks-nodes]
aws_s3_bucket_versioning.backups: Destroying... [id=pratyush-24bcs10238-lostfound-db-backups]
aws_iam_role_policy_attachment.eks_cluster: Destruction complete after 0s
aws_vpc_security_group_egress_rule.nodes_all: Destruction complete after 0s
aws_iam_role.eks_nodes: Destruction complete after 0s
aws_s3_bucket_versioning.backups: Destruction complete after 0s
aws_route_table.private: Destroying... [id=rtb-9886ca5531637d138]
aws_route_table.public: Destroying... [id=rtb-a8711a26e517ed9d1]
aws_subnet.private[1]: Destroying... [id=subnet-c1a891a4d3b234e19]
aws_subnet.private[0]: Destroying... [id=subnet-df6f0ff5fcc2cda66]
aws_subnet.public[0]: Destroying... [id=subnet-b80e5c05afa206880]
aws_subnet.public[1]: Destroying... [id=subnet-c5b65e76e386a14bd]
aws_iam_role.eks_cluster: Destroying... [id=lostfound-eks-cluster]
aws_security_group.nodes: Destroying... [id=sg-0f65cbe4a101affb6]
aws_subnet.private[0]: Destruction complete after 0s
aws_subnet.private[1]: Destruction complete after 0s
aws_s3_bucket.backups: Destroying... [id=pratyush-24bcs10238-lostfound-db-backups]
aws_subnet.public[0]: Destruction complete after 0s
aws_subnet.public[1]: Destruction complete after 0s
aws_security_group.nodes: Destruction complete after 0s
aws_iam_role.eks_cluster: Destruction complete after 0s
aws_s3_bucket.backups: Destruction complete after 0s
aws_route_table.public: Destruction complete after 0s
aws_route_table.private: Destruction complete after 0s
aws_internet_gateway.main: Destroying... [id=igw-52cfa869f5ef322e9]
aws_internet_gateway.main: Destruction complete after 0s
aws_vpc.main: Destroying... [id=vpc-cd9d083b04edf7455]
aws_vpc.main: Destruction complete after 0s

Destroy complete! Resources: 28 destroyed.

state after destroy: 0 resources
VPCs tagged Project=lostfound left: 0
```
