# IAM on LocalStack - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./demo.sh` on 2026-10-07.

```text

==============================================================
1. Who am I? (LocalStack's fake account 000000000000)
==============================================================
$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "000000000000",
    "Arn": "arn:aws:iam::000000000000:root"
}

==============================================================
2. A user, a group, and the user in the group
==============================================================
$ aws iam create-user --user-name dev-pratyush --query User.[UserName,UserId,Arn] --output text
dev-pratyush	0zxhhbl3bq3rclblc3k7	arn:aws:iam::000000000000:user/dev-pratyush
$ aws iam create-group --group-name developers --query Group.[GroupName,Arn] --output text
developers	arn:aws:iam::000000000000:group/developers
$ aws iam add-user-to-group --user-name dev-pratyush --group-name developers
$ aws iam get-group --group-name developers --query Users[].UserName --output text
dev-pratyush

==============================================================
3. A least-privilege policy: read ONE bucket, nothing else
==============================================================
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
$ aws iam create-policy --policy-name s3-read-app-artifacts ...  ->  arn:aws:iam::000000000000:policy/s3-read-app-artifacts
$ aws iam attach-group-policy --group-name developers --policy-arn arn:aws:iam::000000000000:policy/s3-read-app-artifacts
$ aws iam list-attached-group-policies --group-name developers --output table
----------------------------------------------------------------------------
|                         ListAttachedGroupPolicies                        |
+--------------------------------------------------------------------------+
||                            AttachedPolicies                            ||
|+------------+-----------------------------------------------------------+|
||  PolicyArn |  arn:aws:iam::000000000000:policy/s3-read-app-artifacts   ||
||  PolicyName|  s3-read-app-artifacts                                    ||
|+------------+-----------------------------------------------------------+|

==============================================================
4. A role for EC2 (trust policy = WHO may assume it, permissions = WHAT it can do)
==============================================================
$ aws iam create-role --role-name app-ec2-role --assume-role-policy-document file://ec2-trust.json
app-ec2-role	arn:aws:iam::000000000000:role/app-ec2-role
$ aws iam attach-role-policy --role-name app-ec2-role --policy-arn arn:aws:iam::000000000000:policy/s3-read-app-artifacts
$ aws iam create-instance-profile --instance-profile-name app-ec2-profile --query InstanceProfile.Arn --output text
arn:aws:iam::000000000000:instance-profile/app-ec2-profile
$ aws iam add-role-to-instance-profile --instance-profile-name app-ec2-profile --role-name app-ec2-role
$ aws iam get-role --role-name app-ec2-role --query Role.AssumeRolePolicyDocument.Statement[0].Principal
{
    "Service": "ec2.amazonaws.com"
}

==============================================================
5. Clean up (reverse order: detach before delete)
==============================================================
$ aws iam remove-role-from-instance-profile --instance-profile-name app-ec2-profile --role-name app-ec2-role
$ aws iam delete-instance-profile --instance-profile-name app-ec2-profile
$ aws iam detach-role-policy --role-name app-ec2-role --policy-arn arn:aws:iam::000000000000:policy/s3-read-app-artifacts
$ aws iam delete-role --role-name app-ec2-role
$ aws iam detach-group-policy --group-name developers --policy-arn arn:aws:iam::000000000000:policy/s3-read-app-artifacts
$ aws iam remove-user-from-group --user-name dev-pratyush --group-name developers
$ aws iam delete-group --group-name developers
$ aws iam delete-user --user-name dev-pratyush
$ aws iam delete-policy --policy-arn arn:aws:iam::000000000000:policy/s3-read-app-artifacts
$ aws iam list-users --query Users[].UserName --output text
(no users left)
```
