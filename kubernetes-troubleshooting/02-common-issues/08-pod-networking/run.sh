#!/usr/bin/env bash
# Pod networking - a NetworkPolicy with the wrong port silently drops allowed traffic.
# Usage: ./run.sh [all|break|investigate|fix|verify|cleanup]   (default: all)
#        SHOTS=1 ./run.sh   also captures screenshots/
# (kindnet on this kind cluster enforces NetworkPolicy - checked before writing this.)
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lib.sh
NS=s14-issues

call() {   # call <client-pod> <url>
  echo "\$ kubectl -n $NS exec $1 -- curl -sS -m 4 $2"
  kubectl -n $NS exec "$1" -- curl -sS -m 4 -o /dev/null -w 'HTTP %{http_code} in %{time_total}s\n' "$2" 2>&1
}

break_it() {
  hr "STEP 1 - Deploy the broken manifests"
  ensure_ns $NS >/dev/null
  wait_gone $NS issue=netpol
  kubectl apply -f broken.yaml
  kubectl -n $NS rollout status deployment/ledger --timeout=120s
  kubectl -n $NS wait --for=condition=Ready pod/billing pod/intruder --timeout=120s >/dev/null

  hr "STEP 2 - IDENTIFY: billing, the ONE client that should work, cannot"
  run kubectl -n $NS get pods -l issue=netpol -o wide
  echo
  call billing http://ledger
  echo
  echo "Exit code 28 after the full 4s: a TIMEOUT. Nothing answered - not even"
  echo "a refusal. Refused = something said no; timeout = packets vanished."
  shot screenshots/netpol-before.png kubectl -n $NS exec billing -- curl -sS -m 4 http://ledger
}

investigate() {
  local L IP
  L=$(kubectl -n $NS get pods -l app=ledger -o jsonpath='{.items[0].metadata.name}')
  IP=$(kubectl -n $NS get pod "$L" -o jsonpath='{.status.podIP}')

  hr "STEP 3 - INVESTIGATE: rule out the app and the Service"
  echo "--- is the app itself up? (from inside its own pod) ---"
  echo "\$ kubectl -n $NS exec $L -- wget -qO- http://localhost:8080/"
  kubectl -n $NS exec "$L" -- wget -qO- http://localhost:8080/ 2>&1 | head -2
  echo
  echo "--- does the Service have endpoints? ---"
  run kubectl -n $NS get endpointslices -l kubernetes.io/service-name=ledger
  echo
  echo "--- bypass the Service: straight to the pod IP ---"
  call billing "http://$IP:8080"
  echo
  echo "App fine, endpoints fine, and the pod IP times out too. kube-proxy is"
  echo "not involved any more, so something on the path to the POD is dropping"
  echo "packets. In Kubernetes that means a NetworkPolicy."

  hr "STEP 4 - INVESTIGATE: which policies select the ledger pod?"
  run kubectl -n $NS get networkpolicy
  echo
  echo "\$ kubectl -n $NS describe networkpolicy ledger-allow-billing"
  kubectl -n $NS describe networkpolicy ledger-allow-billing | sed -n '/^Spec:/,$p'
  shot screenshots/netpol-describe.png bash -c "kubectl -n $NS get networkpolicy; kubectl -n $NS describe networkpolicy ledger-allow-billing | sed -n '/^Spec:/,\$p'"
  echo
  echo "billing matches 'From: PodSelector app=billing' - so why is it dropped?"
  echo "Compare the allowed port with the port the pod really receives on:"
  echo
  echo "\$ kubectl -n $NS get svc ledger -o jsonpath='port={.spec.ports[0].port} targetPort={.spec.ports[0].targetPort}'"
  kubectl -n $NS get svc ledger -o jsonpath='  port={.spec.ports[0].port} targetPort={.spec.ports[0].targetPort}{"\n"}'
  echo "\$ kubectl -n $NS get pod $L -o jsonpath='{.spec.containers[0].ports}'"
  kubectl -n $NS get pod "$L" -o jsonpath='  {.spec.containers[0].ports}{"\n"}'

  hr "STEP 5 - ROOT CAUSE"
  echo "The allow rule opens TCP 80, which is the SERVICE port. By the time the"
  echo "packet reaches the ledger pod, kube-proxy has DNAT-ed it to the pod's"
  echo "8080, and the policy is evaluated against 8080. Nothing allows 8080, the"
  echo "lockdown policy applies, and the packet is dropped without a reply."
}

fix() {
  hr "STEP 6 - FIX: allow the pod port (by name)"
  echo "\$ kubectl diff -f fixed.yaml"
  kubectl diff -f fixed.yaml 2>&1 | grep -E '^[+-] ' | grep -v generation | sed 's/^/  /'
  echo
  kubectl apply -f fixed.yaml
}

verify() {
  local L IP
  L=$(kubectl -n $NS get pods -l app=ledger -o jsonpath='{.items[0].metadata.name}')
  IP=$(kubectl -n $NS get pod "$L" -o jsonpath='{.status.podIP}')
  hr "STEP 7 - VERIFY: billing gets in, everybody else still does not"
  sleep 3
  echo "billing  -> ledger (first good answer): HTTP $(http_code_retry $NS billing http://ledger)"
  echo
  call billing http://ledger
  call billing "http://$IP:8080"
  echo
  call intruder http://ledger
  echo
  echo "billing now works through the Service and by pod IP, while intruder is"
  echo "still dropped: the policy is fixed, not removed."
  shot screenshots/netpol-after.png bash -c "kubectl -n $NS exec billing -- curl -sS -m 4 -o /dev/null -w 'billing  -> HTTP %{http_code}\n' http://ledger; kubectl -n $NS exec intruder -- curl -sS -m 4 -o /dev/null -w 'intruder -> HTTP %{http_code}\n' http://ledger"
  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f fixed.yaml --ignore-not-found
  wait_gone $NS issue=netpol
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
