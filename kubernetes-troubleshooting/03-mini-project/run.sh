#!/usr/bin/env bash
# Session 14 mini-project: Deploy -> Observe -> Break -> Investigate -> Root cause -> Fix -> Verify.
# Usage: ./run.sh [all|deploy|observe|broken-pod|service-challenge|checklist|cleanup]   (default: all)
#        SHOTS=1 ./run.sh   also captures screenshots/
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../lib.sh
NS=s14-mini
K="kubectl -n $NS"
ACCEPT='Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json'
apppod() { $K get pods -l app=troubleshooting-app -o jsonpath='{.items[0].metadata.name}'; }

deploy() {
  hr "1. DEPLOY THE APPLICATION"
  kubectl wait --for=delete namespace/$NS --timeout=120s >/dev/null 2>&1 || true
  kubectl apply -f namespace.yaml
  kubectl apply -f deployment.yaml -f service.yaml -f client-pod.yaml
  $K rollout status deployment/troubleshooting-app --timeout=180s
  $K wait --for=condition=Ready pod/curl-client --timeout=120s
  echo
  run $K get pods
  echo
  run $K get service
}

observe() {
  local P; P=$(apppod)
  hr "2. CHECK THE APPLICATION"
  run $K get pods -o wide
  echo
  echo "\$ $K describe pod $P   (trimmed)"
  $K describe pod "$P" | sed -n '/^Node:/p;/^Status:/p;/^IP:/p;/^    Image:/p;/^    State:/,/^    Restart Count:/p'
  $K describe pod "$P" | sed -n '/^Events:/,$p'
  echo
  run $K logs "$P" --tail=5

  sub "kubectl exec ... -- bash, then 'curl localhost' (as the instructions say)"
  echo "\$ $K exec $P -- bash -c 'curl -s localhost | grep -o \"<title>.*</title>\"'"
  $K exec "$P" -- bash -c 'curl -s localhost | grep -o "<title>.*</title>"' 2>&1
  echo
  echo "Interactively that is: $K exec -it $P -- bash   then   curl localhost"
  echo
  echo "Many production images have no shell and no curl (distroless). Then"
  echo "kubectl debug attaches an EPHEMERAL container that does - it shares the"
  echo "pod's network namespace, so 'localhost' is still this nginx:"
  echo "\$ $K debug $P --image=curlimages/curl:8.5.0 --container=dbg -- curl -s -o /dev/null -w 'HTTP %{http_code}' http://localhost"
  $K debug "$P" --image=curlimages/curl:8.5.0 --container=dbg -- curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost 2>&1
  for _ in $(seq 1 30); do
    T=$($K get pod "$P" -o jsonpath='{.status.ephemeralContainerStatuses[?(@.name=="dbg")].state.terminated.reason}')
    [ -n "$T" ] && break
    sleep 1
  done
  run $K logs "$P" -c dbg
  shot screenshots/exec-curl-localhost.png bash -c "$K exec $P -- bash -c 'curl -s localhost | head -4'; $K logs $P -c dbg"

  hr "3. CHECK THE SERVICE"
  run $K get service
  echo
  echo "\$ $K describe service troubleshooting-service"
  $K describe service troubleshooting-service | grep -E '^(Name|Selector|Type|IP|Port|TargetPort|Endpoints):'

  hr "4. CHECK ENDPOINTS"
  run $K get endpoints troubleshooting-service
  echo
  echo "(The Endpoints API is deprecated in favour of EndpointSlice - same data:)"
  run $K get endpointslices -l kubernetes.io/service-name=troubleshooting-service
  echo
  echo "--- and the Service really answers from another pod ---"
  echo "\$ $K exec curl-client -- curl -s -o /dev/null -w '%{http_code}' http://troubleshooting-service"
  echo "HTTP $(http_code_retry $NS curl-client http://troubleshooting-service)"
}

broken_pod() {
  hr "5. CREATE A BROKEN POD"
  kubectl apply -f broken-pod.yaml
  watch_for 35 $K get pod project-broken-pod -w
  shot screenshots/broken-pod-status.png $K get pod project-broken-pod -o wide

  hr "6. TROUBLESHOOT IT (no YAML changes yet)"
  run $K get pod project-broken-pod
  echo
  echo "\$ $K describe pod project-broken-pod"
  $K describe pod project-broken-pod | sed -n '/^    Image:/p;/^    State:/,/^      Reason:/p'
  $K describe pod project-broken-pod | sed -n '/^Events:/,$p'
  shot screenshots/broken-pod-events.png bash -c "$K describe pod project-broken-pod | sed -n '/^Events:/,\$p'"
  echo
  run $K logs project-broken-pod
  echo
  sub "confirm against the registry itself (manifest HEAD; 200 = tag exists)"
  echo "(asked via mirror.gcr.io, Google's mirror of the Docker Hub library"
  echo " images, because anonymous Docker Hub requests were being rate limited)"
  for t in this-tag-does-not-exist 1.27; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -I -H "$ACCEPT" "https://mirror.gcr.io/v2/library/nginx/manifests/$t")
    printf "  nginx:%-25s -> %s\n" "$t" "$code"
  done

  hr "6b. FIX THE BROKEN POD"
  echo "A pod's container IMAGE is one of the few fields you may change on a"
  echo "running pod, so the quickest fix needs no delete/recreate:"
  echo
  run $K set image pod/project-broken-pod app=nginx:1.27
  $K wait --for=condition=Ready pod/project-broken-pod --timeout=180s
  echo
  echo "The declarative fix, kept in git, matches what is now live:"
  run kubectl apply -f fixed-pod.yaml
  echo
  run $K get pod project-broken-pod -o wide
  echo
  echo "\$ $K get pod project-broken-pod -o jsonpath='{.status.containerStatuses[0].restartCount}'"
  $K get pod project-broken-pod -o jsonpath='  restarts: {.status.containerStatuses[0].restartCount}{"\n"}'
  shot screenshots/broken-pod-fixed.png $K get pod project-broken-pod -o wide
}

service_challenge() {
  hr "8. SERVICE TROUBLESHOOTING CHALLENGE - break the selector"
  run kubectl apply -f service-broken.yaml
  echo
  run $K get service
  echo
  run $K get endpoints troubleshooting-service
  echo
  echo "\$ $K exec curl-client -- curl -sS -m 5 http://troubleshooting-service"
  $K exec curl-client -- curl -sS -m 5 -o /dev/null -w 'HTTP %{http_code}\n' http://troubleshooting-service 2>&1
  echo
  echo "--- DNS still works, so this is not a DNS problem ---"
  echo "\$ $K exec curl-client -- nslookup troubleshooting-service.$NS.svc.cluster.local"
  $K exec curl-client -- nslookup troubleshooting-service.$NS.svc.cluster.local 2>&1 | grep -E '^(Name|Address: )'

  hr "9. FIND THE ROOT CAUSE"
  run $K get pods --show-labels
  echo
  echo "\$ $K describe service troubleshooting-service"
  $K describe service troubleshooting-service | grep -E '^(Selector|Endpoints):'
  shot screenshots/service-selector-mismatch.png bash -c "$K get pods -l app=troubleshooting-app --show-labels; echo; $K describe service troubleshooting-service | grep -E '^(Selector|Endpoints):'"
  echo
  echo "Selector app=wrong-app vs pod label app=troubleshooting-app: zero matches,"
  echo "so zero endpoints, so kube-proxy rejects every connection to the ClusterIP."

  sub "fix: put the correct selector back"
  run kubectl apply -f service.yaml
  sleep 2
  echo
  run $K get endpoints troubleshooting-service
  echo
  echo "\$ $K exec curl-client -- curl -s -o /dev/null -w '%{http_code}' http://troubleshooting-service"
  echo "HTTP $(http_code_retry $NS curl-client http://troubleshooting-service)"
  shot screenshots/service-fixed.png bash -c "$K get endpoints troubleshooting-service; $K exec curl-client -- curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://troubleshooting-service"
}

checklist() {
  hr "10. FINAL CHECKLIST - kubectl get events for the whole exercise"
  echo "\$ $K get events --sort-by=.lastTimestamp | grep -E 'Warning|project-broken-pod' | tail -8"
  $K get events --sort-by=.lastTimestamp 2>&1 | grep -E 'LAST SEEN|Warning|project-broken-pod' | tail -8 | cut -c1-200
  echo
  run $K get all
  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete namespace $NS --ignore-not-found --wait=false
  kubectl wait --for=delete namespace/$NS --timeout=180s >/dev/null 2>&1 || true
}

case "${1:-all}" in
  all)               deploy; observe; broken_pod; service_challenge; checklist ;;
  deploy)            deploy ;;
  observe)           observe ;;
  broken-pod)        broken_pod ;;
  service-challenge) service_challenge ;;
  checklist)         checklist ;;
  cleanup)           cleanup ;;
  *) echo "usage: $0 [all|deploy|observe|broken-pod|service-challenge|checklist|cleanup]"; exit 1 ;;
esac
