#!/usr/bin/env bash
# NodePort - expose a service on a fixed port of EVERY node.
# Usage: ./run.sh [deploy|verify|cleanup]
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
SVC=web-service-nodeport
DEP=web-app-nodeport
NODEPORT=30080

deploy() {
  hr "STEP 1 - Deploy the backend (2 replicas)"
  kubectl apply -f app-deployment.yaml
  kubectl rollout status deployment/$DEP --timeout=120s

  hr "STEP 2 - Deploy the NodePort service"
  kubectl apply -f service.yaml
  # a client inside the cluster, to contrast internal vs external access
  kubectl run np-client --image=curlimages/curl:8.5.0 --restart=Never \
    --command -- sh -c "sleep 3600" 2>/dev/null || true
  kubectl wait --for=condition=Ready pod/np-client --timeout=120s
  # A freshly created NodePort is not answering yet: kube-proxy on each node has
  # to see the Service + EndpointSlice and write its rules first. Without this
  # poll, a run on 2026-10-07 got HTTP 000 from every node (see README notes).
  echo
  echo "waiting for kube-proxy to program the NodePort rules..."
  for i in $(seq 1 60); do
    CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "http://localhost:$NODEPORT" 2>/dev/null)
    if [ "$CODE" = "200" ]; then echo "  localhost:$NODEPORT answered after ~${i}s"; break; fi
    sleep 1
  done
}

verify() {
  hr "STEP 3 - The service: note it has THREE ports"
  kubectl get svc $SVC -o wide
  CLUSTER_IP=$(kubectl get svc $SVC -o jsonpath='{.spec.clusterIP}')
  echo
  echo "  nodePort   30080  <- port opened on EVERY node, reachable from OUTSIDE"
  echo "  port       80     <- the ClusterIP port, for in-cluster clients"
  echo "  targetPort 80     <- the container port"
  echo
  echo "A NodePort service is a SUPERSET of ClusterIP - it still got one:"
  echo "  ClusterIP = $CLUSTER_IP"

  hr "STEP 4 - Where the pods actually are"
  kubectl get pods -l app=web-nodeport -o wide
  echo
  echo "2 replicas across 3 nodes - so at least one node has NO pod."
  echo "That node will still answer on port 30080. That is the whole point."

  hr "STEP 5 - EVERY node listens on $NODEPORT, pod or no pod"
  echo "Querying each node's internal IP from a pod inside the cluster:"
  echo
  for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    IP=$(kubectl get node "$node" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
    PODS=$(kubectl get pods -l app=web-nodeport --field-selector spec.nodeName=$node --no-headers 2>/dev/null | wc -l | tr -d ' ')
    CODE=$(kubectl exec np-client -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$IP:$NODEPORT" 2>/dev/null)
    printf "  %-26s %-15s pods_on_node=%s   HTTP %s\n" "$node" "$IP" "$PODS" "$CODE"
  done
  echo
  echo "All nodes return 200. kube-proxy programmed the same rule on each one;"
  echo "a node with no local pod just forwards the packet to a node that has one."

  hr "STEP 6 - Reaching it from OUTSIDE the cluster (the actual point)"
  echo "This kind cluster maps hostPort 30080 -> control-plane containerPort 30080"
  echo "(see lab/kind-config.yaml), so macOS can reach the NodePort directly:"
  echo
  curl -s -o /dev/null -w "  curl http://localhost:30080  ->  HTTP %{http_code}\n" --max-time 5 http://localhost:$NODEPORT
  echo
  echo "--- the HTML it served ---"
  curl -s --max-time 5 http://localhost:$NODEPORT | head -8
  echo
  echo "Contrast with Task 01: a ClusterIP was UNREACHABLE from here."

  hr "STEP 7 - Load balancing across the 2 pods"
  MARKER="npprobe-$$"
  for i in $(seq 1 20); do
    curl -s -o /dev/null --max-time 5 "http://localhost:$NODEPORT/?${MARKER}=$i"
  done
  echo "sent 20 requests to localhost:$NODEPORT (tagged $MARKER)"
  echo
  TOTAL=0
  for p in $(kubectl get pods -l app=web-nodeport -o jsonpath='{.items[*].metadata.name}'); do
    N=$(kubectl logs "$p" 2>/dev/null | grep -c "$MARKER" || true)
    printf "  %-38s served %2s requests\n" "$p" "$N"
    TOTAL=$((TOTAL + N))
  done
  echo "  --------------------------------------------------------"
  printf "  %-38s served %2s requests\n" "TOTAL" "$TOTAL"

  hr "STEP 8 - The port range is enforced: 30000-32767"
  echo "Trying to create a NodePort service on port 80:"
  cat <<'YAML' > /tmp/bad-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: bad-nodeport
spec:
  type: NodePort
  selector:
    app: web-nodeport
  ports:
    - port: 80
      targetPort: 80
      nodePort: 80
YAML
  kubectl apply -f /tmp/bad-nodeport.yaml 2>&1 | sed 's/^/  /'
  rm -f /tmp/bad-nodeport.yaml
  echo
  echo "The range is set by the API server's --service-node-port-range."
  echo "Omit nodePort entirely and Kubernetes allocates a free one for you."

  hr "STEP 9 - Internal clients can still use the ClusterIP port"
  kubectl exec np-client -- curl -s -o /dev/null -w "  http://$SVC:80 (in-cluster) -> HTTP %{http_code}\n" "http://$SVC:80"
  echo
  echo "In-cluster traffic should use the service NAME on port 80, not the NodePort."

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete pod np-client --ignore-not-found
  kubectl delete -f service.yaml --ignore-not-found
  kubectl delete -f app-deployment.yaml --ignore-not-found
}

case "${1:-all}" in
  deploy) deploy ;; verify) verify ;; cleanup) cleanup ;;
  all) deploy; verify ;;
  *) echo "usage: $0 [deploy|verify|cleanup]"; exit 1 ;;
esac
