#!/usr/bin/env bash
# Task 4 - CoreDNS: what it is, its config, how a query is resolved, live query
# logging, and a real DNS failure (scoped to my own namespace) fixed step by step.
#
# The ONLY change made to shared cluster state is temporarily adding the 'log'
# plugin to the CoreDNS Corefile. The original is saved first, restored at the
# end, compared byte for byte, and also restored by a trap if the script dies.
#
# Usage: ./run.sh [deploy|verify|cleanup|all]   (default: all)
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr()  { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }
NS=s11-coredns
PROBE_NS=s11-coredns-probe
D()  { kubectl -n "$NS" exec dns-client -c dig  -- "$@"; }
C()  { kubectl -n "$NS" exec dns-client -c curl -- "$@"; }
PD() { kubectl -n "$PROBE_NS" exec dns-probe -- "$@"; }
KS() { kubectl -n kube-system "$@"; }

ORIG_FILE=$(mktemp)
LOG_ENABLED=0

corefile() { KS get configmap coredns -o jsonpath='{.data.Corefile}'; }
set_corefile() {   # $1 = file with the full Corefile text
  local patch
  patch=$(python3 -c 'import json,sys; print(json.dumps({"data":{"Corefile":open(sys.argv[1]).read()}}))' "$1")
  KS patch configmap coredns --type merge -p "$patch"
}
# Wait until every CoreDNS pod logs "Reloading complete" after time $1.
wait_reload() {
  local since="$1" want have
  want=$(KS get pods -l k8s-app=kube-dns --no-headers | wc -l | tr -d ' ')
  for i in $(seq 1 60); do
    have=0
    for p in $(KS get pods -l k8s-app=kube-dns -o name); do
      KS logs "$p" --since-time="$since" 2>/dev/null | grep -q 'Reloading complete' && have=$((have + 1))
    done
    if [ "$have" -ge "$want" ]; then echo "  all $want CoreDNS pods reloaded after ~$((i * 5))s"; return 0; fi
    sleep 5
  done
  echo "  WARNING: only $have/$want CoreDNS pods reported a reload"
}
restore_corefile() {
  if [ "$LOG_ENABLED" = 1 ]; then
    echo "  restoring the original Corefile..."
    set_corefile "$ORIG_FILE" >/dev/null
    LOG_ENABLED=0
  fi
}
trap 'restore_corefile; rm -f "$ORIG_FILE" "$ORIG_FILE.log"' EXIT
trap 'exit 130' INT TERM

deploy() {
  hr "SETUP - namespaces $NS and $PROBE_NS"
  kubectl apply -f lab.yaml
  kubectl -n "$NS" rollout status deployment/hello --timeout=180s
  kubectl -n "$NS" wait --for=condition=Ready pod/dns-client --timeout=240s
  kubectl -n "$PROBE_NS" wait --for=condition=Ready pod/dns-probe --timeout=240s
}

verify() {
  CLIENT_IP=$(kubectl -n "$NS" get pod dns-client -o jsonpath='{.status.podIP}')

  hr "1. What CoreDNS is, in this cluster"
  KS get deployment coredns -o wide
  echo
  KS get pods -l k8s-app=kube-dns -o wide
  echo
  echo "  image     : $(KS get deployment coredns -o jsonpath='{.spec.template.spec.containers[0].image}')"
  echo "  args      : $(KS get deployment coredns -o jsonpath='{.spec.template.spec.containers[0].args}')"
  echo "  dnsPolicy : $(KS get deployment coredns -o jsonpath='{.spec.template.spec.dnsPolicy}')   <- CoreDNS itself uses the NODE's resolver"
  echo
  KS get svc kube-dns -o wide
  echo
  KS get endpointslices -l kubernetes.io/service-name=kube-dns
  echo
  echo "  The Service is still called 'kube-dns' (the pre-CoreDNS name) so nothing that"
  echo "  points at it had to change. Its ClusterIP is the nameserver of every pod."

  hr "2. The configuration: the Corefile (kube-system/configmap coredns)"
  corefile | tee "$ORIG_FILE"
  echo
  echo "  saved a copy of the original ($(wc -c < "$ORIG_FILE" | tr -d ' ') bytes) - it gets restored after step 6"

  hr "3. Every pod is pointed at CoreDNS"
  echo "\$ kubectl exec dns-client -- cat /etc/resolv.conf"
  D cat /etc/resolv.conf | sed 's/^/  /'
  echo
  echo "  nameserver = $(KS get svc kube-dns -o jsonpath='{.spec.clusterIP}') = the kube-dns ClusterIP = kubelet --cluster-dns"
  echo
  for n in kubernetes.default.svc.cluster.local kube-dns.kube-system.svc.cluster.local hello.$NS.svc.cluster.local; do
    printf "  %-42s -> %s\n" "$n" "$(D dig +short "$n" 2>/dev/null)"
  done

  hr "4. Service discovery: CoreDNS learns about Services from the API, live"
  echo "CoreDNS's RBAC - it only ever lists and watches:"
  kubectl get clusterrole system:coredns -o jsonpath='{range .rules[*]}  {.apiGroups} {.resources} {.verbs}{"\n"}{end}'
  echo
  echo "\$ kubectl create service clusterip late-svc --tcp=80:80   (and query it immediately)"
  kubectl -n "$NS" create service clusterip late-svc --tcp=80:80 >/dev/null
  START=$(date +%s)
  for _ in $(seq 1 30); do
    R=$(D dig +short "late-svc.$NS.svc.cluster.local" 2>/dev/null)
    [ -n "$R" ] && break
    sleep 1
  done
  echo "  late-svc.$NS.svc.cluster.local -> $R   (resolvable within ~$(( $(date +%s) - START ))s, API ClusterIP $(kubectl -n "$NS" get svc late-svc -o jsonpath='{.spec.clusterIP}'))"
  kubectl -n "$NS" delete service late-svc >/dev/null
  sleep 2
  echo "\$ kubectl delete service late-svc"
  echo "  late-svc.$NS.svc.cluster.local -> status $(D dig "late-svc.$NS.svc.cluster.local" 2>/dev/null | awk '/status:/{s=$6; sub(/,/,"",s); print s}')"
  echo
  echo "  No restart, no zone file. The kubernetes plugin keeps an in-memory view of"
  echo "  Services/EndpointSlices from its watch and answers straight from it."

  hr "5. How a query is resolved, hop by hop"
  sub "a) cluster name: answered by CoreDNS itself (flag 'aa' = authoritative)"
  D dig "hello.$NS.svc.cluster.local" 2>/dev/null | grep -E 'status:|flags:|IN\s+A|SERVER:' | sed 's/^/  /'
  sub "b) 10.96.0.10 is a VIP: kube-proxy DNATs it to the CoreDNS pods (iptables on devops-hw-worker)"
  docker exec devops-hw-worker iptables-save -t nat 2>/dev/null | grep -E 'kube-system/kube-dns:dns( |")' | grep -E -- '-A (KUBE-SERVICES|KUBE-SVC-)|DNAT' | sed 's/^/  /'
  sub "c) ask one CoreDNS pod directly, bypassing the VIP"
  COREDNS_IP=$(KS get pods -l k8s-app=kube-dns -o jsonpath='{.items[0].status.podIP}')
  D dig +short "@$COREDNS_IP" "hello.$NS.svc.cluster.local" | sed "s/^/  @$COREDNS_IP -> /"
  sub "d) external name: not in cluster.local, so the forward plugin sends it upstream"
  D dig example.com. 2>/dev/null | grep -E 'status:|flags:|^example\.com\.' | sed 's/^/  /'
  echo "  (no 'aa' flag: CoreDNS is not authoritative, it relayed the answer)"
  echo
  echo "  upstream = /etc/resolv.conf of the CoreDNS pod = the node's resolv.conf (dnsPolicy Default):"
  docker exec devops-hw-control-plane grep -E '^(nameserver|options)' /etc/resolv.conf | sed 's/^/    /'
  echo "  192.168.65.254 is Docker Desktop's resolver, which forwards to macOS."
  sub "e) the search list belongs to the CLIENT, not to CoreDNS"
  echo "  dig hello          -> status $(D dig hello 2>/dev/null | awk '/status:/{s=$6; sub(/,/,"",s); print s}')   (dig does not apply 'search' unless told to)"
  echo "  dig +search hello  -> $(D dig +search +short hello 2>/dev/null)"
  echo "  nslookup hello     -> $(D nslookup hello 2>/dev/null | awk '/^Address: /{print $2}')   (system resolver applies 'search')"

  hr "6. Watching real queries: temporarily enabling the 'log' plugin"
  awk '{print} /^    errors$/{print "    log"}' "$ORIG_FILE" > "$ORIG_FILE.log"
  echo "Change (only this one line is added):"
  diff "$ORIG_FILE" "$ORIG_FILE.log" | sed 's/^/  /'
  T0=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  set_corefile "$ORIG_FILE.log"
  LOG_ENABLED=1
  echo "waiting for the reload plugin (checks every 30s) and the configmap volume sync..."
  wait_reload "$T0"
  sub "the client (pod IP $CLIENT_IP) makes three lookups"
  T1=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  sleep 1
  D nslookup hello >/dev/null 2>&1
  D nslookup example.com >/dev/null 2>&1
  D dig +short payments.does-not-exist.svc.cluster.local >/dev/null 2>&1
  sleep 2
  echo "  nslookup hello ; nslookup example.com ; dig payments.does-not-exist.svc.cluster.local"
  sub "what CoreDNS logged for that pod IP (both CoreDNS pods, merged)"
  for p in $(KS get pods -l k8s-app=kube-dns -o name); do
    KS logs "$p" --since-time="$T1" 2>/dev/null | grep "$CLIENT_IP:" | sed "s#^#${p#pod/} #"
  done | sed 's/^/  /'
  echo
  echo "  Each line: client ip:port - id \"TYPE CLASS NAME proto size do bufsize\" RCODE flags size duration"
  echo "  'hello'       -> one query, answered from the first search suffix (aa = authoritative)."
  echo "  'example.com' -> 3 NXDOMAINs from the search list first (ndots:5); the real name has"
  echo "                   no 'aa' and is much slower because it went upstream."
  echo "  The does-not-exist name is answered NXDOMAIN by CoreDNS itself, without going upstream."

  hr "7. Troubleshooting scenario 1 - DNS suddenly 'down' in one namespace"
  echo "Someone applies a namespace-wide 'lock it down' egress policy:"
  kubectl apply -f troubleshooting/broken-deny-egress.yaml
  TB=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  sleep 5
  sub "SYMPTOM: the app cannot reach its backend"
  OUT=$(C curl -s -o /dev/null -w '%{http_code}' --max-time 20 http://hello 2>/dev/null); echo "  curl http://hello -> HTTP $OUT (curl exit $?)"
  sub "STEP 1 - is it DNS? (nslookup from the pod)"
  D nslookup -timeout=2 -retry=1 hello 2>&1 | sed 's/^/  /'
  sub "STEP 2 - is CoreDNS itself healthy?"
  KS get pods -l k8s-app=kube-dns
  KS get endpointslices -l kubernetes.io/service-name=kube-dns
  sub "STEP 3 - does DNS work from ANOTHER namespace?"
  PD nslookup "hello.$NS.svc.cluster.local" 2>&1 | grep -E '^(Name|Address: )' | sed "s/^/  [$PROBE_NS] /"
  echo "  -> CoreDNS is fine; the problem is local to $NS."
  sub "STEP 4 - is the pod's resolver config right?"
  D cat /etc/resolv.conf | sed 's/^/  /'
  echo "  -> correct nameserver and search list."
  sub "STEP 5 - skip the VIP: ask a CoreDNS pod IP directly"
  D dig +time=2 +tries=1 "@$COREDNS_IP" "hello.$NS.svc.cluster.local" 2>&1 | grep -E 'timed out|status:' | sed 's/^/  /'
  echo "  -> even the pod IP times out, so it is not kube-proxy. Packets are dropped."
  sub "STEP 6 - did the queries even arrive? CoreDNS log for $CLIENT_IP during this test"
  N=0
  for p in $(KS get pods -l k8s-app=kube-dns -o name); do
    c=$(KS logs "$p" --since-time="$TB" 2>/dev/null | grep -c "$CLIENT_IP:")
    N=$((N + c))
  done
  echo "  log lines from $CLIENT_IP since the policy was applied: $N   -> nothing reached CoreDNS"
  sub "STEP 7 - what filters traffic in this namespace?"
  kubectl -n "$NS" get networkpolicy
  echo
  kubectl -n "$NS" describe networkpolicy default-deny-egress | sed -n '/Spec:/,$p' | sed 's/^/  /'
  echo
  echo "ROOT CAUSE: default-deny-egress selects every pod and allows no egress. DNS to"
  echo "kube-system on port 53 is egress too, so every lookup is dropped at the pod."
  sub "FIX 1 - allow DNS to the CoreDNS pods"
  kubectl apply -f troubleshooting/fix-allow-dns.yaml
  sleep 5
  D nslookup -timeout=2 -retry=1 hello 2>&1 | grep -E '^(Name|Address: )' | sed 's/^/  /'
  OUT=$(C curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://hello 2>/dev/null); echo "  curl http://hello -> HTTP $OUT (curl exit $?)"
  echo "  -> DNS works now, but curl still fails (exit 28 = timeout): the deny also"
  echo "     blocks the client -> hello traffic itself."
  sub "FIX 2 - allow the client to reach the app"
  kubectl apply -f troubleshooting/fix-allow-app.yaml
  sleep 5
  C curl -s -o /dev/null -w 'HTTP %{http_code} via %{remote_ip}\n' --max-time 10 http://hello 2>&1 | sed 's/^/  curl http:\/\/hello -> /'
  kubectl -n "$NS" get networkpolicy

  hr "8. Troubleshooting scenario 2 - one pod with a hand-written resolver config"
  kubectl apply -f troubleshooting/broken-nameserver-pod.yaml
  kubectl -n "$NS" wait --for=condition=Ready pod/custom-dns --timeout=120s >/dev/null
  sub "SYMPTOM"
  kubectl -n "$NS" exec custom-dns -- nslookup -timeout=2 -retry=1 hello 2>&1 | sed 's/^/  /'
  sub "INVESTIGATE: resolv.conf vs the kube-dns Service"
  kubectl -n "$NS" exec custom-dns -- cat /etc/resolv.conf | sed 's/^/  /'
  echo "  kube-dns ClusterIP: $(KS get svc kube-dns -o jsonpath='{.spec.clusterIP}')"
  echo "  pod dnsPolicy     : $(kubectl -n "$NS" get pod custom-dns -o jsonpath='{.spec.dnsPolicy}')"
  echo
  echo "ROOT CAUSE: dnsPolicy None + a typo'd nameserver (10.96.0.100). Nothing listens"
  echo "there. (The NetworkPolicies from scenario 1 still apply to this pod and would"
  echo "allow DNS to CoreDNS - the address is simply wrong.)"
  sub "FIX: ClusterFirst + only the option that was wanted (dnsPolicy is immutable, so recreate)"
  kubectl -n "$NS" delete pod custom-dns --wait=true
  kubectl apply -f troubleshooting/fixed-nameserver-pod.yaml
  kubectl -n "$NS" wait --for=condition=Ready pod/custom-dns --timeout=120s >/dev/null
  kubectl -n "$NS" exec custom-dns -- cat /etc/resolv.conf | sed 's/^/  /'
  kubectl -n "$NS" exec custom-dns -- nslookup hello 2>&1 | grep -E '^(Name|Address: )' | sed 's/^/  /'

  hr "9. CoreDNS metrics (prometheus plugin, :9153) - the numbers behind the logs"
  echo "  (read through the API server's pod proxy, so no NetworkPolicy is involved)"
  for p in $(KS get pods -l k8s-app=kube-dns -o jsonpath='{.items[*].metadata.name}'); do
    echo "  $p:"
    kubectl get --raw "/api/v1/namespaces/kube-system/pods/$p:9153/proxy/metrics" 2>/dev/null \
      | grep -E '^coredns_dns_responses_total' | grep -E 'rcode="(NOERROR|NXDOMAIN|SERVFAIL)"' | sed 's/^/    /'
  done
  echo
  echo "  A rising SERVFAIL count points at upstream/forwarding trouble; a high NXDOMAIN"
  echo "  share is usually just ndots:5 search-list noise, as seen in step 6."

  hr "10. Restore the original Corefile and prove it is identical"
  T2=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  restore_corefile
  wait_reload "$T2"
  if corefile | diff -q - "$ORIG_FILE" >/dev/null; then
    echo "  Corefile now identical to the saved original - 'log' removed."
  else
    echo "  WARNING: Corefile differs from the original:"; corefile | diff - "$ORIG_FILE"
  fi
  PD nslookup kubernetes.default.svc.cluster.local 2>&1 | grep -E '^(Name|Address: )' | sed "s/^/  [$PROBE_NS] /"

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete namespace "$NS" "$PROBE_NS" --wait=true
}

case "${1:-all}" in
  deploy)  deploy ;;
  verify)  verify ;;
  cleanup) cleanup ;;
  all)     deploy; verify ;;
  *) echo "usage: $0 [deploy|verify|cleanup|all]"; exit 1 ;;
esac
