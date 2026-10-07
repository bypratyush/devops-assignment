#!/usr/bin/env bash
# Session 21 - infrastructure for Campus Lost & Found: VPC across two AZs,
# IAM roles for EKS, an S3 backup bucket, and the EKS cluster + node group
# behind enable_eks. Runs against LocalStack on localhost:4567 (own container,
# localstack-final), verified with the AWS CLI, then destroyed.
#
# Usage: ./run.sh [up|deploy|verify|eks-plan|destroy|shots|down|all]   (default: all)
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
ROOT=$(cd ../.. && pwd)

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

NC=""; [ -t 1 ] || NC="-no-color"   # plain text when captured into output.md

LS_NAME=localstack-final
LS_IMAGE=localstack/localstack:4.14.0   # last image that runs without an auth token
EP=http://localhost:4567
TAG="Name=tag:Project,Values=lostfound"
awsl() { aws --endpoint-url="$EP" "$@"; }
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-south-1
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

up() {
  hr "STEP 0 - LocalStack on $EP (container $LS_NAME)"
  docker inspect "$LS_NAME" >/dev/null 2>&1 \
    || docker run -d --name "$LS_NAME" -p 127.0.0.1:4567:4566 "$LS_IMAGE" >/dev/null
  for _ in $(seq 1 60); do
    curl -sf "$EP/_localstack/health" 2>/dev/null | grep -q '"s3": "\(available\|running\)"' && break
    sleep 1
  done
  docker ps --filter "name=^${LS_NAME}$" --format '{{.Names}}  {{.Image}}  {{.Status}}  {{.Ports}}'
  curl -s "$EP/_localstack/health" > "$TMP/health.json"
  python3 - "$TMP/health.json" <<'PY2'
import json, sys
d = json.load(open(sys.argv[1]))
print("LocalStack", d["version"], d["edition"])
for s in ("ec2", "iam", "s3", "sts", "eks"):
    print(f"  {s:4} {d['services'].get(s, 'not in this edition')}")
PY2
}

deploy() {
  hr "STEP 1 - Tools and files"
  terraform version | head -1
  aws --version
  echo "use_localstack = $(sed -n 's/^use_localstack *= *//p' terraform.tfvars), enable_eks = $(sed -n 's/^enable_eks *= *//p' terraform.tfvars)"
  ls -1 *.tf

  hr "STEP 2 - terraform init"
  terraform init $NC -input=false

  hr "STEP 3 - terraform fmt -check  and  terraform validate"
  terraform fmt -check -diff -recursive && echo "fmt: all files already in canonical format"
  terraform validate $NC

  hr "STEP 4 - terraform plan -out=tfplan  (enable_eks = false: one line per resource)"
  terraform plan $NC -input=false -out=tfplan > "$TMP/plan.txt" 2>&1
  grep -E "^  # |^Plan:|Error" "$TMP/plan.txt"

  hr "STEP 5 - terraform apply tfplan"
  terraform apply $NC -input=false tfplan
  rm -f tfplan
}

verify() {
  hr "STEP 6 - terraform output"
  terraform output $NC

  hr "STEP 7 - terraform state list"
  terraform state list
  echo
  echo "$(terraform state list | wc -l | tr -d ' ') addresses in state (incl. data sources)"

  hr "STEP 8 - Verify with the AWS CLI (asking the API, not Terraform)"
  echo '$ aws ec2 describe-vpcs'
  awsl ec2 describe-vpcs --filters "$TAG" --query 'Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,State:State,Name:Tags[?Key==`Name`]|[0].Value}' --output table
  echo '$ aws ec2 describe-subnets'
  awsl ec2 describe-subnets --filters "$TAG" --query 'sort_by(Subnets,&CidrBlock)[].{Name:Tags[?Key==`Name`]|[0].Value,Id:SubnetId,Cidr:CidrBlock,AZ:AvailabilityZone,PublicIp:MapPublicIpOnLaunch}' --output table
  echo '$ aws ec2 describe-route-tables  (routes per table)'
  awsl ec2 describe-route-tables --filters "$TAG" --query 'RouteTables[].{Name:Tags[?Key==`Name`]|[0].Value,Routes:join(`, `,Routes[].join(` -> `,[DestinationCidrBlock,GatewayId])),Subnets:length(Associations[?SubnetId])}' --output table
  echo '$ aws ec2 describe-security-group-rules  (worker node SG)'
  SG=$(terraform output -raw node_security_group_id)
  awsl ec2 describe-security-group-rules --filters "Name=group-id,Values=$SG" --query 'SecurityGroupRules[].{Egress:IsEgress,Proto:IpProtocol,From:FromPort,To:ToPort,Source:CidrIpv4||ReferencedGroupInfo.GroupId,Desc:Description}' --output table
  echo '$ aws iam list-attached-role-policies  (both EKS roles)'
  for r in lostfound-eks-cluster lostfound-eks-nodes; do
    echo "$r:"; awsl iam list-attached-role-policies --role-name "$r" --query 'AttachedPolicies[].PolicyArn' --output text | tr '\t' '\n' | sed 's/^/  /'
  done
  BUCKET=$(terraform output -raw backup_bucket)
  echo "\$ aws s3api get-bucket-versioning --bucket $BUCKET"
  awsl s3api get-bucket-versioning --bucket "$BUCKET"
  echo "\$ aws s3api get-bucket-encryption --bucket $BUCKET"
  awsl s3api get-bucket-encryption --bucket "$BUCKET" --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault'
  echo "\$ aws s3api get-public-access-block --bucket $BUCKET"
  awsl s3api get-public-access-block --bucket "$BUCKET" --query PublicAccessBlockConfiguration
  echo '--- a backup round trip: two uploads of the same key = two versions'
  echo "pg_dump placeholder 1" > "$TMP/lostfound.sql"; awsl s3 cp "$TMP/lostfound.sql" "s3://$BUCKET/daily/lostfound.sql" --only-show-errors
  echo "pg_dump placeholder 2" > "$TMP/lostfound.sql"; awsl s3 cp "$TMP/lostfound.sql" "s3://$BUCKET/daily/lostfound.sql" --only-show-errors
  awsl s3api list-object-versions --bucket "$BUCKET" --query 'Versions[].{Key:Key,Latest:IsLatest,Size:Size}' --output table

  hr "STEP 9 - Idempotency: a second plan right after apply must be empty"
  terraform plan $NC -input=false -detailed-exitcode > "$TMP/replan.txt" 2>&1
  echo "plan exit code: $?  (0 = no changes, 2 = changes)"
  grep -E "No changes|Plan:" "$TMP/replan.txt"
}

eks_plan() {
  hr "STEP 10 - terraform plan -var enable_eks=true  (what a real account would get)"
  terraform plan $NC -input=false -var enable_eks=true > "$TMP/eks.txt" 2>&1
  echo "plan exit code: $?"
  grep -E "^  # |^Plan:|Error" "$TMP/eks.txt"
  echo
  echo "--- aws_eks_cluster.main[0] and aws_eks_node_group.main[0], as plan prints them ---"
  # both blocks, minus their tags / tags_all maps (the default_tags, 6 lines each)
  for r in aws_eks_cluster aws_eks_node_group; do
    awk -v r="$r" '$0 ~ "^  # "r".main\\[0\\] will be created" {on=1}
      on && /^ +\+ tags(_all)? += \{/ {skip=1; next}
      skip { if ($0 ~ /^ +}$/) skip=0; next }
      on {print} on && /^    }$/ {exit}' "$TMP/eks.txt"
  done
  echo
  echo "--- and why it is not applied here: LocalStack Community has no EKS API ---"
  echo "\$ aws eks list-clusters --endpoint-url $EP"
  awsl eks list-clusters 2>&1 | head -3
}

destroy() {
  hr "STEP 11 - terraform destroy"
  BUCKET=$(terraform output -raw backup_bucket 2>/dev/null)
  if [ -n "$BUCKET" ]; then
    # a versioned bucket only deletes when every version is gone; the test
    # backups from STEP 8 are removed here (force_destroy stays false on purpose)
    awsl s3api list-object-versions --bucket "$BUCKET" --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json > "$TMP/v.json"
    grep -q VersionId "$TMP/v.json" && awsl s3api delete-objects --bucket "$BUCKET" --delete "file://$TMP/v.json" --query 'length(Deleted)' --output text | sed 's/$/ object versions deleted/'
  fi
  terraform destroy $NC -input=false -auto-approve
  echo
  echo "state after destroy: $(terraform state list | wc -l | tr -d ' ') resources"
  echo "VPCs tagged Project=lostfound left: $(awsl ec2 describe-vpcs --filters "$TAG" --query 'length(Vpcs)')"
}

shots() {
  local S="$ROOT/lab/shot.sh"
  terraform init -input=false >/dev/null
  WIDTH=110 "$S" screenshots/terraform-plan-summary.png bash -c 'terraform plan -input=false | grep -E "will be|Plan:"'
  WIDTH=120 "$S" screenshots/terraform-eks-plan.png bash -c 'terraform plan -no-color -input=false -var enable_eks=true | grep -E "aws_eks|aws_nat|aws_launch|aws_route.private_nat|aws_eip|Plan:|\+ (name|version|ami_type|capacity_type|node_group_name|desired_size|min_size|max_size|authentication_mode|endpoint_public_access) +="'
  WIDTH=120 "$S" screenshots/terraform-apply-outputs.png bash -c 'terraform apply -input=false -auto-approve | tail -n 30'
  WIDTH=120 "$S" screenshots/aws-cli-verify.png bash -c "aws --endpoint-url=$EP ec2 describe-subnets --filters $TAG --query 'sort_by(Subnets,&CidrBlock)[].{Name:Tags[?Key==\`Name\`]|[0].Value,Cidr:CidrBlock,AZ:AvailabilityZone,PublicIp:MapPublicIpOnLaunch}' --output table && aws --endpoint-url=$EP s3api get-bucket-versioning --bucket pratyush-24bcs10238-lostfound-db-backups"
  WIDTH=120 "$S" screenshots/terraform-destroy.png bash -c 'terraform destroy -input=false -auto-approve | tail -n 22'
}

down() {
  hr "CLEANUP - remove $LS_NAME and the provider cache"
  docker rm -f "$LS_NAME" >/dev/null 2>&1 && echo "removed $LS_NAME"
  rm -rf .terraform && echo "removed .terraform/"
}

case "${1:-all}" in
  up)       up ;;
  deploy)   deploy ;;
  verify)   verify ;;
  eks-plan) eks_plan ;;
  destroy)  destroy ;;
  shots)    shots ;;
  down)     down ;;
  all)      up; deploy; verify; eks_plan; destroy ;;
  *) echo "usage: $0 [up|deploy|verify|eks-plan|destroy|shots|down|all]"; exit 1 ;;
esac
