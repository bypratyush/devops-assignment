# Kubernetes Networking & Services

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

**Form field:** Kubernetes Networking & Services · **Course session:** `session-11-kubernetes-services`

| # | Service type | Reachable from | Docs |
|---|---|---|---|
| 01 | **ClusterIP** | Inside the cluster only | [README](01-clusterip/README.md) · [output](01-clusterip/output.md) |
| 02 | **NodePort** | `<AnyNodeIP>:30080`, i.e. outside | [run.sh](02-nodeport/run.sh) · [output](02-nodeport/output.md) |
| 03 | **LoadBalancer** | A dedicated external IP | [run.sh](03-loadbalancer/run.sh) · [output](03-loadbalancer/output.md) |
| 04 | **ExternalName** | n/a - it is a DNS CNAME outward | [run.sh](04-externalname/run.sh) · [output](04-externalname/output.md) |
| 05 | **Headless** | No VIP - DNS returns pod IPs | [run.sh](05-headless/run.sh) · [output](05-headless/output.md) |

All five verified, each with its own runnable script and captured output.

Verified against a local [kind](https://kind.sigs.k8s.io/) cluster running
**Kubernetes v1.37.0**.

```bash
kind create cluster --name devops-hw
cd 01-clusterip && ./run.sh
```

---

## 01 - ClusterIP

The default Service type: a stable virtual IP from the service CIDR, routable
**only inside the cluster**, load balancing to pods selected by labels.

Verified four ways:

**Reachable by name, ClusterIP and FQDN** - all HTTP 200:
```text
HTTP 200 from http://web-service-clusterip:8080  (0.003835s)
HTTP 200 from http://10.96.157.27:8080
HTTP 200 from FQDN
```

**Load balancing proven** - the 3 nginx pods serve identical HTML, so reading the
response proves nothing. Instead 30 requests are tagged with a unique marker and
counted in each pod's own access log:
```text
  web-app-clusterip-66865d4855-2wpqg       served 10 requests
  web-app-clusterip-66865d4855-48bcj       served 14 requests
  web-app-clusterip-66865d4855-5sd7z       served  6 requests
  TOTAL                                    served 30 requests
```
Uneven because kube-proxy in iptables mode picks a backend **at random per
connection** - it is not round-robin.

**Internal-only proven** - the same ClusterIP times out from the host.

**The reason ClusterIP exists proven** - a pod is deleted mid-run:
```text
before:  web-app-clusterip-66865d4855-bk42c   10.244.0.12   <-- deleted
after:   web-app-clusterip-66865d4855-wsjdf   10.244.0.15   <-- new name, NEW IP

but the ClusterIP is UNCHANGED:  10.96.157.27
and the service still answers:   HTTP 200 - still serving
```
Pod IP changed, service IP didn't, endpoints re-bound automatically, traffic
never stopped. That is the whole value proposition.

Full write-up covers how it works under the hood (endpoints controller ->
EndpointSlice -> kube-proxy iptables -> CoreDNS), all five service types, a
troubleshooting table, and 10 interview Q&As.

![clusterip service](screenshots/clusterip-service.png)

![service dns test](screenshots/service-dns-test.png)