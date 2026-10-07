# 01 - IAM (Governance)

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

**Form field:** AWS Services Research - IAM · **Course session:** `session18-terraform-iac`

Hands-on: [demo.sh](demo.sh) · real output against LocalStack: [output.md](output.md)

## What is IAM?

Identity and Access Management decides **who** can do **what** on **which**
AWS resources. It is global (not per region) and free. Every API call - from
the console, the CLI, Terraform or an app - is signed by some identity and
checked against IAM policies before it runs.

## The building blocks

| Thing | What it is | Typical use |
|---|---|---|
| **Root user** | The email that created the account. Can do everything, including close the account | Lock away with MFA, use almost never |
| **User** | A long-lived identity for one person or app, with a password and/or access keys | Humans (better: SSO), legacy apps |
| **Group** | A collection of users. Policies attached to the group apply to all members | `developers`, `admins` - permissions follow the job, not the person |
| **Role** | An identity with **no** long-term credentials. Someone or something *assumes* it and gets temporary keys from STS | EC2 instances, Lambda, CI pipelines, cross-account access |
| **Policy** | A JSON document of Allow/Deny statements | Attached to users, groups or roles (identity-based) or to resources such as S3 buckets (resource-based) |

A **role** has two policies: the **trust policy** (who may assume it, e.g.
`ec2.amazonaws.com`) and **permission policies** (what it can do once assumed).

## Policies and permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Sid": "ListOneBucket", "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::app-artifacts" },
    { "Sid": "ReadObjectsInIt", "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::app-artifacts/*" }
  ]
}
```

- **Effect** Allow or Deny, **Action** the API calls, **Resource** the ARNs,
  optional **Condition** (source IP, MFA present, tags, TLS...).
- `ListBucket` acts on the bucket ARN, `GetObject` on the objects (`/*`) - a
  classic mistake is putting both on one ARN and getting AccessDenied.
- Policy types: **AWS managed** (e.g. `ReadOnlyAccess`), **customer managed**
  (your own, reusable, versioned - used above), **inline** (embedded in one
  identity, deleted with it).

**Evaluation order:** everything starts as an implicit deny; an Allow grants;
an explicit **Deny always wins**, wherever it comes from (identity policy,
resource policy, SCP, permission boundary).

## Least privilege

Grant only the actions and resources a job needs, nothing more. The policy
above can read one bucket and cannot write, delete or see any other bucket.
In practice: start from nothing, add what fails, review with IAM Access
Analyzer (which can generate a policy from CloudTrail activity), and prefer
specific ARNs over `*`.

## What the demo does (LocalStack)

```text
$ aws iam create-user --user-name dev-pratyush --query User.[UserName,UserId,Arn] --output text
dev-pratyush	xg18v0w96pz7hkip8jl9	arn:aws:iam::000000000000:user/dev-pratyush
$ aws iam add-user-to-group --user-name dev-pratyush --group-name developers
$ aws iam create-policy --policy-name s3-read-app-artifacts ...  ->  arn:aws:iam::000000000000:policy/s3-read-app-artifacts
$ aws iam attach-group-policy --group-name developers --policy-arn arn:aws:iam::000000000000:policy/s3-read-app-artifacts
$ aws iam create-role --role-name app-ec2-role --assume-role-policy-document file://ec2-trust.json
app-ec2-role	arn:aws:iam::000000000000:role/app-ec2-role
$ aws iam get-role --role-name app-ec2-role --query Role.AssumeRolePolicyDocument.Statement[0].Principal
{
    "Service": "ec2.amazonaws.com"
}
```

User -> group -> customer-managed policy, then a role with an EC2 trust policy
wrapped in an instance profile (EC2 takes a profile, not a role directly).
Clean-up has to go in reverse: detach a policy before deleting it, remove a
role from its profile before deleting either.

> Honest limit: LocalStack Community stores IAM objects but does **not enforce**
> them - the S3 demo ran everything with the fake keys `test`/`test`. I tried
> `iam simulate-principal-policy` to show Allow vs Deny, but it returned
> `explicitDeny` for both an allowed and a denied action, so it is not used as
> evidence here. On real AWS the same command is the right way to test a policy.

The session 19 project uses the same pattern in Terraform: an instance role
limited to `s3:ListBucket`, `GetObject`, `PutObject` on one bucket
([../../../cloud-terraform/iam.tf](../../../cloud-terraform/iam.tf)).

## IAM best practices

1. Lock the root user: MFA, no access keys, use it only for the few
   root-only tasks.
2. Humans sign in through IAM Identity Center (SSO), not IAM users with keys.
3. Workloads use **roles**, never access keys baked into code, AMIs or env files.
4. MFA for every human; enforce with a `aws:MultiFactorAuthPresent` condition.
5. Least privilege, attached to groups/roles rather than individual users.
6. Rotate or remove unused credentials (the credential report shows them).
7. Turn on CloudTrail so every call is logged with the identity that made it.
8. Use permission boundaries / SCPs to cap what even admins can grant.

## Common use cases

| Need | IAM answer |
|---|---|
| App on EC2 reads S3 | Role + instance profile |
| GitHub Actions deploys to AWS | Role trusted via OIDC - no stored keys |
| Developers read prod, admins change it | Two groups with different policies |
| Another account reads our bucket | Cross-account role, or bucket policy naming that account |
| Contractor for one week | Temporary access via SSO assignment, removed after |

## Interview Q&A

**Q: User vs role?**
A user has permanent credentials; a role has none and hands out temporary ones
(minutes to hours) to whoever is allowed to assume it.

**Q: If one policy allows and another denies, what happens?**
Deny. An explicit Deny anywhere overrides any number of Allows.

**Q: Why is an access key in a git repo so bad?**
Bots scan public repos for keys within minutes and start crypto-mining on your
bill. Use roles; if a key leaks, deactivate it first, investigate second.

**Q: Identity-based vs resource-based policy?**
Identity-based is attached to the user/group/role ("what can I do"). Resource-
based is attached to the resource, e.g. an S3 bucket policy ("who can touch
me"), and is how cross-account access is usually granted.
