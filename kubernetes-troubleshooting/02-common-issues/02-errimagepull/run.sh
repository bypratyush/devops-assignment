#!/usr/bin/env bash
# ErrImagePull - a typo in the image tag.
# Usage: ./run.sh [all|break|investigate|fix|verify|cleanup]   (default: all)
#        SHOTS=1 ./run.sh   also captures screenshots/
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lib.sh
NS=s14-issues
pod_of() { kubectl -n $NS get pods -l app=storefront -o jsonpath='{.items[0].metadata.name}' 2>/dev/null; }
ACCEPT='Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json'

break_it() {
  hr "STEP 1 - Deploy the broken manifest"
  ensure_ns $NS >/dev/null
  wait_gone $NS issue=errimagepull
  kubectl apply -f broken.yaml

  hr "STEP 2 - IDENTIFY: watch the pod's first 45 seconds"
  watch_for 45 kubectl -n $NS get pods -l issue=errimagepull -w
  echo
  echo "Two statuses take turns:"
  echo "  ErrImagePull     - a pull was just ATTEMPTED and FAILED"
  echo "  ImagePullBackOff - the kubelet is WAITING before the next attempt"
  echo "Same problem, two phases of the retry loop. The container never starts,"
  echo "so there are no logs to read (try it below)."
  shot screenshots/errimagepull-before.png kubectl -n $NS get pods -l issue=errimagepull -o wide
}

investigate() {
  local P; P=$(pod_of)
  hr "STEP 3 - INVESTIGATE: logs are empty, describe has the answer"
  run kubectl -n $NS logs "$P"
  echo
  echo "\$ kubectl -n $NS describe pod $P   (Containers + Events)"
  kubectl -n $NS describe pod "$P" | sed -n '/^    Image:/p;/^    State:/,/^      Reason:/p'
  kubectl -n $NS describe pod "$P" | sed -n '/^Events:/,$p'
  shot screenshots/errimagepull-events.png bash -c "kubectl -n $NS describe pod $P | sed -n '/^Events:/,\$p'"

  sub "the waiting reason and message straight from status (jsonpath)"
  kubectl -n $NS get pod "$P" -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}{"\n"}{.status.containerStatuses[0].state.waiting.message}{"\n"}' | fold -w 110

  hr "STEP 4 - INVESTIGATE: ask the registry directly, from outside Kubernetes"
  echo "A manifest HEAD request is what the kubelet does first. 200 = tag exists."
  for t in 1.27-alpne 1.27-alpine; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -I -H "$ACCEPT" "https://mirror.gcr.io/v2/library/nginx/manifests/$t")
    printf "  HEAD mirror.gcr.io/v2/library/nginx/manifests/%-12s -> %s\n" "$t" "$code"
  done
  echo
  echo "The repository is fine and reachable (no auth error, no timeout); only the"
  echo "tag is wrong. That narrows it to a typo, not networking or credentials."

  hr "STEP 5 - ROOT CAUSE"
  echo "The Deployment asks for nginx:1.27-alpne (typo). The registry answers"
  echo "404 / 'not found', the kubelet reports ErrImagePull, then backs off"
  echo "(ImagePullBackOff) and retries forever with growing delays."
}

fix() {
  hr "STEP 6 - FIX: correct the tag"
  echo "\$ kubectl diff -f fixed.yaml"
  kubectl diff -f fixed.yaml 2>&1 | grep -E '^[+-] +(image|- image):' | sed 's/^/  /'
  echo
  kubectl apply -f fixed.yaml
  kubectl -n $NS rollout status deployment/storefront --timeout=180s
}

verify() {
  local P
  hr "STEP 7 - VERIFY"
  sleep 3
  kubectl -n $NS get pods -l issue=errimagepull -o wide
  shot screenshots/errimagepull-after.png kubectl -n $NS get pods -l issue=errimagepull -o wide
  P=$(kubectl -n $NS get pods -l app=storefront --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
  echo
  echo "--- the pull events for the new pod ---"
  kubectl -n $NS get events --field-selector involvedObject.name="$P" \
    -o custom-columns=REASON:.reason,MESSAGE:.message --no-headers | grep -E 'Pull|Created|Started' | cut -c1-140
  echo
  echo "\$ kubectl -n $NS exec $P -- curl -s -o /dev/null -w '%{http_code}' http://localhost/"
  kubectl -n $NS exec "$P" -- curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost/
  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f fixed.yaml --ignore-not-found
  wait_gone $NS issue=errimagepull
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
