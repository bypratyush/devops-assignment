#!/usr/bin/env bash
# DNS issues - a cross-namespace short name (NXDOMAIN) and a pod pointed at the wrong DNS server.
# Usage: ./run.sh [all|break|investigate|fix|verify|cleanup]   (default: all)
#        SHOTS=1 ./run.sh   also captures screenshots/
# Only pods in s14-issues are affected; cluster DNS keeps working for everyone.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lib.sh
NS=s14-issues

break_it() {
  hr "STEP 1 - Deploy the broken manifests"
  ensure_ns $NS >/dev/null
  wait_gone $NS issue=dns
  kubectl wait --for=delete namespace/s14-shop --timeout=120s >/dev/null 2>&1 || true
  kubectl apply -f broken.yaml
  kubectl -n s14-shop rollout status deployment/payments --timeout=120s
  kubectl -n $NS rollout status deployment/checkout --timeout=120s
  kubectl -n $NS rollout status deployment/report-mailer --timeout=120s

  hr "STEP 2 - IDENTIFY: both apps log failed calls to payments"
  sleep 15
  run kubectl -n $NS get pods -l issue=dns
  echo
  run kubectl -n $NS logs deploy/checkout --tail=2
  echo
  run kubectl -n $NS logs deploy/report-mailer --tail=2
  shot screenshots/dns-before.png bash -c "kubectl -n $NS logs deploy/checkout --tail=2; kubectl -n $NS logs deploy/report-mailer --tail=2"
  echo
  echo "Both say 'Could not resolve host' (curl exit 6) - but report-mailer is"
  echo "already using the FULL name, so the two are probably not the same bug."
}

investigate() {
  hr "STEP 3 - INVESTIGATE: is cluster DNS itself healthy? (read-only checks)"
  run kubectl -n kube-system get pods -l k8s-app=kube-dns -o wide
  echo
  run kubectl -n kube-system get svc kube-dns
  echo
  echo "\$ kubectl -n $NS exec deploy/checkout -- nslookup kubernetes.default"
  kubectl -n $NS exec deploy/checkout -- nslookup kubernetes.default 2>&1 | grep -E '^(Server|Name|Address)'
  echo
  echo "CoreDNS is up and answers from the checkout pod. So DNS works - the"
  echo "NAME 'payments' is the problem for checkout."

  hr "STEP 4 - INVESTIGATE checkout: why does 'payments' not resolve?"
  run kubectl -n $NS exec deploy/checkout -- cat /etc/resolv.conf
  echo
  echo "\$ kubectl -n $NS exec deploy/checkout -- nslookup payments"
  kubectl -n $NS exec deploy/checkout -- nslookup payments 2>&1 | grep -v '^$'
  echo
  echo "The resolver tried payments.s14-issues.svc.cluster.local, payments.svc..."
  echo "and payments.cluster.local - all NXDOMAIN. Where does payments live?"
  echo
  run kubectl get svc -A --field-selector metadata.name=payments
  echo
  echo "\$ kubectl -n $NS exec deploy/checkout -- nslookup payments.s14-shop.svc.cluster.local"
  kubectl -n $NS exec deploy/checkout -- nslookup payments.s14-shop.svc.cluster.local 2>&1 | grep -E '^(Name|Address)'
  echo "With the namespace in the name it resolves from the very same pod."
  shot screenshots/dns-nxdomain.png bash -c "kubectl get svc -A --field-selector metadata.name=payments; kubectl -n $NS exec deploy/checkout -- nslookup payments; kubectl -n $NS exec deploy/checkout -- nslookup payments.s14-shop.svc.cluster.local"

  hr "STEP 5 - INVESTIGATE report-mailer: even names that always exist fail"
  echo "\$ kubectl -n $NS exec deploy/report-mailer -- nslookup kubernetes.default.svc.cluster.local"
  kubectl -n $NS exec deploy/report-mailer -- nslookup kubernetes.default.svc.cluster.local 2>&1 | grep -v '^$'
  echo
  echo "kubernetes.default ALWAYS exists, so this is not a naming mistake. Look at"
  echo "the 'Server:' line: 10.96.0.99, not the kube-dns IP 10.96.0.10 from STEP 3."
  echo "And an internet name works from the same pod:"
  echo
  echo "\$ kubectl -n $NS exec deploy/report-mailer -- nslookup example.com"
  kubectl -n $NS exec deploy/report-mailer -- nslookup example.com 2>&1 | grep -E '^(Server|Name|Address: )' | head -4
  echo
  echo "So SOMETHING answers on 10.96.0.99, but it knows nothing about"
  echo "cluster.local. It is not a Service in this cluster:"
  echo
  echo "\$ kubectl get svc -A -o wide | grep -c 10.96.0.99"
  kubectl get svc -A -o wide | grep -c '10\.96\.0\.99'
  echo
  echo "Ask a documentation-only address (192.0.2.53, TEST-NET-1) that cannot"
  echo "possibly host a DNS server:"
  echo "\$ kubectl -n $NS exec deploy/report-mailer -- nslookup example.com 192.0.2.53"
  kubectl -n $NS exec deploy/report-mailer -- nslookup example.com 192.0.2.53 2>&1 | grep -E '^(Server|Name|Address: )' | head -3
  echo
  echo "It answers too. Docker Desktop intercepts outbound DNS (port 53) to ANY IP"
  echo "and resolves it with the Mac's own resolver. On a real cluster the same"
  echo "mistake gives 'connection timed out; no servers could be reached'; here it"
  echo "gives NXDOMAIN for cluster names - which LOOKS like a naming problem."

  sub "where does the wrong server come from?"
  run kubectl -n $NS exec deploy/report-mailer -- cat /etc/resolv.conf
  echo
  echo "\$ kubectl -n $NS get deploy report-mailer -o jsonpath='{.spec.template.spec.dnsPolicy} {.spec.template.spec.dnsConfig}'"
  kubectl -n $NS get deploy report-mailer -o jsonpath='  {.spec.template.spec.dnsPolicy} {.spec.template.spec.dnsConfig}{"\n"}'
  echo
  echo "Ask the RIGHT server explicitly, from the same pod:"
  echo "\$ kubectl -n $NS exec deploy/report-mailer -- nslookup payments.s14-shop.svc.cluster.local 10.96.0.10"
  kubectl -n $NS exec deploy/report-mailer -- nslookup payments.s14-shop.svc.cluster.local 10.96.0.10 2>&1 | grep -E '^(Server|Name|Address)'
  shot screenshots/dns-wrong-nameserver.png bash -c "kubectl -n $NS exec deploy/report-mailer -- cat /etc/resolv.conf; kubectl -n kube-system get svc kube-dns; kubectl -n $NS exec deploy/report-mailer -- nslookup kubernetes.default.svc.cluster.local"

  hr "STEP 6 - ROOT CAUSE"
  echo "checkout      : 'payments' is a short name. The search list only expands it"
  echo "                inside the pod's OWN namespace (s14-issues); the Service is"
  echo "                in s14-shop. Cross-namespace calls need <svc>.<namespace>."
  echo "report-mailer : dnsPolicy None + a hand-written nameserver (10.96.0.99)"
  echo "                that is not CoreDNS. Its queries never reach the cluster's"
  echo "                DNS, so no cluster name can resolve, short or full."
}

fix() {
  OLD_PODS=$(kubectl -n $NS get pods -l issue=dns -o name)
  hr "STEP 7 - FIX"
  echo "\$ kubectl diff -f fixed.yaml"
  kubectl diff -f fixed.yaml 2>&1 | grep -E '^[+-] ' | grep -v generation | sed 's/^/  /'
  echo
  kubectl apply -f fixed.yaml
  kubectl -n $NS rollout status deployment/checkout --timeout=120s
  kubectl -n $NS rollout status deployment/report-mailer --timeout=120s
  # the old pods take their 30s grace period to exit; wait so 'logs deploy/x'
  # reads the NEW pod
  [ -n "${OLD_PODS:-}" ] && kubectl -n $NS wait --for=delete $OLD_PODS --timeout=90s >/dev/null 2>&1
}

verify() {
  hr "STEP 8 - VERIFY"
  sleep 8
  run kubectl -n $NS get pods -l issue=dns
  echo
  run kubectl -n $NS logs deploy/checkout --tail=2
  echo
  run kubectl -n $NS logs deploy/report-mailer --tail=2
  echo
  run kubectl -n $NS exec deploy/report-mailer -- cat /etc/resolv.conf
  shot screenshots/dns-after.png bash -c "kubectl -n $NS logs deploy/checkout --tail=2; kubectl -n $NS logs deploy/report-mailer --tail=2"
  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f fixed.yaml --ignore-not-found
  wait_gone $NS issue=dns
  kubectl wait --for=delete namespace/s14-shop --timeout=120s >/dev/null 2>&1 || true
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
