#!/usr/bin/env bash
# Helm rollback workflow:
#   Install -> Upgrade -> Verify -> Upgrade again (bad) -> Verify -> Rollback -> Verify
# plus a bonus run of --rollback-on-failure (Helm 4's name for --atomic).
#
# Usage: ./run.sh [all|cleanup]        (default: all)
#   SHOTS=1 ./run.sh   also saves termshot screenshots into screenshots/
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
NS=helm-rollback
REL=web
CHART=./rollback-web

x() { echo "\$ $1"; eval "$1" 2>&1; }

shot() {
  [ "${SHOTS:-0}" = 1 ] || return 0
  local name=$1; shift
  WIDTH="${W:-130}" ../../lab/shot.sh "screenshots/$name.png" "$@" >/dev/null 2>&1 \
    || echo "  (screenshot $name failed)"
}

# Live pods of the release (terminating ones filtered out, see the
# kubernetes-pods-replicasets-deployments notes for why custom-columns + awk).
pods() {
  kubectl get pods -n $NS -l app.kubernetes.io/instance=$REL --no-headers \
    -o custom-columns='POD:.metadata.name,IMAGE:.spec.containers[0].image,PORT:.spec.containers[0].ports[0].containerPort,READY:.status.containerStatuses[0].ready,RESTARTS:.status.containerStatuses[0].restartCount,DEL:.metadata.deletionTimestamp' \
    | awk 'BEGIN {printf "  %-22s %-18s %-5s %-6s %s\n", "POD", "IMAGE", "PORT", "READY", "RESTARTS"}
           $6=="<none>" {printf "  %-22s %-18s %-5s %-6s %s\n", $1, $2, $3, $4, $5}'
}

# What a user actually gets: 10 requests through the Service, grouped.
traffic() {
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    kubectl -n $NS exec curl -- curl -si -m 2 http://$REL/ 2>/dev/null | tr -d '\r' \
      | awk '/^Server:/ {s=$2} /^site version/ {v=$4} END {print (v=="" ? "NO RESPONSE" : "page " v "  served by " s)}'
  done | sort | uniq -c | sed 's/^ */  /'
}

# One snapshot of the release: Helm's view, the pods, and the real traffic.
verify() {
  echo "--- helm history ---"
  helm history $REL -n $NS 2>&1
  echo
  echo "--- pods ---"
  pods
  echo
  echo "--- 10 requests through Service/$REL ---"
  traffic
}

run_all() {
  hr "STEP 0 - Lint, and see exactly what each values file changes"
  x "helm lint $CHART -f values-v2.yaml -f values-v3-bad.yaml"
  echo
  echo "v1 (chart defaults) -> v2:"
  x "diff <(helm template $REL $CHART) <(helm template $REL $CHART -f values-v2.yaml) | grep -E '^[<>] .*(image:|site version|message|containerPort)'"
  echo
  echo "v2 -> v3-bad:"
  x "diff <(helm template $REL $CHART -f values-v2.yaml) <(helm template $REL $CHART -f values-v3-bad.yaml)"

  hr "STEP 1 - INSTALL (revision 1: page v1, nginx 1.25)"
  x "helm install $REL $CHART -n $NS --create-namespace --wait --timeout 90s --description 'v1: first release, nginx 1.25'"
  kubectl -n $NS run curl --image=curlimages/curl:8.5.0 --restart=Never --command -- sleep 3600 >/dev/null
  kubectl -n $NS wait --for=condition=Ready pod/curl --timeout=120s >/dev/null

  hr "STEP 2 - VERIFY revision 1"
  verify

  hr "STEP 3 - UPGRADE (revision 2: page v2, nginx 1.27)"
  x "helm upgrade $REL $CHART -n $NS -f values-v2.yaml --wait --timeout 90s --description 'v2: new page, nginx 1.27'"

  hr "STEP 4 - VERIFY revision 2"
  verify
  W=150 shot 1-after-good-upgrade bash -c "helm history $REL -n $NS | tr '\\t' ' '; echo; kubectl -n $NS exec curl -- curl -s http://$REL/"

  hr "STEP 5 - UPGRADE AGAIN (revision 3: containerPort 8080 - the bad one)"
  x "helm upgrade $REL $CHART -n $NS -f values-v3-bad.yaml --wait --timeout 45s --description 'v3: move to port 8080'"
  echo "exit code: $?"

  hr "STEP 6 - VERIFY revision 3 - Helm says failed; what do users see?"
  verify
  echo
  echo "--- helm status ---"
  x "helm status $REL -n $NS | head -n 7"
  echo
  echo "--- why the new pod never becomes Ready ---"
  BAD=$(kubectl get pods -n $NS -l app.kubernetes.io/instance=$REL --no-headers \
        -o custom-columns='N:.metadata.name,P:.spec.containers[0].ports[0].containerPort' | awk '$2==8080 {print $1; exit}')
  kubectl get events -n $NS --field-selector involvedObject.name=$BAD,reason=Unhealthy \
    -o custom-columns='MESSAGE:.message' --no-headers 2>/dev/null | sort -u | sed 's/^/  /'
  echo
  echo ">>> Helm marked revision 3 FAILED, but users never noticed: the rolling"
  echo "    update only added ONE surge pod (maxSurge 25% of 3 -> 1, maxUnavailable"
  echo "    -> 0) and it never became Ready, so the three v2 pods kept serving."
  echo "    The Deployment is stuck half-way, though - that is what rollback fixes."
  W=150 shot 2-after-bad-upgrade bash -c "helm history $REL -n $NS | tr '\\t' ' ' | cut -c1-145; echo; kubectl get pods -n $NS -l app.kubernetes.io/instance=$REL"

  hr "STEP 7 - What exactly differs between revision 2 and revision 3?"
  x "helm get values $REL -n $NS --revision 2"
  x "helm get values $REL -n $NS --revision 3"
  echo
  x "diff <(helm get manifest $REL -n $NS --revision 2) <(helm get manifest $REL -n $NS --revision 3)"

  hr "STEP 8 - ROLLBACK to revision 2"
  x "helm rollback $REL 2 -n $NS --wait --timeout 90s"

  hr "STEP 9 - VERIFY after the rollback"
  verify
  echo
  x "helm history $REL -n $NS --show-rollback-revision"
  echo
  echo "Revision 4 is a NEW revision whose content is revision 2's:"
  x "diff <(helm get manifest $REL -n $NS --revision 2) <(helm get manifest $REL -n $NS --revision 4) && echo '  manifests of revision 2 and 4 are identical'"
  x "kubectl get secrets -n $NS -l owner=helm,name=$REL"
  W=150 shot 3-after-rollback bash -c "helm history $REL -n $NS | tr '\\t' ' ' | cut -c1-145; echo; kubectl -n $NS exec curl -- curl -s http://$REL/"

  hr "STEP 10 - BONUS: let Helm roll back by itself (--rollback-on-failure)"
  echo "Helm 4 renamed --atomic to --rollback-on-failure; the old flag still works but warns:"
  x "helm upgrade $REL $CHART -n $NS -f values-v2.yaml --atomic --dry-run=client | head -n 1"
  echo "  (client dry run - nothing was changed)"
  echo
  echo "Now a real bad upgrade - a typo in the image tag - with automatic rollback:"
  x "helm upgrade $REL $CHART -n $NS -f values-v2.yaml --set image.tag=1.27-alpinee --rollback-on-failure --timeout 40s --description 'v5: typo in image tag'"
  echo
  x "kubectl get events -n $NS --field-selector reason=Failed -o custom-columns=MESSAGE:.message --no-headers | sort -u"
  echo
  verify
  W=150 shot 4-rollback-on-failure bash -c "helm history $REL -n $NS | tr '\\t' ' ' | cut -c1-145"

  hr "DONE - final history"
  x "helm history $REL -n $NS --show-rollback-revision"
}

cleanup() {
  hr "CLEANUP"
  helm uninstall $REL -n $NS --ignore-not-found --wait 2>&1
  kubectl delete ns $NS --ignore-not-found --wait=true 2>&1
}

case "${1:-all}" in
  all) run_all; cleanup ;;
  cleanup) cleanup ;;
  *) echo "usage: $0 [all|cleanup]"; exit 1 ;;
esac
