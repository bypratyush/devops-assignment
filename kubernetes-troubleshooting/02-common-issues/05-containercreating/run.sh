#!/usr/bin/env bash
# ContainerCreating (stuck) - volumes that reference a missing ConfigMap and Secret.
# Usage: ./run.sh [all|break|investigate|fix|verify|cleanup]   (default: all)
#        SHOTS=1 ./run.sh   also captures screenshots/
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lib.sh
NS=s14-issues
pod_of() { kubectl -n $NS get pods -l app=invoice-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null; }

break_it() {
  hr "STEP 1 - Deploy the broken manifest"
  ensure_ns $NS >/dev/null
  wait_gone $NS issue=containercreating
  kubectl apply -f broken.yaml

  hr "STEP 2 - IDENTIFY: scheduled, but never gets past ContainerCreating"
  sleep 45
  kubectl -n $NS get pods -l issue=containercreating -o wide
  shot screenshots/containercreating-before.png kubectl -n $NS get pods -l issue=containercreating -o wide
  echo
  echo "Unlike Pending, NODE is set: the scheduler did its job. The kubelet on"
  echo "that node is stuck preparing the pod. 45 seconds for a 2 MB busybox"
  echo "image that is already cached is not 'slow', it is stuck."
}

investigate() {
  local P; P=$(pod_of)
  hr "STEP 3 - INVESTIGATE: describe -> Volumes and Events"
  echo "\$ kubectl -n $NS describe pod $P"
  kubectl -n $NS describe pod "$P" | sed -n '/^Volumes:/,/^QoS/p' | grep -v -E 'kube-api-access|Projected|TokenExpiration|ConfigMapName: *kube-root|ConfigMapOptional: *<nil>|DownwardAPI|^QoS'
  kubectl -n $NS describe pod "$P" | sed -n '/^Events:/,$p'
  shot screenshots/containercreating-events.png bash -c "kubectl -n $NS describe pod $P | sed -n '/^Events:/,\$p'"

  sub "check whether the referenced objects exist"
  run kubectl -n $NS get configmap invoice-config
  run kubectl -n $NS get secret invoice-db
  echo
  echo "\$ kubectl -n $NS get configmaps,secrets"
  kubectl -n $NS get configmaps,secrets 2>&1

  sub "no container yet, so nothing to exec into or read logs from"
  run kubectl -n $NS logs "$P"

  hr "STEP 4 - ROOT CAUSE"
  echo "The pod mounts ConfigMap 'invoice-config' and Secret 'invoice-db'."
  echo "Neither exists in namespace $NS, so MountVolume.SetUp fails and the"
  echo "kubelet will not start a container with half its volumes missing."
  echo "(A missing key referenced from an ENV var fails differently - see"
  echo " 09-configuration, CreateContainerConfigError.)"
}

fix() {
  local P; P=$(pod_of)
  hr "STEP 5 - FIX: create the missing ConfigMap and Secret"
  echo "pod before the fix: $P"
  kubectl apply -f fixed.yaml
  echo
  echo "The Deployment is unchanged ('unchanged' above), so no new pod is"
  echo "created. Watching the SAME pod recover as the kubelet retries the mount:"
  watch_for 75 kubectl -n $NS get pods -l issue=containercreating -w
}

verify() {
  local P; P=$(pod_of)
  hr "STEP 6 - VERIFY"
  kubectl -n $NS get pods -l issue=containercreating -o wide
  shot screenshots/containercreating-after.png kubectl -n $NS get pods -l issue=containercreating -o wide
  echo
  run kubectl -n $NS logs "$P"
  echo
  echo "\$ kubectl -n $NS exec $P -- ls /etc/invoice /etc/invoice-db"
  kubectl -n $NS exec "$P" -- ls /etc/invoice /etc/invoice-db 2>&1
  echo
  kubectl -n $NS get events --field-selector involvedObject.name="$P" \
    -o custom-columns=REASON:.reason,COUNT:.count,MESSAGE:.message --no-headers | cut -c1-140
  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f fixed.yaml --ignore-not-found
  wait_gone $NS issue=containercreating
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
