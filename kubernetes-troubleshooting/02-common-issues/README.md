# Troubleshooting Common Kubernetes Issues

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

**Form field:** Kubernetes Troubleshooting · **Course session:** `session-14-kubernetes-troubleshooting`

Every issue has its own folder with `broken.yaml`, `fixed.yaml`, a `run.sh`
(`break | investigate | fix | verify | cleanup`, default all), the captured
`output.md`, screenshots, and a README written as
**Identify -> Investigate -> Root cause -> Fix -> Verify**. All of them run in
the dedicated namespace `s14-issues` ([namespace.yaml](namespace.yaml)); the
DNS case adds `s14-shop` for a cross-namespace Service.

| # | Issue | What I broke | Where the answer was |
|---|---|---|---|
| 01 | [CrashLoopBackOff](01-crashloopbackoff/README.md) | missing env var (exit 1) and a too-small memory limit (OOMKilled, 137) | `logs --previous` / `describe` Last State |
| 02 | [ErrImagePull](02-errimagepull/README.md) | typo in the image tag | `describe` Events: `not found`; registry HEAD 404 |
| 03 | [ImagePullBackOff](03-imagepullbackoff/README.md) | private registry, no pull secret (plus a real Docker Hub 429) | Events: `403 Forbidden` |
| 04 | [Pending](04-pending/README.md) | 64-CPU request; nodeSelector no node matches | `FailedScheduling` event tally |
| 05 | [ContainerCreating](05-containercreating/README.md) | ConfigMap and Secret volumes that do not exist | `FailedMount` events |
| 06 | [Service connectivity](06-service-connectivity/README.md) | selector/label mismatch, then wrong targetPort | empty EndpointSlice, then `netstat` in the pod |
| 07 | [DNS](07-dns/README.md) | short name across namespaces; `dnsPolicy: None` with a wrong nameserver | `resolv.conf`, the `Server:` line of `nslookup` |
| 08 | [Pod networking](08-pod-networking/README.md) | NetworkPolicy allowing the Service port instead of the pod port | timeout (not refused), `describe networkpolicy` |
| 09 | [Configuration](09-configuration/README.md) | wrong ConfigMap key in env; `command` that is not in the image | `CreateContainerConfigError`, `StartError` exit 128 |

## The status tells you where to look

| Status | Stage that failed | First command |
|---|---|---|
| `Pending` (no node) | scheduling | `describe pod` -> FailedScheduling |
| `ContainerCreating` for minutes | kubelet setup (volumes, network) | `describe pod` -> FailedMount |
| `ErrImagePull` / `ImagePullBackOff` | image pull | `describe pod` -> the pull error text |
| `CreateContainerConfigError` | building the container config | `describe pod` -> missing key/object |
| `RunContainerError` / `StartError` | starting the process | `describe pod` -> Last State message |
| `CrashLoopBackOff` | the process ran and exited | `logs --previous`, then `describe` for OOMKilled |
| Running + Ready but unreachable | Service / DNS / NetworkPolicy | endpoints, `nslookup`, curl pod IP directly |

## Notes from actually running this

- **Docker Hub rate limiting was a real ImagePullBackOff.** Pulls of
  `nginx:1.27` failed with `429 Too Many Requests` on this cluster, so the
  image-typo demo uses `mirror.gcr.io` to get an honest `not found`.
- **Don't edit a script while it is running.** Bash reads scripts as it goes;
  I changed a `run.sh` mid-run and got `unexpected EOF while looking for
  matching '"'` at the end of the output. I re-ran it cleanly.
- **Old pods pollute a re-run.** `kubectl delete` returns before the pods'
  30s grace period ends, and the next `get -w` timeline showed the previous
  run's pods terminating. The scripts now wait for them (`wait_gone`).
- **A wrong nameserver did not time out.** Docker Desktop answers DNS sent to
  any IP, so the bad `dnsPolicy: None` pod got NXDOMAIN instead of a timeout -
  documented in 07.
- **Refused vs timeout is a real clue.** curl exit 7 in milliseconds (no
  endpoints, wrong port) vs exit 28 after the full timeout (NetworkPolicy drop).
