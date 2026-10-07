# Kubernetes Storage, HPA & Probes

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

**Form field:** Kubernetes Storage, HPA & Probes · **Course session:** `session-13-storage-hpa-probes`

| # | Topic | Docs | Script | Verified output |
|---|---|---|---|---|
| 01 | **Volumes** - emptyDir, hostPath, PV, PVC, StorageClass, dynamic provisioning | [README](01-kubernetes-volumes/README.md) | [run.sh](01-kubernetes-volumes/run.sh) | [output.md](01-kubernetes-volumes/output.md) |
| 02 | **HPA** - metrics-server, CPU-based autoscaling under real load | [README](02-hpa/README.md) | [run.sh](02-hpa/run.sh) | [output.md](02-hpa/output.md) |
| 03 | **Probes** - liveness, readiness, startup | [README](03-probes/README.md) | [run.sh](03-probes/run.sh) | [output.md](03-probes/output.md) |
| 04 | **Mini project** - production-ready web app: PVC + HPA + probes | [README](04-mini-project/README.md) | [run.sh](04-mini-project/run.sh) | [output.md](04-mini-project/output.md) |

Verified on the 3-node [kind](https://kind.sigs.k8s.io/) cluster `devops-hw`
(**Kubernetes v1.37.0**, 1 control-plane + 2 workers, arm64), each part in its
own namespace (`s13-volumes`, `s13-hpa`, `s13-probes`, `production-webapp`).
Storage is kind's default `standard` StorageClass (`rancher.io/local-path`);
metrics come from metrics-server v0.9.0, installed by
[02-hpa/install-metrics-server.sh](02-hpa/install-metrics-server.sh).

```bash
cd 01-kubernetes-volumes && ./run.sh && ./run.sh cleanup
cd 02-hpa && ./install-metrics-server.sh   # once per cluster
./run.sh && ./run.sh cleanup
```

---

## Deliverables checklist

| Deliverable (homework spec) | Where |
|---|---|
| Volume documentation: emptyDir, hostPath, PV, PVC, StorageClass, dynamic provisioning, with practical examples | [01-kubernetes-volumes/README.md](01-kubernetes-volumes/README.md), manifests and [output](01-kubernetes-volumes/output.md) in the same folder |
| HPA YAML | [02-hpa/hpa.yml](02-hpa/hpa.yml) (app: [deployment.yaml](02-hpa/deployment.yaml), [service.yaml](02-hpa/service.yaml)) |
| Load generator | [02-hpa/load-generator.yaml](02-hpa/load-generator.yaml) |
| Deploy, configure HPA, verify, load, observe CPU and pod scaling | [02-hpa/run.sh](02-hpa/run.sh), steps 1-9 of [02-hpa/output.md](02-hpa/output.md) |
| HPA output: `kubectl get hpa`, `get pods`, `top pods`, `describe hpa` | [02-hpa/output.md](02-hpa/output.md) (incl. a timestamped `kubectl get hpa -w` timeline) |
| Screenshots | `screenshots/` in every subfolder, embedded in each README |
| Mini-project implementation | [04-mini-project/](04-mini-project/) - course manifests, [run.sh](04-mini-project/run.sh), [output.md](04-mini-project/output.md) |
| README documentation | this file plus one README per subfolder |
| Probes (session topic) | [03-probes/README.md](03-probes/README.md) |

---

## What the four parts add up to

- **Volumes** decide whether data survives. emptyDir lives and dies with the
  pod; hostPath is tied to one node; a PVC bound to a PV outlives every pod
  that uses it, and with a StorageClass nobody has to create PVs by hand.
- **HPA** decides how many pods there are. It needs two things that are easy
  to forget: metrics-server, and a CPU **request** on the container (the
  percentage is of the request).
- **Probes** decide whether a pod gets traffic (readiness), gets restarted
  (liveness), or is left alone while it boots (startup).
- The **mini project** combines all three, and shows how they interact: an RWO
  local volume pins every replica, including the ones the HPA adds, to one node.
