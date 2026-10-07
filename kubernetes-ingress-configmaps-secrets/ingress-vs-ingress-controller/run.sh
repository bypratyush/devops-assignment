#!/usr/bin/env bash
# Task 4 - Ingress vs Ingress Controller, proven on the cluster:
#   an Ingress is only data; the controller is the pod that turns it into nginx config.
# Usage: ./run.sh [deploy|verify|cleanup|all]   (default: all)
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr()  { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }
NS=s12-ingress
CTRL_NS=ingress-nginx
ctrl() { kubectl -n "$CTRL_NS" get pods -l app.kubernetes.io/component=controller -o jsonpath='{.items[0].metadata.name}'; }
X() { kubectl -n "$CTRL_NS" exec "$(ctrl)" -- "$@"; }
# curl the controller (kind maps host port 80 to it) with a Host header
hit() {
  local host="$1" body code
  body=$(curl -s --max-time 5 -H "Host: $host" -w '\n%{http_code}' http://localhost/ 2>/dev/null)
  code=$(echo "$body" | tail -1)
  printf "  curl -H 'Host: %-20s' http://localhost/  ->  HTTP %s  %s\n" "$host" "$code" \
    "$(echo "$body" | awk -F': ' '/^Server name/{print "served by " $2} /<title>/{gsub(/<\/?title>/,""); print "(" $0 ")"}' | head -1)"
}
# wait until an ingress has (or keeps not having) a status address
wait_addr() { for _ in $(seq 1 30); do [ -n "$(kubectl -n "$NS" get ingress "$1" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)" ] && return; sleep 2; done; }

deploy() {
  hr "SETUP - an app and a Service in namespace $NS"
  kubectl apply -f app.yaml
  kubectl -n "$NS" rollout status deployment/hello --timeout=180s
}

verify() {
  hr "1. The Ingress CONTROLLER is a real program running in a pod"
  kubectl -n "$CTRL_NS" get deploy,pods,svc -l app.kubernetes.io/component=controller
  sub "what runs inside it"
  X ps | grep -E 'PID|nginx-ingress-controller --|nginx: master' | grep -v dumb-init | cut -c1-150 | sed 's/^/  /'
  echo
  echo "  A Go process (/nginx-ingress-controller) watches the API server and writes"
  echo "  nginx.conf; a normal nginx master/worker set actually proxies the traffic."
  sub "the flags that decide WHICH Ingress objects it takes"
  kubectl -n "$CTRL_NS" get deploy ingress-nginx-controller -o jsonpath='{range .spec.template.spec.containers[0].args[*]}{@}{"\n"}{end}' \
    | grep -E 'class|publish' | sed 's/^/  /'

  hr "2. The IngressClass: the link between an Ingress and a controller"
  kubectl get ingressclass
  echo
  echo "  IngressClass 'nginx' -> spec.controller = $(kubectl get ingressclass nginx -o jsonpath='{.spec.controller}')"
  echo "  default class?       -> '$(kubectl get ingressclass nginx -o jsonpath='{.metadata.annotations.ingressclass\.kubernetes\.io/is-default-class}')' (annotation not set)"
  echo "  An Ingress names a class; the class names a controller; the controller pod"
  echo "  only acts on Ingresses whose class points at its --controller-class."

  hr "3. Two Ingress objects, identical except ingressClassName"
  kubectl apply -f ingresses.yaml
  wait_addr routed
  sleep 5
  kubectl -n "$NS" get ingress -o wide
  echo
  echo "  routed (class nginx)  : ADDRESS filled in - a controller claimed it and wrote its status"
  echo "  orphan (class traefik): no ADDRESS - no IngressClass 'traefik', no controller, nobody"
  echo "                          ever looks at it. The API server accepted it anyway."

  hr "4. Does it route?"
  hit routed.s12.local
  hit orphan.s12.local
  echo
  echo "  The orphan request still reaches ingress-nginx (port 80 belongs to it), but"
  echo "  the controller has no rule for that host, so its default server answers 404."

  hr "5. Events and controller logs: who touched what"
  sub "kubectl describe ingress routed (events)"
  kubectl -n "$NS" describe ingress routed | sed -n '/^Events:/,$p' | sed 's/^/  /'
  sub "kubectl describe ingress orphan (events)"
  kubectl -n "$NS" describe ingress orphan | sed -n '/^Events:/,$p' | sed 's/^/  /'
  sub "controller log lines about namespace $NS"
  kubectl -n "$CTRL_NS" logs "$(ctrl)" --since=5m 2>/dev/null | grep "$NS/" | grep -viE '^[0-9.]+ - ' | cut -c1-220 | sed 's/^/  /'

  hr "6. What the controller GENERATED from the routed Ingress (inside its pod)"
  sub "nginx.conf: the server block for routed.s12.local"
  X cat /etc/nginx/nginx.conf | grep -n -A2 -E 'server_name routed\.s12\.local|start server routed' | head -8 | sed 's/^/  /'
  X cat /etc/nginx/nginx.conf | grep -E 'set \$(namespace|ingress_name|service_name|service_port) ' | grep -A3 "\"$NS\"" | head -4 | sed 's/^/  /'
  sub "nginx.conf: anything for orphan.s12.local?"
  echo "  matches: $(X cat /etc/nginx/nginx.conf | grep -c 'orphan.s12.local')"
  sub "the pod IPs are NOT in nginx.conf - they are pushed to Lua at runtime (/dbg backends)"
  X /dbg backends get "$NS-hello-80" 2>/dev/null | grep -E '"address"|"port"' | sed 's/^/  /'
  kubectl -n "$NS" get pods -l app=hello -o custom-columns=POD:.metadata.name,IP:.status.podIP --no-headers | sed 's/^/  pod: /'
  echo
  echo "  Endpoint changes do not even need an nginx reload; Ingress rule changes do."

  hr "7. Fix the orphan: point it at a class that has a controller"
  echo "\$ kubectl patch ingress orphan -p '{\"spec\":{\"ingressClassName\":\"nginx\"}}'"
  kubectl -n "$NS" patch ingress orphan --type merge -p '{"spec":{"ingressClassName":"nginx"}}'
  wait_addr orphan
  sleep 3
  kubectl -n "$NS" get ingress
  hit orphan.s12.local
  echo "  nginx.conf matches for orphan.s12.local now: $(X cat /etc/nginx/nginx.conf | grep -c 'orphan.s12.local')"

  hr "8. And an Ingress with NO class at all?"
  kubectl apply -f ingress-no-class.yaml
  wait_addr classless
  sleep 3
  kubectl -n "$NS" get ingress classless
  hit classless.s12.local
  echo
  echo "  Served - but only because this ingress-nginx runs with"
  echo "  --watch-ingress-without-class=true. Without that flag (and with no IngressClass"
  echo "  marked default) it would sit exactly like 'orphan' did."

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete namespace "$NS" --wait=true
}

case "${1:-all}" in
  deploy)  deploy ;;
  verify)  verify ;;
  cleanup) cleanup ;;
  all)     deploy; verify ;;
  *) echo "usage: $0 [deploy|verify|cleanup|all]"; exit 1 ;;
esac
