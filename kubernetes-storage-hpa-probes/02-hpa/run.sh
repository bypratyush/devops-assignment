#!/usr/bin/env bash
# Session 13 - HPA hands-on: deploy, configure the HPA, verify it, generate load,
# watch CPU and replicas go up, stop the load, watch them come back down.
# Needs metrics-server (see install-metrics-server.sh).
# Usage: ./run.sh [all|deploy|verify|load|cleanup]      SHOTS=1 also captures screenshots
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
NS=s13-hpa
K="kubectl -n $NS"
SHOT=../../lab/shot.sh
TL=$(mktemp -t hpa-timeline)
shot() { [ "${SHOTS:-0}" = "1" ] || return 0; local out=$1; shift; ( cd ../.. && WIDTH=130 ./lab/shot.sh "kubernetes-storage-hpa-probes/02-hpa/screenshots/$out" "$@" ) >/dev/null 2>&1 || echo "  (screenshot $out failed)"; }
replicas() { $K get deploy cpu-app -o jsonpath='{.status.replicas}'; }
stamp() { printf '[%s] ' "$(date +%T)"; }
status() { $K get hpa cpu-app -o jsonpath='cpu {.status.currentMetrics[0].resource.current.averageUtilization}% of request (target 50%)   replicas current={.status.currentReplicas} desired={.status.desiredReplicas}{"\n"}'; }

deploy() {
  hr "STEP 1 - Is the Metrics API there? (the HPA cannot work without it)"
  kubectl get apiservice v1beta1.metrics.k8s.io
  echo
  kubectl top nodes

  hr "STEP 2 - Deploy the application and its Service"
  kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f -
  $K apply -f deployment.yaml -f service.yaml
  $K rollout status deployment/cpu-app --timeout=180s
  $K get deploy,svc,pods -o wide

  hr "STEP 3 - Configure the HPA (hpa.yml)"
  $K apply -f hpa.yml
  echo
  echo "right after creation:"
  $K get hpa cpu-app
  echo
  echo "waiting for the first metrics to arrive..."
  for _ in $(seq 1 40); do
    $K get hpa cpu-app -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization}' 2>/dev/null | grep -q '[0-9]' && break
    sleep 3
  done
  $K get hpa cpu-app
}

verify() {
  hr "STEP 4 - Verify the HPA at rest"
  $K get hpa cpu-app
  echo
  $K get pods -l app=cpu-app
  echo
  echo "\$ kubectl top pods -n $NS"
  $K top pods
  echo
  $K describe hpa cpu-app | sed -n '1,/^Events/p'
  echo
  echo "TARGETS 'cpu: x%/50%' = average CPU as a % of the 100m request / the target."
  echo "Idle, so 1 replica (minReplicas)."
  shot hpa-at-rest.png kubectl -n $NS get hpa,deploy,pods
}

load() {
  hr "STEP 5 - Start a timestamped 'kubectl get hpa -w' in the background"
  ( $K get hpa cpu-app --watch 2>&1 | while IFS= read -r line; do echo "$(date +%T)  $line"; done ) > "$TL" &
  WPID=$!
  disown $WPID   # so bash does not print a "Terminated" job notice when it is stopped
  echo "watching in the background (pid $WPID)"

  hr "STEP 6 - Deploy the load generator"
  $K apply -f load-generator.yaml
  $K rollout status deployment/load-generator --timeout=120s
  $K get pods -l app=load-generator
  echo
  echo "Two busybox pods, each looping 'wget http://cpu-app' = two requests in flight."

  hr "STEP 7 - Observe CPU utilisation and pod scaling under load"
  START=$(date +%s)
  SHOT_TAKEN=0
  for i in $(seq 1 16); do
    sleep 15
    stamp; status
    R=$(replicas)
    if [ $((i % 4)) -eq 0 ] || [ "$R" = "5" ]; then
      $K top pods -l app=cpu-app --no-headers 2>/dev/null | sed 's/^/             /'
    fi
    if [ "$R" = "5" ] && [ $SHOT_TAKEN -eq 0 ]; then
      READY=$($K get deploy cpu-app -o jsonpath='{.status.readyReplicas}')
      if [ "${READY:-0}" = "5" ]; then
        SHOT_TAKEN=1
        sleep 20   # let metrics-server scrape the new pods so top shows them all
        shot hpa-scaled-up.png kubectl -n $NS get hpa,pods -o wide
        shot top-pods-under-load.png kubectl -n $NS top pods
        PEAK_AT=$i
      fi
    fi
    # once at max and seen for a few rounds, stop observing
    [ $SHOT_TAKEN -eq 1 ] && [ $i -ge $((PEAK_AT + 2)) ] && break
  done
  if [ $SHOT_TAKEN -eq 0 ]; then
    shot hpa-scaled-up.png kubectl -n $NS get hpa,pods -o wide
    shot top-pods-under-load.png kubectl -n $NS top pods
  fi
  echo
  echo "reached $(replicas) replicas in about $(( $(date +%s) - START ))s of load"

  hr "STEP 8 - The scaled-up state"
  $K get hpa cpu-app
  echo
  $K get pods -o wide
  echo
  echo "\$ kubectl top pods -n $NS"
  $K top pods
  echo
  $K describe hpa cpu-app | sed -n '/^Conditions/,/^Events/p'

  hr "STEP 9 - Stop the load and observe the scale-down"
  $K scale deployment load-generator --replicas=0
  STOP=$(date +%s)
  for _ in $(seq 1 24); do
    sleep 15
    stamp; status
    [ "$(replicas)" = "1" ] && break
  done
  echo
  echo "back to $(replicas) replica(s) $(( $(date +%s) - STOP ))s after the load stopped"
  echo "(stabilizationWindowSeconds: 60 in hpa.yml; with the default 300 the"
  echo " scale-down would only start about 5 minutes after the CPU dropped)"
  sleep 5
  $K get pods -l app=cpu-app

  hr "STEP 10 - The whole 'kubectl get hpa -w' timeline"
  pkill -f "kubectl -n $NS get hpa cpu-app --watch" 2>/dev/null
  kill $WPID 2>/dev/null
  sleep 1
  cat "$TL"

  hr "STEP 11 - kubectl describe hpa: the HPA's own record of what it did"
  $K describe hpa cpu-app
  shot describe-hpa-events.png bash -c "kubectl -n $NS describe hpa cpu-app | sed -n '/^Events/,\$p'"
  shot hpa-watch-timeline.png cat "$TL"
  rm -f "$TL"

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete namespace $NS --ignore-not-found
  echo "(metrics-server is left installed)"
}

case "${1:-all}" in
  deploy) deploy ;; verify) verify ;; load) load ;; cleanup) cleanup ;;
  all) deploy; verify; load ;;
  *) echo "usage: $0 [all|deploy|verify|load|cleanup]"; exit 1 ;;
esac
