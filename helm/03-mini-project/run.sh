#!/usr/bin/env bash
# Session 15 mini project - package the Notes app as a Helm chart and run it
# as two environments (dev + prod) from ONE chart with different values.
#
# Usage: ./run.sh [all|cleanup]        (default: all)
#   SHOTS=1 ./run.sh   also saves termshot screenshots into screenshots/
#
# Needs ingress-nginx in the cluster with host port 80 mapped to localhost.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
CHART=./notes-chart
DEV_NS=notes-dev;   DEV=notes-dev;   DEV_HOST=notes-dev.local
PROD_NS=notes-prod; PROD=notes-prod; PROD_HOST=notes.local
NEW_NOTES='["Finish the Session 15 Helm homework","Read up on values precedence","Rollback creates a NEW revision"]'

x() { echo "\$ $1"; eval "$1" 2>&1; }

shot() {
  [ "${SHOTS:-0}" = 1 ] || return 0
  local name=$1; shift
  WIDTH="${W:-130}" ../../lab/shot.sh "screenshots/$name.png" "$@" >/dev/null 2>&1 \
    || echo "  (screenshot $name failed)"
}

# GET the app through ingress-nginx on the Mac's port 80, with a Host header.
# Retries briefly: the ingress controller needs a moment to pick up changes.
open_app() {
  local host=$1 out="" i
  for i in $(seq 1 20); do
    out=$(curl -s -i -m 3 -H "Host: $host" http://localhost/ | tr -d '\r')
    echo "$out" | head -1 | grep -q ' 200' && break
    sleep 1
  done
  echo "$out" | grep -E '^(HTTP|X-)' | sed 's/^/  /'
  echo "$out" | awk 'b {print "  | " $0} /^$/ {b=1}'
}

# One line per environment: what is really running.
compare() {
  printf "  %-11s %-9s %-18s %-21s %-21s %-13s %s\n" NAMESPACE REPLICAS IMAGE REQUESTS LIMITS ENV PDB
  local ns dep
  for ns in $DEV_NS $PROD_NS; do
    dep=$ns
    kubectl get deploy $dep -n $ns -o jsonpath='{.spec.replicas} {.spec.template.spec.containers[0].image} {.spec.template.spec.containers[0].resources.requests.cpu}/{.spec.template.spec.containers[0].resources.requests.memory} {.spec.template.spec.containers[0].resources.limits.cpu}/{.spec.template.spec.containers[0].resources.limits.memory}' \
      | { read -r r img req lim
          env=$(kubectl get cm $dep-config -n $ns -o jsonpath='{.data.ENVIRONMENT}/{.data.LOG_LEVEL}')
          pdb=$(kubectl get pdb $dep -n $ns -o jsonpath='minAvailable={.spec.minAvailable}' 2>/dev/null || true)
          printf "  %-11s %-9s %-18s %-21s %-21s %-13s %s\n" "$ns" "$r" "$img" "$req" "$lim" "$env" "${pdb:-none}"; }
  done
}

run_all() {
  hr "STEP 1 - The chart"
  (cd "$CHART" && find . -type f | sort | sed 's#^\./#  notes-chart/#')
  echo
  x "helm lint $CHART"
  x "helm lint $CHART -f $CHART/values-prod.yaml"

  hr "STEP 2 - Bad values are rejected before anything reaches the cluster"
  echo "values.schema.json - replicas must be >= 1, environment must be a known one:"
  x "helm lint $CHART --set replicaCount=0 --set app.environment=prod"
  echo
  echo "required in a template - an ingress with no host makes no sense:"
  x "helm template notes $CHART --set ingress.host=null"
  shot schema-validation helm lint $CHART --set replicaCount=0 --set app.environment=prod

  hr "STEP 3 - helm template: dev vs prod rendered from the same chart"
  echo "Both rendered with the same release name, so every difference below comes"
  echo "from values-prod.yaml and nothing else ('<' dev, '>' prod):"
  x "diff <(helm template notes $CHART) <(helm template notes $CHART -f $CHART/values-prod.yaml)"
  W=120 shot template-diff-dev-vs-prod bash -c "diff <(helm template notes $CHART) <(helm template notes $CHART -f $CHART/values-prod.yaml) | grep -vE '^---|environment: (development|production)$'"

  hr "STEP 4 - INSTALL dev (chart defaults = values.yaml)"
  x "helm install $DEV $CHART -n $DEV_NS --create-namespace --wait --timeout 120s"

  hr "STEP 5 - INSTALL prod (values.yaml + values-prod.yaml)"
  x "helm install $PROD $CHART -n $PROD_NS --create-namespace -f $CHART/values-prod.yaml --wait --timeout 120s"

  hr "STEP 6 - Same chart, two environments: what actually differs"
  x "helm list -A --filter '^notes-'"
  echo
  x "kubectl get deploy,svc,ingress,pdb -n $DEV_NS"
  echo
  x "kubectl get deploy,svc,ingress,pdb -n $PROD_NS"
  echo
  echo "--- side by side (read from the live objects) ---"
  compare
  echo
  echo "--- env vars inside one pod of each (from the -config ConfigMap) ---"
  x "kubectl exec -n $DEV_NS deploy/$DEV -- printenv APP_NAME ENVIRONMENT LOG_LEVEL"
  x "kubectl exec -n $PROD_NS deploy/$PROD -- printenv APP_NAME ENVIRONMENT LOG_LEVEL"
  echo
  echo "--- through ingress-nginx from the Mac: curl -H 'Host: $DEV_HOST' http://localhost/ ---"
  open_app $DEV_HOST
  echo
  echo "--- curl -H 'Host: $PROD_HOST' http://localhost/ ---"
  open_app $PROD_HOST
  echo
  echo "--- prod has 3 replicas: 12 requests, grouped by the pod that answered ---"
  for _ in $(seq 1 12); do curl -s -i -H "Host: $PROD_HOST" http://localhost/ | tr -d '\r' | awk '/^X-Served-By/ {print $2}'; done \
    | sort | uniq -c | sed 's/^ */  /'
  shot dev-prod-releases helm list -A --filter '^notes-'
  W=110 shot curl-dev-vs-prod bash -c "curl -s -H 'Host: $DEV_HOST' http://localhost/; echo; curl -s -H 'Host: $PROD_HOST' http://localhost/"
  W=140 shot dev-prod-resources kubectl get deploy,svc,ingress,pdb -A -l app.kubernetes.io/name=notes-chart

  hr "STEP 7 - UPGRADE dev (revision 2): one more note, 2 replicas"
  x "helm upgrade $DEV $CHART -n $DEV_NS --set replicaCount=2 --set-json 'notes=$NEW_NOTES' --wait --timeout 120s | head -n 7"
  echo
  open_app $DEV_HOST
  echo
  x "helm history $DEV -n $DEV_NS"

  hr "STEP 8 - A BAD UPGRADE: prod values applied to the dev release by mistake"
  echo "(the instructor's step 11 command - harmless with one release, wrong once"
  echo " a separate prod release exists)"
  x "helm upgrade $DEV $CHART -n $DEV_NS -f $CHART/values-prod.yaml --wait --timeout 120s"
  echo "exit code: $?"
  echo
  echo "Helm says FAILED - so did nothing change? Let the Deployment finish and look:"
  kubectl rollout status deploy/$DEV -n $DEV_NS --timeout=120s | tail -n 1
  kubectl wait --for=delete pod -n $DEV_NS -l environment=development --timeout=60s >/dev/null 2>&1
  echo
  x "helm history $DEV -n $DEV_NS"
  echo
  compare
  echo
  open_app $DEV_HOST
  echo
  echo ">>> The webhook rejected only the Ingress (notes.local belongs to prod)."
  echo "    The ConfigMaps, the Deployment and a brand-new PDB were applied BEFORE"
  echo "    that, so the dev URL now serves a 3-replica PRODUCTION config even"
  echo "    though Helm marked the revision failed. Helm upgrades are not"
  echo "    transactions."
  W=140 shot bad-upgrade-dev bash -c "helm history $DEV -n $DEV_NS | tr '\\t' ' ' | cut -c1-138; echo; curl -s -H 'Host: $DEV_HOST' http://localhost/"

  hr "STEP 9 - ROLLBACK dev to revision 2"
  x "helm rollback $DEV 2 -n $DEV_NS --wait --timeout 120s"
  kubectl wait --for=delete pod -n $DEV_NS -l environment=production --timeout=60s >/dev/null 2>&1
  echo
  x "helm history $DEV -n $DEV_NS"
  echo
  compare
  echo
  open_app $DEV_HOST
  echo
  echo "prod was never touched - each release has its own history:"
  x "helm history $PROD -n $PROD_NS"
  W=140 shot rollback-dev bash -c "helm history $DEV -n $DEV_NS | tr '\\t' ' ' | cut -c1-138; echo; curl -s -H 'Host: $DEV_HOST' http://localhost/"

  hr "STEP 10 - helm get: values and NOTES per environment"
  x "helm get values $DEV -n $DEV_NS"
  x "helm get values $PROD -n $PROD_NS"
  echo
  x "helm get notes $PROD -n $PROD_NS"
  W=110 shot notes-txt-prod helm get notes $PROD -n $PROD_NS

  hr "STEP 11 - Why the chart does not hard-code nodePort (the instructor's values do)"
  echo "nodePorts are cluster-wide. Two releases asking for 30090:"
  x "helm install nodeport-a $CHART -n $DEV_NS --set service.type=NodePort --set service.nodePort=30090 --set ingress.enabled=false | grep -E '^(STATUS|Error)'"
  x "helm install nodeport-b $CHART -n $PROD_NS --set service.type=NodePort --set service.nodePort=30090 --set ingress.enabled=false --dry-run=server | grep -E '^(STATUS|DESCRIPTION|Error)'"
  x "helm install nodeport-b $CHART -n $PROD_NS --set service.type=NodePort --set service.nodePort=30090 --set ingress.enabled=false"
  echo
  echo ">>> --dry-run=server said fine; the real install failed. A dry run does not"
  echo "    allocate ports, so it cannot see the clash."
  helm uninstall nodeport-a -n $DEV_NS >/dev/null 2>&1
  helm uninstall nodeport-b -n $PROD_NS >/dev/null 2>&1
}

cleanup() {
  hr "CLEANUP"
  helm uninstall $DEV -n $DEV_NS --ignore-not-found --wait 2>&1
  helm uninstall $PROD -n $PROD_NS --ignore-not-found --wait 2>&1
  helm uninstall nodeport-a -n $DEV_NS --ignore-not-found >/dev/null 2>&1
  helm uninstall nodeport-b -n $PROD_NS --ignore-not-found >/dev/null 2>&1
  kubectl delete ns $DEV_NS $PROD_NS --ignore-not-found --wait=true 2>&1
}

case "${1:-all}" in
  all) run_all; cleanup ;;
  cleanup) cleanup ;;
  *) echo "usage: $0 [all|cleanup]"; exit 1 ;;
esac
