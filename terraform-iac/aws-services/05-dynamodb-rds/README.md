# 05 - DynamoDB & RDS (Database Services)

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

**Form field:** AWS Services Research - DynamoDB & RDS · **Course session:** `session18-terraform-iac`

Hands-on: [demo.sh](demo.sh) · real output against LocalStack: [output.md](output.md)

---

## DynamoDB

### NoSQL

DynamoDB is a fully managed, serverless **key-value and document** database.
No servers, no patching, no connection pools; you pay per request
(on-demand) or for provisioned capacity, and it scales to millions of
requests per second with single-digit millisecond latency. "NoSQL" here means:
no joins, no fixed schema beyond the key, and you design the table around the
queries you will run rather than normalising first.

### Tables, items, attributes

| Relational | DynamoDB |
|---|---|
| Table | Table |
| Row | **Item** (max 400 KB) |
| Column | **Attribute** (typed: S, N, B, BOOL, L, M, SS...) |
| Fixed schema | Only the key attributes are required; every item can differ |

The demo puts three items; two have a `grade`, one has a `status` instead -
no `ALTER TABLE` needed.

### Partition key and sort key

- **Partition key** (HASH): hashed to decide which physical partition stores
  the item. Must be high-cardinality so load spreads out; a key like
  `country = "IN"` creates a hot partition.
- **Sort key** (RANGE, optional): orders items that share a partition key and
  enables range queries (`begins_with`, `between`, `<`, `>`).
- Partition key alone, or partition + sort, is the **primary key** and must be
  unique.

From the demo (LocalStack), table `Enrolments` with `student_id` + `course_id`:

```text
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

$ aws dynamodb query ... --key-condition-expression student_id = :s ...
CLOUD-201	None	in-progress
DEVOPS-101	A	None
$ aws dynamodb query ... student_id = :s AND begins_with(course_id, :c) ... --query Count
1
$ aws dynamodb scan --table-name Enrolments --query [Count, ScannedCount] --output text
3	3
```

- `get-item` needs the full primary key and returns one item.
- `query` needs the partition key and returns that partition's items, sorted
  by the sort key - one student's courses came back in order `CLOUD-201`,
  `DEVOPS-101`. `None` is just the CLI printing a missing attribute.
- `scan` reads the whole table (`ScannedCount` 3). Fine for 3 items, slow and
  expensive at a million. Needing scans usually means a missing index.

Other access patterns are served by **Global Secondary Indexes** (different
partition/sort key) and **Local Secondary Indexes** (same partition key,
different sort key).

### Use cases

Session stores, shopping carts, user profiles, leaderboards, IoT telemetry,
gaming state, serverless backends with Lambda, and the **Terraform state lock
table** (older S3 backends; newer ones use `use_lockfile`).

---

## RDS

### Relational database, managed

Relational Database Service runs a SQL database for you: AWS handles
provisioning, OS and engine patching, backups, failover and monitoring; you
keep the schema, queries, indexes and tuning. Use it when data is relational,
needs joins and multi-row transactions, or an existing app expects SQL.

### Supported engines

| Engine | Notes |
|---|---|
| PostgreSQL | Popular default for new apps |
| MySQL | Widely used, simple |
| MariaDB | MySQL fork |
| Oracle | Licence included or bring your own |
| SQL Server | Express to Enterprise editions |
| Db2 | IBM |
| **Aurora** (MySQL / PostgreSQL compatible) | AWS-built storage layer: 6 copies across 3 AZs, faster failover, up to 15 replicas; Aurora Serverless v2 scales capacity automatically |

### DB instances

A DB instance is the managed server: an instance class (`db.t4g.micro`,
`db.m7g.large`, `db.r7g.xlarge`), storage (gp3 or io2, autoscaling possible),
an engine version, and a **DB subnet group** - subnets in at least two AZs,
normally private ones, where RDS may place it. You connect to an **endpoint**
DNS name, never an IP, because the IP changes on failover.

### Security

- Put it in **private subnets**, `publicly_accessible = false`.
- A security group allowing the DB port **only from the app's security group**.
- Encryption at rest with KMS (must be chosen at creation; covers storage,
  backups, snapshots and replicas) and TLS in transit.
- Master password in **Secrets Manager** with rotation (RDS can manage it
  itself), or IAM database authentication instead of passwords.
- Deletion protection on, so a stray `terraform destroy` fails.

### Backups

- **Automated backups**: daily snapshot plus transaction logs, retention 1-35
  days, giving **point-in-time restore** to any second in that window.
- **Manual snapshots**: kept until you delete them; can be copied to another
  region or account for DR.
- A restore always creates a **new** DB instance with a new endpoint.

### Multi-AZ

A synchronous standby in another AZ. If the primary or its AZ fails, RDS flips
the endpoint's DNS to the standby, typically in 60-120 seconds. The standby
serves **no reads** - it is for availability, not performance. (Multi-AZ DB
*clusters* with two readable standbys also exist for MySQL/PostgreSQL.)

### Read replicas

Asynchronous copies that **serve reads**, in the same region or another one, to
scale read-heavy workloads or bring data closer to users. Replication lag
means they can be slightly behind. A replica can be promoted to a standalone
database (manual DR).

| | Multi-AZ standby | Read replica |
|---|---|---|
| Purpose | High availability | Read scaling |
| Replication | Synchronous | Asynchronous |
| Readable | No | Yes |
| Failover | Automatic | Manual promote |

### Use cases

Web and mobile app backends, e-commerce orders and payments (transactions),
ERP/CRM systems, reporting, and moving an existing on-prem MySQL/PostgreSQL/
Oracle database to the cloud without rewriting the app.

### Why there is no RDS demo

```text
$ aws rds describe-db-instances

aws: [ERROR]: An error occurred (InternalFailure) when calling the DescribeDBInstances operation: The API for service rds is either not included in your current license plan or has not yet been emulated by LocalStack.
```

RDS is not in the LocalStack Community image (the health endpoint does not
list it), and creating a real one needs an AWS account. So this half is study
notes only.

---

## DynamoDB or RDS?

| Question | DynamoDB | RDS |
|---|---|---|
| Access pattern known and key-based? | Ideal | Works |
| Joins, ad-hoc queries, reporting? | Poor | Ideal |
| Scale | Practically unlimited, automatic | Vertical + read replicas |
| Operations | None (serverless) | Some: instance size, maintenance windows |
| Pricing | Per request or capacity | Per instance-hour + storage, even idle |

## Interview Q&A

**Q: What makes a good partition key?**
High cardinality and evenly accessed - user ID, order ID. A low-cardinality key
concentrates traffic on one partition and gets throttled.

**Q: Query vs scan?**
Query reads one partition using the key and is efficient. Scan reads every item
in the table and filters afterwards; avoid it on large tables.

**Q: Multi-AZ vs read replica?**
Multi-AZ is a synchronous, non-readable standby for automatic failover. A read
replica is an asynchronous, readable copy for scaling reads.

**Q: How do you restore an RDS database to 10 minutes ago?**
Point-in-time restore from automated backups. It creates a new instance; you
then repoint the application (or swap names).
