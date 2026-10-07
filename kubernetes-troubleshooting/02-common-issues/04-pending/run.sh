#!/usr/bin/env bash
# Pending - pods the scheduler cannot place (impossible CPU request, bad nodeSelector).
# Usage: ./run.sh [all|break|investigate|fix|verify|cleanup]   (default: all)
#        SHOTS=1 ./run.sh   also captures screenshots/
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lib.sh
NS=s14-issues
pod_of() { kubectl -n $NS get pods -l app="$1" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null; }

break_it() {
  hr "STEP 1 - Deploy the broken manifests"
  ensure_ns $NS >/dev/null
  wait_gone $NS issue=pending
  kubectl apply -f broken.yaml

  hr "STEP 2 - IDENTIFY: Pending, with no node and no IP"
  sleep 10
  kubectl -n $NS get pods -l issue=pending -o wide
  shot screenshots/pending-before.png kubectl -n $NS get pods -l issue=pending -o wide
  echo
  echo "NODE is <none>: the pod was never scheduled, so the kubelet never saw it."
  echo "That means no image pull, no container and no logs:"
  echo
  run kubectl -n $NS logs "$(pod_of report-builder)"
}

investigate() {
  local R S
  R=$(pod_of report-builder); S=$(pod_of search-indexer)
  hr "STEP 3 - INVESTIGATE: the scheduler explains itself in the Events"
  echo "\$ kubectl -n $NS describe pod $R"
  kubectl -n $NS describe pod "$R" | sed -n '/^    Requests:/,/^      memory:/p'
  kubectl -n $NS describe pod "$R" | sed -n '/^Events:/,$p'
  echo
  echo "\$ kubectl -n $NS describe pod $S"
  kubectl -n $NS describe pod "$S" | sed -n '/^Node-Selectors:/p'
  kubectl -n $NS describe pod "$S" | sed -n '/^Events:/,$p'
  shot screenshots/pending-events.png bash -c "kubectl -n $NS get events --field-selector reason=FailedScheduling -o custom-columns=OBJECT:.involvedObject.name,MESSAGE:.message"
  echo
  echo "Read the message as a tally over all 3 nodes:"
  echo "  - the control-plane is excluded by its NoSchedule taint (normal)"
  echo "  - the 2 workers are excluded for 'Insufficient cpu' / not matching"
  echo "    the node selector"
  echo "  - 'preemption: ... not helpful': evicting lower-priority pods would"
  echo "    not make room either, so it will stay Pending forever"

  hr "STEP 4 - INVESTIGATE: compare the ask with what the nodes have"
  echo "\$ kubectl get nodes -o custom-columns=NAME,CPU,MEMORY,TAINTS"
  kubectl get nodes -o custom-columns='NAME:.metadata.name,ALLOCATABLE_CPU:.status.allocatable.cpu,ALLOCATABLE_MEM:.status.allocatable.memory,TAINTS:.spec.taints[*].key'
  echo
  echo "\$ kubectl describe node devops-hw-worker   (Allocated resources)"
  kubectl describe node devops-hw-worker | sed -n '/^Allocated resources:/,/^  memory/p'
  echo
  echo "\$ kubectl get nodes -L disktype"
  kubectl get nodes -L disktype
  echo
  echo "64 CPUs requested vs 15 allocatable per node; and the DISKTYPE column is"
  echo "empty on every node, so 'disktype=ssd' can never match."

  hr "STEP 5 - ROOT CAUSE"
  echo "report-builder : requests.cpu=64 is larger than any node. Requests are"
  echo "                 a scheduling RESERVATION, not usage - the scheduler will"
  echo "                 not place a pod whose request does not fit."
  echo "search-indexer : nodeSelector disktype=ssd matches zero nodes."
}

fix() {
  hr "STEP 6 - FIX"
  echo "\$ kubectl diff -f fixed.yaml"
  kubectl diff -f fixed.yaml 2>&1 | grep -E '^[+-] ' | grep -v -E 'generation' | sed 's/^/  /'
  echo
  kubectl apply -f fixed.yaml
  kubectl -n $NS rollout status deployment/report-builder --timeout=120s
  kubectl -n $NS rollout status deployment/search-indexer --timeout=120s
}

verify() {
  hr "STEP 7 - VERIFY: scheduled, on a real node, Running"
  sleep 3
  kubectl -n $NS get pods -l issue=pending -o wide
  shot screenshots/pending-after.png kubectl -n $NS get pods -l issue=pending -o wide
  echo
  P=$(kubectl -n $NS get pods -l app=report-builder --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
  kubectl -n $NS get events --field-selector involvedObject.name="$P",reason=Scheduled \
    -o custom-columns=REASON:.reason,MESSAGE:.message --no-headers
  echo
  run kubectl -n $NS logs deploy/report-builder
  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f fixed.yaml --ignore-not-found
  wait_gone $NS issue=pending
}

case "${1:-all}" in
  all)         break_it; investigate; fix; verify ;;
  break)       break_it ;;
  investigate) investigate ;;
  fix)         fix ;;
  verify)      verify ;;
  cleanup)     cleanup ;;
  *) echo "usage: $0 [all|break|investigate|fix|verify|cleanup]"; exit 1 ;;
esac
