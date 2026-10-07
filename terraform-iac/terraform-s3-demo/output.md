# Terraform S3 Demo - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 0 - Tools, and where the API calls will go
==============================================================
Terraform v1.16.4
aws-cli/2.35.15 Python/3.14.6 Darwin/25.5.0 source/arm64
LocalStack 4.14.0 community edition - s3: running
use_localstack in terraform.tfvars: true

==============================================================
STEP 1 - terraform init (download the AWS provider, create .terraform/ and the lock file)
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

--- what init created ---
.terraform
.terraform.lock.hcl
6.67.0

==============================================================
STEP 2 - terraform fmt (canonical formatting; -check exits 3 if a file needs rewriting)
==============================================================
terraform fmt -check exit code: 0  (0 = every file already formatted)

==============================================================
STEP 3 - terraform validate (syntax, types, references - no API calls)
==============================================================
Success! The configuration is valid.


==============================================================
STEP 4 - terraform plan (refresh + diff, saved to a plan file)
==============================================================

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.demo will be created
  + resource "aws_s3_bucket" "demo" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "pratyush-24bcs10238-tf-s3-demo"
      + bucket_domain_name          = (known after apply)
      + bucket_namespace            = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_region               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = true
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = "ap-south-1"
      + request_payer               = (known after apply)
      + tags                        = {
          + "Environment" = "dev"
          + "Name"        = "pratyush-24bcs10238-tf-s3-demo"
        }
      + tags_all                    = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Name"        = "pratyush-24bcs10238-tf-s3-demo"
          + "Owner"       = "Pratyush Mohanty"
          + "Project"     = "session18-terraform-s3-demo"
          + "RollNo"      = "24BCS10238"
        }
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)

      + cors_rule (known after apply)

      + grant (known after apply)

      + lifecycle_rule (known after apply)

      + logging (known after apply)

      + object_lock_configuration (known after apply)

      + replication_configuration (known after apply)

      + server_side_encryption_configuration (known after apply)

      + versioning (known after apply)

      + website (known after apply)
    }

  # aws_s3_bucket_lifecycle_configuration.demo will be created
  + resource "aws_s3_bucket_lifecycle_configuration" "demo" {
      + bucket                                 = (known after apply)
      + expected_bucket_owner                  = (known after apply)
      + id                                     = (known after apply)
      + region                                 = "ap-south-1"
      + transition_default_minimum_object_size = "all_storage_classes_128K"

      + rule {
          + id     = "expire-old-versions"
          + status = "Enabled"
            # (1 unchanged attribute hidden)

          + abort_incomplete_multipart_upload {
              + days_after_initiation = 7
            }

          + filter {
                # (1 unchanged attribute hidden)
            }

          + noncurrent_version_expiration {
              + noncurrent_days = 30
            }
        }
      + rule {
          + id     = "logs-to-infrequent-access"
          + status = "Enabled"
            # (1 unchanged attribute hidden)

          + filter {
              + prefix = "logs/"
            }

          + transition {
              + days          = 30
              + storage_class = "STANDARD_IA"
            }
        }
    }

  # aws_s3_bucket_public_access_block.demo will be created
  + resource "aws_s3_bucket_public_access_block" "demo" {
      + block_public_acls       = true
      + block_public_policy     = true
      + bucket                  = (known after apply)
      + id                      = (known after apply)
      + ignore_public_acls      = true
      + region                  = "ap-south-1"
      + restrict_public_buckets = true
    }

  # aws_s3_bucket_server_side_encryption_configuration.demo will be created
  + resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
      + bucket = (known after apply)
      + id     = (known after apply)
      + region = "ap-south-1"

      + rule {
          + blocked_encryption_types = (known after apply)
          + bucket_key_enabled       = (known after apply)

          + apply_server_side_encryption_by_default {
              + kms_master_key_id = (known after apply)
              + sse_algorithm     = "AES256"
            }
        }
    }

  # aws_s3_bucket_versioning.demo will be created
  + resource "aws_s3_bucket_versioning" "demo" {
      + bucket = (known after apply)
      + id     = (known after apply)
      + region = "ap-south-1"

      + versioning_configuration {
          + mfa_delete = (known after apply)
          + status     = "Enabled"
        }
    }

  # aws_s3_object.welcome will be created
  + resource "aws_s3_object" "welcome" {
      + acl                    = (known after apply)
      + arn                    = (known after apply)
      + bucket                 = (known after apply)
      + bucket_key_enabled     = (known after apply)
      + checksum_crc32         = (known after apply)
      + checksum_crc32c        = (known after apply)
      + checksum_crc64nvme     = (known after apply)
      + checksum_sha1          = (known after apply)
      + checksum_sha256        = (known after apply)
      + content                = <<-EOT
            Bucket pratyush-24bcs10238-tf-s3-demo
            Created by Terraform for Pratyush Mohanty (24BCS10238), session 18.
        EOT
      + content_type           = "text/plain"
      + etag                   = (known after apply)
      + force_destroy          = false
      + id                     = (known after apply)
      + key                    = "welcome.txt"
      + kms_key_id             = (known after apply)
      + region                 = "ap-south-1"
      + server_side_encryption = (known after apply)
      + storage_class          = (known after apply)
      + tags_all               = {
          + "ManagedBy" = "Terraform"
          + "Owner"     = "Pratyush Mohanty"
          + "Project"   = "session18-terraform-s3-demo"
          + "RollNo"    = "24BCS10238"
        }
      + version_id             = (known after apply)
    }

Plan: 6 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + bucket_arn          = (known after apply)
  + bucket_name         = "pratyush-24bcs10238-tf-s3-demo"
  + bucket_region       = "ap-south-1"
  + versioning_status   = "Enabled"
  + welcome_object_etag = (known after apply)
  + welcome_object_uri  = "s3://pratyush-24bcs10238-tf-s3-demo/welcome.txt"

─────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"

==============================================================
STEP 5 - terraform apply tfplan (exactly the reviewed plan, so no yes/no prompt)
==============================================================
aws_s3_bucket.demo: Creating...
aws_s3_bucket.demo: Creation complete after 0s [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_public_access_block.demo: Creating...
aws_s3_bucket_versioning.demo: Creating...
aws_s3_bucket_server_side_encryption_configuration.demo: Creating...
aws_s3_bucket_public_access_block.demo: Creation complete after 0s [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_server_side_encryption_configuration.demo: Creation complete after 0s [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_object.welcome: Creating...
aws_s3_object.welcome: Creation complete after 0s [id=pratyush-24bcs10238-tf-s3-demo/welcome.txt]
aws_s3_bucket_versioning.demo: Creation complete after 2s [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_lifecycle_configuration.demo: Creating...
aws_s3_bucket_lifecycle_configuration.demo: Still creating... [00m10s elapsed]
aws_s3_bucket_lifecycle_configuration.demo: Still creating... [00m20s elapsed]
aws_s3_bucket_lifecycle_configuration.demo: Still creating... [00m30s elapsed]
aws_s3_bucket_lifecycle_configuration.demo: Still creating... [00m40s elapsed]
aws_s3_bucket_lifecycle_configuration.demo: Still creating... [00m50s elapsed]
aws_s3_bucket_lifecycle_configuration.demo: Creation complete after 55s [id=pratyush-24bcs10238-tf-s3-demo]

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::pratyush-24bcs10238-tf-s3-demo"
bucket_name = "pratyush-24bcs10238-tf-s3-demo"
bucket_region = "ap-south-1"
versioning_status = "Enabled"
welcome_object_etag = "738bf6111e2f3b31e23c245057094814"
welcome_object_uri = "s3://pratyush-24bcs10238-tf-s3-demo/welcome.txt"

==============================================================
STEP 6 - Prove the bucket really exists, asking S3 directly (not Terraform)
==============================================================
$ aws s3 ls
2026-10-07 23:29:32 pratyush-24bcs10238-tf-s3-demo

$ aws s3api head-bucket --bucket pratyush-24bcs10238-tf-s3-demo
{
    "BucketArn": "arn:aws:s3:::pratyush-24bcs10238-tf-s3-demo",
    "BucketRegion": "ap-south-1"
}
(exit 0 = bucket exists and we can access it)

$ aws s3api get-bucket-versioning
{
    "Status": "Enabled"
}
$ aws s3api get-bucket-encryption
{
    "SSEAlgorithm": "AES256"
}
$ aws s3api get-public-access-block
{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
}
$ aws s3api get-bucket-lifecycle-configuration (rule ids only)
----------------------------------------------------
|          GetBucketLifecycleConfiguration         |
+----------------------------+---------+-----------+
|             id             | prefix  |  status   |
+----------------------------+---------+-----------+
|  expire-old-versions       |         |  Enabled  |
|  logs-to-infrequent-access |  logs/  |  Enabled  |
+----------------------------+---------+-----------+
$ aws s3api get-bucket-tagging (default_tags + resource tags merged)
Environment	dev
ManagedBy	Terraform
Name	pratyush-24bcs10238-tf-s3-demo
Owner	Pratyush Mohanty
Project	session18-terraform-s3-demo
RollNo	24BCS10238

$ aws s3 ls s3://pratyush-24bcs10238-tf-s3-demo/  and read the object back
2026-10-07 23:29:32        106 welcome.txt
Bucket pratyush-24bcs10238-tf-s3-demo
Created by Terraform for Pratyush Mohanty (24BCS10238), session 18.
$ aws s3api head-object (was it encrypted by the bucket default?)
{
    "size": 106,
    "type": "text/plain",
    "sse": "AES256",
    "version": "AaEXgQal0CNpSczgDxuX0tYQ9KtkCIlp"
}

==============================================================
STEP 7 - terraform show (the state file, human-readable)
==============================================================
# aws_s3_bucket.demo:
resource "aws_s3_bucket" "demo" {
    acceleration_status         = null
    arn                         = "arn:aws:s3:::pratyush-24bcs10238-tf-s3-demo"
    bucket                      = "pratyush-24bcs10238-tf-s3-demo"
    bucket_domain_name          = "pratyush-24bcs10238-tf-s3-demo.s3.amazonaws.com"
    bucket_namespace            = "global"
    bucket_prefix               = null
    bucket_region               = "ap-south-1"
    bucket_regional_domain_name = "pratyush-24bcs10238-tf-s3-demo.s3.ap-south-1.amazonaws.com"
    force_destroy               = true
    hosted_zone_id              = "Z11RGJOFQNVJUP"
    id                          = "pratyush-24bcs10238-tf-s3-demo"
    object_lock_enabled         = false
    policy                      = null
    region                      = "ap-south-1"
    request_payer               = "BucketOwner"
    tags                        = {
        "Environment" = "dev"
        "Name"        = "pratyush-24bcs10238-tf-s3-demo"
    }
    tags_all                    = {
        "Environment" = "dev"
        "ManagedBy"   = "Terraform"
        "Name"        = "pratyush-24bcs10238-tf-s3-demo"
        "Owner"       = "Pratyush Mohanty"
        "Project"     = "session18-terraform-s3-demo"
        "RollNo"      = "24BCS10238"
    }

    grant {
        id          = "75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a"
        permissions = [
            "FULL_CONTROL",
        ]
        type        = "CanonicalUser"
        uri         = null
    }

    server_side_encryption_configuration {
        rule {
            bucket_key_enabled = false

            apply_server_side_encryption_by_default {
                kms_master_key_id = null
                sse_algorithm     = "AES256"
            }
        }
    }

    versioning {
        enabled    = false
        mfa_delete = false
    }
}

# aws_s3_bucket_lifecycle_configuration.demo:
resource "aws_s3_bucket_lifecycle_configuration" "demo" {
    bucket                                 = "pratyush-24bcs10238-tf-s3-demo"
    expected_bucket_owner                  = null
    id                                     = "pratyush-24bcs10238-tf-s3-demo"
    region                                 = "ap-south-1"
    transition_default_minimum_object_size = "all_storage_classes_128K"

    rule {
        id     = "expire-old-versions"
        prefix = null
        status = "Enabled"

        abort_incomplete_multipart_upload {
            days_after_initiation = 7
        }

        filter {
            prefix = null
        }

        noncurrent_version_expiration {
            noncurrent_days = 30
        }
    }
    rule {
        id     = "logs-to-infrequent-access"
        prefix = null
        status = "Enabled"

        filter {
            prefix = "logs/"
        }

        transition {
            days          = 30
            storage_class = "STANDARD_IA"
        }
    }
}

# aws_s3_bucket_public_access_block.demo:
resource "aws_s3_bucket_public_access_block" "demo" {
    block_public_acls       = true
    block_public_policy     = true
    bucket                  = "pratyush-24bcs10238-tf-s3-demo"
    id                      = "pratyush-24bcs10238-tf-s3-demo"
    ignore_public_acls      = true
    region                  = "ap-south-1"
    restrict_public_buckets = true
}

# aws_s3_bucket_server_side_encryption_configuration.demo:
resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
    bucket                = "pratyush-24bcs10238-tf-s3-demo"
    expected_bucket_owner = null
    id                    = "pratyush-24bcs10238-tf-s3-demo"
    region                = "ap-south-1"

    rule {
        blocked_encryption_types = []
        bucket_key_enabled       = false

        apply_server_side_encryption_by_default {
            kms_master_key_id = null
            sse_algorithm     = "AES256"
        }
    }
}

# aws_s3_bucket_versioning.demo:
resource "aws_s3_bucket_versioning" "demo" {
    bucket                = "pratyush-24bcs10238-tf-s3-demo"
    expected_bucket_owner = null
    id                    = "pratyush-24bcs10238-tf-s3-demo"
    region                = "ap-south-1"

    versioning_configuration {
        mfa_delete = "Disabled"
        status     = "Enabled"
    }
}

# aws_s3_object.welcome:
resource "aws_s3_object" "welcome" {
    arn                           = "arn:aws:s3:::pratyush-24bcs10238-tf-s3-demo/welcome.txt"
    bucket                        = "pratyush-24bcs10238-tf-s3-demo"
    bucket_key_enabled            = false
    cache_control                 = null
    checksum_crc32                = null
    checksum_crc32c               = null
    checksum_crc64nvme            = null
    checksum_sha1                 = null
    checksum_sha256               = null
    content                       = <<-EOT
        Bucket pratyush-24bcs10238-tf-s3-demo
        Created by Terraform for Pratyush Mohanty (24BCS10238), session 18.
    EOT
    content_disposition           = null
    content_encoding              = null
    content_language              = null
    content_type                  = "text/plain"
    etag                          = "738bf6111e2f3b31e23c245057094814"
    force_destroy                 = false
    id                            = "pratyush-24bcs10238-tf-s3-demo/welcome.txt"
    key                           = "welcome.txt"
    object_lock_legal_hold_status = null
    object_lock_mode              = null
    object_lock_retain_until_date = null
    region                        = "ap-south-1"
    server_side_encryption        = "AES256"
    storage_class                 = "STANDARD"
    tags_all                      = {
        "ManagedBy" = "Terraform"
        "Owner"     = "Pratyush Mohanty"
        "Project"   = "session18-terraform-s3-demo"
        "RollNo"    = "24BCS10238"
    }
    version_id                    = "AaEXgQal0CNpSczgDxuX0tYQ9KtkCIlp"
    website_redirect              = null
}


Outputs:

bucket_arn = "arn:aws:s3:::pratyush-24bcs10238-tf-s3-demo"
bucket_name = "pratyush-24bcs10238-tf-s3-demo"
bucket_region = "ap-south-1"
versioning_status = "Enabled"
welcome_object_etag = "738bf6111e2f3b31e23c245057094814"
welcome_object_uri = "s3://pratyush-24bcs10238-tf-s3-demo/welcome.txt"

==============================================================
STEP 8 - terraform state list (every resource Terraform is tracking)
==============================================================
aws_s3_bucket.demo
aws_s3_bucket_lifecycle_configuration.demo
aws_s3_bucket_public_access_block.demo
aws_s3_bucket_server_side_encryption_configuration.demo
aws_s3_bucket_versioning.demo
aws_s3_object.welcome

12678 bytes  terraform.tfstate
format version 4 | terraform 1.16.4 | serial 7 | lineage 65be624a-51f3-3a3c-a4c7-6ee1aeb13fe4

==============================================================
STEP 9 - terraform output (values exported by outputs.tf)
==============================================================
bucket_arn = "arn:aws:s3:::pratyush-24bcs10238-tf-s3-demo"
bucket_name = "pratyush-24bcs10238-tf-s3-demo"
bucket_region = "ap-south-1"
versioning_status = "Enabled"
welcome_object_etag = "738bf6111e2f3b31e23c245057094814"
welcome_object_uri = "s3://pratyush-24bcs10238-tf-s3-demo/welcome.txt"

$ terraform output -raw bucket_name      # no quotes, for use in scripts
pratyush-24bcs10238-tf-s3-demo
$ terraform output -json   (machine-readable, e.g. for a CI step; first 8 lines)
{
  "bucket_arn": {
    "sensitive": false,
    "type": "string",
    "value": "arn:aws:s3:::pratyush-24bcs10238-tf-s3-demo"
  },
  "bucket_name": {
    "sensitive": false,

==============================================================
STEP 10 - Versioning in action, and why force_destroy matters
==============================================================
Uploading logs/app.log twice with different content ...
------------------------------------------------------------------------
|                          ListObjectVersions                          |
+--------------+---------+-------+-------------------------------------+
|      key     | latest  | size  |               version               |
+--------------+---------+-------+-------------------------------------+
|  logs/app.log|  True   |  13   |  AaEXgQansDCKFoYJUs.7Z83Urii_I6hd   |
|  logs/app.log|  False  |  12   |  AaEXgQamsEATM_UdqkcrXKfJqdBNLlO0   |
+--------------+---------+-------+-------------------------------------+
Both versions are kept. These objects are NOT in Terraform state, so without
force_destroy = true the destroy step would fail with BucketNotEmpty.

==============================================================
STEP 11 - Drift: change the bucket behind Terraform's back, let plan catch it
==============================================================
$ aws s3api put-bucket-versioning --versioning-configuration Status=Suspended
{
    "Status": "Suspended"
}

$ terraform plan -detailed-exitcode   (exit 0 = no changes, 2 = changes pending)
aws_s3_bucket.demo: Refreshing state... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_versioning.demo: Refreshing state... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_public_access_block.demo: Refreshing state... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_server_side_encryption_configuration.demo: Refreshing state... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_object.welcome: Refreshing state... [id=pratyush-24bcs10238-tf-s3-demo/welcome.txt]
aws_s3_bucket_lifecycle_configuration.demo: Refreshing state... [id=pratyush-24bcs10238-tf-s3-demo]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_s3_bucket_versioning.demo will be updated in-place
  ~ resource "aws_s3_bucket_versioning" "demo" {
        id                    = "pratyush-24bcs10238-tf-s3-demo"
        # (3 unchanged attributes hidden)

      ~ versioning_configuration {
          ~ status     = "Suspended" -> "Enabled"
            # (1 unchanged attribute hidden)
        }
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
plan exit code: 2

$ terraform apply -auto-approve   (put it back the way the code says)
aws_s3_bucket_versioning.demo: Modifying... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_versioning.demo: Modifications complete after 1s [id=pratyush-24bcs10238-tf-s3-demo]
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
{
    "Status": "Enabled"
}

==============================================================
STEP 12 - terraform plan -destroy (preview what will be deleted)
==============================================================
  # aws_s3_bucket.demo will be destroyed
  # aws_s3_bucket_lifecycle_configuration.demo will be destroyed
  # aws_s3_bucket_public_access_block.demo will be destroyed
  # aws_s3_bucket_server_side_encryption_configuration.demo will be destroyed
  # aws_s3_bucket_versioning.demo will be destroyed
  # aws_s3_object.welcome will be destroyed
Plan: 0 to add, 0 to change, 6 to destroy.

==============================================================
STEP 13 - terraform destroy
==============================================================
aws_s3_bucket.demo: Refreshing state... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_versioning.demo: Refreshing state... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_public_access_block.demo: Refreshing state... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_server_side_encryption_configuration.demo: Refreshing state... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_object.welcome: Refreshing state... [id=pratyush-24bcs10238-tf-s3-demo/welcome.txt]
aws_s3_bucket_lifecycle_configuration.demo: Refreshing state... [id=pratyush-24bcs10238-tf-s3-demo]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # aws_s3_bucket.demo will be destroyed
  - resource "aws_s3_bucket" "demo" {
      - arn                         = "arn:aws:s3:::pratyush-24bcs10238-tf-s3-demo" -> null
      - bucket                      = "pratyush-24bcs10238-tf-s3-demo" -> null
      - bucket_domain_name          = "pratyush-24bcs10238-tf-s3-demo.s3.amazonaws.com" -> null
      - bucket_namespace            = "global" -> null
      - bucket_region               = "ap-south-1" -> null
      - bucket_regional_domain_name = "pratyush-24bcs10238-tf-s3-demo.s3.ap-south-1.amazonaws.com" -> null
      - force_destroy               = true -> null
      - hosted_zone_id              = "Z11RGJOFQNVJUP" -> null
      - id                          = "pratyush-24bcs10238-tf-s3-demo" -> null
      - object_lock_enabled         = false -> null
      - region                      = "ap-south-1" -> null
      - request_payer               = "BucketOwner" -> null
      - tags                        = {
          - "Environment" = "dev"
          - "Name"        = "pratyush-24bcs10238-tf-s3-demo"
        } -> null
      - tags_all                    = {
          - "Environment" = "dev"
          - "ManagedBy"   = "Terraform"
          - "Name"        = "pratyush-24bcs10238-tf-s3-demo"
          - "Owner"       = "Pratyush Mohanty"
          - "Project"     = "session18-terraform-s3-demo"
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
          - id                                     = "expire-old-versions" -> null
          - tags                                   = {} -> null
            # (1 unchanged attribute hidden)

          - noncurrent_version_expiration {
              - days = 30 -> null
            }
        }
      - lifecycle_rule {
          - abort_incomplete_multipart_upload_days = 0 -> null
          - enabled                                = true -> null
          - id                                     = "logs-to-infrequent-access" -> null
          - prefix                                 = "logs/" -> null
          - tags                                   = {} -> null

          - transition {
              - days          = 30 -> null
              - storage_class = "STANDARD_IA" -> null
                # (1 unchanged attribute hidden)
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

  # aws_s3_bucket_lifecycle_configuration.demo will be destroyed
  - resource "aws_s3_bucket_lifecycle_configuration" "demo" {
      - bucket                                 = "pratyush-24bcs10238-tf-s3-demo" -> null
      - id                                     = "pratyush-24bcs10238-tf-s3-demo" -> null
      - region                                 = "ap-south-1" -> null
      - transition_default_minimum_object_size = "all_storage_classes_128K" -> null
        # (1 unchanged attribute hidden)

      - rule {
          - id     = "expire-old-versions" -> null
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
      - rule {
          - id     = "logs-to-infrequent-access" -> null
          - status = "Enabled" -> null
            # (1 unchanged attribute hidden)

          - filter {
              - prefix = "logs/" -> null
            }

          - transition {
              - days          = 30 -> null
              - storage_class = "STANDARD_IA" -> null
            }
        }
    }

  # aws_s3_bucket_public_access_block.demo will be destroyed
  - resource "aws_s3_bucket_public_access_block" "demo" {
      - block_public_acls       = true -> null
      - block_public_policy     = true -> null
      - bucket                  = "pratyush-24bcs10238-tf-s3-demo" -> null
      - id                      = "pratyush-24bcs10238-tf-s3-demo" -> null
      - ignore_public_acls      = true -> null
      - region                  = "ap-south-1" -> null
      - restrict_public_buckets = true -> null
    }

  # aws_s3_bucket_server_side_encryption_configuration.demo will be destroyed
  - resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
      - bucket                = "pratyush-24bcs10238-tf-s3-demo" -> null
      - id                    = "pratyush-24bcs10238-tf-s3-demo" -> null
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

  # aws_s3_bucket_versioning.demo will be destroyed
  - resource "aws_s3_bucket_versioning" "demo" {
      - bucket                = "pratyush-24bcs10238-tf-s3-demo" -> null
      - id                    = "pratyush-24bcs10238-tf-s3-demo" -> null
      - region                = "ap-south-1" -> null
        # (1 unchanged attribute hidden)

      - versioning_configuration {
          - mfa_delete = "Disabled" -> null
          - status     = "Enabled" -> null
        }
    }

  # aws_s3_object.welcome will be destroyed
  - resource "aws_s3_object" "welcome" {
      - arn                           = "arn:aws:s3:::pratyush-24bcs10238-tf-s3-demo/welcome.txt" -> null
      - bucket                        = "pratyush-24bcs10238-tf-s3-demo" -> null
      - bucket_key_enabled            = false -> null
      - content                       = <<-EOT
            Bucket pratyush-24bcs10238-tf-s3-demo
            Created by Terraform for Pratyush Mohanty (24BCS10238), session 18.
        EOT -> null
      - content_type                  = "text/plain" -> null
      - etag                          = "738bf6111e2f3b31e23c245057094814" -> null
      - force_destroy                 = false -> null
      - id                            = "pratyush-24bcs10238-tf-s3-demo/welcome.txt" -> null
      - key                           = "welcome.txt" -> null
      - metadata                      = {} -> null
      - region                        = "ap-south-1" -> null
      - server_side_encryption        = "AES256" -> null
      - storage_class                 = "STANDARD" -> null
      - tags                          = {} -> null
      - tags_all                      = {
          - "ManagedBy" = "Terraform"
          - "Owner"     = "Pratyush Mohanty"
          - "Project"   = "session18-terraform-s3-demo"
          - "RollNo"    = "24BCS10238"
        } -> null
      - version_id                    = "AaEXgQal0CNpSczgDxuX0tYQ9KtkCIlp" -> null
        # (13 unchanged attributes hidden)
    }

Plan: 0 to add, 0 to change, 6 to destroy.

Changes to Outputs:
  - bucket_arn          = "arn:aws:s3:::pratyush-24bcs10238-tf-s3-demo" -> null
  - bucket_name         = "pratyush-24bcs10238-tf-s3-demo" -> null
  - bucket_region       = "ap-south-1" -> null
  - versioning_status   = "Enabled" -> null
  - welcome_object_etag = "738bf6111e2f3b31e23c245057094814" -> null
  - welcome_object_uri  = "s3://pratyush-24bcs10238-tf-s3-demo/welcome.txt" -> null
aws_s3_bucket_public_access_block.demo: Destroying... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_object.welcome: Destroying... [id=pratyush-24bcs10238-tf-s3-demo/welcome.txt]
aws_s3_bucket_lifecycle_configuration.demo: Destroying... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_public_access_block.demo: Destruction complete after 0s
aws_s3_object.welcome: Destruction complete after 0s
aws_s3_bucket_lifecycle_configuration.demo: Destruction complete after 0s
aws_s3_bucket_versioning.demo: Destroying... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_server_side_encryption_configuration.demo: Destroying... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket_versioning.demo: Destruction complete after 0s
aws_s3_bucket_server_side_encryption_configuration.demo: Destruction complete after 0s
aws_s3_bucket.demo: Destroying... [id=pratyush-24bcs10238-tf-s3-demo]
aws_s3_bucket.demo: Destruction complete after 0s

Destroy complete! Resources: 6 destroyed.

==============================================================
STEP 14 - Prove it is gone
==============================================================
$ aws s3api head-bucket --bucket pratyush-24bcs10238-tf-s3-demo

aws: [ERROR]: An error occurred (404) when calling the HeadBucket operation: Not Found
(non-zero exit: the bucket no longer exists)

$ terraform state list   (empty)
$ terraform show
The state file is empty. No resources are represented.

The state file itself remains, with no resources in it:
serial 16 | resources: 0

==============================================================
DONE
==============================================================
```
