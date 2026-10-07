#!/usr/bin/env bash
# Session 18 Task 1 - an S3 bucket with Terraform, the whole lifecycle:
#   init -> fmt -> validate -> plan -> apply -> (AWS CLI proof) -> show -> output -> destroy
#
# Runs against LocalStack. Start it first:  ./lab/localstack.sh up
# Usage: ./run.sh [deploy|verify|destroy|shots|all]   (default: all)
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
ROOT=$(cd ../.. && pwd)

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

# colour in a terminal, plain text when captured into output.md
NC=""; [ -t 1 ] || NC="-no-color"

EP=http://localhost:4566
BUCKET=$(sed -n 's/^bucket_name *= *"\(.*\)"/\1/p' terraform.tfvars)
awsl() { aws --endpoint-url="$EP" "$@"; }

# LocalStack accepts any credentials, but the AWS CLI refuses to run without some.
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-south-1

preflight() {
  hr "STEP 0 - Tools, and where the API calls will go"
  terraform version | head -1
  aws --version
  if ! curl -sf "$EP/_localstack/health" >/dev/null; then
    echo "LocalStack is not running on $EP - start it with ./lab/localstack.sh up"; exit 1
  fi
  curl -s "$EP/_localstack/health" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("LocalStack", d["version"], d["edition"], "edition - s3:", d["services"]["s3"])'
  echo "use_localstack in terraform.tfvars: $(sed -n 's/^use_localstack *= *//p' terraform.tfvars)"
}

deploy() {
  preflight

  hr "STEP 1 - terraform init (download the AWS provider, create .terraform/ and the lock file)"
  terraform init $NC
  echo
  echo "--- what init created ---"
  ls -d .terraform .terraform.lock.hcl
  ls .terraform/providers/registry.terraform.io/hashicorp/aws/

  hr "STEP 2 - terraform fmt (canonical formatting; -check exits 3 if a file needs rewriting)"
  terraform fmt -check -diff -recursive
  echo "terraform fmt -check exit code: $?  (0 = every file already formatted)"

  hr "STEP 3 - terraform validate (syntax, types, references - no API calls)"
  terraform validate $NC

  hr "STEP 4 - terraform plan (refresh + diff, saved to a plan file)"
  terraform plan $NC -out=tfplan

  hr "STEP 5 - terraform apply tfplan (exactly the reviewed plan, so no yes/no prompt)"
  terraform apply $NC tfplan
  rm -f tfplan
}

verify() {
  hr "STEP 6 - Prove the bucket really exists, asking S3 directly (not Terraform)"
  echo '$ aws s3 ls'
  awsl s3 ls
  echo
  echo "\$ aws s3api head-bucket --bucket $BUCKET"
  awsl s3api head-bucket --bucket "$BUCKET" && echo "(exit 0 = bucket exists and we can access it)"
  echo
  echo '$ aws s3api get-bucket-versioning'
  awsl s3api get-bucket-versioning --bucket "$BUCKET"
  echo '$ aws s3api get-bucket-encryption'
  awsl s3api get-bucket-encryption --bucket "$BUCKET" --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault'
  echo '$ aws s3api get-public-access-block'
  awsl s3api get-public-access-block --bucket "$BUCKET" --query PublicAccessBlockConfiguration
  echo '$ aws s3api get-bucket-lifecycle-configuration (rule ids only)'
  awsl s3api get-bucket-lifecycle-configuration --bucket "$BUCKET" --query 'Rules[].{id:ID,status:Status,prefix:Filter.Prefix}' --output table
  echo '$ aws s3api get-bucket-tagging (default_tags + resource tags merged)'
  awsl s3api get-bucket-tagging --bucket "$BUCKET" --query 'TagSet[].[Key,Value]' --output text | sort
  echo
  echo "\$ aws s3 ls s3://$BUCKET/  and read the object back"
  awsl s3 ls "s3://$BUCKET/"
  awsl s3 cp "s3://$BUCKET/welcome.txt" -
  echo '$ aws s3api head-object (was it encrypted by the bucket default?)'
  awsl s3api head-object --bucket "$BUCKET" --key welcome.txt --query '{size:ContentLength,type:ContentType,sse:ServerSideEncryption,version:VersionId}'

  hr "STEP 7 - terraform show (the state file, human-readable)"
  terraform show $NC

  hr "STEP 8 - terraform state list (every resource Terraform is tracking)"
  terraform state list
  echo
  ls -l terraform.tfstate | awk '{print $5" bytes  "$9}'
  python3 -c 'import json; s=json.load(open("terraform.tfstate")); print("format version", s["version"], "| terraform", s["terraform_version"], "| serial", s["serial"], "| lineage", s["lineage"])'

  hr "STEP 9 - terraform output (values exported by outputs.tf)"
  terraform output $NC
  echo
  echo '$ terraform output -raw bucket_name      # no quotes, for use in scripts'
  terraform output -raw bucket_name; echo
  echo '$ terraform output -json   (machine-readable, e.g. for a CI step; first 8 lines)'
  terraform output -json | head -8

  hr "STEP 10 - Versioning in action, and why force_destroy matters"
  echo "Uploading logs/app.log twice with different content ..."
  echo "first write"  | awsl s3 cp - "s3://$BUCKET/logs/app.log" >/dev/null
  echo "second write" | awsl s3 cp - "s3://$BUCKET/logs/app.log" >/dev/null
  awsl s3api list-object-versions --bucket "$BUCKET" --prefix logs/ \
    --query 'Versions[].{key:Key,latest:IsLatest,version:VersionId,size:Size}' --output table
  echo "Both versions are kept. These objects are NOT in Terraform state, so without"
  echo "force_destroy = true the destroy step would fail with BucketNotEmpty."

  hr "STEP 11 - Drift: change the bucket behind Terraform's back, let plan catch it"
  echo "\$ aws s3api put-bucket-versioning --versioning-configuration Status=Suspended"
  awsl s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Suspended
  awsl s3api get-bucket-versioning --bucket "$BUCKET"
  echo
  echo '$ terraform plan -detailed-exitcode   (exit 0 = no changes, 2 = changes pending)'
  terraform plan $NC -detailed-exitcode
  echo "plan exit code: $?"
  echo
  echo '$ terraform apply -auto-approve   (put it back the way the code says)'
  terraform apply $NC -auto-approve | grep -E "Modifying|Modifications complete|Apply complete"
  awsl s3api get-bucket-versioning --bucket "$BUCKET"
}

destroy() {
  hr "STEP 12 - terraform plan -destroy (preview what will be deleted)"
  terraform plan $NC -destroy | grep -E "will be destroyed|^Plan:"

  hr "STEP 13 - terraform destroy"
  terraform destroy $NC -auto-approve

  hr "STEP 14 - Prove it is gone"
  echo "\$ aws s3api head-bucket --bucket $BUCKET"
  awsl s3api head-bucket --bucket "$BUCKET" 2>&1 || echo "(non-zero exit: the bucket no longer exists)"
  echo
  echo '$ terraform state list   (empty)'
  terraform state list
  echo '$ terraform show'
  terraform show $NC
  echo
  echo "The state file itself remains, with no resources in it:"
  python3 -c 'import json; s=json.load(open("terraform.tfstate")); print("serial", s["serial"], "| resources:", len(s["resources"]))'
  hr "DONE"
}

shots() {
  # Real terminal captures. Creates and destroys the bucket again.
  local S="$ROOT/lab/shot.sh"
  terraform init -input=false >/dev/null
  WIDTH=120 "$S" screenshots/terraform-plan.png bash -c 'terraform plan | tail -n 24'
  WIDTH=120 "$S" screenshots/terraform-apply.png bash -c 'terraform apply -auto-approve | tail -n 22'
  WIDTH=110 "$S" screenshots/terraform-output.png terraform output
  WIDTH=120 "$S" screenshots/aws-s3-ls-proof.png bash -c "aws --endpoint-url=$EP s3 ls && aws --endpoint-url=$EP s3 ls s3://$BUCKET/ && aws --endpoint-url=$EP s3api get-bucket-versioning --bucket $BUCKET && aws --endpoint-url=$EP s3api get-bucket-encryption --bucket $BUCKET --query 'ServerSideEncryptionConfiguration.Rules[0]'"
  WIDTH=120 "$S" screenshots/terraform-destroy.png bash -c 'terraform destroy -auto-approve | tail -n 16'
}

case "${1:-all}" in
  deploy)  deploy ;;
  verify)  verify ;;
  destroy) destroy ;;
  shots)   shots ;;
  all)     deploy; verify; destroy ;;
  *) echo "usage: $0 [deploy|verify|destroy|shots|all]"; exit 1 ;;
esac
