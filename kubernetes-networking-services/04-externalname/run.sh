#!/usr/bin/env bash
# ExternalName - a Service that is just a DNS CNAME to something outside the cluster.
# Usage: ./run.sh [deploy|verify|cleanup]
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
SVC=external-database-service

deploy() {
  hr "STEP 1 - Deploy the ExternalName service and a test client"
  kubectl apply -f service.yaml
  kubectl apply -f client-pod.yaml
  kubectl wait --for=condition=Ready pod/dns-test-client --timeout=120s
}

verify() {
  hr "STEP 2 - What this Service does and does NOT have"
  kubectl get svc $SVC
  echo
  echo ">>> CLUSTER-IP is <none>.  EXTERNAL-IP is the DNS name."
  echo
  kubectl get svc $SVC -o yaml | grep -E '^\s+(type|externalName|clusterIP|selector):' | sed 's/^/  /'
  echo
  echo "Compare with every other service type:"
  echo "  no clusterIP   -> nothing to route to, no virtual IP allocated"
  echo "  no selector    -> it selects no pods at all"
  echo "  no ports       -> it does not proxy, so ports are meaningless"

  hr "STEP 3 - Therefore it has NO endpoints"
  kubectl get endpointslices -l kubernetes.io/service-name=$SVC 2>&1 | sed 's/^/  /'
  echo
  echo "An empty endpoint list is NORMAL here. For any other service type it"
  echo "would mean the selector is broken."

  hr "STEP 4 - What it actually is: a CNAME served by CoreDNS"
  echo "\$ nslookup $SVC.default.svc.cluster.local"
  kubectl exec dns-test-client -- nslookup $SVC.default.svc.cluster.local 2>&1 | sed 's/^/  /'
  echo
  echo "CoreDNS answers the in-cluster name with a CNAME pointing at the"
  echo "external hostname, and the resolver then follows it to the real A record."

  hr "STEP 5 - Using it, and the Host-header trap you WILL hit"
  echo "\$ curl http://$SVC/"
  kubectl exec dns-test-client -- curl -s -o /dev/null -w "  HTTP %{http_code}\n" --max-time 10 "http://$SVC/" 2>&1
  echo
  echo ">>> 403, not 200. The DNS worked perfectly - we really did reach the"
  echo "    external host. What failed is HTTP virtual hosting:"
  echo
  echo "    ExternalName rewrites DNS ONLY. curl still sends"
  echo "        Host: $SVC"
  echo "    because that is the name in the URL. The origin has no vhost by that"
  echo "    name, so it refuses the request."
  echo
  echo "Proof - same URL, correct Host header:"
  echo "\$ curl -H 'Host: example.com' http://$SVC/"
  kubectl exec dns-test-client -- curl -s -o /dev/null -w "  HTTP %{http_code}\n" -H "Host: example.com" --max-time 10 "http://$SVC/" 2>&1
  echo
  echo "--- what came back ---"
  kubectl exec dns-test-client -- curl -s -H "Host: example.com" --max-time 10 "http://$SVC/" 2>/dev/null | grep -iE '<title>|<h1>' | head -2 | sed 's/^/  /'
  echo
  echo "The pod addressed an internal Kubernetes name and the traffic went"
  echo "straight to the external host - it never passed through kube-proxy or"
  echo "any virtual IP. ExternalName is DNS, and nothing but DNS."

  hr "STEP 6 - Why this is useful: swap the backend without touching the app"
  echo "The application hardcodes 'external-database-service'. To repoint it from"
  echo "a managed dev database to a prod one, you edit only the Service:"
  echo
  echo "\$ kubectl patch svc $SVC -p '{\"spec\":{\"externalName\":\"iana.org\"}}'"
  kubectl patch svc $SVC -p '{"spec":{"externalName":"iana.org"}}' >/dev/null
  sleep 3
  kubectl get svc $SVC
  echo
  kubectl exec dns-test-client -- nslookup $SVC.default.svc.cluster.local 2>&1 | grep -iE 'canonical|name:' | head -3 | sed 's/^/  /'
  echo
  echo "Same in-cluster name, different external target, zero application changes."
  echo "Restoring the original target..."
  kubectl patch svc $SVC -p '{"spec":{"externalName":"example.com"}}' >/dev/null
  kubectl get svc $SVC --no-headers | sed 's/^/  /'

  hr "STEP 7 - The gotchas"
  echo "1. HTTPS/TLS: the external host serves a certificate for ITS name"
  echo "   (example.com), not for '$SVC'. Verification fails unless the client"
  echo "   sends the right SNI/Host. This is the #1 ExternalName surprise."
  kubectl exec dns-test-client -- curl -s -o /dev/null -w "   curl https://$SVC/ -> exit %{http_code}\n" --max-time 10 "https://$SVC/" 2>&1 | sed 's/^/  /' || true
  echo
  echo "2. No health checking, no load balancing, no retries - it is only DNS."
  echo "3. It cannot point at an IP address, only at a DNS NAME."
  echo "   (To front a fixed external IP, use a selector-less Service with a"
  echo "    manually-created EndpointSlice instead.)"
  echo "4. Some clients cache DNS forever, so a change may not be picked up."

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f client-pod.yaml --ignore-not-found
  kubectl delete -f service.yaml --ignore-not-found
}

case "${1:-all}" in
  deploy) deploy ;; verify) verify ;; cleanup) cleanup ;;
  all) deploy; verify ;;
  *) echo "usage: $0 [deploy|verify|cleanup]"; exit 1 ;;
esac
