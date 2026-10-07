#!/usr/bin/env bash
# ImagePullBackOff - an image the cluster is not allowed to pull.
# Usage: ./run.sh [all|break|investigate|fix|verify|cleanup]   (default: all)
#        SHOTS=1 ./run.sh   also captures screenshots/
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lib.sh
NS=s14-issues
pod_of() { kubectl -n $NS get pods -l app=orders-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null; }

break_it() {
  hr "STEP 1 - Deploy the broken manifest"
  ensure_ns $NS >/dev/null
  wait_gone $NS issue=imagepullbackoff
  kubectl apply -f broken.yaml

  hr "STEP 2 - IDENTIFY: watch it for 100 seconds - note the GAPS growing"
  watch_for 100 kubectl -n $NS get pods -l issue=imagepullbackoff -w
  echo
  echo "Each ErrImagePull line is one real pull attempt. The time between them"
  echo "grows (kubelet back-off doubles each time, capped at 5 minutes), which"
  echo "is why a fixed registry problem can take minutes to 'heal' on its own."
  shot screenshots/imagepullbackoff-before.png kubectl -n $NS get pods -l issue=imagepullbackoff -o wide
}

investigate() {
  local P; P=$(pod_of)
  hr "STEP 3 - INVESTIGATE: the Events, with retry counts"
  echo "\$ kubectl -n $NS describe pod $P"
  kubectl -n $NS describe pod "$P" | sed -n '/^Events:/,$p'
  shot screenshots/imagepullbackoff-events.png bash -c "kubectl -n $NS describe pod $P | sed -n '/^Events:/,\$p'"
  echo
  echo "The message is what separates the causes of an image pull failure:"
  echo "  'not found'                      -> wrong name or tag (see 02-errimagepull)"
  echo "  '401 Unauthorized' / '403' / 'denied' -> private repo, no or wrong credentials"
  echo "  '429 Too Many Requests'          -> registry rate limit (hit for real, see README)"
  echo "  'i/o timeout' / 'no such host'   -> node cannot reach or resolve the registry"
  echo "Here it is 403 Forbidden while fetching an ANONYMOUS token: no credentials"
  echo "were even offered."

  sub "is any pull secret configured? (pod spec, then the service account)"
  echo "\$ kubectl -n $NS get pod $P -o jsonpath='{.spec.imagePullSecrets}'"
  echo "  '$(kubectl -n $NS get pod "$P" -o jsonpath='{.spec.imagePullSecrets}')'"
  echo "\$ kubectl -n $NS get serviceaccount default -o jsonpath='{.imagePullSecrets}'"
  echo "  '$(kubectl -n $NS get serviceaccount default -o jsonpath='{.imagePullSecrets}')'"
  echo "Both empty - the kubelet pulls anonymously."

  sub "reproduce the registry's answer from the laptop"
  echo "\$ curl 'https://ghcr.io/token?scope=repository:devops-hw-private/orders-api:pull&service=ghcr.io'"
  curl -s -w '\n  HTTP %{http_code}\n' "https://ghcr.io/token?scope=repository:devops-hw-private/orders-api:pull&service=ghcr.io" | sed 's/^{/  {/'
  echo "Same 403 outside Kubernetes, so this is not a node or CNI problem."

  hr "STEP 4 - ROOT CAUSE"
  echo "The image reference points at a GHCR repository that is not public, and"
  echo "the pod has no imagePullSecret. Every attempt is refused, the kubelet"
  echo "backs off, and the pod sits in ImagePullBackOff forever."
}

fix() {
  hr "STEP 5 - FIX: use the image that is actually published"
  echo "\$ kubectl diff -f fixed.yaml"
  kubectl diff -f fixed.yaml 2>&1 | grep -E '^[+-] +(image|- image):' | sed 's/^/  /'
  echo
  kubectl apply -f fixed.yaml
  kubectl -n $NS rollout status deployment/orders-api --timeout=180s
  echo
  echo "(If the image really is private, the fix is credentials instead:"
  echo "   kubectl -n $NS create secret docker-registry ghcr-pull \\"
  echo "     --docker-server=ghcr.io --docker-username=<user> --docker-password=<PAT>"
  echo " and 'imagePullSecrets: [{name: ghcr-pull}]' in the pod spec.)"
}

verify() {
  local P
  hr "STEP 6 - VERIFY"
  sleep 3
  kubectl -n $NS get pods -l issue=imagepullbackoff -o wide
  shot screenshots/imagepullbackoff-after.png kubectl -n $NS get pods -l issue=imagepullbackoff -o wide
  P=$(kubectl -n $NS get pods -l app=orders-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
  echo
  kubectl -n $NS get events --field-selector involvedObject.name="$P" \
    -o custom-columns=REASON:.reason,MESSAGE:.message --no-headers | grep -E 'Pull|Started' | cut -c1-140
  echo
  echo "\$ kubectl -n $NS exec $P -- wget -qO- http://localhost:8080/"
  kubectl -n $NS exec "$P" -- wget -qO- http://localhost:8080/ 2>&1 | head -4
  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f fixed.yaml --ignore-not-found
  wait_gone $NS issue=imagepullbackoff
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
