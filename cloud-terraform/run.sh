#!/usr/bin/env bash
# Session 19 - VPC + subnets + IGW + route table + security group + EC2 + S3 + IAM,
# end to end with Terraform, verified with the AWS CLI, then destroyed.
#
# Runs against LocalStack. Start it first:  ./lab/localstack.sh up
# Usage: ./run.sh [deploy|verify|graph|destroy|shots|all]   (default: all)
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
ROOT=$(cd .. && pwd)

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

NC=""; [ -t 1 ] || NC="-no-color"   # plain text when captured into output.md

EP=http://localhost:4566
TAG="Name=tag:Project,Values=s19-web"
awsl() { aws --endpoint-url="$EP" "$@"; }
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-south-1
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

deploy() {
  hr "STEP 0 - Tools and target"
  terraform version | head -1
  aws --version
  curl -sf "$EP/_localstack/health" >/dev/null || { echo "LocalStack not running - ./lab/localstack.sh up"; exit 1; }
  curl -s "$EP/_localstack/health" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("LocalStack", d["version"], d["edition"])'
  echo "use_localstack = $(sed -n 's/^use_localstack *= *//p' terraform.tfvars)"
  echo
  echo "Files in this project:"
  ls -1 *.tf templates/

  hr "STEP 1 - terraform init"
  terraform init $NC

  hr "STEP 2 - terraform fmt -check  and  terraform validate"
  terraform fmt -check -diff -recursive && echo "fmt: all files already in canonical format"
  terraform validate $NC

  hr "STEP 3 - terraform plan -out=tfplan  (summary: one line per resource)"
  terraform plan $NC -out=tfplan > "$TMP/plan.txt" 2>&1
  grep -E "^  # |^Plan:" "$TMP/plan.txt"
  echo
  echo "--- the full planned block for the EC2 instance, as plan prints it ---"
  awk '/^  # aws_instance.web will be created/,/^    }$/' "$TMP/plan.txt"

  hr "STEP 4 - terraform apply tfplan  (watch the creation order follow the dependencies)"
  terraform apply $NC tfplan
  rm -f tfplan
}

verify() {
  hr "STEP 5 - terraform output"
  terraform output $NC

  hr "STEP 6 - terraform state list  (everything Terraform now tracks)"
  terraform state list
  echo
  python3 - <<'PY'
import json
s = json.load(open("terraform.tfstate"))
managed = [r for r in s["resources"] if r["mode"] == "managed"]
data = [r for r in s["resources"] if r["mode"] == "data"]
print(f"terraform.tfstate: format v{s['version']}, serial {s['serial']}, lineage {s['lineage'][:8]}...")
print(f"  {len(managed)} managed resources, {len(data)} data sources, {len(s['outputs'])} outputs")
PY

  hr "STEP 7 - terraform state show aws_route_table.public  (one resource, as recorded)"
  terraform state show $NC aws_route_table.public

  hr "STEP 8 - The same state, machine-readable: aws_instance.web via terraform show -json"
  terraform show -json > "$TMP/state.json"
  python3 - "$TMP/state.json" <<'PY'
import json, sys
s = json.load(open(sys.argv[1]))
r = next(r for r in s["values"]["root_module"]["resources"] if r["address"] == "aws_instance.web")
v = r["values"]
for k in ["id", "ami", "instance_type", "instance_state", "availability_zone", "subnet_id",
          "vpc_security_group_ids", "private_ip", "public_ip", "iam_instance_profile"]:
    print(f"  {k:24} {v[k]}")
print(f"  {'metadata http_tokens':24} {v['metadata_options'][0]['http_tokens']}")
rb = v["root_block_device"][0]
print(f"  {'root volume':24} {rb['volume_size']} GiB {rb['volume_type']}, encrypted={rb['encrypted']}")
print(f"  {'depends_on (in state)':24} {r.get('depends_on')}")
PY

  hr "STEP 9 - Verify with the AWS CLI (asking the API, not Terraform)"
  echo '$ aws ec2 describe-vpcs'
  awsl ec2 describe-vpcs --filters "$TAG" --query 'Vpcs[].{VpcId:VpcId,Cidr:CidrBlock,State:State,Name:Tags[?Key==`Name`]|[0].Value}' --output table
  echo '$ aws ec2 describe-subnets'
  awsl ec2 describe-subnets --filters "$TAG" --query 'Subnets[].{Name:Tags[?Key==`Name`]|[0].Value,Id:SubnetId,Cidr:CidrBlock,AZ:AvailabilityZone,PublicIpOnLaunch:MapPublicIpOnLaunch}' --output table
  echo '$ aws ec2 describe-internet-gateways'
  awsl ec2 describe-internet-gateways --filters "$TAG" --query 'InternetGateways[].{Id:InternetGatewayId,AttachedTo:Attachments[0].VpcId,State:Attachments[0].State}' --output table
  echo '$ aws ec2 describe-route-tables  (the public one: local route + default route to the IGW)'
  awsl ec2 describe-route-tables --filters "$TAG" --query 'RouteTables[].Routes[].{Destination:DestinationCidrBlock,Target:GatewayId,State:State}' --output table
  awsl ec2 describe-route-tables --filters "$TAG" --query 'RouteTables[].Associations[].{RouteTable:RouteTableId,Subnet:SubnetId}' --output table
  echo '$ aws ec2 describe-security-group-rules'
  SG=$(terraform output -raw security_group_id)
  awsl ec2 describe-security-group-rules --filters "Name=group-id,Values=$SG" --query 'SecurityGroupRules[].{Egress:IsEgress,Proto:IpProtocol,From:FromPort,To:ToPort,Cidr:CidrIpv4,Desc:Description}' --output table
  echo '$ aws ec2 describe-instances'
  awsl ec2 describe-instances --filters "$TAG" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].{Id:InstanceId,Type:InstanceType,State:State.Name,Ami:ImageId,PrivateIp:PrivateIpAddress,PublicIp:PublicIpAddress,IMDS:MetadataOptions.HttpTokens}' --output table
  echo '$ aws s3 ls  and the release artifact'
  BUCKET=$(terraform output -raw artifacts_bucket)
  awsl s3 ls
  awsl s3 ls "s3://$BUCKET/" --recursive
  awsl s3 cp "s3://$BUCKET/releases/v1/RELEASE.txt" -
  echo '$ aws iam get-role-policy  (the least-privilege policy on the instance role)'
  awsl iam get-role-policy --role-name s19-web-web-role --policy-name artifacts-bucket-rw --query 'PolicyDocument.Statement[].{Sid:Sid,Action:Action,Resource:Resource}' --output json

  hr "STEP 10 - Idempotency: a second plan right after apply must be empty"
  terraform plan $NC -detailed-exitcode > "$TMP/replan.txt" 2>&1
  echo "plan exit code: $?  (0 = no changes, 2 = changes)"
  grep -E "No changes|Plan:" "$TMP/replan.txt"

  hr "STEP 11 - In-place update vs replacement (plan only, nothing applied)"
  echo '--- change the instance type: the provider can stop, resize and start the same'
  echo '    instance, so this is ~ update in-place. RELEASE.txt changes too, because its'
  echo '    content references var.instance_type ---'
  terraform plan $NC -var instance_type=t3.small 2>&1 | grep -E "^  # |^Plan:|instance_type"
  echo
  echo '--- change the public subnet CIDR: a subnet CIDR is immutable, so -/+ replace,'
  echo '    and everything that references the subnet is replaced with it ---'
  terraform plan $NC -var public_subnet_cidr=10.20.3.0/24 2>&1 | grep -E "^  # |^Plan:|forces replacement"
}

graph() {
  hr "STEP 12 - terraform graph  (dependency graph -> docs/terraform-graph.png)"
  terraform graph > docs/terraform-graph.dot
  echo "$(grep -c -- '->' docs/terraform-graph.dot) edges written to docs/terraform-graph.dot"
  if command -v dot >/dev/null; then
    dot -Tpng -Gdpi=110 docs/terraform-graph.dot -o docs/terraform-graph.png && echo "rendered docs/terraform-graph.png with $(dot -V 2>&1)"
  else
    echo "graphviz 'dot' not installed - skipping the PNG"
  fi
  echo
  echo "--- what aws_instance.web waits for (edges out of it) ---"
  grep '"aws_instance.web" ->' docs/terraform-graph.dot
  echo
  echo "--- the same, from a copy of the code with depends_on deleted ---"
  mkdir -p "$TMP/nodep"
  cp ./*.tf .terraform.lock.hcl terraform.tfvars "$TMP/nodep/"; cp -r templates "$TMP/nodep/"
  ln -s "$PWD/.terraform" "$TMP/nodep/.terraform"
  python3 - "$TMP/nodep/compute.tf" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
open(p, "w").write(s[:s.index("  depends_on")] + "}\n")
PY
  (cd "$TMP/nodep" && terraform graph | grep '"aws_instance.web" ->')
  echo
  echo "Without depends_on the instance points straight at the subnet and nothing ties"
  echo "it to the route table, so both could be created in parallel. With it, the edge"
  echo "goes to the route table association instead (the direct subnet edge is dropped"
  echo "from the drawing because it is now implied through the association)."
}

destroy() {
  hr "STEP 13 - terraform destroy  (progress lines only; the plan is the reverse of apply)"
  terraform destroy $NC -auto-approve 2>&1 | grep -E "^Plan:|Destroying\.\.\.|Destruction complete|Destroy complete|Error"

  hr "STEP 14 - Prove it is gone"
  echo '$ aws ec2 describe-vpcs --filters tag:Project=s19-web'
  awsl ec2 describe-vpcs --filters "$TAG" --query 'Vpcs[].VpcId' --output json
  echo '$ aws ec2 describe-instances  (terminated instances stay listed for a while, as on AWS)'
  awsl ec2 describe-instances --filters "$TAG" --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name}' --output table
  echo '$ aws s3 ls'
  awsl s3 ls
  echo "(no bucket listed)"
  echo '$ terraform state list'
  terraform state list
  echo "(empty)"
  hr "DONE"
}

shots() {
  local S="$ROOT/lab/shot.sh"
  terraform init -input=false >/dev/null
  WIDTH=110 "$S" screenshots/terraform-plan-summary.png bash -c 'terraform plan | grep -E "will be|Plan:"'
  WIDTH=120 "$S" screenshots/terraform-apply.png bash -c 'terraform apply -auto-approve | tail -n 32'
  WIDTH=110 "$S" screenshots/terraform-state-list.png terraform state list
  WIDTH=120 "$S" screenshots/aws-cli-verify.png bash -c "aws --endpoint-url=$EP ec2 describe-instances --filters $TAG Name=instance-state-name,Values=running --query 'Reservations[].Instances[].{Id:InstanceId,Type:InstanceType,State:State.Name,PrivateIp:PrivateIpAddress,PublicIp:PublicIpAddress}' --output table && aws --endpoint-url=$EP ec2 describe-subnets --filters $TAG --query 'Subnets[].{Name:Tags[?Key==\`Name\`]|[0].Value,Cidr:CidrBlock,AZ:AvailabilityZone,PublicIp:MapPublicIpOnLaunch}' --output table && aws --endpoint-url=$EP s3 ls"
  WIDTH=120 "$S" screenshots/terraform-destroy.png bash -c 'terraform destroy -auto-approve | tail -n 24'
}

case "${1:-all}" in
  deploy)  deploy ;;
  verify)  verify ;;
  graph)   graph ;;
  destroy) destroy ;;
  shots)   shots ;;
  all)     deploy; verify; graph; destroy ;;
  *) echo "usage: $0 [deploy|verify|graph|destroy|shots|all]"; exit 1 ;;
esac
