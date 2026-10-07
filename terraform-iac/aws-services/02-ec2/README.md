# 02 - EC2 (Compute)

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

**Form field:** AWS Services Research - EC2 · **Course session:** `session18-terraform-iac`

Hands-on: an EC2 instance is created, inspected and destroyed by Terraform in
the session 19 project - [cloud-terraform](../../../cloud-terraform/) (output in
[output.md](../../../cloud-terraform/output.md)).

## What is EC2?

Elastic Compute Cloud: virtual machines on demand. You choose the OS image,
the size, the network and the disk; AWS runs it on its hardware and bills per
second (Linux). It is IaaS - you still patch the OS and run the software.

## AMI (Amazon Machine Image)

The template an instance boots from: root volume snapshot (OS + anything
pre-installed), architecture (x86_64 / arm64), and launch permissions. AMIs
are **regional** - the same Amazon Linux release has a different ID in each
region - so look them up instead of hard-coding:

```text
$ aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
    --query Parameter.Value --output text
ami-0ff5003538b60d5ec
$ aws ec2 describe-images --image-ids ami-0ff5003538b60d5ec \
    --query 'Images[].[ImageId,Name,Architecture,RootDeviceType]' --output text
ami-0ff5003538b60d5ec	al2023-ami-2023.10.20260120.4-kernel-6.1-x86_64	x86_64	ebs
```

(LocalStack.) You can also bake your own AMI ("golden image", e.g. with Packer)
so instances boot already configured.

## Instance types

Named `family + generation + options . size`, e.g. `t3.micro`, `m7g.large`
(`g` = Graviton/arm64).

| Family | Optimised for | Example |
|---|---|---|
| t (burstable) | Low baseline CPU with credits for bursts | t3.micro - dev, small web apps |
| m (general) | Balanced CPU/memory | m7i.large - app servers |
| c (compute) | CPU | c7g.xlarge - batch, encoding |
| r / x (memory) | RAM | r7i.large - caches, in-memory DBs |
| i / d (storage) | Local NVMe / HDD | i4i - high-IOPS databases |
| p / g (accelerated) | GPU | g5 - ML inference |

Pricing models: On-Demand (per second), Savings Plans / Reserved (1-3 year
commitment, up to ~70% off), Spot (spare capacity, up to ~90% off, can be
reclaimed with 2 minutes' notice).

## Key pairs

SSH uses public-key crypto: AWS stores the **public** key and injects it into
`~/.ssh/authorized_keys` at first boot; you keep the **private** `.pem`
(`chmod 400`). AWS cannot recover a lost private key. Modern alternative: no
key and no port 22 at all - connect through **SSM Session Manager**, which is
why `key_name` is optional in the session 19 project.

## Security groups

A stateful virtual firewall on the instance's network interface. Allow rules
only; anything not allowed is dropped; return traffic of an allowed
connection is automatically permitted. The session 19 instance:

```text
|  0.0.0.0/0      |  All outbound (package installs, S3)  |  True   |  -1   |  -1    |  -1  |
|  203.0.113.10/32|  SSH from the admin CIDR only         |  False  |  22   |  tcp   |  22  |
|  0.0.0.0/0      |  HTTP from anywhere                   |  False  |  80   |  tcp   |  80  |
```

A rule can reference another security group instead of a CIDR ("allow 5432
from the app SG"), which is how tiers are wired without hard-coding IPs.

## EBS (Elastic Block Store)

Network-attached block storage - the instance's disks. Lives in **one AZ**,
survives stop/start, can be snapshotted to S3 and resized online.

| Type | Use |
|---|---|
| gp3 | Default SSD; 3,000 IOPS baseline, IOPS and throughput tunable separately |
| io2 | Provisioned IOPS for heavy databases |
| st1 / sc1 | Throughput / cold HDD for big sequential data |

Contrast: **instance store** is physically attached NVMe, fast but wiped on
stop. The session 19 root volume is `gp3`, 8 GiB, `encrypted = true`.

## Public vs private IP

| | Private IP | Public IP | Elastic IP |
|---|---|---|---|
| From | The subnet CIDR | AWS pool, auto-assigned if the subnet says so | Allocated to your account |
| Reachable from | Inside the VPC (and peered/VPN networks) | The internet, via the IGW | The internet |
| Survives stop/start | Yes | **No, changes** | Yes, until released |
| Cost | Free | About USD 0.005/h | Same, also while unattached |

The instance only ever sees its private IP on its NIC; the internet gateway
does 1:1 NAT to the public one. From session 19 (LocalStack):
`instance_private_ip = "10.20.1.4"`, `instance_public_ip = "54.214.148.216"`.

## Instance lifecycle

```text
pending -> running -> stopping -> stopped -> (start) -> pending -> running
   running -> shutting-down -> terminated   (gone; listed for about an hour)
   running -> (reboot) -> running           (same host, same IPs)
```

- **Stop**: no compute charge, EBS kept and billed, public IP lost.
- **Terminate**: instance deleted; root EBS deleted too by default
  (`DeleteOnTermination`).
- **Hibernate**: RAM saved to the encrypted root volume, resumes where it left off.

After `terraform destroy` in session 19, the instance was still listed as
`terminated`, exactly as on AWS.

## User data

A script run once by cloud-init on first boot - the hook for installing
software. The session 19 instance installs nginx and copies its boot log to
S3 ([user_data.sh.tftpl](../../../cloud-terraform/templates/user_data.sh.tftpl)).

## Common use cases

Web and API servers, CI runners, batch jobs on Spot, self-managed databases
(when RDS does not fit), bastion hosts, and the worker nodes underneath EKS.

## Interview Q&A

**Q: Stop vs terminate?**
Stop keeps the EBS volume and can be started again (with a new public IP).
Terminate deletes the instance and, by default, its root volume.

**Q: My instance lost its public IP after a restart - why?**
Auto-assigned public IPs are released on stop. Use an Elastic IP or, better, a
load balancer / DNS name in front.

**Q: How do you give an instance access to S3?**
An IAM role through an instance profile. Never put access keys on the box.

**Q: Why is SSH failing with a timeout rather than "permission denied"?**
Timeout means packets are dropped: security group, NACL, route table or no
public IP. "Permission denied" means you reached sshd and the key or user is wrong.
