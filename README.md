# DevOps Homework

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Coursework for the DevOps module, one folder per submission topic. Every command
was actually executed: each `output.md` is a verbatim transcript from a real run
against a live Linux box, Docker daemon, Kubernetes cluster or (for Terraform)
a local AWS emulator, and each `screenshots/` folder holds terminal and browser
captures of those same runs.

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
| 12 | Kubernetes Storage, HPA & Probes | [kubernetes-storage-hpa-probes](kubernetes-storage-hpa-probes/) |
| 13 | Kubernetes Troubleshooting | [kubernetes-troubleshooting](kubernetes-troubleshooting/) |
| 14 | Helm | [helm](helm/) |
| 15 | CI/CD & GitHub Actions | [cicd-github-actions](cicd-github-actions/) |
| 16 | DevSecOps Pipeline | [devsecops-pipeline](devsecops-pipeline/) |
| 17 | Terraform & Infrastructure as Code | [terraform-iac](terraform-iac/) |
| 18 | Cloud & Terraform in Action | [cloud-terraform](cloud-terraform/) |
| 19 | Monitoring, Observability & GitOps | [monitoring-observability-gitops](monitoring-observability-gitops/) |
| 20 | Final DevOps Project & Troubleshooting | [final-devops-project](final-devops-project/) |

Additions to earlier topics, done with the later sessions:

| Topic | What was added |
|---|---|
| Docker Fundamentals | [hello-world-apps](docker-fundamentals/hello-world-apps/) - the six Hello World apps (`nodejs-app`, `python-app`, `java-app`, `Apache-app`, `React-app`, `nginx-app`) |
| Docker Images | [multi-stage-homework](docker-images/multi-stage-homework/) - the course multi-stage Dockerfile on port 8080, plus Node/Python/Java deployments |
| Docker Networking | [homework.sh](docker-networking/homework.sh) - frontend/backend/database on three networks, Apache on the host network, the "Hello students" bind mount, overlay notes |
| Kubernetes Networking & Services | [comparison](kubernetes-networking-services/comparison/), [fqdn](kubernetes-networking-services/fqdn/), [coredns](kubernetes-networking-services/coredns/), and a README section per Service type |
| Kubernetes Ingress, ConfigMaps & Secrets | [ingress-vs-ingress-controller](kubernetes-ingress-configmaps-secrets/ingress-vs-ingress-controller/), [troubleshooting](kubernetes-ingress-configmaps-secrets/troubleshooting/) |

GitHub Actions only runs workflows from the repository root, so the pipelines
for topics 15, 16 and the final project live in [.github/workflows/](.github/workflows/),
each with a `paths:` filter on its own folder.

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
task, since kind has neither by default. metrics-server (for HPA and `kubectl top`)
was added in session 13, and Argo CD plus an in-cluster Gitea (the Git server for
the GitOps demo) in session 20.

### 3. LocalStack instead of an AWS account

There is no AWS account behind this homework, so both Terraform topics run real
`terraform init/plan/apply/destroy` against [LocalStack](https://www.localstack.cloud/)
on `localhost:4566`. Each project switches to real AWS with one variable
(`use_localstack = false`). The image is pinned to `4.14.0`: newer images refuse to
start without a paid auth token.

```bash
./lab/localstack.sh up
eval "$(./lab/localstack.sh env)"     # dummy credentials for the AWS CLI
```

### 4. GitHub Actions, run locally

The pipelines are written for GitHub-hosted runners, and were executed locally
with [act](https://github.com/nektos/act) so the runs could be captured before
pushing. Steps that only make sense on GitHub (pushing to GHCR, for example) are
guarded with `if: ${{ !env.ACT }}`; see each topic's README for the exact command.

### Helper scripts

| Script | Purpose |
|---|---|
| [lab/lab.sh](lab/lab.sh) | Start, enter and stop the Linux lab container |
| [lab/kind-config.yaml](lab/kind-config.yaml) | The 3-node cluster definition |
| [lab/regen.sh](lab/regen.sh) | Re-run every task script and rewrite its `output.md` |
| [lab/screenshots.sh](lab/screenshots.sh) | Capture the terminal screenshots |
| [lab/shot.sh](lab/shot.sh) | Single screenshot helper (termshot) |
| [lab/localstack.sh](lab/localstack.sh) | Start/stop LocalStack for the Terraform topics |
| [lab/gitops.sh](lab/gitops.sh) | Reach Argo CD and the in-cluster Gitea (port-forwards, demo credentials) |

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
- A NodePort is not usable the instant the Service exists. Checking every node
  straight after `kubectl apply` got HTTP 000 until kube-proxy had programmed the
  rule (about 2 s), so the script now waits for the port to answer first.
- An Ingress whose `ingressClassName` matches no controller is accepted by the
  API server and then silently ignored: no ADDRESS, no events, no error.
- A headless Service with no ready pods returns NXDOMAIN, so clients see
  "Name or service not known" rather than "connection refused".

**Helm**

- A release marked `failed` is not necessarily untouched. An upgrade rejected by
  the ingress admission webhook had already applied the ConfigMaps and Deployment,
  so dev served the prod config until the rollback.
- `helm install --dry-run=server` does not catch a clashing nodePort; only the
  real install fails with "provided port is already allocated".

**Terraform / AWS**

- Recent `localstack/localstack` images exit with code 55 unless
  `LOCALSTACK_AUTH_TOKEN` is set, which is why the image is pinned to `4.14.0`.
- AWS provider 6.x reads S3 bucket tags through the S3 Control API. Without an
  `s3control` endpoint override that one call went to real AWS with the fake keys
  and failed with 403, leaving a tainted bucket for the next apply to replace.

**Tooling**

- Docker Hub rate-limits anonymous pulls hard enough that a few parallel builds
  hit `429 Too Many Requests`. `docker login` with a free account fixes it.
