# Terraform & Infrastructure as Code

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

**Form field:** Terraform & Infrastructure as Code · **Course session:** `session18-terraform-iac`

| # | Task | Docs | Verified output |
|---|---|---|---|
| 1 | **Terraform S3 demo** - init, fmt, validate, plan, apply, show, output, destroy | [README](terraform-s3-demo/README.md) | [output.md](terraform-s3-demo/output.md) |
| 2.01 | **IAM** - users, groups, roles, policies, least privilege | [README](aws-services/01-iam/README.md) | [output.md](aws-services/01-iam/output.md) |
| 2.02 | **EC2** - AMI, instance types, key pairs, SGs, EBS, IPs, lifecycle | [README](aws-services/02-ec2/README.md) | via [cloud-terraform](../cloud-terraform/output.md) |
| 2.03 | **S3** - buckets, objects, classes, versioning, lifecycle, encryption, policies | [README](aws-services/03-s3/README.md) | via [terraform-s3-demo](terraform-s3-demo/output.md) |
| 2.04 | **VPC** - CIDR, subnets, routes, IGW, NAT, SGs, NACLs | [README](aws-services/04-vpc/README.md) | via [cloud-terraform](../cloud-terraform/output.md) |
| 2.05 | **DynamoDB & RDS** - keys, items, query vs scan; engines, Multi-AZ, replicas | [README](aws-services/05-dynamodb-rds/README.md) | [output.md](aws-services/05-dynamodb-rds/output.md) |

The session 19 project, [cloud-terraform](../cloud-terraform/), builds on this
one (VPC + EC2 + S3 + IAM in one Terraform configuration).

---

## Where the AWS calls go: LocalStack

There is no AWS account behind this homework, and I did not want to write about
commands that were never run. So Terraform and the AWS CLI talk to
[LocalStack](https://github.com/localstack/localstack), an AWS API emulator
running as a Docker container on `localhost:4566`.

```bash
./lab/localstack.sh up        # start (or restart) and wait until healthy
./lab/localstack.sh status    # container + per-service health
eval "$(./lab/localstack.sh env)"   # dummy keys for the AWS CLI
./lab/localstack.sh down      # remove it (state is in memory only)

aws --endpoint-url=http://localhost:4566 s3 ls
```

```text
localstack is up on http://localhost:4566 (localstack/localstack:4.14.0)
```

### Why version 4.14.0 and not `latest`

`latest` was tried first. It exits within seconds:

```text
LocalStack version: 2026.9.1
LocalStack build date: 2026-10-07

Localstack returning with exit code 55. Reason: 
...
Reason: No credentials were found in the environment. Please set the LOCALSTACK_AUTH_TOKEN variable to a valid auth token. Alternatively, run `lstk login` and start LocalStack with the lstk CLI, which configures the credentials for you.

Due to this error, Localstack has quit. LocalStack pro features can only be used with a valid license.
```

(`...` is the banner line `License activation failed!`, left out here.)

The first calendar-versioned release, `2026.03.0`, failed the same way
(exit 55, `No credentials were found in the environment`). From March 2026 the
image needs an account token. `4.14.0` (February 2026) is the last Community
release; it prints a deprecation banner and then runs with no account:

```text
LocalStack version: 4.14.0
LocalStack build date: 2026-02-26
LocalStack build git hash: 3d5a0c70e

Ready.
```

Its health endpoint lists S3, IAM, STS, EC2, DynamoDB, SSM and more; RDS is not
included (see [05-dynamodb-rds](aws-services/05-dynamodb-rds/README.md)).

### What LocalStack does and does not prove

| Proven | Not proven |
|---|---|
| The HCL is valid and the provider accepts it | That AWS would allow it (IAM is not enforced) |
| Every API call, its arguments and the order Terraform makes them | That an EC2 instance boots - EC2 is mocked, no VM runs |
| State, outputs, plan diffs, drift detection, destroy | Real-world timings, quotas, costs |

### Switching to real AWS

Each Terraform project has `use_localstack` in `terraform.tfvars`. Set it to
`false` and the provider drops the endpoint overrides and dummy keys, and uses
the normal credential chain (`aws configure`, SSO, env vars). Nothing else in
the code changes.

---

## Terraform in one page

| Concept | Meaning |
|---|---|
| **Provider** | Plugin that turns HCL into API calls for one platform (`hashicorp/aws`) |
| **Resource** | Something Terraform creates and owns (`aws_s3_bucket`) |
| **Data source** | Something Terraform only reads (`aws_ssm_parameter`, `aws_availability_zones`) |
| **Variable** | Input (`var.bucket_name`), set in `terraform.tfvars`, `-var`, or `TF_VAR_*` |
| **Output** | Value printed after apply and readable with `terraform output` |
| **State** | `terraform.tfstate` - the mapping from code addresses to real resource IDs |
| **Plan** | The diff between code and reality, before anything changes |
| **Lock file** | `.terraform.lock.hcl` - exact provider versions, committed |

```text
write .tf  ->  init  ->  fmt / validate  ->  plan  ->  apply  ->  (change code, plan, apply ...)  ->  destroy
```

Helper added for these sessions: [lab/localstack.sh](../lab/localstack.sh).
