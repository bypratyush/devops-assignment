#!/usr/bin/env bash
# Task 3 - FQDNs and Kubernetes Service DNS, tested from inside a pod.
# Usage: ./run.sh [deploy|verify|cleanup|all]   (default: all)
#        ./run.sh trace <name>...   show every query the pod's resolver sends
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr()  { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }
NS=s11-dns
OTHER=s11-dns-other
D() { kubectl -n "$NS" exec dns-client -c dig  -- "$@"; }   # dig / nslookup / host
C() { kubectl -n "$NS" exec dns-client -c curl -- "$@"; }   # curl
# Show every query the resolver really sends for NAME (search list + ndots applied).
trace() {
  D dig +search +showsearch +noall +question +comments "$1" 2>/dev/null \
    | awk '/status:/{s=$6; sub(/,/,"",s)} /^;[a-z0-9_]/{q=$1; sub(/^;/,"",q); printf "    %-62s %s\n", q, s}'
}

deploy() {
  hr "SETUP - namespaces $NS and $OTHER"
  kubectl apply -f dns-lab.yaml
  kubectl -n "$NS" rollout status deployment/backend --timeout=180s
  kubectl -n "$NS" rollout status statefulset/peer --timeout=180s
  kubectl -n "$OTHER" rollout status deployment/payments --timeout=180s
  kubectl -n "$NS" wait --for=condition=Ready pod/dns-client --timeout=240s
}

verify() {
  CIP=$(kubectl -n "$NS" get svc backend -o jsonpath='{.spec.clusterIP}')
  PIP=$(kubectl -n "$OTHER" get svc payments -o jsonpath='{.spec.clusterIP}')

  hr "1. The cluster domain and the DNS server every pod is given"
  echo "kubelet config (kube-system/kubelet-config):"
  kubectl -n kube-system get cm kubelet-config -o jsonpath='{.data.kubelet}' | grep -E -A1 '^clusterDNS' | sed 's/^/  /'
  kubectl -n kube-system get cm kubelet-config -o jsonpath='{.data.kubelet}' | grep -E '^clusterDomain' | sed 's/^/  /'
  echo
  kubectl -n kube-system get svc kube-dns
  echo
  echo "  Every FQDN in this cluster ends in .cluster.local, and every pod is told to"
  echo "  ask 10.96.0.10 - the ClusterIP of the kube-dns Service (CoreDNS pods behind it)."

  hr "2. Inside the pod: /etc/resolv.conf"
  D cat /etc/resolv.conf | sed 's/^/  /'
  echo
  echo "  search  : suffixes tried, in order, for names that are not 'qualified enough'"
  echo "  ndots:5 : a name with FEWER than 5 dots goes through the search list FIRST"

  hr "3. Service DNS: the same Service, five spellings"
  echo "  backend ClusterIP (from the API) = $CIP"
  echo
  for n in backend backend.$NS backend.$NS.svc backend.$NS.svc.cluster.local backend.$NS.svc.cluster.local. ; do
    printf "  %-40s -> %s\n" "$n" "$(D dig +search +short "$n" 2>/dev/null | tr '\n' ' ')"
  done
  echo
  echo "  All five reach the same A record. Pattern: <service>.<namespace>.svc.<cluster-domain>"

  hr "4. What the resolver ACTUALLY sends for each spelling (search list + ndots:5)"
  for n in backend backend.$NS backend.$NS.svc.cluster.local backend.$NS.svc.cluster.local. ; do
    sub "$n"
    trace "$n"
  done
  echo
  echo "  'backend' matched on the FIRST search suffix: one query."
  echo "  The full name WITHOUT the trailing dot has only 4 dots, so it is still treated"
  echo "  as relative: three NXDOMAIN round-trips before the absolute name is tried."
  echo "  WITH the trailing dot it is absolute: exactly one query."

  hr "5. The ndots cost for EXTERNAL names"
  sub "example.com   (1 dot < 5)"
  trace example.com
  sub "example.com.  (trailing dot)"
  trace example.com.
  echo
  echo "  Every external hostname an app calls costs 3 wasted queries to CoreDNS first."
  echo "  Fixes: a trailing dot in config, or dnsConfig.options ndots: \"2\" on the pod."

  hr "6. Namespace-based DNS: crossing namespaces"
  echo "  payments lives in namespace $OTHER (ClusterIP $PIP); the client is in $NS."
  echo
  for n in payments payments.$OTHER payments.$OTHER.svc.cluster.local backend.default.svc.cluster.local; do
    R=$(D dig +search +short "$n" 2>/dev/null | tr '\n' ' ')
    printf "  %-40s -> %s\n" "$n" "${R:-<NXDOMAIN - no answer>}"
  done
  sub "the search list explains it"
  trace payments
  echo
  echo "  The short name only ever expands inside the CLIENT's own namespace. Across"
  echo "  namespaces you need at least <service>.<namespace>."

  hr "7. Pod-to-Service communication (curl container, same pod)"
  for u in http://backend http://backend.$NS http://backend.$NS.svc.cluster.local http://$CIP http://payments http://payments.$OTHER; do
    OUT=$(C curl -s -o /dev/null -w '%{http_code} via %{remote_ip}' --max-time 5 "$u" 2>/dev/null); RC=$?
    [ "$RC" -ne 0 ] && OUT="$OUT(curl exit $RC)"
    printf "  %-45s -> HTTP %s\n" "$u" "$OUT"
  done
  echo
  echo "  'http://payments' fails at the DNS step (curl exit 6, HTTP 000): the name is"
  echo "  looked up as payments.$NS.svc.cluster.local, which does not exist."

  hr "8. Headless Service: one A record per pod, plus per-pod names"
  kubectl -n "$NS" get pods -l app=peer -o custom-columns=POD:.metadata.name,IP:.status.podIP --no-headers | sed 's/^/  /'
  echo
  printf "  %-40s -> %s\n" "peer.$NS.svc.cluster.local" "$(D dig +short peer.$NS.svc.cluster.local 2>/dev/null | sort | tr '\n' ' ')"
  for i in 0 1; do
    printf "  %-40s -> %s\n" "peer-$i.peer.$NS.svc.cluster.local" "$(D dig +short peer-$i.peer.$NS.svc.cluster.local 2>/dev/null)"
  done
  echo
  echo "  Pattern: <pod>.<headless-service>.<namespace>.svc.cluster.local"

  hr "9. SRV records: the PORT is in DNS too (named ports only)"
  echo "\$ dig +short SRV _http._tcp.backend.$NS.svc.cluster.local"
  D dig +short SRV "_http._tcp.backend.$NS.svc.cluster.local" | sed 's/^/  /'
  echo "\$ dig +short SRV _http._tcp.peer.$NS.svc.cluster.local"
  D dig +short SRV "_http._tcp.peer.$NS.svc.cluster.local" | sort | sed 's/^/  /'
  echo
  echo "  Format: priority weight PORT target. For the headless Service there is one"
  echo "  SRV per pod, pointing at its per-pod name."

  hr "10. Pod A records and reverse lookups"
  BIP=$(kubectl -n "$NS" get pods -l app=backend -o jsonpath='{.items[0].status.podIP}')
  BNAME=$(echo "$BIP" | tr . -).$NS.pod.cluster.local
  printf "  %-45s -> %s\n" "$BNAME" "$(D dig +short "$BNAME" 2>/dev/null)"
  printf "  %-45s -> %s\n" "dig -x $CIP (the ClusterIP)" "$(D dig +short -x "$CIP" 2>/dev/null)"
  printf "  %-45s -> %s\n" "dig -x $BIP (a backend pod)" "$(D dig +short -x "$BIP" 2>/dev/null | tr '\n' ' ')"
  echo
  echo "  <ip-with-dashes>.<namespace>.pod.cluster.local exists for every pod ('pods"
  echo "  insecure' in the Corefile answers it for any IP). Reverse lookups map the"
  echo "  ClusterIP back to the Service name, and a pod that backs a Service back to"
  echo "  <ip-with-dashes>.<service>.<namespace>.svc.cluster.local."

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete namespace "$NS" "$OTHER" --wait=true
}

case "${1:-all}" in
  trace)   shift; for n in "$@"; do echo "$n"; trace "$n"; done ;;   # ./run.sh trace <name>...
  deploy)  deploy ;;
  verify)  verify ;;
  cleanup) cleanup ;;
  all)     deploy; verify ;;
  *) echo "usage: $0 [deploy|verify|cleanup|all]"; exit 1 ;;
esac
