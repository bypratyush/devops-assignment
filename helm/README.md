# Helm

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

**Form field:** Helm · **Course session:** `session-15-helm`

| # | Task | Docs | Script | Verified output |
|---|---|---|---|---|
| 01 | **Helm commands** - create, lint, template, install, list, status, get, upgrade, history, rollback, test, uninstall, repo, search | [README](01-commands/README.md) | [run.sh](01-commands/run.sh) | [output.md](01-commands/output.md) |
| 02 | **Rollback workflow** - install -> upgrade -> verify -> bad upgrade -> verify -> rollback -> verify | [README](02-rollback/README.md) | [run.sh](02-rollback/run.sh) | [output.md](02-rollback/output.md) |
| 03 | **Mini project** - Notes app chart, dev + prod releases from one chart, upgrade, rollback | [README](03-mini-project/README.md) | [run.sh](03-mini-project/run.sh) | [output.md](03-mini-project/output.md) |

Verified with **Helm v4.3.0** against the kind cluster `devops-hw` (Kubernetes v1.37.0,
3 nodes, ingress-nginx). Every task runs in its own namespace (`helm-demo`, `helm-rollback`,
`notes-dev`, `notes-prod`) and `./run.sh` cleans up after itself. The Helm 4 differences I hit
are listed in [01-commands](01-commands/README.md#helm-4-vs-helm-3---differences-i-actually-ran-into).

---

## What Helm is

Helm is the package manager for Kubernetes. Instead of a folder of YAML per environment, you
write the YAML once as **templates**, keep the environment-specific parts in **values**, and
let Helm render, apply, version and roll back the result as one unit.

Without Helm, "dev, staging and prod" means three copies of every manifest that slowly drift
apart. With Helm it is one chart and three small values files.

Helm 3 and 4 are client-only: no Tiller in the cluster. Helm talks to the API server with your
kubeconfig permissions and stores release state as Secrets in the release's namespace.

## Vocabulary

| Term | Meaning | Example from this folder |
|---|---|---|
| **Chart** | a package: templates + default values + metadata | `03-mini-project/notes-chart/` |
| **Values** | the inputs that customise a chart | `values.yaml`, `values-prod.yaml`, `--set replicaCount=3` |
| **Release** | one installed instance of a chart, with a name, in a namespace | `notes-dev` and `notes-prod` - same chart, two releases |
| **Revision** | one version of a release; every install/upgrade/rollback adds one | `web` in 02 ended at revision 6 |
| **Repository** | an HTTP server with an `index.yaml` listing packaged charts | `prometheus-community`, `ingress-nginx` |
| **Artifact Hub** | a search index over many repositories (`helm search hub`) | 304 charts matched "nginx" |

## Chart structure

```text
mychart/
  Chart.yaml           name, chart version (SemVer), appVersion, dependencies
  values.yaml          default values
  values.schema.json   optional - JSON Schema the values must satisfy
  .helmignore          files left out of `helm package`
  charts/              dependency charts (subcharts)
  templates/
    _helpers.tpl       named templates (define/include); "_" files render nothing
    deployment.yaml    Go templates that render to Kubernetes YAML
    service.yaml
    NOTES.txt          printed after install/upgrade
    tests/             pods with the helm.sh/hook: test annotation (helm test)
```

`version` is the chart's version; `appVersion` is the version of the software inside it.
They change independently - the APP VERSION column in `helm list`/`history` comes from
`appVersion`, not from whatever image tag you passed with `--set`.

## Values precedence (lowest to highest)

```text
chart values.yaml
  < parent chart's values for this subchart
    < -f / --values files, in the order given (later wins)
      < --set, --set-string, --set-json, --set-file (later wins)
```

Maps are deep-merged, lists are replaced whole. Shown for real in
[01-commands](01-commands/README.md#3-helm-template): `--set web.environment=from-set-flag`
beat the same key from `-f values-staging.yaml`.

On `helm upgrade`, values from the *previous* release are **not** kept unless you pass
`--reuse-values` - a plain upgrade starts again from the chart defaults plus the flags on that
command line.

## How templating works

Templates are Go `text/template` plus the Sprig function library. Helm renders them with these
objects in scope:

| Object | Holds |
|---|---|
| `.Values` | merged values |
| `.Release` | `.Name`, `.Namespace`, `.Revision`, `.Service` ("Helm") |
| `.Chart` | the contents of Chart.yaml (`.Chart.Name`, `.Chart.AppVersion`) |
| `.Capabilities` | cluster version / available APIs |
| `.Template`, `.Files` | current template path, other files in the chart |

```yaml
metadata:
  name: {{ include "notes.fullname" . }}          # named template from _helpers.tpl
  labels:
    {{- include "notes.labels" . | nindent 4 }}    # {{- trims whitespace, nindent re-indents
spec:
  replicas: {{ .Values.replicaCount }}
  {{- if .Values.podDisruptionBudget.enabled }}   # conditional block
  ...
  {{- end }}
  {{- range $i, $note := .Values.notes }}         # loop over a list
  {{ add1 $i }}. {{ $note }}
  {{- end }}
  image: {{ required "image.tag must be set" .Values.image.tag | quote }}
```

The pipeline is: values merged -> templates rendered to YAML -> (schema/lint checks) ->
objects sent to the API server (server-side apply by default in Helm 4) -> a release record
saved as a Secret. `helm template` stops after rendering; `--dry-run=server` stops before
saving.

---

## Interview Q&A

**Q: What problem does Helm solve?**
Templating (one set of manifests for many environments), packaging/sharing (charts in
repositories), and lifecycle (install, upgrade, history, rollback, uninstall as one unit).

**Q: Chart vs release vs revision?**
The chart is the package; a release is one installation of it with a name and namespace; a
revision is one version of that release. Two releases of one chart: 03's `notes-dev` and
`notes-prod`.

**Q: Where is release state stored?**
Secrets of type `helm.sh/release.v1` (`sh.helm.release.v1.<name>.v<revision>`) in the
release namespace, each holding the chart, values and rendered manifest (gzip + base64).

**Q: `version` vs `appVersion` in Chart.yaml?**
`version` is the chart package version (SemVer, bump on any chart change). `appVersion` is
the version of the application the chart deploys; informational, often the default image tag.

**Q: How do you see what an upgrade will change before running it?**
`helm template` with the new values and diff it against `helm get manifest`, or
`helm upgrade --dry-run=server`. (The `helm diff` plugin automates this.)

**Q: What happens on `helm rollback`?**
Helm re-applies the stored manifest of the target revision and records a **new** revision
("Rollback to N"). Nothing is deleted from history. Proven in [02-rollback](02-rollback/README.md).

**Q: An upgrade failed. What state is the cluster in?**
Possibly half-applied - objects applied before the failure stay changed ([03](03-mini-project/README.md#a-bad-upgrade-and-the-rollback)).
Roll back explicitly, or upgrade with `--rollback-on-failure` (`--atomic` in Helm 3).

**Q: Helm 2 vs Helm 3?**
Helm 2 needed Tiller, a server-side pod with broad cluster permissions. Helm 3 removed it;
the client uses your own RBAC and stores releases as Secrets per namespace.

**Q: Helm 3 vs Helm 4 (from what I used)?**
Server-side apply by default, `--wait` as a strategy (kstatus watcher), `--atomic` ->
`--rollback-on-failure`, `--force` -> `--force-replace`, `--dry-run=client|server`,
`helm list` shows all statuses by default, `helm status` always shows resources.

**Q: How would you stop a typo in values reaching the cluster?**
`values.schema.json` plus `required` in templates, and `helm lint -f <env values>` in CI.
