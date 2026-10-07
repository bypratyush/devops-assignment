#!/usr/bin/env bash
# Hands-on with the core troubleshooting commands:
# get, describe, logs, exec, events, explain, top, get -o wide (and -o yaml/jsonpath/custom-columns).
# Usage: ./run.sh [all|deploy|get|describe|logs|exec|events|explain|top|cleanup]   (default: all)
#        SHOTS=1 ./run.sh   also captures screenshots/
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../lib.sh
NS=s14-commands
K="kubectl -n $NS"
webpod() { $K get pods -l app=web -o jsonpath='{.items[0].metadata.name}'; }

deploy() {
  hr "SETUP - deploy the practice workload"
  wait_gone $NS app
  kubectl apply -f commands-demo.yaml
  $K rollout status deployment/web --timeout=120s
  $K wait --for=condition=Ready pod/multi pod/cpu-burner --timeout=120s
  echo "waiting 60s so 'flaky' has crashed and been restarted once..."
  sleep 60
}

do_get() {
  hr "1. kubectl get - WHAT exists and what state is it in?"
  run $K get pods
  echo
  echo "READY 0/1 or a growing RESTARTS column is the first thing to look for."

  sub "-o wide: add IP, NODE (where did it land? is it on the same node as X?)"
  run $K get pods -o wide
  shot screenshots/get-wide.png $K get pods -o wide

  sub "several kinds at once"
  run $K get deploy,rs,svc,endpointslices

  sub "labels, and selecting by label (exactly what a Service does)"
  run $K get pods --show-labels
  echo
  run $K get pods -l 'app=web'
  echo
  run $K get pods -l 'app in (multi,flaky)'

  sub "field selector: filter on status, not labels"
  run $K get pods --field-selector=status.phase=Running,metadata.name!=cpu-burner

  sub "sort by restart count (the noisy pod floats to the bottom)"
  run $K get pods --sort-by='.status.containerStatuses[0].restartCount'

  sub "-o yaml: the full object, including status the API server added"
  echo "\$ $K get pod $(webpod) -o yaml | grep -A6 '^status:'"
  $K get pod "$(webpod)" -o yaml | grep -A6 '^status:'

  sub "-o jsonpath: one field, for scripts"
  echo "\$ $K get pod flaky -o jsonpath='{.status.containerStatuses[0].restartCount}'"
  $K get pod flaky -o jsonpath='{.status.containerStatuses[0].restartCount}{"\n"}'
  echo "\$ $K get pods -o jsonpath='{range .items[*]}{.metadata.name}{\"\\t\"}{.spec.nodeName}{\"\\n\"}{end}'"
  $K get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}'

  sub "-o custom-columns: your own table"
  echo "\$ $K get pods -o custom-columns=POD:.metadata.name,IMAGE:.spec.containers[*].image,RESTARTS:.status.containerStatuses[*].restartCount,NODE:.spec.nodeName"
  $K get pods -o custom-columns='POD:.metadata.name,IMAGE:.spec.containers[*].image,RESTARTS:.status.containerStatuses[*].restartCount,NODE:.spec.nodeName'

  sub "-w: watch changes live (a scale-up happens 2s into the watch)"
  ( sleep 2; $K scale deployment web --replicas=3 >/dev/null ) &
  watch_for 12 $K get pods -l app=web -w
  wait
  $K scale deployment web --replicas=2 >/dev/null
  $K rollout status deployment/web --timeout=60s >/dev/null

  sub "nodes and services with -o wide"
  run kubectl get nodes -o wide
  echo
  run $K get svc -o wide
  echo
  echo "svc -o wide adds the SELECTOR column - compare it with --show-labels."
}

do_describe() {
  local P; P=$(webpod)
  hr "2. kubectl describe - the DETAILS and the recent Events for one object"
  echo "\$ $K describe pod flaky   (trimmed to the useful parts)"
  $K describe pod flaky | sed -n '/^Node:/p;/^IP:/p;/^    State:/,/^    Restart Count:/p;/^Conditions:/,/^Volumes:/p' | grep -v '^Volumes:'
  $K describe pod flaky | sed -n '/^Events:/,$p'
  shot screenshots/describe-pod.png bash -c "$K describe pod flaky | sed -n '/^    State:/,/^    Restart Count:/p;/^Events:/,\$p'"

  sub "describe a Deployment: strategy, replica counts, ReplicaSets, events"
  $K describe deployment web | grep -E '^(Replicas|StrategyType|RollingUpdateStrategy|Selector|OldReplicaSets|NewReplicaSet):|ScalingReplicaSet'

  sub "describe a Service: is anything behind it?"
  $K describe svc web | grep -E '^(Selector|Type|IP|Port|TargetPort|Endpoints):'

  sub "describe a node: what is already reserved on it"
  NODE=$($K get pod "$P" -o jsonpath='{.spec.nodeName}')
  echo "\$ kubectl describe node $NODE | sed -n '/Allocated resources/,/memory/p'"
  kubectl describe node "$NODE" | sed -n '/^Allocated resources:/,/^  memory/p'
}

do_logs() {
  hr "3. kubectl logs - what the APPLICATION says"
  run $K logs "$(webpod)" --tail=3

  sub "--timestamps (when did each line happen?)"
  run $K logs multi -c app --tail=3 --timestamps

  sub "two containers: logs needs -c, or --all-containers"
  run $K logs multi --tail=3
  echo
  run $K logs multi -c sidecar --tail=3
  echo
  run $K logs multi --all-containers --prefix --tail=2
  shot screenshots/logs-containers.png $K logs multi --all-containers --prefix --tail=3

  sub "--since: only the last N seconds"
  run $K logs multi -c app --since=5s

  sub "-f: follow (stream) - captured for 7 seconds, each line time-stamped on arrival"
  watch_for 7 $K logs multi -c app -f --tail=1

  sub "--previous: the container instance BEFORE the last restart"
  # wait until flaky has restarted and its new run is in progress
  for _ in $(seq 1 90); do
    R=$($K get pod flaky -o jsonpath='{.status.containerStatuses[0].restartCount} {.status.containerStatuses[0].state.running.startedAt}')
    case "$R" in 0*|*' ') sleep 1 ;; *) break ;; esac
  done
  run $K get pod flaky
  echo
  run $K logs flaky
  echo
  run $K logs flaky --previous
  shot screenshots/logs-previous.png bash -c "$K get pod flaky; $K logs flaky --previous"
  echo
  echo "The current run has not failed yet; --previous shows the run that did,"
  echo "including the stderr line explaining why."

  sub "by label or through a Deployment (kubectl picks the pods for you)"
  run $K logs -l app=web --tail=1 --prefix
  echo
  run $K logs deploy/web --tail=1
}

do_exec() {
  local P; P=$(webpod)
  hr "4. kubectl exec - look from INSIDE the container"
  run $K exec "$P" -- nginx -v
  echo
  run $K exec "$P" -- cat /etc/resolv.conf
  echo
  echo "\$ $K exec $P -- env | grep -E 'HOSTNAME|WEB_SERVICE'"
  $K exec "$P" -- env | grep -E 'HOSTNAME|WEB_SERVICE'

  sub "is the process listening where we think? (-c picks the container)"
  run $K exec "$P" -- netstat -tlnp
  echo
  run $K exec multi -c sidecar -- ps

  sub "test connectivity from a pod's point of view"
  echo "\$ $K exec multi -c app -- wget -qO- -T 3 http://web | grep -i title"
  $K exec multi -c app -- wget -qO- -T 3 http://web 2>&1 | grep -i '<title>'
  shot screenshots/exec.png bash -c "$K exec $P -- netstat -tlnp; $K exec multi -c app -- wget -qO- -T 3 http://web | grep -i '<title>'"
  echo
  echo "Interactive shell (not capturable in a script): $K exec -it $P -- sh"
}

do_events() {
  hr "5. events - what KUBERNETES tried to do"
  echo "\$ kubectl events -n $NS --types=Warning | tail -4"
  kubectl events -n $NS --types=Warning 2>&1 | tail -4
  shot screenshots/events.png bash -c "kubectl events -n $NS --types=Warning | tail -4; echo; kubectl events -n $NS --for pod/flaky | tail -5"

  sub "events for one object only"
  echo "\$ kubectl events -n $NS --for pod/flaky"
  kubectl events -n $NS --for pod/flaky 2>&1 | tail -6

  sub "the older form: get events, sorted, filtered"
  echo "\$ $K get events --sort-by=.lastTimestamp | tail -6"
  $K get events --sort-by=.lastTimestamp 2>&1 | tail -6
  echo
  echo "\$ $K get events --field-selector type=Warning | tail -4"
  $K get events --field-selector type=Warning 2>&1 | tail -4
  echo
  echo "Events are kept for 1 hour by default (kube-apiserver --event-ttl), so"
  echo "for an incident from yesterday they are already gone."
}

do_explain() {
  hr "6. kubectl explain - the API docs, offline, for the exact cluster version"
  echo "\$ kubectl explain pod.spec.containers.livenessProbe | head -20"
  kubectl explain pod.spec.containers.livenessProbe 2>&1 | head -20
  shot screenshots/explain.png bash -c "kubectl explain service.spec.ports.targetPort"

  sub "a single field"
  run kubectl explain service.spec.ports.targetPort

  sub "--recursive: the shape of a whole sub-tree"
  echo "\$ kubectl explain deployment.spec.strategy --recursive"
  kubectl explain deployment.spec.strategy --recursive 2>&1 | sed -n '/^FIELDS:/,$p'
}

do_top() {
  hr "7. kubectl top - live CPU / memory (needs metrics-server)"
  for _ in $(seq 1 24); do
    $K top pod cpu-burner >/dev/null 2>&1 && break
    sleep 5
  done
  run kubectl top nodes
  echo
  run $K top pods --sort-by=cpu
  echo
  run $K top pods multi --containers
  shot screenshots/top.png bash -c "kubectl top nodes; echo; $K top pods --sort-by=cpu"
  echo
  echo "cpu-burner sits at its 150m LIMIT - it is being throttled, not crashing."
  echo "CPU over the limit is throttled; MEMORY over the limit is OOMKilled."
  echo
  echo "\$ kubectl top pods -n kube-system --sort-by=memory | head -6"
  kubectl top pods -n kube-system --sort-by=memory 2>&1 | head -6
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f commands-demo.yaml --ignore-not-found --wait=false
  kubectl wait --for=delete namespace/$NS --timeout=180s >/dev/null 2>&1 || true
}

case "${1:-all}" in
  all)      deploy; do_get; do_describe; do_logs; do_exec; do_events; do_explain; do_top; hr "DONE" ;;
  deploy)   deploy ;;
  get)      do_get ;;
  describe) do_describe ;;
  logs)     do_logs ;;
  exec)     do_exec ;;
  events)   do_events ;;
  explain)  do_explain ;;
  top)      do_top ;;
  cleanup)  cleanup ;;
  *) echo "usage: $0 [all|deploy|get|describe|logs|exec|events|explain|top|cleanup]"; exit 1 ;;
esac
