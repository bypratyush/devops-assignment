#!/usr/bin/env bash
# Task 5 - Troubleshooting: reproduce each problem, investigate, find the root
# cause, fix it, verify. Namespace s12-trouble.
# Usage: ./run.sh [all|setup|1|2|3|cleanup]
#   1 = Secret with a trailing newline (instructor: secret-base64-gotcha.md)
#   2 = Service with empty endpoints behind an Ingress (instructor: empty-endpoints.yaml)
#   3 = ConfigMap key that does not exist -> CreateContainerConfigError
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr()  { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }
NS=s12-trouble
k() { kubectl -n "$NS" "$@"; }

setup() {
  hr "SETUP - namespace $NS"
  kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
}

issue1() {
  hr "ISSUE 1 - app gets 'password authentication failed' with the right password"
  k apply -f 01-secret-base64-newline/postgres.yaml
  k rollout status deployment/postgres --timeout=240s
  k apply -f 01-secret-base64-newline/broken.yaml
  k rollout status deployment/app --timeout=180s
  sleep 12
  sub "IDENTIFY: the app's own log"
  k logs deploy/app --tail=3 | sed 's/^/  /'
  sub "INVESTIGATE: the database is up and the user exists"
  k get pods -l app=postgres
  k exec deploy/postgres -- psql -U yatri_admin -d postgres -tAc 'select usename from pg_user' | sed 's/^/  user: /'
  sub "INVESTIGATE: what is REALLY in the two secrets? (base64 -d | xxd)"
  echo "  db-server-secret POSTGRES_PASSWORD:"
  k get secret db-server-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d | xxd | sed 's/^/    /'
  echo "  app-db-secret DB_PASSWORD (raw: $(k get secret app-db-secret -o jsonpath='{.data.DB_PASSWORD}')):"
  k get secret app-db-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d | xxd | sed 's/^/    /'
  echo "  length inside the app container: $(k exec deploy/app -- sh -c 'printf %s "$DB_PASSWORD" | wc -c' | tr -d ' ') bytes (expected 10)"
  sub "the two ways the value could have been encoded"
  echo "  echo \"mypassword\" | base64     -> $(echo "mypassword" | base64)"
  echo "  echo -n \"mypassword\" | base64  -> $(printf '%s' "mypassword" | base64)"
  echo
  echo "ROOT CAUSE: the Secret was encoded with plain 'echo', which appends 0x0a. The app"
  echo "sends 'mypassword\\n' (11 bytes); postgres correctly rejects it. kubectl get secret"
  echo "and even 'base64 -d' on screen look right - only xxd/wc show the extra byte."
  sub "FIX: re-encode with echo -n, then restart the app (env vars are read only at start)"
  k apply -f 01-secret-base64-newline/fixed.yaml
  k rollout restart deployment/app
  k rollout status deployment/app --timeout=180s
  sleep 8
  sub "VERIFY"
  k get secret app-db-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d | xxd | sed 's/^/  /'
  k logs deploy/app --tail=2 | sed 's/^/  /'
}

hit_backend() { curl -s --max-time 5 -H 'Host: backend.s12.local' -w '\n%{http_code}' http://localhost/ 2>/dev/null; }

issue2() {
  hr "ISSUE 2 - Ingress returns 503 for backend.s12.local"
  k apply -f 02-empty-endpoints/backend.yaml
  k rollout status deployment/yatri-backend --timeout=180s
  k apply -f 02-empty-endpoints/broken.yaml
  sleep 8
  sub "IDENTIFY"
  R=$(hit_backend); echo "  curl -H 'Host: backend.s12.local' http://localhost/ -> HTTP $(echo "$R" | tail -1)"
  echo "$R" | grep -i '<title>' | sed 's/^/  /'
  sub "INVESTIGATE: Ingress -> Service -> endpoints -> pods"
  k get ingress backend
  k describe ingress backend | grep -A3 '^Rules:' | sed 's/^/  /'
  echo
  k describe svc broken-backend-service | grep -E '^(Selector|Endpoints|Port|TargetPort):' | sed 's/^/  /'
  echo
  k get endpointslices -l kubernetes.io/service-name=broken-backend-service
  echo
  k get pods -l tier=api --show-labels
  sub "the controller says the same thing"
  kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --since=2m 2>/dev/null | grep "$NS/broken-backend-service" | tail -2 | cut -c1-200 | sed 's/^/  /'
  echo
  echo "ROOT CAUSE: the Service selector is app=wrong-backend-name; the pods are"
  echo "app=yatri-backend. No pod matches, the EndpointSlice is empty, and ingress-nginx"
  echo "has no upstream to send to, so it answers 503."
  sub "FIX: correct the selector"
  k apply -f 02-empty-endpoints/fixed.yaml
  sleep 5
  sub "VERIFY"
  k get endpointslices -l kubernetes.io/service-name=broken-backend-service
  for i in 1 2 3; do
    R=$(hit_backend); echo "  HTTP $(echo "$R" | tail -1)  $(echo "$R" | awk -F': ' '/^Server name/{print "served by " $2}')"
  done
}

issue3() {
  hr "ISSUE 3 - pod never starts: CreateContainerConfigError"
  k apply -f 03-configmap-missing-key/broken.yaml
  sleep 10
  sub "IDENTIFY"
  k get pods -l app=settings-app
  sub "INVESTIGATE: describe -> events"
  P=$(k get pods -l app=settings-app -o jsonpath='{.items[0].metadata.name}')
  k describe pod "$P" | sed -n '/^Events:/,$p' | tail -4 | cut -c1-170 | sed 's/^/  /'
  sub "INVESTIGATE: what keys does the ConfigMap really have?"
  k get configmap app-settings -o go-template='{{range $k, $v := .data}}  {{$k}} = {{$v}}{{"\n"}}{{end}}'
  echo "  the pod asks for: $(k get deploy settings-app -o jsonpath='{.spec.template.spec.containers[0].env[0].valueFrom.configMapKeyRef.key}')"
  echo
  echo "ROOT CAUSE: configMapKeyRef asks for key DB_HOST; the ConfigMap only has db_host."
  echo "Keys are case-sensitive, and a missing non-optional key blocks container creation"
  echo "(it is not a crash - the container never exists, so there are no logs)."
  k logs "$P" 2>&1 | sed 's/^/  kubectl logs: /'
  sub "FIX: reference the key that exists"
  k apply -f 03-configmap-missing-key/fixed.yaml
  k rollout status deployment/settings-app --timeout=120s
  sub "VERIFY"
  k get pods -l app=settings-app
  sleep 2
  k logs deploy/settings-app | sed 's/^/  /'
}

cleanup() {
  hr "CLEANUP"
  kubectl delete namespace "$NS" --wait=true
}

case "${1:-all}" in
  setup) setup ;;
  1) issue1 ;; 2) issue2 ;; 3) issue3 ;;
  all) setup; issue1; issue2; issue3; hr "DONE" ;;
  cleanup) cleanup ;;
  *) echo "usage: $0 [all|setup|1|2|3|cleanup]"; exit 1 ;;
esac
