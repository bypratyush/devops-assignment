# DynamoDB and RDS on LocalStack - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./demo.sh` on 2026-10-07.

```text

==============================================================
1. Create a table: partition key student_id (S) + sort key course_id (S), on-demand billing
==============================================================
$ aws dynamodb create-table --table-name Enrolments --attribute-definitions AttributeName=student_id,AttributeType=S AttributeName=course_id,AttributeType=S --key-schema AttributeName=student_id,KeyType=HASH AttributeName=course_id,KeyType=RANGE --billing-mode PAY_PER_REQUEST --query TableDescription.[TableName,TableStatus,KeySchema] --output json
[
    "Enrolments",
    "ACTIVE",
    [
        {
            "AttributeName": "student_id",
            "KeyType": "HASH"
        },
        {
            "AttributeName": "course_id",
            "KeyType": "RANGE"
        }
    ]
]

==============================================================
2. Put items - same keys, but each item can carry different attributes (schemaless)
==============================================================
$ aws dynamodb put-item --table-name Enrolments --item {"student_id":{"S":"24BCS10238"},"course_id":{"S":"DEVOPS-101"},"grade":{"S":"A"},"sessions_done":{"N":"19"}}
$ aws dynamodb put-item --table-name Enrolments --item {"student_id":{"S":"24BCS10238"},"course_id":{"S":"CLOUD-201"},"status":{"S":"in-progress"}}
$ aws dynamodb put-item --table-name Enrolments --item {"student_id":{"S":"24BCS99999"},"course_id":{"S":"DEVOPS-101"},"grade":{"S":"B"}}

==============================================================
3. get-item: needs the FULL primary key (partition + sort)
==============================================================
$ aws dynamodb get-item --table-name Enrolments --key {"student_id":{"S":"24BCS10238"},"course_id":{"S":"DEVOPS-101"}} --output json
{
    "Item": {
        "sessions_done": {
            "N": "19"
        },
        "student_id": {
            "S": "24BCS10238"
        },
        "course_id": {
            "S": "DEVOPS-101"
        },
        "grade": {
            "S": "A"
        }
    }
}

==============================================================
4. query: one partition key, optional condition on the sort key
==============================================================
$ aws dynamodb query --table-name Enrolments --key-condition-expression student_id = :s --expression-attribute-values {":s":{"S":"24BCS10238"}} --query Items[].[course_id.S, grade.S, status.S] --output text
CLOUD-201	None	in-progress
DEVOPS-101	A	None
$ aws dynamodb query --table-name Enrolments --key-condition-expression student_id = :s AND begins_with(course_id, :c) --expression-attribute-values {":s":{"S":"24BCS10238"},":c":{"S":"DEVOPS"}} --query Count
1

==============================================================
5. scan: reads EVERY item in the table (fine here, expensive at scale)
==============================================================
$ aws dynamodb scan --table-name Enrolments --query [Count, ScannedCount] --output text
3	3

==============================================================
6. Clean up
==============================================================
$ aws dynamodb delete-table --table-name Enrolments --query TableDescription.TableStatus --output text
ACTIVE

==============================================================
7. RDS on LocalStack Community?
==============================================================
$ aws rds describe-db-instances

aws: [ERROR]: An error occurred (InternalFailure) when calling the DescribeDBInstances operation: The API for service rds is either not included in your current license plan or has not yet been emulated by LocalStack.
(RDS is not part of the LocalStack Community image - see README)
```
