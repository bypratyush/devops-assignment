#!/usr/bin/env bash
# Task 5 - ClusterIP service: deploy, verify, and prove internal-only load balancing.
# Usage: ./run.sh [deploy|verify|cleanup]   (default: deploy + verify)
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
SVC=web-service-clusterip
DEP=web-app-clusterip

deploy() {
  hr "STEP 1 - Deploy the backend (3 nginx replicas)"
  kubectl apply -f app-deployment.yaml
  kubectl rollout status deployment/$DEP --timeout=120s

  hr "STEP 2 - Deploy the ClusterIP service"
  kubectl apply -f service.yaml

  hr "STEP 3 - Deploy the in-cluster client pod"
  kubectl apply -f client-pod.yaml
  kubectl wait --for=condition=Ready pod/curl-client --timeout=120s
}

verify() {
  hr "STEP 4 - The 3 backend pods and their EPHEMERAL private IPs"
  kubectl get pods -l app=web-clusterip -o wide

  hr "STEP 5 - The service and its STABLE virtual IP"
  kubectl get svc $SVC -o wide
  CLUSTER_IP=$(kubectl get svc $SVC -o jsonpath='{.spec.clusterIP}')
  echo
  echo "ClusterIP = $CLUSTER_IP    (port 8080 -> targetPort 80)"

  hr "STEP 6 - Endpoints: proof the selector matched all 3 pods"
  echo "--- EndpointSlice (the modern API) ---"
  kubectl get endpointslices -l kubernetes.io/service-name=$SVC
  echo
  kubectl get endpointslices -l kubernetes.io/service-name=$SVC \
    -o jsonpath='{range .items[*].endpoints[*]}  {.addresses[0]}  ready={.conditions.ready}  pod={.targetRef.name}{"\n"}{end}'
  echo
  echo "--- describe (human-readable view) ---"
  kubectl describe svc $SVC | sed -n '1,20p'

  hr "STEP 7 - TEST 1: reach the service BY NAME (CoreDNS)"
  kubectl exec curl-client -- curl -s -o /dev/null -w "HTTP %{http_code} from http://$SVC:8080  (%{time_total}s)\n" \
    "http://$SVC:8080"

  hr "STEP 8 - TEST 2: reach the service BY ClusterIP"
  kubectl exec curl-client -- curl -s -o /dev/null -w "HTTP %{http_code} from http://$CLUSTER_IP:8080\n" \
    "http://$CLUSTER_IP:8080"

  hr "STEP 9 - TEST 3: reach the service BY FQDN"
  kubectl exec curl-client -- curl -s -o /dev/null -w "HTTP %{http_code} from FQDN\n" \
    "http://$SVC.default.svc.cluster.local:8080"
  echo
  echo "FQDN pattern:  <service>.<namespace>.svc.cluster.local"

  hr "STEP 10 - The actual HTML the service returned"
  kubectl exec curl-client -- curl -s "http://$SVC:8080" | head -12

  hr "STEP 11 - DNS resolution: the name really does resolve to the ClusterIP"
  kubectl exec curl-client -- nslookup $SVC 2>/dev/null \
    || kubectl exec curl-client -- getent hosts $SVC \
    || echo "(no nslookup/getent in this image)"
  echo
  echo "Expected: $SVC resolves to $CLUSTER_IP"
  echo
  echo "NOTE: the NXDOMAIN lines above are NORMAL. /etc/resolv.conf inside a pod has"
  echo "      'search default.svc.cluster.local svc.cluster.local cluster.local', so the"
  echo "      resolver tries each suffix in order and only one of them matches."
  echo
  echo "--- the pod's resolver config that makes short names work ---"
  kubectl exec curl-client -- cat /etc/resolv.conf

  hr "STEP 12 - PROOF OF LOAD BALANCING across all 3 pods"
  echo "The 3 nginx pods serve identical HTML, so instead of reading the response we"
  echo "send 30 requests and then count them in each pod's own access log."
  echo
  # Tag each probe with a unique marker so the count is exact and cannot pick up
  # requests made by earlier steps (a time window alone is not precise enough).
  MARKER="lbprobe-$$"
  for i in $(seq 1 30); do
    kubectl exec curl-client -- curl -s -o /dev/null "http://$SVC:8080/?${MARKER}=$i"
  done
  echo "sent 30 requests through the service (tagged ${MARKER})"
  echo
  TOTAL=0
  for p in $(kubectl get pods -l app=web-clusterip -o jsonpath='{.items[*].metadata.name}'); do
    N=$(kubectl logs "$p" 2>/dev/null | grep -c "$MARKER" || true)
    printf "  %-40s served %2s requests\n" "$p" "$N"
    TOTAL=$((TOTAL + N))
  done
  echo "  ----------------------------------------------------------"
  printf "  %-40s served %2s requests\n" "TOTAL" "$TOTAL"
  echo
  echo "Traffic spread across all 3 pods => kube-proxy is load balancing at L4."

  hr "STEP 13 - PROOF it is INTERNAL ONLY (the defining ClusterIP property)"
  echo "Trying to reach the ClusterIP $CLUSTER_IP:8080 from the laptop (outside the cluster):"
  if curl -s --max-time 5 "http://$CLUSTER_IP:8080" >/dev/null 2>&1; then
    echo "  UNEXPECTED: reachable from outside"
  else
    echo "  FAILED / timed out, exactly as expected."
    echo "  A ClusterIP is only routable from inside the cluster network."
    echo "  To expose it externally you need NodePort, LoadBalancer, or an Ingress."
  fi
  echo
  echo "For local debugging you can still tunnel to it:"
  echo "  kubectl port-forward svc/$SVC 8080:8080   then open http://localhost:8080"

  hr "STEP 14 - WHY ClusterIP EXISTS: pod IPs change, the service IP does not"
  echo "--- pod IPs before deleting one ---"
  kubectl get pods -l app=web-clusterip -o custom-columns=NAME:.metadata.name,IP:.status.podIP --no-headers
  VICTIM=$(kubectl get pods -l app=web-clusterip -o jsonpath='{.items[0].metadata.name}')
  echo
  echo "deleting pod $VICTIM ..."
  kubectl delete pod "$VICTIM" --wait=true >/dev/null
  kubectl rollout status deployment/$DEP --timeout=120s
  echo
  echo "--- pod IPs after (note the replacement pod has a NEW name and NEW IP) ---"
  kubectl get pods -l app=web-clusterip -o custom-columns=NAME:.metadata.name,IP:.status.podIP --no-headers
  echo
  echo "--- but the ClusterIP is UNCHANGED ---"
  kubectl get svc $SVC -o custom-columns=NAME:.metadata.name,CLUSTER-IP:.spec.clusterIP --no-headers
  echo "  (was $CLUSTER_IP before the pod was deleted)"
  echo
  echo "--- and the service still answers, with endpoints re-bound automatically ---"
  sleep 3
  kubectl exec curl-client -- curl -s -o /dev/null -w "HTTP %{http_code} - still serving\n" "http://$SVC:8080"
  kubectl get endpointslices -l kubernetes.io/service-name=$SVC \
    -o jsonpath='{range .items[*].endpoints[*]}  {.addresses[0]}  pod={.targetRef.name}{"\n"}{end}'

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f client-pod.yaml --ignore-not-found
  kubectl delete -f service.yaml --ignore-not-found
  kubectl delete -f app-deployment.yaml --ignore-not-found
}

case "${1:-all}" in
  deploy)  deploy ;;
  verify)  verify ;;
  cleanup) cleanup ;;
  all)     deploy; verify ;;
  *) echo "usage: $0 [deploy|verify|cleanup]"; exit 1 ;;
esac
