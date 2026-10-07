#!/usr/bin/env bash
# IAM on LocalStack: a user in a group, a least-privilege customer-managed
# policy attached to the group, and a role that EC2 can assume.
# Needs LocalStack:  ./lab/localstack.sh up
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
EP=http://localhost:4566
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-south-1
run() { echo "\$ aws $*"; aws --endpoint-url="$EP" "$@"; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/s3-read-app-artifacts.json" <<'JSON'
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
JSON
cat > "$TMP/ec2-trust.json" <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole" }
  ]
}
JSON

hr "1. Who am I? (LocalStack's fake account 000000000000)"
run sts get-caller-identity

hr "2. A user, a group, and the user in the group"
run iam create-user --user-name dev-pratyush --query 'User.[UserName,UserId,Arn]' --output text
run iam create-group --group-name developers --query 'Group.[GroupName,Arn]' --output text
run iam add-user-to-group --user-name dev-pratyush --group-name developers
run iam get-group --group-name developers --query 'Users[].UserName' --output text

hr "3. A least-privilege policy: read ONE bucket, nothing else"
cat "$TMP/s3-read-app-artifacts.json"
POLICY_ARN=$(aws --endpoint-url="$EP" iam create-policy --policy-name s3-read-app-artifacts \
  --policy-document "file://$TMP/s3-read-app-artifacts.json" --query Policy.Arn --output text)
echo "\$ aws iam create-policy --policy-name s3-read-app-artifacts ...  ->  $POLICY_ARN"
run iam attach-group-policy --group-name developers --policy-arn "$POLICY_ARN"
run iam list-attached-group-policies --group-name developers --output table

hr "4. A role for EC2 (trust policy = WHO may assume it, permissions = WHAT it can do)"
echo '$ aws iam create-role --role-name app-ec2-role --assume-role-policy-document file://ec2-trust.json'
aws --endpoint-url="$EP" iam create-role --role-name app-ec2-role --assume-role-policy-document "file://$TMP/ec2-trust.json" \
  --query 'Role.[RoleName,Arn]' --output text
run iam attach-role-policy --role-name app-ec2-role --policy-arn "$POLICY_ARN"
run iam create-instance-profile --instance-profile-name app-ec2-profile --query 'InstanceProfile.Arn' --output text
run iam add-role-to-instance-profile --instance-profile-name app-ec2-profile --role-name app-ec2-role
run iam get-role --role-name app-ec2-role --query 'Role.AssumeRolePolicyDocument.Statement[0].Principal'

hr "5. Clean up (reverse order: detach before delete)"
run iam remove-role-from-instance-profile --instance-profile-name app-ec2-profile --role-name app-ec2-role
run iam delete-instance-profile --instance-profile-name app-ec2-profile
run iam detach-role-policy --role-name app-ec2-role --policy-arn "$POLICY_ARN"
run iam delete-role --role-name app-ec2-role
run iam detach-group-policy --group-name developers --policy-arn "$POLICY_ARN"
run iam remove-user-from-group --user-name dev-pratyush --group-name developers
run iam delete-group --group-name developers
run iam delete-user --user-name dev-pratyush
run iam delete-policy --policy-arn "$POLICY_ARN"
run iam list-users --query 'Users[].UserName' --output text
echo "(no users left)"
