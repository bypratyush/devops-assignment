# Task 5 - Kubernetes ClusterIP Service

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Source assignment: [devops-heros/session-11-kubernetes-services/01-clusterip](https://github.com/Nency-Ravaliya/devops-heros/tree/main/session-11-kubernetes-services/01-clusterip)

Run it: `./run.sh` (needs a cluster - see [Setup](#7-setup))
Verified output: [output.md](output.md) - a real run against Kubernetes v1.37.0.

---

## 1. What a ClusterIP is

`ClusterIP` is the **default** Service type. Kubernetes allocates a private,
stable virtual IP (VIP) from the service CIDR (here `10.96.0.0/12`) that is
routable **only from inside the cluster**.

```text
               +--------------------------------------+
               |          Client Pod / Frontend       |
               +--------------------------------------+
                                  |
               http://web-service-clusterip:8080
                                  |
                                  v
               +--------------------------------------+
               |         ClusterIP Service            |
               |        VIP: 10.96.157.27:8080        |
               +--------------------------------------+
                                  |
            [kube-proxy / iptables - Layer 4 load balancing]
                                  |
       +--------------------------+--------------------------+
       |                          |                          |
       v                          v                          v
+--------------+           +--------------+           +--------------+
| Backend Pod 1|           | Backend Pod 2|           | Backend Pod 3|
| 10.244.0.11  |           | 10.244.0.12  |           | 10.244.0.13  |
|  (Port: 80)  |           |  (Port: 80)  |           |  (Port: 80)  |
+--------------+           +--------------+           +--------------+
```

## 2. The problem it solves

**Pods are mortal and their IPs are ephemeral.** A pod that crashes, is
rescheduled, or scales gets a brand-new IP. Hardcode `http://10.244.1.25:80` in
your frontend and the moment that pod dies you get `Connection refused`.

A Service gives you a **permanent name and IP** in front of all matching pods,
and keeps the backend list up to date automatically.

**Step 14 of `run.sh` proves this.** A pod is deleted mid-run:

```text
--- pod IPs before ---
web-app-clusterip-66865d4855-bk42c   10.244.0.12      <-- deleted
web-app-clusterip-66865d4855-gll8f   10.244.0.13
web-app-clusterip-66865d4855-wg87g   10.244.0.11

--- pod IPs after (replacement has a NEW name and a NEW IP) ---
web-app-clusterip-66865d4855-wsjdf   10.244.0.15      <-- new
web-app-clusterip-66865d4855-gll8f   10.244.0.13
web-app-clusterip-66865d4855-wg87g   10.244.0.11

--- but the ClusterIP is UNCHANGED ---
web-service-clusterip   10.96.157.27
  (was 10.96.157.27 before the pod was deleted)

--- and the service still answers ---
HTTP 200 - still serving
```

The pod IP changed, the service IP didn't, and the endpoint list re-bound with
no human intervention. **That is the entire value proposition.**

### The analogy
An office has 5 support agents who rotate shifts and swap desks. You don't dial
an agent's personal mobile - you dial extension `*200` (the ClusterIP) and the
switchboard (`kube-proxy` + `EndpointSlice`) routes you to whoever is currently
at their desk (a `Running` + `Ready` pod).

---

## 3. The manifests

### `app-deployment.yaml` - 3 nginx replicas
```yaml
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-clusterip      # which pods this Deployment manages
  template:
    metadata:
      labels:
        app: web-clusterip    # <-- the label the Service will look for
```

### `service.yaml` - the ClusterIP
```yaml
spec:
  type: ClusterIP             # default; can be omitted
  selector:
    app: web-clusterip        # MUST match the pod labels above
  ports:
    - name: http
      port: 8080              # port ON THE SERVICE      (the front door)
      targetPort: 80          # port ON THE CONTAINER    (the back door)
      protocol: TCP
```

| Field | Meaning |
|---|---|
| `type: ClusterIP` | Internal virtual IP. The default if you omit `type`. |
| `selector` | **Label query**, not a name reference. This is the whole coupling. |
| `port: 8080` | What clients connect to: `http://web-service-clusterip:8080` |
| `targetPort: 80` | Where nginx actually listens. They do **not** have to match. |
| `protocol: TCP` | Default. UDP and SCTP also supported. |

> The Service finds its pods **only** through `selector` matching pod labels.
> It has no idea the Deployment exists. Mistype the selector and you get a
> Service with zero endpoints that fails silently.

### `client-pod.yaml`
A `curlimages/curl` pod running `sleep 3600`, so there's something *inside* the
cluster to test from. A ClusterIP can't be reached from your laptop.

---

## 4. Deploy and verify

```bash
kubectl apply -f app-deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f client-pod.yaml
```

**The three pods, with ephemeral IPs:**
```text
NAME                                 READY   STATUS    IP            NODE
web-app-clusterip-66865d4855-2wpqg   1/1     Running   10.244.0.11   devops-hw-control-plane
web-app-clusterip-66865d4855-48bcj   1/1     Running   10.244.0.12   devops-hw-control-plane
web-app-clusterip-66865d4855-5sd7z   1/1     Running   10.244.0.13   devops-hw-control-plane
```

**The service, with its stable VIP:**
```text
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    SELECTOR
web-service-clusterip   ClusterIP   10.96.157.27   <none>        8080/TCP   app=web-clusterip
```
`EXTERNAL-IP: <none>` is the point - there is no external address.

**Endpoints - proof the selector matched:**
```bash
kubectl get endpointslices -l kubernetes.io/service-name=web-service-clusterip
```
```text
NAME                          ADDRESSTYPE   PORTS   ENDPOINTS
web-service-clusterip-qmjzw   IPv4          80      10.244.0.11,10.244.0.12,10.244.0.13
```
All three pod IPs, `ready=true`. **This is the first thing to check when a
service doesn't work.** (`kubectl get endpoints` is the older, now-deprecated
API for the same information; `kubectl describe svc` still prints an
`Endpoints:` line.)

---

## 5. Testing it - three ways to address the service

All from inside the cluster, via the client pod:

```bash
# 1. By service NAME (CoreDNS resolves it)
kubectl exec curl-client -- curl -s http://web-service-clusterip:8080

# 2. By ClusterIP
kubectl exec curl-client -- curl -s http://10.96.157.27:8080

# 3. By FQDN
kubectl exec curl-client -- curl -s http://web-service-clusterip.default.svc.cluster.local:8080
```
```text
HTTP 200 from http://web-service-clusterip:8080  (0.003835s)
HTTP 200 from http://10.96.157.27:8080
HTTP 200 from FQDN
```

FQDN pattern: **`<service>.<namespace>.svc.cluster.local`**. Short names only
work within the same namespace - cross-namespace calls need at least
`<service>.<namespace>`.

### Why the short name works
```text
$ kubectl exec curl-client -- cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10          <-- CoreDNS
options ndots:5
```
The kubelet injects this. The resolver appends each `search` suffix in turn,
which is why `nslookup` prints `NXDOMAIN` for the non-matching ones before
succeeding - that's normal, not an error:
```text
** server can't find web-service-clusterip.cluster.local: NXDOMAIN
Name:	web-service-clusterip.default.svc.cluster.local
Address: 10.96.157.27
```

### Proof of load balancing
All 3 nginx pods serve identical HTML, so reading the response proves nothing.
Instead `run.sh` sends 30 requests tagged with a unique marker, then counts that
marker in each pod's own access log:

```text
sent 30 requests through the service (tagged lbprobe-33827)

  web-app-clusterip-66865d4855-2wpqg       served 10 requests
  web-app-clusterip-66865d4855-48bcj       served 14 requests
  web-app-clusterip-66865d4855-5sd7z       served  6 requests
  ----------------------------------------------------------
  TOTAL                                    served 30 requests
```

All three pods served traffic. The split is uneven because kube-proxy in
iptables mode picks a backend **at random per connection** - it is not
round-robin, and it evens out only over large numbers of requests.

### Proof it is internal only
```text
Trying to reach 10.96.157.27:8080 from the laptop (outside the cluster):
  FAILED / timed out, exactly as expected.
```
The ClusterIP exists only as iptables/IPVS rules on cluster nodes. It is not a
real address on any network your laptop can route to.

For local debugging, tunnel through the API server:
```bash
kubectl port-forward svc/web-service-clusterip 8080:8080
# then open http://localhost:8080
```

---

## 6. How it actually works under the hood

1. You create the Service. The API server allocates a free VIP from the service CIDR.
2. The **endpoints controller** watches for pods matching `selector` that are
   `Ready`, and writes their IPs into an **EndpointSlice**.
3. **kube-proxy** on every node watches Services and EndpointSlices and programs
   **iptables** (or IPVS) rules: "traffic to `10.96.157.27:8080` -> DNAT to one of
   these pod IPs on port 80."
4. **CoreDNS** watches Services and serves `web-service-clusterip.default.svc.cluster.local -> 10.96.157.27`.

So the VIP is **not** a process or a proxy you can ping a daemon on - it is a
set of packet-rewriting rules on each node. That's why it's L4 only (no HTTP
awareness, no path routing - that's what Ingress is for) and why it doesn't
exist outside the cluster.

### The Service types
| Type | Reachable from | Use |
|---|---|---|
| **ClusterIP** | Inside the cluster only | Internal microservices, databases, caches |
| **NodePort** | `<NodeIP>:30000-32767` | Dev/testing, or behind an external LB |
| **LoadBalancer** | Public IP from the cloud provider | Production external entry |
| **ExternalName** | CNAME to an external DNS name | Pointing at an out-of-cluster service |
| **Headless** (`clusterIP: None`) | DNS returns pod IPs directly, no VIP | StatefulSets, Kafka, databases needing per-pod addressing |

NodePort and LoadBalancer are **built on top of** ClusterIP - they still
allocate one internally.

---

## 7. Setup

This was verified on a local [kind](https://kind.sigs.k8s.io/) cluster:

```bash
brew install kind
kind create cluster --name devops-hw
kubectl cluster-info
```
```text
Kubernetes control plane is running at https://127.0.0.1:52373
NAME                      STATUS   ROLES           AGE   VERSION
devops-hw-control-plane   Ready    control-plane   35s   v1.37.0
```

Any cluster works - minikube, k3d, Docker Desktop's built-in Kubernetes.

```bash
./run.sh            # deploy + full verification
./run.sh deploy     # deploy only
./run.sh verify     # verification only
./run.sh cleanup    # remove everything
```

Tear the cluster down with `kind delete cluster --name devops-hw`.

---

## 8. Troubleshooting

| Symptom | Cause | Check |
|---|---|---|
| **Endpoints empty / `<none>`** | `selector` doesn't match pod labels | `kubectl get pods --show-labels` vs `kubectl describe svc` |
| Endpoints empty, labels look right | Pods aren't **Ready** - only ready pods get added | `kubectl get pods`, check the readiness probe |
| **Connection refused** | `targetPort` ≠ the port the container listens on | `kubectl exec <pod> -- ss -tulnp` |
| **DNS fails** | CoreDNS down | `kubectl get pods -n kube-system -l k8s-app=kube-dns` |
| Name resolves, connection hangs | NetworkPolicy blocking it | `kubectl get networkpolicy` |
| Works by IP, not by name | Wrong namespace - use `<svc>.<ns>` | `kubectl get svc -A` |
| Can't reach it from your laptop | **Working as designed** | Use `port-forward`, or NodePort/Ingress |

The single most common bug is a **selector/label mismatch**, and its signature
is always the same: empty endpoints.

```bash
kubectl describe svc web-service-clusterip
kubectl get endpointslices -l kubernetes.io/service-name=web-service-clusterip
kubectl get pods --show-labels
kubectl logs <pod>
kubectl exec curl-client -- curl -v http://web-service-clusterip:8080
```

---

## 9. Cleanup

```bash
kubectl delete -f client-pod.yaml -f service.yaml -f app-deployment.yaml
# or
./run.sh cleanup
```

---

## 10. Interview Q&A

**Q: What is a ClusterIP service?**
The default Service type. It allocates a stable virtual IP from the service CIDR
that load balances to a set of pods selected by labels, reachable only from
within the cluster.

**Q: Why do you need a Service at all?**
Pod IPs are ephemeral - they change on every restart, reschedule, or scale
event. A Service provides a stable IP and DNS name, and keeps the backend list
current as pods come and go.

**Q: Difference between `port` and `targetPort`?**
`port` is what clients connect to on the Service; `targetPort` is the port on
the container. They're independent - `8080 -> 80` here.

**Q: How does a Service know which pods to send to?**
Purely through `spec.selector` matching pod **labels**. The endpoints controller
watches for matching *and Ready* pods and maintains an EndpointSlice; kube-proxy
programs iptables from that.

**Q: Service has no endpoints. How do you debug?**
Compare `kubectl describe svc` selector against `kubectl get pods --show-labels`.
If they match, the pods aren't Ready - check the readiness probe and
`kubectl logs`.

**Q: Is the load balancing round-robin?**
No. kube-proxy in iptables mode selects a backend **randomly per connection**,
which is why the run showed 10/14/6 rather than 10/10/10. IPVS mode does support
real round-robin and other algorithms.

**Q: Can I reach a ClusterIP from outside?**
No - it only exists as iptables/IPVS rules on cluster nodes. Use NodePort,
LoadBalancer, or an Ingress. `kubectl port-forward` tunnels through the API
server for debugging.

**Q: ClusterIP vs Ingress?**
ClusterIP is L4 (TCP/UDP), internal, no HTTP awareness. Ingress is L7 -
host/path routing, TLS termination - for external HTTP traffic. An Ingress
controller routes *to* ClusterIP services.

**Q: What's a headless service?**
`clusterIP: None`. No VIP and no load balancing - DNS returns the pod IPs
directly, so clients address individual pods. Used with StatefulSets and
anything doing its own peer discovery, like Kafka or a database cluster.

**Q: What's the DNS name of a service?**
`<service>.<namespace>.svc.cluster.local`. The short name works in the same
namespace because of the `search` domains in the pod's `/etc/resolv.conf`.
