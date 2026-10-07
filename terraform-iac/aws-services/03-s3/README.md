# 03 - S3 (Storage)

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

**Form field:** AWS Services Research - S3 · **Course session:** `session18-terraform-iac`

Hands-on: every feature below except storage-class pricing is configured and
checked in [../../terraform-s3-demo](../../terraform-s3-demo/) (output in
[output.md](../../terraform-s3-demo/output.md)), on LocalStack.

## What is S3?

Simple Storage Service: object storage behind an HTTP API. Not a disk and not
a filesystem - you PUT and GET whole objects by key. Designed for 11 nines of
durability (data is stored across at least 3 AZs), effectively unlimited
capacity, pay per GB-month plus requests and data out.

## Buckets

The container for objects. Name is **globally unique** across all AWS accounts
(3-63 chars, lowercase, digits, hyphens), which is why the demo bucket is
`pratyush-24bcs10238-tf-s3-demo`. A bucket lives in one region. Settings
(versioning, encryption, lifecycle, policy, public access block) are bucket-level.

## Objects

A key + the bytes (up to 5 TB) + metadata (content type, tags, encryption,
version ID). There are no real folders: `logs/app.log` is one key with a slash
in it; consoles just display prefixes as folders. Uploads over 100 MB should
use multipart upload (the lifecycle rule in the demo aborts abandoned ones
after 7 days, because unfinished parts are billed).

```text
$ aws s3 ls s3://pratyush-24bcs10238-tf-s3-demo/  and read the object back
2026-10-07 23:29:32        106 welcome.txt
Bucket pratyush-24bcs10238-tf-s3-demo
Created by Terraform for Pratyush Mohanty (24BCS10238), session 18.
```

## Storage classes

| Class | For | Retrieval | Notes |
|---|---|---|---|
| S3 Standard | Hot data | Instant | Default, no retrieval fee |
| Intelligent-Tiering | Unknown/changing access | Instant | Moves objects between tiers for a small monitoring fee |
| Standard-IA | Accessed < once a month | Instant | Cheaper storage, per-GB retrieval fee, 30-day minimum |
| One Zone-IA | Re-creatable infrequent data | Instant | One AZ only - lost if the AZ is lost |
| Glacier Instant Retrieval | Archives read a few times a year | Milliseconds | 90-day minimum |
| Glacier Flexible Retrieval | Archives | Minutes to hours | 90-day minimum |
| Glacier Deep Archive | Compliance, 7-10 year retention | Up to 12-48 h | Cheapest, 180-day minimum |
| Express One Zone | Very low latency, one AZ | Single-digit ms | Directory buckets |

## Versioning

Once enabled, every PUT creates a new version and a DELETE only adds a
"delete marker" - old versions stay recoverable. It can be suspended, never
fully turned off. From the demo:

```text
|  logs/app.log|  True   |  13   |  AaEXgQansDCKFoYJUs.7Z83Urii_I6hd   |
|  logs/app.log|  False  |  12   |  AaEXgQamsEATM_UdqkcrXKfJqdBNLlO0   |
```

Every version is billed, so versioning needs a lifecycle rule to expire
noncurrent versions.

## Lifecycle policies

Rules, optionally filtered by prefix or tag, that **transition** objects to
cheaper classes or **expire** them after N days. The demo has two:

```text
|  expire-old-versions       |         |  Enabled  |
|  logs-to-infrequent-access |  logs/  |  Enabled  |
```

`expire-old-versions` deletes noncurrent versions after 30 days and aborts
incomplete multipart uploads after 7; `logs-to-infrequent-access` moves `logs/`
to STANDARD_IA at 30 days (the minimum age S3 allows for that transition).

## Encryption

- **In transit**: HTTPS; enforce it with a bucket policy denying
  `aws:SecureTransport = false`.
- **At rest**, server side:
  - **SSE-S3** - S3-managed AES-256 keys. Default for all new buckets since
    January 2023. Used in the demo.
  - **SSE-KMS** - keys in KMS: key policy controls who can decrypt, every use
    is in CloudTrail. Enable an S3 Bucket Key to cut KMS request costs.
  - **DSSE-KMS** - two layers, for compliance needs.
  - **SSE-C** - you send the key with each request; AWS does not keep it.
- **Client side** - encrypt before upload; S3 only sees ciphertext.

```text
$ aws s3api head-object (was it encrypted by the bucket default?)
    "sse": "AES256",
```

## Bucket policies

A resource-based JSON policy on the bucket: who (Principal) can do what to it.
Typical uses: allow another account, allow a CloudFront distribution, deny
non-TLS, deny uploads without encryption.

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyInsecureTransport",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": ["arn:aws:s3:::pratyush-24bcs10238-tf-s3-demo",
                 "arn:aws:s3:::pratyush-24bcs10238-tf-s3-demo/*"],
    "Condition": { "Bool": { "aws:SecureTransport": "false" } }
  }]
}
```

**Block Public Access** sits above all of this: with the four switches on (as
in the demo), no bucket policy or ACL can make data public, however it is
written. ACLs are the legacy mechanism; new buckets have them disabled
(Object Ownership = bucket owner enforced).

## Common use cases

Static website assets (behind CloudFront), backups and DR copies, data lake
storage for Athena/EMR, application uploads, log archives (CloudTrail, ALB,
VPC flow logs), build artifacts, and **Terraform remote state** (with
versioning on, so a corrupted state can be rolled back).

## Interview Q&A

**Q: How do you stop a bucket from ever becoming public?**
Block Public Access at the bucket and, better, account level. It overrides any
policy or ACL that tries to grant public access.

**Q: Someone deleted a file - can you get it back?**
Only if versioning was on: delete the delete marker (or copy the previous
version back). Without versioning it is gone.

**Q: Why does `terraform destroy` fail with BucketNotEmpty?**
S3 will not delete a bucket that still has objects or versions. Empty it first,
or set `force_destroy = true` for buckets whose contents are disposable.

**Q: SSE-S3 vs SSE-KMS?**
Both encrypt at rest. KMS adds access control on the key itself and an audit
log of every decrypt, at the cost of KMS request charges.
