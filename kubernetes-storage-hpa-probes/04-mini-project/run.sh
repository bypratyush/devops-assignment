#!/usr/bin/env bash
# Session 13 mini project - production-ready web app: PVC + HPA + probes.
# Deploys the course manifests, then works through every verification task and
# the two probe challenges, capturing real output.
# Usage: ./run.sh [all|deploy|verify|load|challenges|cleanup]   SHOTS=1 also captures screenshots
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
NS=production-webapp
K="kubectl -n $NS"
LOCAL_PORT=18080            # any free local port works
TL=$(mktemp -t mini-hpa-timeline)
shot() { [ "${SHOTS:-0}" = "1" ] || return 0; local out=$1; shift; ( cd ../.. && WIDTH=130 ./lab/shot.sh "kubernetes-storage-hpa-probes/04-mini-project/screenshots/$out" "$@" ) >/dev/null 2>&1 || echo "  (screenshot $out failed)"; }
stamp() { printf '[%s] ' "$(date +%T)"; }
status() { $K get hpa web-app-hpa -o jsonpath='cpu {.status.currentMetrics[0].resource.current.averageUtilization}% (target 50%)   replicas current={.status.currentReplicas} desired={.status.desiredReplicas}{"\n"}'; }
replicas() { $K get deploy web-app -o jsonpath='{.status.replicas}'; }

deploy() {
  hr "STEP 1 - Namespace"
  kubectl apply -f namespace.yaml

  hr "STEP 2 - PersistentVolumeClaim"
  kubectl apply -f pvc.yaml
  sleep 2
  $K get pvc
  echo
  echo "Pending until a pod uses it: the default class 'standard' is WaitForFirstConsumer."

  hr "STEP 3 - Deployment and Service"
  kubectl apply -f deployment.yaml -f service.yaml
  $K rollout status deployment/web-app --timeout=240s
  $K get pods -o wide
  echo
  $K get pvc
  PV=$($K get pvc web-data -o jsonpath='{.spec.volumeName}')
  echo
  echo "PV $PV lives on node: $(kubectl get pv "$PV" -o jsonpath='{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}')"
  echo "Both replicas are on that node. RWO means 'one NODE', and the local-path PV"
  echo "has nodeAffinity, so the scheduler had to co-locate every replica with it."
  $K get svc web-service
  echo
  $K get endpointslices -l kubernetes.io/service-name=web-service

  hr "STEP 4 - Horizontal Pod Autoscaler"
  kubectl apply -f hpa.yaml
  echo "waiting for the first CPU metrics..."
  for _ in $(seq 1 40); do
    $K get hpa web-app-hpa -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization}' 2>/dev/null | grep -q '[0-9]' && break
    sleep 3
  done
  $K get hpa
  shot deployed.png kubectl -n $NS get pvc,deploy,pods,svc,hpa -o wide
}

verify() {
  hr "STEP 5 - Task 1: storage persistence"
  P1=$($K get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}')
  P2=$($K get pods -l app=web-app -o jsonpath='{.items[1].metadata.name}')
  echo "\$ kubectl exec $P1 -- sh -c 'echo \"Student: Pratyush Mohanty (24BCS10238)\" > /data/student.txt'"
  $K exec "$P1" -- sh -c 'echo "Student: Pratyush Mohanty (24BCS10238)" > /data/student.txt'
  echo "\$ kubectl exec $P1 -- cat /data/student.txt"
  $K exec "$P1" -- cat /data/student.txt
  echo
  echo "and from the OTHER replica (same PV, same node):"
  echo "\$ kubectl exec $P2 -- cat /data/student.txt"
  $K exec "$P2" -- cat /data/student.txt
  echo
  echo "\$ kubectl delete pod $P1"
  $K delete pod "$P1"
  $K rollout status deployment/web-app --timeout=180s >/dev/null
  $K wait --for=condition=Ready pod -l app=web-app --timeout=180s >/dev/null
  NEW=$($K get pods -l app=web-app -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v "$P2" | head -1)
  echo
  $K get pods -l app=web-app
  echo
  echo "\$ kubectl exec $NEW -- cat /data/student.txt     (the replacement pod)"
  $K exec "$NEW" -- cat /data/student.txt
  echo
  echo "The pod was replaced; the data was not."
  shot storage-persistence.png bash -c "kubectl -n $NS get pods -l app=web-app; echo; for p in \$(kubectl -n $NS get pods -l app=web-app -o name); do echo \"\$p: \$(kubectl -n $NS exec \$p -- cat /data/student.txt)\"; done"

  hr "STEP 6 - Task 2: Service verification through port-forward"
  $K port-forward svc/web-service $LOCAL_PORT:80 >/dev/null 2>&1 &
  PF=$!
  for _ in $(seq 1 20); do curl -s -o /dev/null http://localhost:$LOCAL_PORT && break; sleep 1; done
  echo "\$ kubectl port-forward -n $NS svc/web-service $LOCAL_PORT:80 &"
  echo "\$ curl http://localhost:$LOCAL_PORT"
  curl -s http://localhost:$LOCAL_PORT | head -4
  curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:$LOCAL_PORT
  kill $PF 2>/dev/null; wait $PF 2>/dev/null

  hr "STEP 7 - The three probes, as the kubelet sees them"
  P=$($K get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}')
  $K describe pod "$P" | grep -E '^\s+(Liveness|Readiness|Startup):'
  echo
  $K get pods -l app=web-app -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready,RESTARTS:.status.containerStatuses[0].restartCount,STARTED:.status.containerStatuses[0].started
}

load() {
  hr "STEP 8 - Task 3: the course's load generator (one busybox wget loop)"
  ( $K get hpa web-app-hpa --watch 2>&1 | while IFS= read -r line; do echo "$(date +%T)  $line"; done ) > "$TL" &
  WPID=$!
  disown $WPID   # no "Terminated" job notice when it is stopped later
  kubectl apply -f load-generator.yaml
  $K wait --for=condition=Ready pod/load-generator --timeout=120s
  for _ in $(seq 1 8); do
    sleep 15
    stamp; status
  done
  echo
  echo "\$ kubectl top pods -n $NS"
  $K top pods
  echo
  U=$($K get hpa web-app-hpa -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization}')
  if [ "$(replicas)" = "2" ]; then
    echo "Still 2 replicas at ${U}%. nginx serving a static page is cheap, so one loop"
    echo "keeps the pods around the 50% target, and the HPA only acts when"
    echo "current/target is outside 1.0 +/- 0.1 (its default tolerance)."
  else
    echo "One loop was enough this time: $(replicas) replicas at ${U}%."
  fi
  shot hpa-one-loader.png bash -c "kubectl -n $NS get hpa; echo; kubectl -n $NS top pods"

  hr "STEP 9 - More load: 3 extra copies of the same loop (load-generator-extra.yaml)"
  kubectl apply -f load-generator-extra.yaml
  $K rollout status deployment/load-generator-extra --timeout=120s
  START=$(date +%s)
  for i in $(seq 1 20); do
    sleep 15
    stamp; status
    if [ "$(replicas)" = "5" ] && [ "$($K get deploy web-app -o jsonpath='{.status.readyReplicas}')" = "5" ]; then
      sleep 20
      stamp; status
      break
    fi
  done
  echo
  echo "$(replicas) replicas after $(( $(date +%s) - START ))s of the heavier load"
  echo
  $K get pods -o wide
  echo
  echo "\$ kubectl top pods -n $NS"
  $K top pods
  echo
  echo "nodes of the web-app pods (the PV lives on $(kubectl get pv "$($K get pvc web-data -o jsonpath='{.spec.volumeName}')" -o jsonpath='{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}')):"
  $K get pods -l app=web-app -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort | uniq -c | sed 's/^/  /'
  shot hpa-under-load.png bash -c "kubectl -n $NS get hpa; echo; kubectl -n $NS top pods"
  shot pods-scaled.png kubectl -n $NS get pods -o wide

  hr "STEP 10 - Stop all load; scale-down uses the DEFAULT 5-minute window here"
  kubectl delete pod load-generator -n $NS --wait=false
  kubectl delete -f load-generator-extra.yaml --wait=false
  STOP=$(date +%s)
  for _ in $(seq 1 30); do
    sleep 20
    stamp; status
    [ "$(replicas)" = "2" ] && break
  done
  echo
  echo "back to $(replicas) replicas $(( $(date +%s) - STOP ))s after the load stopped"
  echo "(hpa.yaml sets no behavior, so the default scaleDown stabilizationWindowSeconds"
  echo " of 300s applies: the HPA keeps the highest recommendation of the last 5 minutes)"

  hr "STEP 11 - 'kubectl get hpa -w' timeline and the HPA's events"
  pkill -f "kubectl -n $NS get hpa web-app-hpa --watch" 2>/dev/null
  kill $WPID 2>/dev/null
  sleep 1
  cat "$TL"
  echo
  $K describe hpa web-app-hpa | sed -n '/^Conditions/,$p'
  shot hpa-timeline.png cat "$TL"
  shot hpa-events.png bash -c "kubectl -n $NS describe hpa web-app-hpa | sed -n '/^Events/,\$p'"
  rm -f "$TL"
}

challenges() {
  hr "STEP 12 - Challenge 2: readiness gating (readinessProbe path -> /does-not-exist)"
  $K patch deployment web-app --type=json \
    -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/does-not-exist"}]'
  # Recreate strategy: old pods go first, new ones never become ready
  for _ in $(seq 1 40); do
    N=$($K get pods -l app=web-app --no-headers 2>/dev/null | grep -c 'Running')
    NR=$($K get pods -l app=web-app -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' | grep -c true)
    [ "$N" -ge 2 ] && [ "$NR" -eq 0 ] && break
    sleep 3
  done
  sleep 10
  $K get pods -l app=web-app
  echo
  echo "--- EndpointSlice: the pod IPs are listed, but marked not ready ---"
  $K get endpointslices -l kubernetes.io/service-name=web-service \
    -o jsonpath='{range .items[*].endpoints[*]}  {.addresses[0]}  ready={.conditions.ready}  {.targetRef.name}{"\n"}{end}'
  echo
  echo "--- describe svc: only READY addresses count as endpoints ---"
  $K describe svc web-service | grep -E '^Endpoints:'
  echo
  $K get events --field-selector reason=Unhealthy --sort-by=.lastTimestamp -o custom-columns=REASON:.reason,MESSAGE:.message | tail -2
  echo
  P=$($K get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}')
  echo "\$ kubectl exec $P -- curl http://web-service     (from inside one of the pods)"
  $K exec "$P" -- curl -s -o /dev/null -w "HTTP %{http_code}" --max-time 5 http://web-service; echo ", curl exit code $?"
  echo
  echo "STATUS Running, READY 0/1, RESTARTS 0, and the Service has no ready endpoints:"
  echo "the pods are alive but receive no traffic. Readiness never restarts anything."
  shot challenge-readiness.png bash -c "kubectl -n $NS get pods -l app=web-app; echo; kubectl -n $NS describe svc web-service | grep -E '^(Selector|Endpoints):'; echo; kubectl -n $NS get endpointslices -l kubernetes.io/service-name=web-service -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}  ready={.conditions.ready}{\"\\n\"}{end}'"
  echo
  echo "restoring the readiness path..."
  $K patch deployment web-app --type=json \
    -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/"}]' >/dev/null
  $K rollout status deployment/web-app --timeout=240s

  hr "STEP 13 - Challenge 3: liveness restart loop (livenessProbe path -> /crash)"
  $K patch deployment web-app --type=json \
    -p '[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/path","value":"/crash"}]'
  # Recreate: old pods go, new ones start (startup + readiness still pass on /)
  $K rollout status deployment/web-app --timeout=240s >/dev/null
  START=$(date +%s)
  printf "  %-6s %s\n" "t(s)" "pod / READY / RESTARTS"
  for _ in $(seq 1 8); do
    $K get pods -l app=web-app --no-headers | awk -v t=$(( $(date +%s) - START )) '{printf "  %-6s %s  %s  %s  %s\n", t, $1, $2, $3, $4}'
    sleep 12
  done
  echo
  P=$($K get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}')
  $K describe pod "$P" | sed -n '/^Events/,$p' | grep -E 'Events|Unhealthy|Killing' | head -4
  echo
  echo "Each new container gets initialDelaySeconds 5 + 3 failures x periodSeconds 5"
  echo "before the kubelet restarts it, so RESTARTS climbs every 15-25s. The readiness"
  echo "probe still passes in between, so the pod also flaps in and out of the Service."
  shot challenge-liveness.png bash -c "kubectl -n $NS get pods -l app=web-app; echo; kubectl -n $NS describe pod $P | sed -n '/^Events/,\$p' | grep -E 'Events|Type|Unhealthy|Killing' | head -5"
  echo
  echo "restoring the liveness path..."
  $K patch deployment web-app --type=json \
    -p '[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/path","value":"/"}]' >/dev/null
  $K rollout status deployment/web-app --timeout=240s
  $K get pods -l app=web-app

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete namespace $NS --ignore-not-found
}

case "${1:-all}" in
  deploy) deploy ;; verify) verify ;; load) load ;; challenges) challenges ;; cleanup) cleanup ;;
  all) deploy; verify; load; challenges ;;
  *) echo "usage: $0 [all|deploy|verify|load|challenges|cleanup]"; exit 1 ;;
esac
