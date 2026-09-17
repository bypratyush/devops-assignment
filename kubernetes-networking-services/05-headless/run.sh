#!/usr/bin/env bash
# Headless Service (clusterIP: None) - DNS returns the POD IPs, not a VIP.
# Usage: ./run.sh [deploy|verify|cleanup]
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
SVC=web-service-headless
STS=web-stateful

deploy() {
  hr "STEP 1 - Deploy the headless service and a StatefulSet"
  kubectl apply -f service.yaml
  kubectl apply -f app-statefulset.yaml
  kubectl apply -f client-pod.yaml
  kubectl rollout status statefulset/$STS --timeout=180s
  kubectl wait --for=condition=Ready pod/headless-dns-client --timeout=120s
}

verify() {
  hr "STEP 2 - The service has NO ClusterIP"
  kubectl get svc $SVC
  echo
  echo ">>> CLUSTER-IP is 'None'. That is what 'headless' means."
  echo "    No virtual IP, no kube-proxy rules, no L4 load balancing."

  hr "STEP 3 - StatefulSet pods have STABLE, ORDERED names"
  kubectl get pods -l app=web-headless -o wide
  echo
  echo "Names are web-stateful-0, -1, -2 - an ordinal index, not a random hash."
  echo "A Deployment would give you names like web-app-66865d4855-xxnrh."
  echo "Delete web-stateful-1 and it comes back as web-stateful-1, every time."

  hr "STEP 4 - Endpoints still exist (unlike ExternalName)"
  kubectl get endpointslices -l kubernetes.io/service-name=$SVC
  echo
  kubectl get endpointslices -l kubernetes.io/service-name=$SVC \
    -o jsonpath='{range .items[*].endpoints[*]}  {.addresses[0]}  hostname={.hostname}  pod={.targetRef.name}{"\n"}{end}'

  hr "STEP 5 - THE KEY DIFFERENCE: DNS returns ALL pod IPs, not one VIP"
  echo "\$ nslookup $SVC.default.svc.cluster.local"
  # Query the FQDN so the resolver does not walk the search list and print
  # NXDOMAIN noise for the suffixes that do not match.
  kubectl exec headless-dns-client -- nslookup "$SVC.default.svc.cluster.local" 2>/dev/null \
    | grep -E 'Name:|Address: ' | sed 's/^/  /'
  echo
  echo "Three A records - one per pod. A normal ClusterIP service would return"
  echo "exactly ONE address (the virtual IP). The client now sees every backend"
  echo "and can choose for itself."

  hr "STEP 6 - Every pod gets its OWN stable DNS name"
  echo "Pattern:  <pod-name>.<service-name>.<namespace>.svc.cluster.local"
  echo
  for i in 0 1 2; do
    FQDN="$STS-$i.$SVC.default.svc.cluster.local"
    IP=$(kubectl exec headless-dns-client -- nslookup "$FQDN" 2>/dev/null | awk '/^Address: /{print $2; exit}')
    printf "  %-52s -> %s\n" "$STS-$i.$SVC" "${IP:-<no answer>}"
  done
  echo
  echo "This is what a Deployment CANNOT give you. It is the reason StatefulSets"
  echo "and headless services go together."

  hr "STEP 7 - Addressing a SPECIFIC pod by name"
  for i in 0 1 2; do
    kubectl exec headless-dns-client -- curl -s -o /dev/null \
      -w "  curl http://$STS-$i.$SVC:80  ->  HTTP %{http_code}\n" \
      --max-time 8 "http://$STS-$i.$SVC:80"
  done
  echo
  echo "Each request goes to that exact pod - no load balancing in between."

  hr "STEP 8 - Stable identity survives a pod deletion"
  IP_BEFORE=$(kubectl get pod $STS-1 -o jsonpath='{.status.podIP}')
  echo "before:  $STS-1  ip=$IP_BEFORE"
  echo "deleting $STS-1 ..."
  kubectl delete pod $STS-1 --wait=true >/dev/null
  kubectl wait --for=condition=Ready pod/$STS-1 --timeout=120s >/dev/null
  IP_AFTER=$(kubectl get pod $STS-1 -o jsonpath='{.status.podIP}')
  echo "after:   $STS-1  ip=$IP_AFTER"
  echo
  echo "The NAME came back identical ($STS-1) even though the IP changed."
  echo "Its DNS record follows it:"
  sleep 3
  kubectl exec headless-dns-client -- nslookup "$STS-1.$SVC.default.svc.cluster.local" 2>&1 | grep -E 'Name:|Address:' | tail -2 | sed 's/^/  /'
  echo
  echo "A peer that had written down '$STS-1' in its config still finds it."
  echo "That is why databases and Kafka use this: peers reference each other by"
  echo "STABLE NAME, and the cluster survives rescheduling."

  hr "STEP 9 - Ordered, one-at-a-time scaling"
  echo "\$ kubectl scale statefulset $STS --replicas=5"
  kubectl scale statefulset $STS --replicas=5 >/dev/null
  kubectl rollout status statefulset/$STS --timeout=180s
  kubectl get pods -l app=web-headless --no-headers | awk '{printf "  %-20s %s\n", $1, $3}'
  echo
  echo "Pods are created strictly in order 0,1,2,3,4 - each waits for the"
  echo "previous one to be Ready. Scaling DOWN reverses it: 4,3,2..."
  kubectl scale statefulset $STS --replicas=3 >/dev/null
  kubectl rollout status statefulset/$STS --timeout=180s >/dev/null
  echo "scaled back to 3"

  hr "STEP 10 - Headless vs ClusterIP, side by side"
  cat <<'TABLE'
                        ClusterIP                 Headless (clusterIP: None)
  Virtual IP            yes, one stable VIP       none
  DNS answer            the single VIP            every ready pod IP
  Load balancing        kube-proxy, L4            none - the client decides
  Per-pod DNS           no                        yes, with a StatefulSet
  kube-proxy rules      yes                       no
  Typical use           stateless web/API         databases, Kafka, Zookeeper,
                                                  Elasticsearch, any peer-aware
                                                  or leader-elected system
TABLE

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f client-pod.yaml --ignore-not-found
  kubectl delete -f app-statefulset.yaml --ignore-not-found
  kubectl delete -f service.yaml --ignore-not-found
}

case "${1:-all}" in
  deploy) deploy ;; verify) verify ;; cleanup) cleanup ;;
  all) deploy; verify ;;
  *) echo "usage: $0 [deploy|verify|cleanup]"; exit 1 ;;
esac
