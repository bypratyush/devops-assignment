#!/usr/bin/env bash
# ReplicaSets - keep N identical pods alive. And why you still don't use them directly.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
RS=web-rs

deploy() {
  hr "STEP 1 - Create a ReplicaSet with 3 replicas"
  kubectl apply -f replicaset.yaml
  kubectl wait --for=jsonpath='{.status.readyReplicas}'=3 rs/$RS --timeout=120s
}

verify() {
  hr "STEP 2 - The ReplicaSet and the pods it created"
  kubectl get rs $RS
  echo
  kubectl get pods -l app=web-rs -o wide
  echo
  echo "Pod names = <replicaset-name>-<random suffix>. They are interchangeable"
  echo "and have no stable identity (contrast with a StatefulSet)."

  hr "STEP 3 - Ownership: each pod records who created it"
  kubectl get pods -l app=web-rs -o jsonpath='{range .items[*]}  {.metadata.name}  ownedBy={.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}{"\n"}{end}'
  echo
  echo "This ownerReference is how garbage collection works: delete the"
  echo "ReplicaSet and the pods it owns are deleted with it."

  hr "STEP 4 - SELF-HEALING: delete a pod and watch it come back"
  VICTIM=$(kubectl get pods -l app=web-rs -o jsonpath='{.items[0].metadata.name}')
  echo "before:"
  kubectl get pods -l app=web-rs --no-headers | awk '{printf "  %-24s %s  %s\n", $1, $3, $5}'
  echo
  echo "deleting $VICTIM ..."
  kubectl delete pod "$VICTIM" --wait=true >/dev/null
  kubectl wait --for=jsonpath='{.status.readyReplicas}'=3 rs/$RS --timeout=120s >/dev/null
  echo
  echo "after:"
  kubectl get pods -l app=web-rs --no-headers | awk '{printf "  %-24s %s  %s\n", $1, $3, $5}'
  echo
  echo ">>> Still 3 pods. A REPLACEMENT was created automatically (note the new"
  echo "    name and the very low AGE). This is exactly what a bare Pod could"
  echo "    not do in task 01."

  hr "STEP 5 - Scaling"
  echo "\$ kubectl scale rs/$RS --replicas=5"
  kubectl scale rs/$RS --replicas=5 >/dev/null
  kubectl wait --for=jsonpath='{.status.readyReplicas}'=5 rs/$RS --timeout=120s >/dev/null
  kubectl get rs $RS
  kubectl get pods -l app=web-rs --no-headers | wc -l | xargs printf "  pods now: %s\n"
  echo
  echo "\$ kubectl scale rs/$RS --replicas=2"
  kubectl scale rs/$RS --replicas=2 >/dev/null
  sleep 4
  kubectl get rs $RS
  kubectl get pods -l app=web-rs --no-headers | wc -l | xargs printf "  pods now: %s\n"
  kubectl scale rs/$RS --replicas=3 >/dev/null
  kubectl wait --for=jsonpath='{.status.readyReplicas}'=3 rs/$RS --timeout=120s >/dev/null
  echo "  (restored to 3)"

  hr "STEP 6 - It selects on LABELS, so it ADOPTS matching stray pods"
  echo "Deterministic demo: delete the ReplicaSet, create a BARE pod carrying"
  echo "the label app=web-rs, and only THEN recreate the ReplicaSet."
  echo
  kubectl delete -f replicaset.yaml --ignore-not-found --wait=true >/dev/null
  kubectl wait --for=delete pod -l app=web-rs --timeout=90s >/dev/null 2>&1
  kubectl apply -f orphan-pod.yaml
  kubectl wait --for=condition=Ready pod/orphan-pod --timeout=120s >/dev/null
  echo
  echo "--- before the ReplicaSet exists: one bare pod, owned by nobody ---"
  kubectl get pod orphan-pod --no-headers | awk '{printf "  %-24s %s\n", $1, $3}'
  OWNER=$(kubectl get pod orphan-pod -o jsonpath='{.metadata.ownerReferences[0].name}' 2>/dev/null)
  echo "  ownerReferences: ${OWNER:-<none>}"
  echo
  echo "Now creating the ReplicaSet with replicas=3 ..."
  kubectl apply -f replicaset.yaml
  kubectl wait --for=jsonpath='{.status.readyReplicas}'=3 rs/$RS --timeout=120s >/dev/null
  echo
  echo "--- after ---"
  kubectl get pods -l app=web-rs --no-headers | awk '{printf "  %-24s %-9s age=%s\n", $1, $3, $5}'
  echo
  echo "--- orphan-pod is still alive, and is now OWNED by the ReplicaSet ---"
  kubectl get pod orphan-pod -o jsonpath='  orphan-pod ownedBy = {.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}{"\n"}' 2>/dev/null \
    || echo "  (orphan-pod was deleted instead)"
  echo
  RSCOUNT=$(kubectl get pods -l app=web-rs --no-headers | wc -l | tr -d ' ')
  echo ">>> Total pods matching the selector: $RSCOUNT (not 4)."
  echo "    The ReplicaSet ADOPTED the existing pod and created only 2 more."
  echo
  echo "Lesson: a ReplicaSet owns every pod matching its selector, whether or"
  echo "not it created it. Overlapping selectors between two controllers make"
  echo "them fight over the same pods - a real and very confusing production bug."

  hr "STEP 7 - WHY YOU STILL DON'T USE ReplicaSets DIRECTLY"
  echo "Current image on the running pods:"
  kubectl get pods -l app=web-rs -o jsonpath='{range .items[*]}  {.metadata.name}  {.spec.containers[0].image}{"\n"}{end}'
  echo
  echo "Now change the ReplicaSet's image to nginx:1.27-alpine:"
  kubectl patch rs $RS --type=json \
    -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"nginx:1.27-alpine"}]' >/dev/null
  echo
  echo "--- the ReplicaSet template says: ---"
  kubectl get rs $RS -o jsonpath='  template image: {.spec.template.spec.containers[0].image}{"\n"}'
  echo
  sleep 5
  echo "--- but the RUNNING PODS still say: ---"
  kubectl get pods -l app=web-rs -o jsonpath='{range .items[*]}  {.metadata.name}  {.spec.containers[0].image}{"\n"}{end}'
  echo
  echo ">>> NOTHING WAS UPDATED. A ReplicaSet only guarantees the COUNT of pods,"
  echo "    not their content. The new image is used only when a pod happens to"
  echo "    be recreated - so your fleet ends up in a mixed, unpredictable state."
  echo
  echo "There is no rollout, no rollback, no revision history, no controlled"
  echo "replacement. That gap is precisely what a DEPLOYMENT fills (task 03)."

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f orphan-pod.yaml --ignore-not-found
  kubectl delete -f replicaset.yaml --ignore-not-found
}

case "${1:-all}" in
  deploy) deploy ;; verify) verify ;; cleanup) cleanup ;;
  all) deploy; verify ;;
  *) echo "usage: $0 [deploy|verify|cleanup]"; exit 1 ;;
esac
