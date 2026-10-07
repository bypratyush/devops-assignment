#!/usr/bin/env bash
# CrashLoopBackOff - two crash loops with two different root causes.
# Usage: ./run.sh [all|break|investigate|fix|verify|cleanup]   (default: all)
#        SHOTS=1 ./run.sh   also captures screenshots/ at the interesting moments
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lib.sh
NS=s14-issues
pod_of() { kubectl -n $NS get pods -l app="$1" --field-selector=status.phase!=Succeeded \
             -o jsonpath='{.items[0].metadata.name}' 2>/dev/null; }

break_it() {
  hr "STEP 1 - Deploy the broken manifests"
  ensure_ns $NS >/dev/null
  wait_gone $NS issue=crashloop
  kubectl apply -f broken.yaml

  hr "STEP 2 - IDENTIFY: watch the pods for 100 seconds"
  echo "(each line is prefixed with the time it arrived)"
  watch_for 100 kubectl -n $NS get pods -l issue=crashloop -w
  echo
  echo "Status flips Running/Error/OOMKilled -> CrashLoopBackOff, and RESTARTS"
  echo "keeps climbing. CrashLoopBackOff is not the error, it is the kubelet"
  echo "WAITING (10s, 20s, 40s ... capped at 5m) before the next restart."
  shot screenshots/crashloop-before.png kubectl -n $NS get pods -l issue=crashloop -o wide
}

investigate() {
  local W1 T1
  W1=$(pod_of orders-worker); T1=$(pod_of thumbnailer)

  hr "STEP 3 - INVESTIGATE orders-worker: describe"
  echo "\$ kubectl -n $NS describe pod $W1   (State / Last State / Events)"
  kubectl -n $NS describe pod "$W1" | sed -n '/^    State:/,/^    Restart Count:/p'
  echo "  ..."
  kubectl -n $NS describe pod "$W1" | sed -n '/^Events:/,$p'
  echo
  echo "describe says WHAT happened (exit code 1, restarted N times) but not WHY."

  hr "STEP 4 - INVESTIGATE orders-worker: logs, current and --previous"
  echo "Waiting for a moment when the container has just been RESTARTED and is"
  echo "running again, because that is when the two commands differ..."
  for _ in $(seq 1 120); do
    R=$(kubectl -n $NS get pod "$W1" -o jsonpath='{.status.containerStatuses[0].state.running.startedAt}')
    [ -n "$R" ] && break
    sleep 1
  done
  sleep 1
  kubectl -n $NS get pod "$W1"
  echo
  run kubectl -n $NS logs "$W1"
  echo
  run kubectl -n $NS logs "$W1" --previous
  echo
  echo "Plain 'logs' shows the CURRENT attempt, which has not reached the error"
  echo "yet. '--previous' shows the attempt that crashed, and the app says"
  echo "exactly what is wrong: QUEUE_URL is not set."
  shot screenshots/crashloop-logs-previous.png kubectl -n $NS logs "$W1" --previous

  sub "confirm from the spec: what env does the container actually get?"
  echo "\$ kubectl -n $NS get deploy orders-worker -o jsonpath='{.spec.template.spec.containers[0].env}'"
  OUT=$(kubectl -n $NS get deploy orders-worker -o jsonpath='{.spec.template.spec.containers[0].env}')
  echo "  env = '${OUT}'   (empty: nothing is injected)"

  hr "STEP 5 - INVESTIGATE thumbnailer: the logs do NOT explain it"
  run kubectl -n $NS logs "$T1"
  echo
  echo "It printed 'starting' and then silence - no stack trace, no error line."
  echo "Something outside the process killed it. describe shows who:"
  echo
  echo "\$ kubectl -n $NS describe pod $T1"
  kubectl -n $NS describe pod "$T1" | sed -n '/^    Last State:/,/^    Restart Count:/p'
  kubectl -n $NS describe pod "$T1" | sed -n '/^    Limits:/,/^      memory:/p'

  sub "the same facts as one line per pod (jsonpath / custom-columns)"
  kubectl -n $NS get pods -l issue=crashloop \
    -o custom-columns='POD:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount,LAST_REASON:.status.containerStatuses[0].lastState.terminated.reason,EXIT_CODE:.status.containerStatuses[0].lastState.terminated.exitCode,MEM_LIMIT:.spec.containers[0].resources.limits.memory'
  shot screenshots/crashloop-last-state.png kubectl -n $NS get pods -l issue=crashloop \
    -o custom-columns='POD:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount,LAST_REASON:.status.containerStatuses[0].lastState.terminated.reason,EXIT_CODE:.status.containerStatuses[0].lastState.terminated.exitCode,MEM_LIMIT:.spec.containers[0].resources.limits.memory'

  sub "warnings only, newest last"
  kubectl -n $NS events --types=Warning 2>&1 | grep -E "LAST SEEN|$W1|$T1" | tail -6

  hr "STEP 6 - ROOT CAUSE"
  echo "orders-worker : exit code 1  = the APP chose to exit. Its own log line says"
  echo "                QUEUE_URL is missing; the Deployment has no env section."
  echo "thumbnailer   : exit code 137 = 128 + 9 (SIGKILL), reason OOMKilled. The"
  echo "                kernel killed it for exceeding the 64Mi memory limit while"
  echo "                warming a 150 MB cache. Nothing in the app is 'wrong'."
}

fix() {
  hr "STEP 7 - FIX: see exactly what will change, then apply"
  echo "\$ kubectl diff -f fixed.yaml"
  kubectl diff -f fixed.yaml 2>&1 | grep -E '^[+-] ' | grep -v -E 'generation|^[+-] +(creationTimestamp|resourceVersion|uid):' | sed 's/^/  /'
  echo
  kubectl apply -f fixed.yaml
  kubectl -n $NS rollout status deployment/orders-worker --timeout=120s
  kubectl -n $NS rollout status deployment/thumbnailer --timeout=120s
}

verify() {
  hr "STEP 8 - VERIFY: Running, and STAYS running"
  sleep 5
  kubectl -n $NS get pods -l issue=crashloop
  echo
  echo "waiting 40s - a crash loop would have restarted at least once by now..."
  sleep 40
  kubectl -n $NS get pods -l issue=crashloop
  shot screenshots/crashloop-after.png kubectl -n $NS get pods -l issue=crashloop -o wide
  echo
  run kubectl -n $NS logs deploy/orders-worker --tail=3
  echo
  run kubectl -n $NS logs deploy/thumbnailer
  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f fixed.yaml --ignore-not-found
  wait_gone $NS issue=crashloop
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
