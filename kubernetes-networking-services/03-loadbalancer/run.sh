#!/usr/bin/env bash
# LoadBalancer - an externally-reachable IP, allocated by an external controller.
# Usage: ./run.sh [deploy|verify|cleanup]
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
SVC=web-service-loadbalancer
DEP=web-app-loadbalancer

deploy() {
  hr "STEP 1 - Deploy the backend (3 replicas)"
  kubectl apply -f app-deployment.yaml
  kubectl rollout status deployment/$DEP --timeout=120s
  kubectl run lb-client --image=curlimages/curl:8.5.0 --restart=Never \
    --command -- sh -c "sleep 3600" 2>/dev/null || true
  kubectl wait --for=condition=Ready pod/lb-client --timeout=120s
}

verify() {
  hr "STEP 2 - First, WITHOUT a load balancer controller"
  echo "Removing the MetalLB address pool to show the default kind behaviour:"
  kubectl delete -f metallb-pool.yaml --ignore-not-found >/dev/null 2>&1
  kubectl delete -f service.yaml --ignore-not-found >/dev/null 2>&1
  kubectl apply -f service.yaml
  echo
  echo "waiting a few seconds..."
  kubectl wait --for=jsonpath='{.spec.type}'=LoadBalancer svc/$SVC --timeout=30s >/dev/null 2>&1
  for _ in 1 2 3 4 5 6; do
    kubectl get svc $SVC --no-headers 2>/dev/null | grep -q pending && break
    kubectl get svc $SVC --no-headers 2>/dev/null | awk '{print $4}' | grep -q '<none>' && break
    sleep 2
  done
  kubectl get svc $SVC
  echo
  echo ">>> EXTERNAL-IP is <pending>, and it will stay that way forever."
  echo
  echo "WHY: 'type: LoadBalancer' does not create a load balancer by itself."
  echo "     It just asks an EXTERNAL controller to provide one:"
  echo "       - on EKS/GKE/AKS the cloud controller manager provisions a real"
  echo "         cloud LB (an AWS NLB, a GCP forwarding rule, ...)"
  echo "       - on bare metal or kind there is no such controller, so nothing"
  echo "         ever answers the request"
  echo
  echo "--- the service's events say exactly this ---"
  kubectl describe svc $SVC | sed -n '/Events/,$p' | head -8

  hr "STEP 3 - Install the missing piece (MetalLB address pool)"
  echo "MetalLB is already installed in namespace metallb-system:"
  kubectl get pods -n metallb-system --no-headers | awk '{printf "  %-30s %s\n", $1, $3}'
  echo
  echo "Now giving it a pool of IPs to hand out, from kind's own Docker network:"
  kubectl apply -f metallb-pool.yaml
  echo
  kubectl get ipaddresspool -n metallb-system

  hr "STEP 4 - The EXTERNAL-IP is allocated"
  for _ in $(seq 1 30); do
    EXT=$(kubectl get svc $SVC -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    [ -n "$EXT" ] && break
    sleep 2
  done
  kubectl get svc $SVC
  EXTERNAL_IP=$(kubectl get svc $SVC -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  echo
  echo "EXTERNAL-IP = $EXTERNAL_IP   (allocated by MetalLB from 192.168.96.200-250)"

  hr "STEP 5 - A LoadBalancer is a SUPERSET of NodePort and ClusterIP"
  kubectl get svc $SVC -o jsonpath='  ClusterIP : {.spec.clusterIP}{"\n"}  NodePort  : {.spec.ports[0].nodePort}{"\n"}  ExternalIP: {.status.loadBalancer.ingress[0].ip}{"\n"}'
  echo
  echo "All three exist at once. Kubernetes layers them:"
  echo "  ClusterIP     <- always allocated"
  echo "  + NodePort    <- added automatically for LoadBalancer"
  echo "  + External IP <- added by the LB controller"

  hr "STEP 6 - Reaching the external IP FROM INSIDE the Docker network"
  # MetalLB in L2 mode needs a few seconds after allocation for a speaker to
  # start answering ARP for the new IP. Poll until it does, instead of firing
  # one request at it and reporting a misleading timeout.
  echo "waiting for MetalLB L2 advertisement to converge..."
  for i in $(seq 1 30); do
    CODE=$(kubectl exec lb-client -- curl -s -o /dev/null -w '%{http_code}' --max-time 3 "http://$EXTERNAL_IP" 2>/dev/null)
    if [ "$CODE" = "200" ]; then echo "  answered after ~${i}s"; break; fi
    sleep 1
  done
  echo
  kubectl exec lb-client -- curl -s -o /dev/null -w "  http://$EXTERNAL_IP  ->  HTTP %{http_code}\n" --max-time 8 "http://$EXTERNAL_IP"
  echo
  echo "--- the HTML it served ---"
  kubectl exec lb-client -- curl -s --max-time 8 "http://$EXTERNAL_IP" | head -6

  hr "STEP 7 - And from a kind NODE (also on the Docker network)"
  docker exec devops-hw-control-plane sh -c "curl -s -o /dev/null -w 'HTTP %{http_code}\n' --max-time 8 http://$EXTERNAL_IP" 2>/dev/null \
    | sed 's/^/  from control-plane node: /' \
    || echo "  (no curl inside the node image)"

  hr "STEP 8 - From macOS: NOT reachable, and that is a Docker Desktop limit"
  echo "Trying http://$EXTERNAL_IP from the host:"
  if curl -s --max-time 5 -o /dev/null "http://$EXTERNAL_IP" 2>/dev/null; then
    echo "  reachable"
  else
    echo "  TIMED OUT."
  fi
  echo
  echo "This is NOT a Kubernetes failure. Docker Desktop on macOS runs containers"
  echo "inside a Linux VM, and the 192.168.96.0/20 Docker network is not routed"
  echo "from the host. On Linux (where Docker runs natively) this same IP would"
  echo "be curl-able directly, and on a real cloud the EXTERNAL-IP would be a"
  echo "public address."
  echo
  echo "To reach it from macOS anyway:"
  echo "  kubectl port-forward svc/$SVC 9090:80"

  hr "STEP 9 - Load balancing across the 3 pods"
  MARKER="lbprobe-$$"
  for i in $(seq 1 30); do
    kubectl exec lb-client -- curl -s -o /dev/null --max-time 8 "http://$EXTERNAL_IP/?${MARKER}=$i"
  done
  echo "sent 30 requests to the EXTERNAL IP (tagged $MARKER)"
  echo
  TOTAL=0
  for p in $(kubectl get pods -l app=web-loadbalancer -o jsonpath='{.items[*].metadata.name}'); do
    N=$(kubectl logs "$p" 2>/dev/null | grep -c "$MARKER" || true)
    printf "  %-42s served %2s requests\n" "$p" "$N"
    TOTAL=$((TOTAL + N))
  done
  echo "  ------------------------------------------------------------"
  printf "  %-42s served %2s requests\n" "TOTAL" "$TOTAL"

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete pod lb-client --ignore-not-found
  kubectl delete -f service.yaml --ignore-not-found
  kubectl delete -f app-deployment.yaml --ignore-not-found
  echo "(MetalLB itself and the address pool are left in place for other tasks)"
}

case "${1:-all}" in
  deploy) deploy ;; verify) verify ;; cleanup) cleanup ;;
  all) deploy; verify ;;
  *) echo "usage: $0 [deploy|verify|cleanup]"; exit 1 ;;
esac
