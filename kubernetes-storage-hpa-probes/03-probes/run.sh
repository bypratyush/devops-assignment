#!/usr/bin/env bash
# Session 13 - probes: liveness restarts, readiness removes from endpoints,
# startup protects a slow starter. Every behaviour is observed, not described.
# Usage: ./run.sh [all|liveness|readiness|startup|cleanup]   SHOTS=1 also captures screenshots
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
NS=s13-probes
K="kubectl -n $NS"
shot() { [ "${SHOTS:-0}" = "1" ] || return 0; local out=$1; shift; ( cd ../.. && WIDTH=130 ./lab/shot.sh "kubernetes-storage-hpa-probes/03-probes/screenshots/$out" "$@" ) >/dev/null 2>&1 || echo "  (screenshot $out failed)"; }
ns() { kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f - >/dev/null; }
rc() { $K get pod "$1" -o jsonpath='{.status.containerStatuses[0].restartCount}'; }

liveness() {
  ns
  hr "STEP 1 - Liveness: the app hangs 20s after every start"
  # start the startup demo now too, so it has had time to play out by STEP 7
  $K apply -f startup.yaml >/dev/null
  $K apply -f liveness.yaml
  $K wait --for=condition=Ready pod/liveness-demo --timeout=120s >/dev/null
  START=$(date +%s)
  echo
  echo "watching RESTARTS (probe: 'cat /tmp/healthy' every 5s, 2 misses -> restart)"
  printf "  %-8s %-8s %-18s %s\n" "t(s)" "RESTARTS" "STATUS" "READY"
  for _ in $(seq 1 30); do
    S=$($K get pod liveness-demo --no-headers | awk '{print $3}')
    R=$($K get pod liveness-demo -o jsonpath='{.status.containerStatuses[0].ready}')
    printf "  %-8s %-8s %-18s %s\n" "$(( $(date +%s) - START ))" "$(rc liveness-demo)" "$S" "$R"
    [ "$(rc liveness-demo)" -ge 3 ] && break
    sleep 8
  done

  hr "STEP 2 - Why it was restarted: the probe failures are in the events"
  $K get events --field-selector involvedObject.name=liveness-demo --sort-by=.lastTimestamp \
    -o custom-columns=TYPE:.type,REASON:.reason,COUNT:.count,MESSAGE:.message | grep -E 'TYPE|Unhealthy|Killing|Started' | head -8
  echo
  echo "--- last state of the container ---"
  $K get pod liveness-demo -o jsonpath='  lastState: reason={.status.containerStatuses[0].lastState.terminated.reason} exitCode={.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
  echo
  echo "--- the log of the PREVIOUS (killed) container ---"
  $K logs liveness-demo --previous | sed 's/^/  /'
  echo
  echo "The process never exited by itself - it was 'running' but useless. Only the"
  echo "liveness probe noticed. Each kill is a fresh container (new /tmp), so it is"
  echo "healthy again for 20s, then killed again, with a growing back-off between."
  shot liveness-restarts.png bash -c "kubectl -n $NS get pod liveness-demo; echo; kubectl -n $NS describe pod liveness-demo | sed -n '/^Events/,\$p' | grep -E 'Events|Type|Unhealthy|Killing' | head -6"
}

readiness() {
  ns
  hr "STEP 3 - Readiness: 3 nginx pods behind a Service, all Ready"
  $K apply -f readiness.yaml
  $K rollout status deployment/readiness-demo --timeout=120s
  $K wait --for=condition=Ready pod/client --timeout=120s >/dev/null
  $K get pods -l app=readiness-demo -o wide
  echo
  $K get endpointslices -l kubernetes.io/service-name=readiness-demo \
    -o jsonpath='{range .items[*].endpoints[*]}  {.addresses[0]}  ready={.conditions.ready}  {.targetRef.name}{"\n"}{end}'
  # endpoints programming lags Ready by a moment; wait until the service answers
  for _ in $(seq 1 15); do
    $K exec client -- curl -s -o /dev/null --max-time 2 http://readiness-demo && break
    sleep 1
  done
  echo
  echo "30 requests through the Service, counted by which pod answered:"
  $K exec client -- sh -c 'for i in $(seq 1 30); do curl -s --max-time 2 http://readiness-demo; done' | sort | uniq -c | sed 's/^/  /'

  hr "STEP 4 - Make ONE pod not ready (delete its /ready file)"
  VICTIM=$($K get pods -l app=readiness-demo -o jsonpath='{.items[0].metadata.name}')
  echo "\$ kubectl exec $VICTIM -- rm /usr/share/nginx/html/ready"
  $K exec "$VICTIM" -- rm /usr/share/nginx/html/ready
  for _ in $(seq 1 20); do
    [ "$($K get pod "$VICTIM" -o jsonpath='{.status.containerStatuses[0].ready}')" = "false" ] && break
    sleep 1
  done
  sleep 2
  $K get pods -l app=readiness-demo
  echo
  $K get endpointslices -l kubernetes.io/service-name=readiness-demo \
    -o jsonpath='{range .items[*].endpoints[*]}  {.addresses[0]}  ready={.conditions.ready}  {.targetRef.name}{"\n"}{end}'
  echo
  echo "30 requests through the Service again:"
  $K exec client -- sh -c 'for i in $(seq 1 30); do curl -s --max-time 2 http://readiness-demo; done' | sort | uniq -c | sed 's/^/  /'
  echo
  echo "$VICTIM is still Running with RESTARTS 0 - readiness never restarts anything."
  echo "It is just taken out of the Service until it reports ready again."
  shot readiness-endpoints.png bash -c "kubectl -n $NS get pods -l app=readiness-demo; echo; kubectl -n $NS get endpointslices -l kubernetes.io/service-name=readiness-demo -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}  ready={.conditions.ready}  {.targetRef.name}{\"\\n\"}{end}'"

  hr "STEP 5 - The probe failure as Kubernetes recorded it"
  $K get events --field-selector involvedObject.name="$VICTIM",reason=Unhealthy -o custom-columns=REASON:.reason,COUNT:.count,MESSAGE:.message | head -3

  hr "STEP 6 - Recover: put the file back, the pod rejoins by itself"
  $K exec "$VICTIM" -- sh -c 'echo ok > /usr/share/nginx/html/ready'
  $K wait --for=condition=Ready pod/"$VICTIM" --timeout=30s
  sleep 2
  $K get endpointslices -l kubernetes.io/service-name=readiness-demo \
    -o jsonpath='{range .items[*].endpoints[*]}  {.addresses[0]}  ready={.conditions.ready}  {.targetRef.name}{"\n"}{end}'
  echo
  $K exec client -- sh -c 'for i in $(seq 1 30); do curl -s --max-time 2 http://readiness-demo; done' | sort | uniq -c | sed 's/^/  /'
}

startup() {
  ns
  hr "STEP 7 - Startup probe: the same slow app, with and without one"
  $K apply -f startup.yaml >/dev/null
  # both pods need at least ~75s to show the difference
  for _ in $(seq 1 30); do
    AGE=$(( $(date +%s) - $(TZ=UTC date -j -f '%Y-%m-%dT%H:%M:%SZ' "$($K get pod slow-with-startup -o jsonpath='{.metadata.creationTimestamp}')" +%s 2>/dev/null || date +%s) ))
    [ "$AGE" -ge 80 ] && break
    sleep 5
  done
  $K get pods -l demo=startup
  echo
  echo "--- slow-no-startup: liveness probe fires during the warm-up ---"
  $K get events --field-selector involvedObject.name=slow-no-startup --sort-by=.lastTimestamp \
    -o custom-columns=REASON:.reason,COUNT:.count,MESSAGE:.message | grep -E 'REASON|Unhealthy|Killing' | head -4
  echo
  $K logs slow-no-startup --previous 2>&1 | sed 's/^/  previous container log: /'
  echo
  echo "--- slow-with-startup: startup probe fails while warming up, then passes ---"
  $K get events --field-selector involvedObject.name=slow-with-startup --sort-by=.lastTimestamp \
    -o custom-columns=REASON:.reason,COUNT:.count,MESSAGE:.message | grep -E 'REASON|Unhealthy|Started' | head -4
  echo
  $K logs slow-with-startup | sed 's/^/  log: /' | head -3
  echo
  echo "Same image, same liveness probe. Without a startup probe the liveness probe"
  echo "kills the container before it finishes starting, forever. With one, liveness"
  echo "is held off until startup succeeds (here after ~30s, within its 60s budget)."
  shot startup-vs-liveness.png kubectl -n $NS get pods -l demo=startup -o wide

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete namespace $NS --ignore-not-found
}

case "${1:-all}" in
  liveness) liveness ;; readiness) readiness ;; startup) startup ;; cleanup) cleanup ;;
  all) liveness; readiness; startup ;;
  *) echo "usage: $0 [all|liveness|readiness|startup|cleanup]"; exit 1 ;;
esac
