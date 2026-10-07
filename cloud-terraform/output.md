# Cloud & Terraform in Action - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 0 - Tools and target
==============================================================
Terraform v1.16.4
aws-cli/2.35.15 Python/3.14.6 Darwin/25.5.0 source/arm64
LocalStack 4.14.0 community
use_localstack = true

Files in this project:
compute.tf
iam.tf
network.tf
outputs.tf
providers.tf
security.tf
storage.tf
variables.tf
versions.tf

templates/:
user_data.sh.tftpl

==============================================================
STEP 1 - terraform init
==============================================================
Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Installing hashicorp/aws v6.67.0...
- Installed hashicorp/aws v6.67.0 (signed by HashiCorp)

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

==============================================================
STEP 2 - terraform fmt -check  and  terraform validate
==============================================================
fmt: all files already in canonical format
Success! The configuration is valid.


==============================================================
STEP 3 - terraform plan -out=tfplan  (summary: one line per resource)
==============================================================
  # data.aws_iam_policy_document.artifacts_rw will be read during apply
  # (config refers to values not yet known)
  # aws_iam_instance_profile.web will be created
  # aws_iam_role.web will be created
  # aws_iam_role_policy.artifacts_rw will be created
  # aws_instance.web will be created
  # aws_internet_gateway.main will be created
  # aws_route_table.public will be created
  # aws_route_table_association.public will be created
  # aws_s3_bucket.artifacts will be created
  # aws_s3_bucket_public_access_block.artifacts will be created
  # aws_s3_bucket_server_side_encryption_configuration.artifacts will be created
  # aws_s3_bucket_versioning.artifacts will be created
  # aws_s3_object.release_notes will be created
  # aws_security_group.web will be created
  # aws_subnet.private will be created
  # aws_subnet.public will be created
  # aws_vpc.main will be created
  # aws_vpc_security_group_egress_rule.all will be created
  # aws_vpc_security_group_ingress_rule.http will be created
  # aws_vpc_security_group_ingress_rule.ssh will be created
Plan: 19 to add, 0 to change, 0 to destroy.

--- the full planned block for the EC2 instance, as plan prints it ---
  # aws_instance.web will be created
  + resource "aws_instance" "web" {
      + ami                                  = "ami-0ff5003538b60d5ec"
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
      + availability_zone                    = (known after apply)
      + disable_api_stop                     = (known after apply)
      + disable_api_termination              = (known after apply)
      + ebs_optimized                        = (known after apply)
      + enable_primary_ipv6                  = (known after apply)
      + force_destroy                        = false
      + get_password_data                    = false
      + host_id                              = (known after apply)
      + host_resource_group_arn              = (known after apply)
      + iam_instance_profile                 = "s19-web-web-profile"
      + id                                   = (known after apply)
      + instance_initiated_shutdown_behavior = (known after apply)
      + instance_lifecycle                   = (known after apply)
      + instance_state                       = (known after apply)
      + instance_type                        = "t3.micro"
      + ipv6_address_count                   = (known after apply)
      + ipv6_addresses                       = (known after apply)
      + key_name                             = (known after apply)
      + monitoring                           = (known after apply)
      + outpost_arn                          = (known after apply)
      + password_data                        = (known after apply)
      + placement_group                      = (known after apply)
      + placement_group_id                   = (known after apply)
      + placement_partition_number           = (known after apply)
      + primary_network_interface_id         = (known after apply)
      + private_dns                          = (known after apply)
      + private_ip                           = (known after apply)
      + public_dns                           = (known after apply)
      + public_ip                            = (known after apply)
      + region                               = "ap-south-1"
      + secondary_private_ips                = (known after apply)
      + security_groups                      = (known after apply)
      + source_dest_check                    = true
      + spot_instance_request_id             = (known after apply)
      + subnet_id                            = (known after apply)
      + tags                                 = {
          + "Name" = "s19-web-web"
        }
      + tags_all                             = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "s19-web-web"
          + "Owner"       = "Pratyush Mohanty"
          + "Project"     = "s19-web"
          + "RollNo"      = "24BCS10238"
        }
      + tenancy                              = (known after apply)
      + user_data                            = <<-EOT
            #!/bin/bash
            # First-boot script for the web instance (rendered by templatefile()).
            set -euxo pipefail
            
            dnf install -y nginx
            
            cat > /usr/share/nginx/html/index.html <<HTML
            <h1>s19-web</h1>
            <p>Provisioned by Terraform for Pratyush Mohanty (24BCS10238).</p>
            <p>Instance: $(hostname)</p>
            HTML
            
            systemctl enable --now nginx
            
            # The instance role allows writes to this bucket only (see iam.tf).
            aws s3 cp /var/log/cloud-init-output.log "s3://pratyush-24bcs10238-s19-artifacts/logs/$(hostname)/cloud-init-output.log"
        EOT
      + user_data_base64                     = (known after apply)
      + user_data_replace_on_change          = true
      + vpc_security_group_ids               = (known after apply)

      + capacity_reservation_specification (known after apply)

      + cpu_options (known after apply)

      + ebs_block_device (known after apply)

      + enclave_options (known after apply)

      + ephemeral_block_device (known after apply)

      + instance_market_options (known after apply)

      + maintenance_options (known after apply)

      + metadata_options {
          + http_endpoint               = "enabled"
          + http_protocol_ipv6          = "disabled"
          + http_put_response_hop_limit = (known after apply)
          + http_tokens                 = "required"
          + instance_metadata_tags      = (known after apply)
        }

      + network_interface (known after apply)

      + primary_network_interface (known after apply)

      + private_dns_name_options (known after apply)

      + root_block_device {
          + delete_on_termination = true
          + device_name           = (known after apply)
          + encrypted             = true
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + tags_all              = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = 8
          + volume_type           = "gp3"
        }

      + secondary_network_interface (known after apply)
    }

==============================================================
STEP 4 - terraform apply tfplan  (watch the creation order follow the dependencies)
==============================================================
aws_iam_role.web: Creating...
aws_s3_bucket.artifacts: Creating...
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 2s [id=vpc-1343639b420af3a36]
aws_internet_gateway.main: Creating...
aws_subnet.private: Creating...
aws_subnet.public: Creating...
aws_security_group.web: Creating...
aws_internet_gateway.main: Creation complete after 0s [id=igw-a4a249d28fcb4d1a5]
aws_subnet.private: Creation complete after 0s [id=subnet-a19ef5b7f68063c11]
aws_route_table.public: Creating...
aws_security_group.web: Creation complete after 1s [id=sg-dee8785394a128d6a]
aws_vpc_security_group_egress_rule.all: Creating...
aws_vpc_security_group_ingress_rule.ssh: Creating...
aws_vpc_security_group_ingress_rule.http: Creating...
aws_vpc_security_group_ingress_rule.http: Creation complete after 0s [id=sgr-8a9a5a311c1e0e3dd]
aws_vpc_security_group_ingress_rule.ssh: Creation complete after 0s [id=sgr-bbaf8dd81f35dc21d]
aws_vpc_security_group_egress_rule.all: Creation complete after 0s [id=sgr-17d2e7ce5615d762f]
aws_route_table.public: Creation complete after 1s [id=rtb-cafafee3ec0ece15f]
aws_iam_role.web: Creation complete after 3s [id=s19-web-web-role]
aws_iam_instance_profile.web: Creating...
aws_s3_bucket.artifacts: Creation complete after 3s [id=pratyush-24bcs10238-s19-artifacts]
data.aws_iam_policy_document.artifacts_rw: Reading...
aws_s3_bucket_public_access_block.artifacts: Creating...
aws_s3_bucket_versioning.artifacts: Creating...
aws_s3_bucket_server_side_encryption_configuration.artifacts: Creating...
data.aws_iam_policy_document.artifacts_rw: Read complete after 0s [id=214291932]
aws_iam_role_policy.artifacts_rw: Creating...
aws_s3_bucket_public_access_block.artifacts: Creation complete after 0s [id=pratyush-24bcs10238-s19-artifacts]
aws_s3_bucket_server_side_encryption_configuration.artifacts: Creation complete after 0s [id=pratyush-24bcs10238-s19-artifacts]
aws_iam_role_policy.artifacts_rw: Creation complete after 0s [id=s19-web-web-role:artifacts-bucket-rw]
aws_s3_object.release_notes: Creating...
aws_s3_object.release_notes: Creation complete after 0s [id=pratyush-24bcs10238-s19-artifacts/releases/v1/RELEASE.txt]
aws_s3_bucket_versioning.artifacts: Creation complete after 1s [id=pratyush-24bcs10238-s19-artifacts]
aws_iam_instance_profile.web: Creation complete after 5s [id=s19-web-web-profile]
aws_subnet.public: Still creating... [00m10s elapsed]
aws_subnet.public: Creation complete after 10s [id=subnet-28ace29de50f5704f]
aws_route_table_association.public: Creating...
aws_route_table_association.public: Creation complete after 1s [id=rtbassoc-da12bcb70106cf739]
aws_instance.web: Creating...
aws_instance.web: Still creating... [00m10s elapsed]
aws_instance.web: Creation complete after 11s [id=i-17d970bb33eee9df6]

Apply complete! Resources: 19 added, 0 changed, 0 destroyed.

Outputs:

ami_id = "ami-0ff5003538b60d5ec"
artifacts_bucket = "pratyush-24bcs10238-s19-artifacts"
availability_zone = "ap-south-1a"
instance_id = "i-17d970bb33eee9df6"
instance_private_ip = "10.20.1.4"
instance_public_ip = "54.214.148.216"
instance_role_arn = "arn:aws:iam::000000000000:role/s19-web-web-role"
internet_gateway_id = "igw-a4a249d28fcb4d1a5"
private_subnet_id = "subnet-a19ef5b7f68063c11"
public_route_table_id = "rtb-cafafee3ec0ece15f"
public_subnet_id = "subnet-28ace29de50f5704f"
security_group_id = "sg-dee8785394a128d6a"
vpc_id = "vpc-1343639b420af3a36"
web_url = "http://54.214.148.216/"

==============================================================
STEP 5 - terraform output
==============================================================
ami_id = "ami-0ff5003538b60d5ec"
artifacts_bucket = "pratyush-24bcs10238-s19-artifacts"
availability_zone = "ap-south-1a"
instance_id = "i-17d970bb33eee9df6"
instance_private_ip = "10.20.1.4"
instance_public_ip = "54.214.148.216"
instance_role_arn = "arn:aws:iam::000000000000:role/s19-web-web-role"
internet_gateway_id = "igw-a4a249d28fcb4d1a5"
private_subnet_id = "subnet-a19ef5b7f68063c11"
public_route_table_id = "rtb-cafafee3ec0ece15f"
public_subnet_id = "subnet-28ace29de50f5704f"
security_group_id = "sg-dee8785394a128d6a"
vpc_id = "vpc-1343639b420af3a36"
web_url = "http://54.214.148.216/"

==============================================================
STEP 6 - terraform state list  (everything Terraform now tracks)
==============================================================
data.aws_availability_zones.available
data.aws_iam_policy_document.artifacts_rw
data.aws_iam_policy_document.ec2_assume
data.aws_ssm_parameter.al2023
aws_iam_instance_profile.web
aws_iam_role.web
aws_iam_role_policy.artifacts_rw
aws_instance.web
aws_internet_gateway.main
aws_route_table.public
aws_route_table_association.public
aws_s3_bucket.artifacts
aws_s3_bucket_public_access_block.artifacts
aws_s3_bucket_server_side_encryption_configuration.artifacts
aws_s3_bucket_versioning.artifacts
aws_s3_object.release_notes
aws_security_group.web
aws_subnet.private
aws_subnet.public
aws_vpc.main
aws_vpc_security_group_egress_rule.all
aws_vpc_security_group_ingress_rule.http
aws_vpc_security_group_ingress_rule.ssh

terraform.tfstate: format v4, serial 21, lineage b1eb9c91...
  19 managed resources, 4 data sources, 14 outputs

==============================================================
STEP 7 - terraform state show aws_route_table.public  (one resource, as recorded)
==============================================================
# aws_route_table.public:
resource "aws_route_table" "public" {
    arn              = "arn:aws:ec2:ap-south-1:000000000000:route-table/rtb-cafafee3ec0ece15f"
    id               = "rtb-cafafee3ec0ece15f"
    owner_id         = "000000000000"
    propagating_vgws = []
    region           = "ap-south-1"
    route            = [
        {
            carrier_gateway_id         = null
            cidr_block                 = "0.0.0.0/0"
            core_network_arn           = null
            destination_prefix_list_id = null
            egress_only_gateway_id     = null
            gateway_id                 = "igw-a4a249d28fcb4d1a5"
            ipv6_cidr_block            = null
            local_gateway_id           = null
            nat_gateway_id             = null
            network_interface_id       = null
            odb_network_arn            = null
            transit_gateway_id         = null
            vpc_endpoint_id            = null
            vpc_peering_connection_id  = null
        },
    ]
    tags             = {
        "Name" = "s19-web-public-rt"
    }
    tags_all         = {
        "Environment" = "dev"
        "ManagedBy"   = "Terraform"
        "Name"        = "s19-web-public-rt"
        "Owner"       = "Pratyush Mohanty"
        "Project"     = "s19-web"
        "RollNo"      = "24BCS10238"
    }
    vpc_id           = "vpc-1343639b420af3a36"
}

==============================================================
STEP 8 - The same state, machine-readable: aws_instance.web via terraform show -json
==============================================================
  id                       i-17d970bb33eee9df6
  ami                      ami-0ff5003538b60d5ec
  instance_type            t3.micro
  instance_state           running
  availability_zone        ap-south-1a
  subnet_id                subnet-28ace29de50f5704f
  vpc_security_group_ids   ['sg-dee8785394a128d6a']
  private_ip               10.20.1.4
  public_ip                54.214.148.216
  iam_instance_profile     s19-web-web-profile
  metadata http_tokens     required
  root volume              8 GiB gp3, encrypted=True
  depends_on (in state)    ['aws_iam_instance_profile.web', 'aws_iam_role.web', 'aws_internet_gateway.main', 'aws_route_table.public', 'aws_route_table_association.public', 'aws_s3_bucket.artifacts', 'aws_security_group.web', 'aws_subnet.public', 'aws_vpc.main', 'data.aws_availability_zones.available', 'data.aws_iam_policy_document.ec2_assume', 'data.aws_ssm_parameter.al2023']

==============================================================
STEP 9 - Verify with the AWS CLI (asking the API, not Terraform)
==============================================================
$ aws ec2 describe-vpcs
-----------------------------------------------------------------------
|                            DescribeVpcs                             |
+--------------+--------------+------------+--------------------------+
|     Cidr     |    Name      |   State    |          VpcId           |
+--------------+--------------+------------+--------------------------+
|  10.20.0.0/16|  s19-web-vpc |  available |  vpc-1343639b420af3a36   |
+--------------+--------------+------------+--------------------------+
$ aws ec2 describe-subnets
------------------------------------------------------------------------------------------------------
|                                           DescribeSubnets                                          |
+-------------+---------------+----------------------------+--------------------+--------------------+
|     AZ      |     Cidr      |            Id              |       Name         | PublicIpOnLaunch   |
+-------------+---------------+----------------------------+--------------------+--------------------+
|  ap-south-1a|  10.20.2.0/24 |  subnet-a19ef5b7f68063c11  |  s19-web-private-a |  False             |
|  ap-south-1a|  10.20.1.0/24 |  subnet-28ace29de50f5704f  |  s19-web-public-a  |  True              |
+-------------+---------------+----------------------------+--------------------+--------------------+
$ aws ec2 describe-internet-gateways
-----------------------------------------------------------------
|                   DescribeInternetGateways                    |
+------------------------+-------------------------+------------+
|       AttachedTo       |           Id            |   State    |
+------------------------+-------------------------+------------+
|  vpc-1343639b420af3a36 |  igw-a4a249d28fcb4d1a5  |  available |
+------------------------+-------------------------+------------+
$ aws ec2 describe-route-tables  (the public one: local route + default route to the IGW)
-----------------------------------------------------
|                DescribeRouteTables                |
+---------------+---------+-------------------------+
|  Destination  |  State  |         Target          |
+---------------+---------+-------------------------+
|  10.20.0.0/16 |  active |  local                  |
|  0.0.0.0/0    |  active |  igw-a4a249d28fcb4d1a5  |
+---------------+---------+-------------------------+
-------------------------------------------------------
|                 DescribeRouteTables                 |
+------------------------+----------------------------+
|       RouteTable       |          Subnet            |
+------------------------+----------------------------+
|  rtb-cafafee3ec0ece15f |  subnet-28ace29de50f5704f  |
+------------------------+----------------------------+
$ aws ec2 describe-security-group-rules
---------------------------------------------------------------------------------------------
|                                DescribeSecurityGroupRules                                 |
+-----------------+---------------------------------------+---------+-------+--------+------+
|      Cidr       |                 Desc                  | Egress  | From  | Proto  | To   |
+-----------------+---------------------------------------+---------+-------+--------+------+
|  0.0.0.0/0      |  All outbound (package installs, S3)  |  True   |  -1   |  -1    |  -1  |
|  203.0.113.10/32|  SSH from the admin CIDR only         |  False  |  22   |  tcp   |  22  |
|  0.0.0.0/0      |  HTTP from anywhere                   |  False  |  80   |  tcp   |  80  |
+-----------------+---------------------------------------+---------+-------+--------+------+
$ aws ec2 describe-instances
----------------------------------------
|           DescribeInstances          |
+------------+-------------------------+
|  Ami       |  ami-0ff5003538b60d5ec  |
|  IMDS      |  required               |
|  Id        |  i-17d970bb33eee9df6    |
|  PrivateIp |  10.20.1.4              |
|  PublicIp  |  54.214.148.216         |
|  State     |  running                |
|  Type      |  t3.micro               |
+------------+-------------------------+
$ aws s3 ls  and the release artifact
2026-10-07 23:48:25 pratyush-24bcs10238-s19-artifacts
2026-10-07 23:48:26         54 releases/v1/RELEASE.txt
s19-web v1 - VPC 10.20.0.0/16, instance type t3.micro
$ aws iam get-role-policy  (the least-privilege policy on the instance role)
[
    {
        "Sid": "ListTheOneBucket",
        "Action": "s3:ListBucket",
        "Resource": "arn:aws:s3:::pratyush-24bcs10238-s19-artifacts"
    },
    {
        "Sid": "ReadWriteObjectsInIt",
        "Action": [
            "s3:PutObject",
            "s3:GetObject"
        ],
        "Resource": "arn:aws:s3:::pratyush-24bcs10238-s19-artifacts/*"
    }
]

==============================================================
STEP 10 - Idempotency: a second plan right after apply must be empty
==============================================================
plan exit code: 0  (0 = no changes, 2 = changes)
No changes. Your infrastructure matches the configuration.

==============================================================
STEP 11 - In-place update vs replacement (plan only, nothing applied)
==============================================================
--- change the instance type: the provider can stop, resize and start the same
    instance, so this is ~ update in-place. RELEASE.txt changes too, because its
    content references var.instance_type ---
  # aws_instance.web will be updated in-place
      ~ instance_type                        = "t3.micro" -> "t3.small"
  # aws_s3_object.release_notes will be updated in-place
Plan: 0 to add, 2 to change, 0 to destroy.

--- change the public subnet CIDR: a subnet CIDR is immutable, so -/+ replace,
    and everything that references the subnet is replaced with it ---
  # aws_instance.web must be replaced
      ~ subnet_id                            = "subnet-28ace29de50f5704f" -> (known after apply) # forces replacement
  # aws_route_table_association.public must be replaced
      ~ subnet_id      = "subnet-28ace29de50f5704f" -> (known after apply) # forces replacement
  # aws_subnet.public must be replaced
      ~ cidr_block                                     = "10.20.1.0/24" -> "10.20.3.0/24" # forces replacement
Plan: 3 to add, 0 to change, 3 to destroy.

==============================================================
STEP 12 - terraform graph  (dependency graph -> docs/terraform-graph.png)
==============================================================
26 edges written to docs/terraform-graph.dot
rendered docs/terraform-graph.png with dot - graphviz version 16.1.0 (20260904.0139)

--- what aws_instance.web waits for (edges out of it) ---
  "aws_instance.web" -> "data.aws_ssm_parameter.al2023";
  "aws_instance.web" -> "aws_iam_instance_profile.web";
  "aws_instance.web" -> "aws_route_table_association.public";
  "aws_instance.web" -> "aws_s3_bucket.artifacts";
  "aws_instance.web" -> "aws_security_group.web";

--- the same, from a copy of the code with depends_on deleted ---
  "aws_instance.web" -> "data.aws_ssm_parameter.al2023";
  "aws_instance.web" -> "aws_iam_instance_profile.web";
  "aws_instance.web" -> "aws_s3_bucket.artifacts";
  "aws_instance.web" -> "aws_security_group.web";
  "aws_instance.web" -> "aws_subnet.public";

Without depends_on the instance points straight at the subnet and nothing ties
it to the route table, so both could be created in parallel. With it, the edge
goes to the route table association instead (the direct subnet edge is dropped
from the drawing because it is now implied through the association).

==============================================================
STEP 13 - terraform destroy  (progress lines only; the plan is the reverse of apply)
==============================================================
Plan: 0 to add, 0 to change, 19 to destroy.
aws_vpc_security_group_egress_rule.all: Destroying... [id=sgr-17d2e7ce5615d762f]
aws_subnet.private: Destroying... [id=subnet-a19ef5b7f68063c11]
aws_s3_bucket_public_access_block.artifacts: Destroying... [id=pratyush-24bcs10238-s19-artifacts]
aws_s3_object.release_notes: Destroying... [id=pratyush-24bcs10238-s19-artifacts/releases/v1/RELEASE.txt]
aws_vpc_security_group_ingress_rule.http: Destroying... [id=sgr-8a9a5a311c1e0e3dd]
aws_s3_bucket_versioning.artifacts: Destroying... [id=pratyush-24bcs10238-s19-artifacts]
aws_vpc_security_group_ingress_rule.ssh: Destroying... [id=sgr-bbaf8dd81f35dc21d]
aws_iam_role_policy.artifacts_rw: Destroying... [id=s19-web-web-role:artifacts-bucket-rw]
aws_instance.web: Destroying... [id=i-17d970bb33eee9df6]
aws_s3_bucket_versioning.artifacts: Destruction complete after 0s
aws_vpc_security_group_ingress_rule.http: Destruction complete after 1s
aws_vpc_security_group_egress_rule.all: Destruction complete after 1s
aws_iam_role_policy.artifacts_rw: Destruction complete after 1s
aws_s3_bucket_public_access_block.artifacts: Destruction complete after 1s
aws_vpc_security_group_ingress_rule.ssh: Destruction complete after 1s
aws_subnet.private: Destruction complete after 1s
aws_s3_object.release_notes: Destruction complete after 1s
aws_s3_bucket_server_side_encryption_configuration.artifacts: Destroying... [id=pratyush-24bcs10238-s19-artifacts]
aws_s3_bucket_server_side_encryption_configuration.artifacts: Destruction complete after 0s
aws_instance.web: Destruction complete after 12s
aws_route_table_association.public: Destroying... [id=rtbassoc-da12bcb70106cf739]
aws_iam_instance_profile.web: Destroying... [id=s19-web-web-profile]
aws_security_group.web: Destroying... [id=sg-dee8785394a128d6a]
aws_s3_bucket.artifacts: Destroying... [id=pratyush-24bcs10238-s19-artifacts]
aws_iam_instance_profile.web: Destruction complete after 0s
aws_iam_role.web: Destroying... [id=s19-web-web-role]
aws_route_table_association.public: Destruction complete after 0s
aws_subnet.public: Destroying... [id=subnet-28ace29de50f5704f]
aws_route_table.public: Destroying... [id=rtb-cafafee3ec0ece15f]
aws_subnet.public: Destruction complete after 0s
aws_iam_role.web: Destruction complete after 1s
aws_s3_bucket.artifacts: Destruction complete after 1s
aws_security_group.web: Destruction complete after 1s
aws_route_table.public: Destruction complete after 1s
aws_internet_gateway.main: Destroying... [id=igw-a4a249d28fcb4d1a5]
aws_internet_gateway.main: Destruction complete after 0s
aws_vpc.main: Destroying... [id=vpc-1343639b420af3a36]
aws_vpc.main: Destruction complete after 0s
Destroy complete! Resources: 19 destroyed.

==============================================================
STEP 14 - Prove it is gone
==============================================================
$ aws ec2 describe-vpcs --filters tag:Project=s19-web
[]
$ aws ec2 describe-instances  (terminated instances stay listed for a while, as on AWS)
---------------------------------------
|          DescribeInstances          |
+----------------------+--------------+
|          Id          |    State     |
+----------------------+--------------+
|  i-17d970bb33eee9df6 |  terminated  |
+----------------------+--------------+
$ aws s3 ls
(no bucket listed)
$ terraform state list
(empty)

==============================================================
DONE
==============================================================
```
