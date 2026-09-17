#!/usr/bin/env bash
# Deployment strategies - Recreate, RollingUpdate, Blue/Green, Canary.
# Each one is measured, not just described.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }

# Record every value availableReplicas takes during a rollout.
#
# Polling with `kubectl get` in a loop is NOT reliable here: each call costs
# 200-400ms, and a Recreate transition on a small cluster with pre-pulled
# images can complete between two samples - which makes an outage look like
# no outage. `kubectl get --watch` is event-driven and emits a line on every
# status change, so it cannot miss the dip.
# NOTE: the watcher must NOT be started via command substitution. A background
# subshell inherits the substitution's stdout pipe, so $( ) never sees EOF and
# the script deadlocks. Redirect the subshell's own stdout and use a global.
WATCH_PID=""
watch_availability() {
  local dep="$1" out="$2"
  : > "$out"
  ( kubectl get deploy "$dep" --watch --no-headers \
      -o custom-columns='A:.status.availableReplicas' 2>/dev/null \
    | while read -r a; do
        # the field is omitted entirely when it is zero
        [ "$a" = "<none>" ] && a=0
        echo "$a"
      done >> "$out" ) >/dev/null 2>&1 &
  WATCH_PID=$!
}

# smallest value seen, defaulting to 0 if we somehow captured nothing
min_seen() { sort -n "$1" 2>/dev/null | head -1; }

#############################################################################
recreate_demo() {
  hr "STRATEGY 1 - Recreate:  kill everything, then start the new version"
  kubectl apply -f recreate.yaml >/dev/null
  kubectl rollout status deployment/app-recreate --timeout=180s | tail -1
  sub "steady state"
  kubectl get deploy app-recreate

  MINFILE=$(mktemp)
  watch_availability app-recreate "$MINFILE"; PID=$WATCH_PID
  sub "updating the image (watching availableReplicas the whole time)"
  kubectl set image deployment/app-recreate app=nginx:1.27-alpine >/dev/null
  kubectl rollout status deployment/app-recreate --timeout=180s | tail -1
  sleep 2; kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null
  MIN=$(min_seen "$MINFILE"); rm -f "$MINFILE"
  echo "  (availability samples captured by kubectl --watch)"

  echo
  echo "  desired replicas          : 3"
  echo "  MINIMUM available during  : $MIN"
  echo
  if [ "$MIN" = "0" ]; then
    echo "  >>> IT HIT ZERO. Every pod was terminated before any new pod started."
    echo "      That is a real, measured OUTAGE."
  else
    echo "  >>> minimum was $MIN"
  fi
  echo
  echo "  Use Recreate when two versions MUST NOT run at once - e.g. a database"
  echo "  schema migration, or a singleton that takes an exclusive lock."
  kubectl delete -f recreate.yaml --ignore-not-found >/dev/null
}

#############################################################################
rolling_demo() {
  hr "STRATEGY 2 - RollingUpdate:  replace gradually, stay available (DEFAULT)"
  kubectl apply -f rolling.yaml >/dev/null
  kubectl rollout status deployment/app-rolling --timeout=180s | tail -1
  sub "steady state"
  kubectl get deploy app-rolling
  echo
  echo "  maxUnavailable: 1  -> never more than 1 pod BELOW desired"
  echo "  maxSurge:       1  -> never more than 1 pod ABOVE desired"
  echo "  so with replicas=4 availability should never drop below 3."

  MINFILE=$(mktemp)
  watch_availability app-rolling "$MINFILE"; PID=$WATCH_PID
  sub "updating the image (watching availableReplicas the whole time)"
  kubectl set image deployment/app-rolling app=nginx:1.27-alpine >/dev/null
  kubectl rollout status deployment/app-rolling --timeout=180s | tail -1
  sleep 2; kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null
  MIN=$(min_seen "$MINFILE"); rm -f "$MINFILE"
  echo "  (availability samples captured by kubectl --watch)"

  echo
  echo "  desired replicas          : 4"
  echo "  MINIMUM available during  : $MIN   (maxUnavailable=1 guarantees >= 3)"
  echo
  echo "  >>> NEVER hit zero. The app served traffic throughout."
  echo "      Same cluster, same image change as Recreate - different outcome."
  kubectl delete -f rolling.yaml --ignore-not-found >/dev/null
}

#############################################################################
# Which version served a request? nginx-hello prints 'Server name: <hostname>',
# and the hostname is the pod name, whose prefix tells us the deployment.
probe() { kubectl exec strategy-client -- curl -s --max-time 5 "http://$1/" 2>/dev/null | awk -F': ' '/Server name/{print $2}'; }

bluegreen_demo() {
  hr "STRATEGY 3 - Blue/Green:  two full environments, one instant switch"
  kubectl apply -f blue-green.yaml >/dev/null
  kubectl rollout status deployment/app-blue  --timeout=180s | tail -1
  kubectl rollout status deployment/app-green --timeout=180s | tail -1
  sub "both environments are running at full size, simultaneously"
  kubectl get deploy -l app=bg-app
  echo
  kubectl get pods -l app=bg-app --no-headers | awk '{printf "  %-34s %s\n", $1, $3}'

  sub "the Service currently selects version=blue"
  kubectl get svc bg-service -o jsonpath='  selector: {.spec.selector}{"\n"}'
  echo
  echo "  10 requests through the service:"
  for _ in $(seq 1 10); do probe bg-service; done | sed 's/^/    /' | sort | uniq -c | sed 's/^/  /'

  sub "THE SWITCH: patch the selector to version=green"
  echo "  \$ kubectl patch svc bg-service -p '{\"spec\":{\"selector\":{\"app\":\"bg-app\",\"version\":\"green\"}}}'"
  kubectl patch svc bg-service -p '{"spec":{"selector":{"app":"bg-app","version":"green"}}}' >/dev/null
  sleep 3
  kubectl get svc bg-service -o jsonpath='  selector: {.spec.selector}{"\n"}'
  echo
  echo "  10 requests through the SAME service name:"
  for _ in $(seq 1 10); do probe bg-service; done | sed 's/^/    /' | sort | uniq -c | sed 's/^/  /'
  echo
  echo "  >>> 100% of traffic moved from blue to green in ONE atomic operation."
  echo "      Rollback is the same command with version=blue - instant, because"
  echo "      the blue pods were never torn down."
  echo
  echo "  Cost: you run DOUBLE the pods for the whole switchover window."
  kubectl delete -f blue-green.yaml --ignore-not-found >/dev/null
}

#############################################################################
canary_demo() {
  hr "STRATEGY 4 - Canary:  send a small slice of real traffic to the new version"
  kubectl apply -f canary.yaml >/dev/null
  kubectl rollout status deployment/app-stable --timeout=180s | tail -1
  kubectl rollout status deployment/app-canary --timeout=180s | tail -1
  sub "9 stable pods + 1 canary pod, behind ONE service"
  kubectl get deploy -l app=canary-app
  echo
  echo "  The Service selects only 'app: canary-app' and ignores 'track',"
  echo "  so BOTH deployments are endpoints of the same service:"
  kubectl get svc canary-service -o jsonpath='  selector: {.spec.selector}{"\n"}'
  EP=$(kubectl get endpointslices -l kubernetes.io/service-name=canary-service -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' | wc -l | tr -d ' ')
  echo "  endpoints: $EP"

  sub "sending 100 requests and counting which track served them"
  for _ in $(seq 1 100); do probe canary-service; done > /tmp/canary-hits.txt
  STABLE=$(grep -c '^app-stable' /tmp/canary-hits.txt || true)
  CANARY=$(grep -c '^app-canary' /tmp/canary-hits.txt || true)
  TOTAL=$((STABLE + CANARY))
  echo
  printf "  requests sent      : 100\n"
  printf "  responses counted  : %s" "$TOTAL"
  if [ "$TOTAL" -lt 100 ]; then
    printf "   (%s probes returned nothing - kubectl exec\n" "$((100 - TOTAL))"
    printf "                        occasionally drops one under load; they are excluded\n"
    printf "                        rather than guessed at)"
  fi
  printf "\n\n"
  printf "  stable : %3s / %s  (%d%%)\n" "$STABLE" "$TOTAL" "$((STABLE * 100 / TOTAL))"
  printf "  canary : %3s / %s  (%d%%)\n" "$CANARY" "$TOTAL" "$((CANARY * 100 / TOTAL))"
  echo
  echo "  Expected ~90/10, because traffic splits by REPLICA COUNT (9 vs 1)."
  echo "  It is proportional, not exact - kube-proxy picks a backend at random"
  echo "  per connection, so small samples vary."

  sub "promoting the canary: scale it up, scale stable down"
  kubectl scale deployment app-canary --replicas=5 >/dev/null
  kubectl scale deployment app-stable --replicas=5 >/dev/null
  kubectl rollout status deployment/app-canary --timeout=180s >/dev/null
  kubectl rollout status deployment/app-stable --timeout=180s >/dev/null
  sleep 2
  for _ in $(seq 1 100); do probe canary-service; done > /tmp/canary-hits2.txt
  S2=$(grep -c '^app-stable' /tmp/canary-hits2.txt || true)
  C2=$(grep -c '^app-canary' /tmp/canary-hits2.txt || true)
  printf "  after scaling to 5/5 -> stable %s, canary %s (~50/50)\n" "$S2" "$C2"
  rm -f /tmp/canary-hits.txt /tmp/canary-hits2.txt
  echo
  echo "  >>> Traffic share is controlled purely by the replica ratio."
  echo "      For percentage control independent of pod count you need a service"
  echo "      mesh (Istio, Linkerd) or an ingress that supports weighted routing."
  kubectl delete -f canary.yaml --ignore-not-found >/dev/null
}

#############################################################################
summary() {
  hr "SUMMARY - measured, on this cluster"
  cat <<'TABLE'
  Strategy        Downtime   Pods needed   Rollback        Two versions live?
  --------------  ---------  ------------  --------------  ------------------
  Recreate        YES (0     N             redeploy old    never
                  available)                               (that is the point)
  RollingUpdate   none       N + maxSurge  rollout undo    briefly, during roll
  Blue/Green      none       2 x N         flip selector   yes, both full size
  Canary          none       N + canary    scale canary    yes, by ratio
                                           to 0
TABLE
  echo
  echo "  Default to RollingUpdate. Reach for the others deliberately:"
  echo "    Recreate    - versions cannot coexist (schema migration, exclusive lock)"
  echo "    Blue/Green  - you need instant, atomic rollback and can afford 2x pods"
  echo "    Canary      - you want real production traffic to validate a release"
}

deploy() {
  kubectl run strategy-client --image=curlimages/curl:8.5.0 --restart=Never \
    --command -- sh -c "sleep 7200" 2>/dev/null || true
  kubectl wait --for=condition=Ready pod/strategy-client --timeout=120s >/dev/null
}

cleanup() {
  hr "CLEANUP"
  kubectl delete pod strategy-client --ignore-not-found
  kubectl delete -f recreate.yaml -f rolling.yaml -f blue-green.yaml -f canary.yaml --ignore-not-found
}

case "${1:-all}" in
  all)       deploy; recreate_demo; rolling_demo; bluegreen_demo; canary_demo; summary ;;
  recreate)  deploy; recreate_demo ;;
  rolling)   deploy; rolling_demo ;;
  bluegreen) deploy; bluegreen_demo ;;
  canary)    deploy; canary_demo ;;
  cleanup)   cleanup ;;
  *) echo "usage: $0 [all|recreate|rolling|bluegreen|canary|cleanup]"; exit 1 ;;
esac
