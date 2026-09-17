#!/usr/bin/env bash
# Ingress, ConfigMaps and Secrets.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }
POD() { kubectl get pod -l app=config-demo -o jsonpath='{.items[0].metadata.name}' 2>/dev/null; }

deploy() {
  hr "SETUP"
  kubectl apply -f configmap.yaml -f secret.yaml -f app.yaml -f services.yaml -f ingress.yaml
  kubectl rollout status deployment/config-demo --timeout=180s | tail -1
  kubectl rollout status deployment/second-app  --timeout=180s | tail -1
}

verify() {
  hr "1. CONFIGMAP - non-secret configuration, kept out of the image"
  kubectl get configmap app-config
  echo
  sub "its contents"
  kubectl get configmap app-config -o jsonpath='{range $k,$v := .data}  {$k} = {$v}{"\n"}{end}' | head -6
  echo
  echo "  The point: ONE image, many environments. The image has no environment"
  echo "  baked in, so the same artifact you tested is the one you ship."

  hr "2. CONSUMING A CONFIGMAP AS ENVIRONMENT VARIABLES"
  P=$(POD)
  echo "  pod: $P"
  echo
  echo "\$ kubectl exec $P -- env | grep -E 'APP_ENV|LOG_LEVEL|FEATURE_FLAG'"
  kubectl exec "$P" -- env 2>/dev/null | grep -E '^(APP_ENV|LOG_LEVEL|FEATURE_FLAG)=' | sed 's/^/  /'
  echo
  echo "  Two ways, both used in app.yaml:"
  echo "    configMapKeyRef  one specific key -> one env var"
  echo "    envFrom          EVERY key in the ConfigMap becomes an env var"

  hr "3. CONSUMING A CONFIGMAP AS FILES (a mounted volume)"
  echo "\$ kubectl exec $P -- ls /etc/app-config"
  kubectl exec "$P" -- ls /etc/app-config 2>/dev/null | sed 's/^/  /'
  echo
  echo "\$ kubectl exec $P -- cat /etc/app-config/app.properties"
  kubectl exec "$P" -- cat /etc/app-config/app.properties 2>/dev/null | sed 's/^/  /'
  echo
  echo "  Each KEY becomes a FILE, each VALUE its content. This is how you inject"
  echo "  a whole config file (nginx.conf, application.yml) without rebuilding."

  hr "4. THE UPDATE BEHAVIOUR THAT CATCHES EVERYONE"
  echo "Changing LOG_LEVEL from info to debug in the ConfigMap:"
  kubectl patch configmap app-config -p '{"data":{"LOG_LEVEL":"debug","app.properties":"server.port=8080\nserver.timeout=60\ncache.enabled=false\n"}}' >/dev/null
  echo "  patched. Now waiting for the kubelet to sync the mounted volume..."
  for _ in $(seq 1 40); do
    kubectl exec "$P" -- cat /etc/app-config/app.properties 2>/dev/null | grep -q 'timeout=60' && break
    sleep 3
  done
  echo
  sub "the MOUNTED FILE updated itself, with no restart"
  kubectl exec "$P" -- cat /etc/app-config/app.properties 2>/dev/null | sed 's/^/  /'
  echo
  sub "but the ENVIRONMENT VARIABLE did NOT"
  kubectl exec "$P" -- env 2>/dev/null | grep '^LOG_LEVEL=' | sed 's/^/  /'
  echo "  still 'info', even though the ConfigMap now says 'debug'."
  echo
  echo "  >>> THE RULE:"
  echo "      Mounted volumes  update live (kubelet re-syncs, ~60s by default)."
  echo "      Environment vars are injected ONCE at container start and NEVER"
  echo "      change. To pick them up you must restart the pods:"
  echo "          kubectl rollout restart deployment/config-demo"
  echo
  echo "  This is the single most common ConfigMap surprise in production."

  hr "5. SECRETS - and what they are actually NOT"
  kubectl get secret app-secret
  echo
  sub "the stored value"
  kubectl get secret app-secret -o jsonpath='{.data.DB_PASSWORD}' | sed 's/^/  stored : /'
  echo
  sub "decoding it - anyone with read access can do this"
  kubectl get secret app-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d | sed 's/^/  decoded: /'
  echo
  echo
  echo "  >>> A Secret is BASE64-ENCODED, NOT ENCRYPTED."
  echo "      Base64 is an encoding, not a cipher. Anyone who can read the"
  echo "      Secret object can read the value, and by default it is stored"
  echo "      in etcd in plain text."
  echo
  echo "      To make Secrets actually secret you need:"
  echo "        - encryption at rest in etcd (EncryptionConfiguration)"
  echo "        - RBAC that restricts who can 'get secrets'"
  echo "        - or an external store: Vault, AWS/GCP Secrets Manager,"
  echo "          External Secrets Operator, Sealed Secrets"
  echo
  echo "      NEVER commit a Secret manifest with real values to git."

  hr "6. CONSUMING A SECRET"
  echo "\$ kubectl exec $P -- env | grep DB_PASSWORD"
  kubectl exec "$P" -- env 2>/dev/null | grep '^DB_PASSWORD=' | sed 's/^/  /'
  echo
  echo "\$ kubectl exec $P -- ls /etc/app-secret"
  kubectl exec "$P" -- ls /etc/app-secret 2>/dev/null | sed 's/^/  /'
  echo "\$ kubectl exec $P -- cat /etc/app-secret/API_KEY"
  kubectl exec "$P" -- cat /etc/app-secret/API_KEY 2>/dev/null | sed 's/^/  /'
  echo
  echo
  echo "  Prefer FILES over env vars for secrets: env vars leak into crash dumps,"
  echo "  child processes, 'docker inspect' and logging of the process table."

  hr "7. INGRESS - one entry point, HTTP routing to many services"
  kubectl get ingress demo-ingress
  echo
  sub "the rules"
  kubectl describe ingress demo-ingress | sed -n '/Rules:/,/Annotations:/p' | head -16
  echo
  echo "  A Service is L4 (TCP). An Ingress is L7 (HTTP): it can route on"
  echo "  HOSTNAME and PATH, terminate TLS, and rewrite URLs."

  hr "8. THE INGRESS CONTROLLER - the piece that does the work"
  kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --no-headers | awk '{printf "  %-46s %s\n", $1, $3}'
  echo
  echo "  An Ingress OBJECT is only a rule. Nothing happens without a CONTROLLER"
  echo "  watching for Ingress objects and configuring a real proxy. Here that is"
  echo "  ingress-nginx; on a cloud it might be an ALB or GCE controller."
  echo
  echo "  ingressClassName: nginx  is what says WHICH controller should act."

  hr "9. HOST-BASED ROUTING, tested for real"
  echo "This kind cluster maps host port 80 -> the ingress controller,"
  echo "so curl with a Host header reaches it exactly as a browser would."
  echo
  for h in app.local second.local; do
    BODY=$(curl -s --max-time 8 -H "Host: $h" http://localhost/ 2>/dev/null | awk -F': ' '/Server name/{print $2}')
    printf "  curl -H 'Host: %-13s' http://localhost/   ->  served by %s\n" "$h" "${BODY:-<no response>}"
  done
  echo
  echo "  Same IP, same port, different backend - chosen purely by the Host header."

  hr "10. PATH-BASED ROUTING"
  for p in /one /two; do
    BODY=$(curl -s --max-time 8 -H "Host: shared.local" "http://localhost$p" 2>/dev/null | awk -F': ' '/Server name/{print $2}')
    printf "  curl -H 'Host: shared.local' http://localhost%-5s ->  served by %s\n" "$p" "${BODY:-<no response>}"
  done
  echo
  echo "  One hostname, two paths, two different Deployments. This is how you put"
  echo "  /api and /app behind a single domain without a public IP per service."
  echo
  echo "  pathType: Prefix   matches /one and /one/anything"
  echo "  pathType: Exact    matches ONLY /one"

  hr "11. WHY THIS BEATS A LoadBalancer PER SERVICE"
  cat <<'WHY'
    Without Ingress: every service needs its own LoadBalancer.
      10 services = 10 cloud load balancers = 10 public IPs = 10x the bill.

    With Ingress:   ONE LoadBalancer -> the ingress controller -> every service.
      10 services = 1 load balancer, 1 IP, 1 TLS certificate, one place for
      auth, rate limiting, redirects and rewrites.
WHY

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f ingress.yaml -f services.yaml -f app.yaml -f secret.yaml -f configmap.yaml --ignore-not-found
}

case "${1:-all}" in
  all) deploy; verify ;;
  deploy) deploy ;; verify) verify ;; cleanup) cleanup ;;
  *) echo "usage: $0 [all|deploy|verify|cleanup]"; exit 1 ;;
esac
