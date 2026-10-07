#!/usr/bin/env bash
# DynamoDB on LocalStack: a table with a partition key + sort key, items with
# different attributes, get-item vs query. Then what happens when asking for RDS.
# Needs LocalStack:  ./lab/localstack.sh up
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
EP=http://localhost:4566
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=ap-south-1
run() { echo "\$ aws $*"; aws --endpoint-url="$EP" "$@"; }

hr "1. Create a table: partition key student_id (S) + sort key course_id (S), on-demand billing"
run dynamodb create-table --table-name Enrolments \
  --attribute-definitions AttributeName=student_id,AttributeType=S AttributeName=course_id,AttributeType=S \
  --key-schema AttributeName=student_id,KeyType=HASH AttributeName=course_id,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST --query 'TableDescription.[TableName,TableStatus,KeySchema]' --output json
aws --endpoint-url="$EP" dynamodb wait table-exists --table-name Enrolments

hr "2. Put items - same keys, but each item can carry different attributes (schemaless)"
run dynamodb put-item --table-name Enrolments --item '{"student_id":{"S":"24BCS10238"},"course_id":{"S":"DEVOPS-101"},"grade":{"S":"A"},"sessions_done":{"N":"19"}}'
run dynamodb put-item --table-name Enrolments --item '{"student_id":{"S":"24BCS10238"},"course_id":{"S":"CLOUD-201"},"status":{"S":"in-progress"}}'
run dynamodb put-item --table-name Enrolments --item '{"student_id":{"S":"24BCS99999"},"course_id":{"S":"DEVOPS-101"},"grade":{"S":"B"}}'

hr "3. get-item: needs the FULL primary key (partition + sort)"
run dynamodb get-item --table-name Enrolments \
  --key '{"student_id":{"S":"24BCS10238"},"course_id":{"S":"DEVOPS-101"}}' --output json

hr "4. query: one partition key, optional condition on the sort key"
run dynamodb query --table-name Enrolments \
  --key-condition-expression "student_id = :s" \
  --expression-attribute-values '{":s":{"S":"24BCS10238"}}' \
  --query 'Items[].[course_id.S, grade.S, status.S]' --output text
run dynamodb query --table-name Enrolments \
  --key-condition-expression "student_id = :s AND begins_with(course_id, :c)" \
  --expression-attribute-values '{":s":{"S":"24BCS10238"},":c":{"S":"DEVOPS"}}' \
  --query 'Count'

hr "5. scan: reads EVERY item in the table (fine here, expensive at scale)"
run dynamodb scan --table-name Enrolments --query '[Count, ScannedCount]' --output text

hr "6. Clean up"
run dynamodb delete-table --table-name Enrolments --query 'TableDescription.TableStatus' --output text

hr "7. RDS on LocalStack Community?"
run rds describe-db-instances 2>&1 | head -3
echo "(RDS is not part of the LocalStack Community image - see README)"
