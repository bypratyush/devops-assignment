# DevOps Homework

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Coursework for the DevOps module, one folder per submission topic. Every command
was actually executed: each `output.md` is a verbatim transcript from a real run
against a live Linux box, Docker daemon or Kubernetes cluster, and each
`screenshots/` folder holds terminal captures of those same commands.

| # | Topic | Folder |
|---|---|---|
| 01 | Linux Fundamentals | [linux-fundamentals](linux-fundamentals/) |
| 02 | Shell Scripting | [shell-scripting](shell-scripting/) |
| 03 | Networking | [networking](networking/) |
| 04 | Git and GitHub | [git-and-github](git-and-github/) |
| 05 | Docker Fundamentals | [docker-fundamentals](docker-fundamentals/) |
| 06 | Docker Images | [docker-images](docker-images/) |
| 07 | Docker Networking | [docker-networking](docker-networking/) |
| 08 | Kubernetes Fundamentals | [kubernetes-fundamentals](kubernetes-fundamentals/) |
| 09 | Kubernetes Pods, ReplicaSets & Deployments | [kubernetes-pods-replicasets-deployments](kubernetes-pods-replicasets-deployments/) |
| 10 | Kubernetes Networking & Services | [kubernetes-networking-services](kubernetes-networking-services/) |
| 11 | Kubernetes Ingress, ConfigMaps & Secrets | [kubernetes-ingress-configmaps-secrets](kubernetes-ingress-configmaps-secrets/) |

Each topic folder contains a `README.md` explaining the concepts, one or more
runnable scripts, an `output.md` of the real captured output, and `screenshots/`.

---

## Environment

This work was done on macOS, which has no `useradd`, `adduser`, `journalctl` or
systemd. Rather than write about commands that could not be run, two real
environments were built.

### 1. A Linux lab

Ubuntu 22.04 with **systemd running as PID 1**, so `systemctl` and `journalctl`
genuinely work. A plain `docker run ubuntu` gives neither. Built from
[lab/Dockerfile](lab/Dockerfile), because the common pre-built systemd images are
amd64-only and this is an arm64 Mac.

```bash
./lab/lab.sh up                          # start (repo mounted at /work)
./lab/lab.sh shell                       # interactive shell
./lab/lab.sh exec 'journalctl -n 5'      # one-off command
./lab/lab.sh down                        # remove
```

```text
PID1: systemd
Ubuntu 22.04.5 LTS
running
```

### 2. A Kubernetes cluster

A 3-node [kind](https://kind.sigs.k8s.io/) cluster, **Kubernetes v1.37.0**, with
host port mappings so NodePort and Ingress are reachable from the Mac. Multiple
nodes matter: the DaemonSet and scheduling demos are meaningless on one node.

```bash
kind create cluster --config lab/kind-config.yaml
```

MetalLB is installed for the LoadBalancer task, and ingress-nginx for the Ingress
task, since kind has neither by default.

### Helper scripts

| Script | Purpose |
|---|---|
| [lab/lab.sh](lab/lab.sh) | Start, enter and stop the Linux lab container |
| [lab/kind-config.yaml](lab/kind-config.yaml) | The 3-node cluster definition |
| [lab/regen.sh](lab/regen.sh) | Re-run every task script and rewrite its `output.md` |
| [lab/screenshots.sh](lab/screenshots.sh) | Capture the terminal screenshots |
| [lab/shot.sh](lab/shot.sh) | Single screenshot helper (termshot) |

`regen.sh` exists so that no `output.md` can drift from the script beside it. Any
edit to a script is followed by a regeneration run.

---

## Notes collected while doing this

Things that only surfaced by running everything for real, rather than reading
about it.

**Linux**

- `journalctl` pipes to `less` by default, so any script that calls it without
  `--no-pager` appears to hang forever.
- `deluser --remove-home` exits 8 on a minimal Ubuntu image with
  `you need to install the 'perl' package`. `deluser` is a Perl script and only
  `perl-base` ships by default; `userdel -r` is a binary and has no such need.
- HTTPS fails inside a minimal container until `ca-certificates` is installed,
  which shows up as `curl: (77) error setting certificate file`.

**Docker**

- With the containerd snapshotter, `docker images` and `docker image inspect
  .Size` report genuinely different numbers: uncompressed on-disk size versus
  compressed download size. Both are correct, so both are labelled.
- Exit code 137 after `docker stop` means SIGKILL: the app ignored SIGTERM and
  was force-killed after the grace period. In production that drops in-flight
  requests on every deploy.
- macOS already runs the AirPlay Receiver on port 5000, so `-p 5000:5000` fails
  with `address already in use`.
- A build-cache demonstration needs a **unique** change each run. Appending the
  same fixed comment produces byte-identical content that the previous run
  already cached, so everything shows CACHED and the demo proves nothing.

**Kubernetes**

- Polling with `kubectl get` in a loop is not a measurement. It reported that a
  `Recreate` rollout never dropped below 3 available replicas, which is the
  opposite of the truth. Each call costs 200 to 400 ms and the whole transition
  finished between two samples. `kubectl get --watch` is event-driven and
  immediately showed the real answer: **0**.
- Backgrounding a watcher with `$( )` deadlocks, because the background subshell
  inherits the command substitution's stdout pipe so `$( )` never sees EOF.
- `kubectl` jsonpath has no `!` operator, so terminating pods cannot be filtered
  with `[?(!@.metadata.deletionTimestamp)]`. Use `-o custom-columns` and awk.
- kube-proxy in iptables mode picks a backend at random per connection, not
  round-robin, which is why 30 requests split 10/14/6 rather than evenly.
- `kubernetes.io/change-cause` must be set in the **same** patch as the change,
  or it labels the wrong revision in `rollout history`.
- A ConfigMap mounted as a volume updates live; the same ConfigMap consumed as
  environment variables never does. This is the most common ConfigMap surprise.
- A Kubernetes Secret is base64-encoded, not encrypted.
