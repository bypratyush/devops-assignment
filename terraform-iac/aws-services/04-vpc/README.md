# 04 - VPC (Networking)

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

**Form field:** AWS Services Research - VPC · **Course session:** `session18-terraform-iac`

Hands-on: a full VPC (public + private subnet, IGW, route table, security
group) is built by Terraform in [cloud-terraform](../../../cloud-terraform/)
and checked with the AWS CLI; the snippets below are from that run and from a
throwaway VPC, all on LocalStack.

## What is a VPC?

A Virtual Private Cloud is your own isolated network inside an AWS region: you
pick the IP range, cut it into subnets, and decide what can reach the internet
and what cannot. Every account gets a default VPC per region; real workloads
get their own.

## CIDR

The VPC's address range in CIDR notation, IPv4 between `/16` (65,536
addresses) and `/28` (16). The session 19 VPC is `10.20.0.0/16`.

- Use private (RFC 1918) ranges: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.
- Plan ranges so VPCs you might **peer** or connect to the office never
  overlap - overlapping CIDRs cannot be routed between.
- AWS reserves **5 addresses per subnet**: network, `.1` router, `.2` DNS, `.3`
  reserved, and broadcast. A `/24` gives 251 usable; the first instance in
  `10.20.1.0/24` got `10.20.1.4`.

## Subnets

A slice of the VPC CIDR that lives in **exactly one Availability Zone**. High
availability therefore means at least two subnets in two AZs per tier.

```text
|     AZ      |     Cidr      |            Id              |       Name         | PublicIpOnLaunch   |
|  ap-south-1a|  10.20.2.0/24 |  subnet-a19ef5b7f68063c11  |  s19-web-private-a |  False             |
|  ap-south-1a|  10.20.1.0/24 |  subnet-28ace29de50f5704f  |  s19-web-public-a  |  True              |
```

## Route tables

Each subnet is associated with one route table; the most specific matching
route wins. Every table has the `local` route for the VPC CIDR, which cannot
be removed. A brand-new VPC has one **main** table with only that route:

```text
$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=vpc-a2cce0e7c8467325c ...
[
    {
        "Main": true,
        "Routes": [
            "10.30.0.0/16"
        ]
    }
]
```

The session 19 public table adds the default route:

```text
|  Destination  |  State  |         Target          |
|  10.20.0.0/16 |  active |  local                  |
|  0.0.0.0/0    |  active |  igw-a4a249d28fcb4d1a5  |
```

## Internet Gateway

A horizontally scaled, highly available VPC component (one per VPC, no
bandwidth limit, free) that connects the VPC to the internet and does 1:1 NAT
between an instance's private IP and its public IP. It only helps instances
that have a public IP **and** sit in a subnet whose route table points at it.

## NAT Gateway

Lets instances in **private** subnets start outbound connections (OS updates,
calling APIs) while staying unreachable from the internet. It sits in a
**public** subnet with an Elastic IP; private route tables send `0.0.0.0/0` to
it. It is zonal (one per AZ for HA) and costs about USD 0.05/hour plus
per-GB processing, which is why the session 19 project deliberately does not
create one. Cheaper options for AWS-only traffic: VPC endpoints (the S3
gateway endpoint is free).

## Security groups

Stateful, instance-level (ENI) firewall, allow rules only, evaluated as a
whole. Return traffic is automatic. Can reference other security groups.
Details and the session 19 rules are in [02-ec2](../02-ec2/README.md).

## Network ACLs

Stateless, subnet-level firewall with numbered rules evaluated lowest first,
supporting both allow and **deny**. Because it is stateless, a rule for
inbound port 80 is not enough - the response leaves on an ephemeral port
(1024-65535) and needs its own outbound rule. The default NACL of a new VPC
allows everything:

```text
| Action |    Cidr     | Egress  | Proto  |  Rule   |
|  allow |  0.0.0.0/0  |  True   |  -1    |  100    |
|  deny  |  0.0.0.0/0  |  True   |  -1    |  32767  |
|  allow |  0.0.0.0/0  |  False  |  -1    |  100    |
|  deny  |  0.0.0.0/0  |  False  |  -1    |  32767  |
```

Rule `32767` (shown as `*` in the console) is the final catch-all deny.

| | Security group | Network ACL |
|---|---|---|
| Applies to | Instance / ENI | Subnet |
| State | Stateful | Stateless |
| Rules | Allow only | Allow and deny |
| Evaluation | All rules together | In number order, first match wins |
| Typical use | Main access control | Coarse subnet guard, blocking a bad IP range |

## Public vs private subnet

| | Public subnet | Private subnet |
|---|---|---|
| Route `0.0.0.0/0` to | Internet gateway | NAT gateway, or nothing |
| Instances get public IPs | Usually (`map_public_ip_on_launch`) | No |
| Reachable from the internet | Yes, if the SG allows | No |
| Put here | Load balancers, NAT gateways, bastions | App servers, databases, caches |

A subnet is public **only** because of its route to an IGW - the name means
nothing to AWS.

## Interview Q&A

**Q: Instance in a public subnet but unreachable - what do you check?**
In order: does it have a public IP, does the subnet's route table have
`0.0.0.0/0 -> igw`, does the security group allow the port from your IP, does
the NACL allow inbound and outbound ephemeral ports, is the service listening.

**Q: How does a private instance download updates?**
Through a NAT gateway in a public subnet (or VPC endpoints / a proxy). The
NAT allows outbound-initiated traffic only.

**Q: Why at least two AZs?**
A subnet lives in one AZ; if that AZ fails, everything in it fails. Two
subnets per tier in two AZs survive it.

**Q: Can you change a VPC's CIDR later?**
You cannot change the primary block, only add secondary CIDRs. Subnet CIDRs
cannot change at all - Terraform shows `forces replacement`, as seen in
session 19.
