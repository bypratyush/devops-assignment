# Kubernetes Troubleshooting

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

**Form field:** Kubernetes Troubleshooting · **Course session:** `session-14-kubernetes-troubleshooting`

| # | Part | Script | Verified output |
|---|---|---|---|
| 01 | [Troubleshooting commands](01-commands/README.md) - get, describe, logs, exec, events, explain, top, `-o wide/yaml/jsonpath/custom-columns` | [run.sh](01-commands/run.sh) | [output.md](01-commands/output.md) |
| 02 | [Common issues](02-common-issues/README.md) - 9 issues, each broken.yaml + fixed.yaml | one `run.sh` per issue | one `output.md` per issue |
| 03 | [Mini-project](03-mini-project/README.md) - the instructor's session-14 challenge, end to end | [run.sh](03-mini-project/run.sh) | [output.md](03-mini-project/output.md) |

The common issues, each documented Identify -> Investigate -> Root cause ->
Fix -> Verify with before/after output and screenshots:
[CrashLoopBackOff](02-common-issues/01-crashloopbackoff/README.md) ·
[ErrImagePull](02-common-issues/02-errimagepull/README.md) ·
[ImagePullBackOff](02-common-issues/03-imagepullbackoff/README.md) ·
[Pending](02-common-issues/04-pending/README.md) ·
[ContainerCreating](02-common-issues/05-containercreating/README.md) ·
[Service connectivity](02-common-issues/06-service-connectivity/README.md) ·
[DNS](02-common-issues/07-dns/README.md) ·
[Pod networking](02-common-issues/08-pod-networking/README.md) ·
[Configuration](02-common-issues/09-configuration/README.md)

Verified on the 3-node kind cluster `devops-hw` (Kubernetes v1.37.0, kindnet,
metrics-server v0.9.0), in my own namespaces `s14-commands`, `s14-issues`,
`s14-shop` and `s14-mini`, all deleted afterwards. Every script supports
`SHOTS=1 ./run.sh` to retake the screenshots during the run, and shares the
helpers in [lib.sh](lib.sh).

## My troubleshooting order

Distilled from what I actually did in these folders, not from a textbook:

1. **`kubectl get pods -o wide`** - read STATUS, **READY** and **RESTARTS**
   together, and check NODE. `NODE <none>` means a scheduling problem; a node
   but no container means a kubelet problem; restarts mean the process ran.
2. **Let the status pick the next command** - Pending / ContainerCreating /
   ImagePull / CreateContainerConfigError / StartError are all answered by
   **`kubectl describe pod`** (Events and Last State). Only a container that
   actually ran has logs.
3. **`kubectl logs --previous`** for CrashLoopBackOff. Plain `logs` shows the
   attempt in progress. Exit code 1 = the app, 137 + OOMKilled = memory limit,
   128 + StartError = bad command.
4. **`kubectl events --types=Warning`** for the whole namespace when I don't
   know which object is wrong yet.
5. **Running but unreachable? Walk the path in order:** DNS (`nslookup` the
   FQDN, check the `Server:` line and `/etc/resolv.conf`) -> Service
   (`get endpointslices`; empty = selector or readiness) -> pod
   (curl the **pod IP** directly, `netstat -tln` inside) -> policy
   (`get networkpolicy` when it is a **timeout** rather than a refusal).
6. **Compare intent with reality side by side** - selector vs
   `--show-labels`, `targetPort` vs `containerPort`, requested CPU vs
   allocatable, ConfigMap key vs `-o jsonpath='{.data}'`.
7. **Change one thing, `kubectl diff` before `apply`,** then verify with the
   same command that showed the failure - and check it is still fine a minute
   later (a crash loop looks Running for a few seconds).

## Interview Q&A

**Q: Pod is Running but the app is unreachable. Where do you start?**
`get endpointslices` for the Service. Empty means the selector matches nothing
or the pods are not Ready. If endpoints exist, curl the pod IP directly from
another pod; if that fails, check the container port and NetworkPolicies.

**Q: ErrImagePull vs ImagePullBackOff?**
Same failure, two phases: `ErrImagePull` is the attempt that just failed,
`ImagePullBackOff` is the wait before the next one. The Events message gives
the cause - not found, unauthorized, rate limited or unreachable.

**Q: Exit code 137?**
128 + 9, SIGKILL. With reason `OOMKilled` the memory limit was exceeded;
without it something else killed the container, typically a failing liveness
probe.

**Q: Logs are empty for a crashing pod. Why?**
Either the process never started (StartError, CreateContainerConfigError,
image pull - check `describe`), or it was killed before writing anything
(OOMKilled), or you are reading the new attempt - use `--previous`.

**Q: Pending pod, how do you debug it?**
`describe pod` -> the `FailedScheduling` message tallies why each node was
rejected: insufficient CPU/memory, taints, selectors/affinity, unbound PVCs.
Compare requests with `kubectl describe node` -> Allocated resources.

**Q: Connection refused vs timeout?**
Refused: something answered "no" - nothing listening on that port, or
kube-proxy rejecting a Service with no endpoints. Timeout: packets were
dropped - NetworkPolicy, firewall, or a dead route.

**Q: A pod in namespace A cannot resolve a Service in namespace B.**
Short names only expand within the pod's own namespace (`search` list in
`/etc/resolv.conf`). Use `<svc>.<namespace>` or the FQDN.

**Q: How do you check a field's meaning without leaving the terminal?**
`kubectl explain <kind>.<path>`, which documents the API version the cluster
actually serves.
