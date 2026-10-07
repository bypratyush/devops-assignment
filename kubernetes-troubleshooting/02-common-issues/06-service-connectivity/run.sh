#!/usr/bin/env bash
# Service connectivity - selector mismatch (empty endpoints) and then a wrong targetPort.
# Usage: ./run.sh [all|break|investigate|fix|verify|cleanup]   (default: all)
#        SHOTS=1 ./run.sh   also captures screenshots/
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lib.sh
NS=s14-issues
FE="kubectl -n $NS exec shop-frontend --"

try_curl() {   # print curl's verdict and its exit code, the way an app log would
  echo "\$ kubectl -n $NS exec shop-frontend -- curl -sS -m 5 $1"
  $FE curl -sS -m 5 -o /dev/null -w 'HTTP %{http_code}\n' "$1" 2>&1
}

break_it() {
  hr "STEP 1 - Deploy the broken manifests"
  ensure_ns $NS >/dev/null
  wait_gone $NS issue=svc
  kubectl apply -f broken.yaml
  kubectl -n $NS rollout status deployment/catalog-api --timeout=120s
  kubectl -n $NS wait --for=condition=Ready pod/shop-frontend --timeout=120s

  hr "STEP 2 - IDENTIFY: the frontend cannot reach the catalog"
  kubectl -n $NS get pods -l issue=svc -o wide
  echo
  try_curl http://catalog
  echo
  echo "Every pod is Running and Ready, yet the call fails. So the problem is"
  echo "between the client and the pods: DNS, the Service, or the network."
  shot screenshots/svc-before.png $FE curl -sS -m 5 http://catalog
}

investigate() {
  hr "STEP 3 - INVESTIGATE layer 1: DNS? Service? Endpoints?"
  sub "DNS first - does the name resolve?"
  $FE nslookup catalog.$NS.svc.cluster.local 2>&1 | grep -E 'Name:|Address:' | tail -2
  echo "Yes - it resolves to the Service's ClusterIP. DNS is fine."

  sub "the Service and what it selects"
  run kubectl -n $NS get svc catalog -o wide
  echo
  run kubectl -n $NS get endpointslices -l kubernetes.io/service-name=catalog
  echo
  echo "\$ kubectl -n $NS describe svc catalog"
  kubectl -n $NS describe svc catalog | grep -E '^(Selector|TargetPort|Endpoints):'
  echo
  echo "ENDPOINTS is <unset> / empty: the Service matched ZERO pods."

  sub "compare the selector with the real pod labels"
  run kubectl -n $NS get pods -l issue=svc --show-labels
  echo
  echo "\$ kubectl -n $NS get pods -l app=catalog        (what the Service asks for)"
  kubectl -n $NS get pods -l app=catalog 2>&1
  echo "\$ kubectl -n $NS get pods -l app=catalog-api    (what the pods actually have)"
  kubectl -n $NS get pods -l app=catalog-api 2>&1
  shot screenshots/svc-selector-mismatch.png bash -c "kubectl -n $NS get svc catalog -o wide; echo; kubectl -n $NS get endpointslices -l kubernetes.io/service-name=catalog; echo; kubectl -n $NS get pods -l app=catalog-api --show-labels"

  hr "STEP 4 - FIX layer 1 and re-test (patch the selector only)"
  echo "\$ kubectl -n $NS patch svc catalog -p '{\"spec\":{\"selector\":{\"app\":\"catalog-api\"}}}'"
  kubectl -n $NS patch svc catalog -p '{"spec":{"selector":{"app":"catalog-api"}}}'
  sleep 3
  echo
  run kubectl -n $NS get endpointslices -l kubernetes.io/service-name=catalog
  echo
  try_curl http://catalog
  echo
  echo "Progress: the EndpointSlice now lists both pod IPs - but curl fails"
  echo "exactly as before (exit 7, refused in a few ms). The SYMPTOM did not"
  echo "change: with no endpoints kube-proxy rejects the connection itself, and"
  echo "now something at the pod end refuses it. Only the endpoints check could"
  echo "tell those two apart. Note the PORTS column of the EndpointSlice: 80."

  hr "STEP 5 - INVESTIGATE layer 2: which port does the app really use?"
  P=$(kubectl -n $NS get pods -l app=catalog-api -o jsonpath='{.items[0].metadata.name}')
  IP=$(kubectl -n $NS get pod "$P" -o jsonpath='{.status.podIP}')
  echo "\$ kubectl -n $NS get pod $P -o jsonpath='{.spec.containers[0].ports}'"
  kubectl -n $NS get pod "$P" -o jsonpath='{.spec.containers[0].ports}'; echo
  echo
  echo "\$ kubectl -n $NS exec $P -- netstat -tln"
  kubectl -n $NS exec "$P" -- netstat -tln 2>&1
  echo
  echo "Bypass the Service and hit the pod IP directly on both ports:"
  try_curl "http://$IP:80"
  try_curl "http://$IP:8080"
  shot screenshots/svc-targetport.png bash -c "kubectl -n $NS describe svc catalog | grep -E '^(Selector|TargetPort|Endpoints):'; kubectl -n $NS exec $P -- netstat -tln"

  hr "STEP 6 - ROOT CAUSE"
  echo "1. selector app=catalog did not match the pods (app=catalog-api), so the"
  echo "   EndpointSlice was empty and kube-proxy had nowhere to send traffic."
  echo "2. targetPort 80, but nginx-hello listens on 8080, so once endpoints"
  echo "   existed every connection was refused by the pod."
}

fix() {
  hr "STEP 7 - FIX: apply the corrected manifest"
  echo "\$ kubectl diff -f fixed.yaml"
  kubectl diff -f fixed.yaml 2>&1 | grep -E '^[+-] ' | grep -v generation | sed 's/^/  /'
  echo
  kubectl apply -f fixed.yaml
}

verify() {
  hr "STEP 8 - VERIFY"
  sleep 3
  run kubectl -n $NS get endpointslices -l kubernetes.io/service-name=catalog
  echo
  echo "\$ kubectl -n $NS describe svc catalog"
  kubectl -n $NS describe svc catalog | grep -E '^(Selector|TargetPort|Endpoints):'
  echo
  echo "first call after the change: HTTP $(http_code_retry $NS shop-frontend http://catalog)"
  echo
  echo "6 requests through the Service - which pod answered each one:"
  for i in 1 2 3 4 5 6; do
    $FE curl -s -m 5 http://catalog 2>/dev/null | awk -F': ' '/Server name/{print "  "$2}'
  done
  shot screenshots/svc-after.png $FE curl -sS -m 5 http://catalog
  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f fixed.yaml --ignore-not-found
  wait_gone $NS issue=svc
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
