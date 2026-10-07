#!/usr/bin/env bash
# Helm commands - every command from Session 15, executed for real against the
# kind cluster, in the order you would meet them in a release's life.
#
# Usage: ./run.sh [local|release|repo|cleanup|all]     (default: all)
#   local    create, lint, template, install --dry-run   (no release is created)
#   release  install, list, status, get, upgrade, history, rollback, test, uninstall
#   repo     repo add/list/update, search repo/hub, show, repo remove
#   SHOTS=1 ./run.sh   also saves termshot screenshots into screenshots/
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
NS=helm-demo
REL=pratyush-web
CHART=./pratyush-web
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# x "<command>" - print the command exactly as run, then run it (stderr too).
x() { echo "\$ $1"; eval "$1" 2>&1; }

# Real terminal screenshot of a read-only command (only when SHOTS=1).
shot() {
  [ "${SHOTS:-0}" = 1 ] || return 0
  local name=$1; shift
  WIDTH="${W:-130}" ../../lab/shot.sh "screenshots/$name.png" "$@" >/dev/null 2>&1 \
    || echo "  (screenshot $name failed)"
}

# Hit the Service from the in-cluster client pod. `helm --wait` can return a
# moment before kube-proxy has the new endpoints, so retry briefly.
page() {
  local out="" i
  for i in $(seq 1 15); do
    out=$(kubectl -n $NS exec curl -- curl -si -m 2 http://$REL/ 2>/dev/null) && break
    sleep 1
  done
  # print the body, then the Server header (it reveals the nginx version)
  echo "$out" | tr -d '\r' | awk '
    h==0 && /^$/ {h=1; next}
    h==0 && tolower($0) ~ /^server:/ {srv=$0}
    h==1 {print "  | " $0}
    END {print "  | " srv}'
}

local_only() {
  hr "STEP 1 - helm version (client only - Helm 3+ has no server side)"
  x "helm version"

  hr "STEP 2 - helm create: scaffold a chart"
  (cd "$TMP" && x "helm create pratyush-web")
  echo
  echo "What the scaffold contains:"
  (cd "$TMP" && find pratyush-web | sort | sed 's/^/  /')
  echo
  echo "My committed ./pratyush-web started as exactly this. Files I changed or added:"
  diff -rq "$TMP/pratyush-web" "$CHART" | sed "s#$TMP/##; s/^/  /"
  echo
  echo "(charts/ is empty in a fresh scaffold; git does not track empty dirs and"
  echo " this chart has no dependencies, so I dropped it.)"

  hr "STEP 3 - helm lint: catch mistakes before the cluster sees them"
  x "helm lint $CHART"
  echo
  x "helm lint $CHART -f values-staging.yaml --strict"
  echo
  echo "A broken copy - one template with an unclosed {{ action:"
  cp -r "$CHART" "$TMP/broken-web"
  echo 'broken: {{ .Values.web.message' >> "$TMP/broken-web/templates/configmap.yaml"
  (cd "$TMP" && x "helm lint broken-web"; echo "exit code: $?")

  hr "STEP 4 - helm template: render locally, no cluster involved"
  x "helm template $REL $CHART -s templates/configmap.yaml"
  echo
  echo "Same chart, three sets of values - only the rendered fields change:"
  x "helm template $REL $CHART | grep -E 'replicas:|image: \"nginx'"
  x "helm template $REL $CHART -f values-staging.yaml | grep -E 'replicas:|image: \"nginx'"
  x "helm template $REL $CHART -f values-staging.yaml --set replicaCount=4 | grep -E 'replicas:|image: \"nginx'"
  echo
  echo "Precedence: --set beats -f, and -f beats the chart's values.yaml:"
  x "helm template $REL $CHART -f values-staging.yaml --set web.environment=from-set-flag -s templates/configmap.yaml | grep -E 'message|environment'"

  hr "STEP 5 - helm install --dry-run: everything except actually installing"
  x "helm install $REL $CHART -n $NS --dry-run=client | head -n 8"
  echo "  ... (hooks, full manifest and NOTES follow)"
  echo
  echo "--debug additionally prints the values the templates were rendered with:"
  x "helm install $REL $CHART -n $NS --dry-run=client --debug --set replicaCount=3 | sed -n '/^USER-SUPPLIED/,/^COMPUTED/p'"
  echo
  echo "Helm 4: a bare --dry-run still works but is deprecated:"
  x "helm install $REL $CHART -n $NS --dry-run | head -n 1"
  echo
  echo "--dry-run=server also sends the objects to the API server for validation:"
  x "helm install $REL $CHART -n $NS --dry-run=server | grep -E '^(STATUS|DESCRIPTION):'"
  echo
  echo "Nothing was persisted:"
  x "helm list -n $NS"
  x "kubectl get ns $NS"
}

release() {
  hr "STEP 6 - helm install: create the release (revision 1)"
  x "helm install $REL $CHART -n $NS --create-namespace --wait --timeout 120s"
  echo
  x "kubectl get deploy,svc,cm -n $NS -l app.kubernetes.io/instance=$REL"
  kubectl -n $NS run curl --image=curlimages/curl:8.5.0 --restart=Never --command -- sleep 3600 >/dev/null
  kubectl -n $NS wait --for=condition=Ready pod/curl --timeout=120s >/dev/null
  echo
  echo "What the Service actually serves (curl from a client pod in $NS):"
  page

  hr "STEP 7 - helm list: which releases exist"
  x "helm list -n $NS"
  echo
  x "helm list -A"
  echo
  x "helm list -A -q"
  shot helm-list-all helm list -A

  hr "STEP 8 - helm status: state, resources and NOTES of one release"
  x "helm status $REL -n $NS"
  echo
  echo "Helm 3 needed --show-resources for the RESOURCES block; Helm 4 always prints it"
  echo "and the flag is gone:"
  x "helm status $REL -n $NS --show-resources"
  shot helm-status helm status $REL -n $NS

  hr "STEP 9 - helm get: download what Helm stored for the release"
  x "helm get values $REL -n $NS"
  echo "  (null = I passed no overrides; the chart defaults were used)"
  echo
  x "helm get values $REL -n $NS --all | grep -A3 -E '^(replicaCount|web):'"
  echo
  x "helm get manifest $REL -n $NS | grep -E '^(# Source|kind):'"
  echo
  x "helm get notes $REL -n $NS | head -n 4"
  echo
  x "helm get hooks $REL -n $NS | grep -E 'Source|helm.sh/hook'"
  echo
  x "helm get metadata $REL -n $NS"
  echo
  x "helm get all $REL -n $NS | grep -E '^[A-Z][A-Z -]+:'"
  echo "  (section headers only - 'get all' is values + hooks + manifest + notes in one)"
  shot helm-get-metadata helm get metadata $REL -n $NS

  hr "STEP 10 - helm upgrade --set (revision 2)"
  x "helm upgrade $REL $CHART -n $NS --set replicaCount=3 --set 'web.message=Upgraded with --set' --wait --timeout 120s | head -n 7"
  echo
  x "kubectl get deploy $REL -n $NS"
  page
  x "helm get values $REL -n $NS"

  hr "STEP 11 - helm upgrade -f values-staging.yaml (revision 3)"
  x "helm upgrade $REL $CHART -n $NS -f values-staging.yaml --wait --timeout 120s | head -n 7"
  echo
  x "kubectl get deploy $REL -n $NS -o wide"
  page
  x "helm get values $REL -n $NS"
  echo
  echo ">>> The --set values from revision 2 are GONE (replicas 3 -> 2, message replaced)."
  echo "    A plain 'helm upgrade' starts again from the chart defaults plus only the"
  echo "    overrides given on THIS command line."

  hr "STEP 12 - helm upgrade --reuse-values (revision 4)"
  x "helm upgrade $REL $CHART -n $NS --reuse-values --set replicaCount=4 --wait --timeout 120s | head -n 7"
  echo
  x "helm get values $REL -n $NS"
  x "kubectl get deploy $REL -n $NS"
  echo ">>> --reuse-values kept the staging values and merged replicaCount=4 on top."

  hr "STEP 13 - helm history: every revision is kept"
  x "helm history $REL -n $NS"
  echo
  echo "Where that history lives - one Secret per revision, in the release namespace:"
  x "kubectl get secrets -n $NS -l owner=helm"
  echo
  echo "Each Secret holds the whole release (chart, values, rendered manifest) as"
  echo "base64 + gzip'd JSON:"
  x "kubectl get secret sh.helm.release.v1.$REL.v2 -n $NS -o jsonpath='{.data.release}' | base64 -d | base64 -d | gunzip | python3 -c 'import json,sys; r=json.load(sys.stdin); print(sorted(r)); print(\"config =\", r[\"config\"])'"
  shot helm-history helm history $REL -n $NS

  hr "STEP 14 - helm rollback to revision 1 (creates revision 5)"
  x "helm rollback $REL 1 -n $NS --wait --timeout 120s"
  echo
  x "helm history $REL -n $NS"
  echo
  page
  x "helm get values $REL -n $NS"
  echo
  echo ">>> The page says 'revision 1' while the release is at revision 5: rollback"
  echo "    re-applies the manifest STORED for revision 1, it does not re-render it."
  shot helm-rollback-history helm history $REL -n $NS

  hr "STEP 15 - helm test: run the chart's test hook (templates/tests/)"
  x "helm test $REL -n $NS --logs"

  hr "STEP 16 - helm uninstall --keep-history"
  x "helm uninstall $REL -n $NS --keep-history --wait"
  kubectl wait --for=delete pod -n $NS -l app.kubernetes.io/instance=$REL,pod-template-hash --timeout=90s >/dev/null 2>&1
  echo
  x "kubectl get all,cm,sa -n $NS"
  echo "  The Deployment, Service, ConfigMap and ServiceAccount are gone. Two pods remain:"
  echo "  - curl: I created it with kubectl, so Helm never owned it"
  echo "  - pratyush-web-test-connection: a test HOOK; hook resources are not tracked"
  echo "    as part of the release, so uninstall leaves them behind"
  echo
  x "helm list -n $NS"
  x "helm list -n $NS --deployed"
  x "helm history $REL -n $NS"
  shot helm-uninstall-keep-history bash -c "helm list -n $NS --uninstalled; echo; helm history $REL -n $NS"
  echo
  echo "Because history was kept, the release can be brought back:"
  x "helm rollback $REL 4 -n $NS --wait --timeout 120s"
  x "helm list -n $NS"
  page

  hr "STEP 17 - helm uninstall (plain): resources AND history removed"
  x "helm uninstall $REL -n $NS --wait"
  x "helm history $REL -n $NS"
  x "kubectl get secrets -n $NS -l owner=helm"
}

repo() {
  hr "STEP 18 - helm repo add / list / update"
  x "helm repo add prometheus-community https://prometheus-community.github.io/helm-charts"
  x "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
  x "helm repo list"
  x "helm repo update"
  shot helm-repo-list helm repo list

  hr "STEP 19 - helm search repo: search the repos added locally"
  x "helm search repo nginx"
  echo
  x "helm search repo ingress-nginx/ingress-nginx --versions | head -n 5"
  echo
  x "helm search repo kube-prometheus-stack"
  echo
  echo "helm show reads a chart without installing it:"
  x "helm show chart ingress-nginx/ingress-nginx | grep -E '^(name|version|appVersion|kubeVersion|description):'"
  shot helm-search-repo helm search repo nginx

  hr "STEP 20 - helm search hub: search Artifact Hub (no repo needed)"
  x "helm search hub nginx --max-col-width 45 | head -n 8"
  echo "  ..."
  x "helm search hub nginx | tail -n +2 | wc -l | tr -d ' '"
  echo "  (charts matching 'nginx' on Artifact Hub)"
  W=150 shot helm-search-hub bash -c "helm search hub nginx --max-col-width 38 | head -n 10"

  hr "STEP 21 - helm repo remove"
  x "helm repo remove prometheus-community ingress-nginx"
  x "helm repo list"
}

cleanup() {
  hr "CLEANUP"
  helm uninstall $REL -n $NS --ignore-not-found 2>&1
  kubectl delete ns $NS --ignore-not-found --wait=true 2>&1
  helm repo remove prometheus-community ingress-nginx >/dev/null 2>&1 || true
  echo "namespace $NS and repos removed"
}

case "${1:-all}" in
  local) local_only ;; release) release ;; repo) repo ;; cleanup) cleanup ;;
  all) local_only; release; repo; cleanup ;;
  *) echo "usage: $0 [local|release|repo|cleanup|all]"; exit 1 ;;
esac
