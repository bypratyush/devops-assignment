#!/usr/bin/env bash
# Configuration issues - a missing ConfigMap key in an env var, and a wrong command.
# Usage: ./run.sh [all|break|investigate|fix|verify|cleanup]   (default: all)
#        SHOTS=1 ./run.sh   also captures screenshots/
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lib.sh
NS=s14-issues
pod_of() { kubectl -n $NS get pods -l app="$1" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null; }

break_it() {
  hr "STEP 1 - Deploy the broken manifests"
  ensure_ns $NS >/dev/null
  wait_gone $NS issue=config
  kubectl apply -f broken.yaml

  hr "STEP 2 - IDENTIFY: watch the first 40 seconds"
  watch_for 40 kubectl -n $NS get pods -l issue=config -w
  echo
  echo "Two statuses that are NOT CrashLoopBackOff at first:"
  echo "  CreateContainerConfigError - the kubelet could not even BUILD the"
  echo "                               container's config (env, mounts)"
  echo "  StartError / RunContainerError - the container was created but the"
  echo "                               runtime could not START its process"
  shot screenshots/config-before.png kubectl -n $NS get pods -l issue=config -o wide
}

investigate() {
  local N G
  N=$(pod_of notifier); G=$(pod_of web-gateway)

  hr "STEP 3 - INVESTIGATE notifier: CreateContainerConfigError"
  run kubectl -n $NS logs "$N"
  echo
  echo "\$ kubectl -n $NS describe pod $N"
  kubectl -n $NS describe pod "$N" | sed -n '/^    State:/,/^      Reason:/p;/^    Environment:/,/^    Mounts:/p' | grep -v '^    Mounts:'
  kubectl -n $NS describe pod "$N" | sed -n '/^Events:/,$p' | grep -E 'Events|Type|----|Failed'
  echo
  echo "--- what keys does the ConfigMap really have? ---"
  echo "\$ kubectl -n $NS get configmap notifier-config -o jsonpath='{.data}'"
  kubectl -n $NS get configmap notifier-config -o jsonpath='  {.data}{"\n"}'
  shot screenshots/config-missing-key.png bash -c "kubectl -n $NS describe pod $N | sed -n '/^Events:/,\$p' | grep -E 'Events|Type|Failed'; kubectl -n $NS get configmap notifier-config -o jsonpath='{.data}{\"\\n\"}'"

  hr "STEP 4 - INVESTIGATE web-gateway: the process cannot start"
  run kubectl -n $NS logs "$G"
  echo
  echo "\$ kubectl -n $NS describe pod $G"
  kubectl -n $NS describe pod "$G" | sed -n '/^    Command:/,/^    Restart Count:/p'
  kubectl -n $NS describe pod "$G" | sed -n '/^Events:/,$p' | grep -E 'Events|Type|----|Failed|BackOff' | cut -c1-260
  echo
  echo "--- is that file in the image at all? (a throwaway pod of the same image) ---"
  echo "\$ kubectl -n $NS run probe-nginx --image=nginx:1.27-alpine --restart=Never --command -- ls -l /app/start.sh /docker-entrypoint.sh"
  kubectl -n $NS run probe-nginx --image=nginx:1.27-alpine --restart=Never --command -- ls -l /app/start.sh /docker-entrypoint.sh >/dev/null 2>&1
  for _ in $(seq 1 30); do
    PH=$(kubectl -n $NS get pod probe-nginx -o jsonpath='{.status.phase}' 2>/dev/null)
    [ "$PH" = Succeeded ] || [ "$PH" = Failed ] && break
    sleep 1
  done
  kubectl -n $NS logs probe-nginx 2>&1 | sed 's/^/  /'
  kubectl -n $NS delete pod probe-nginx --wait=false >/dev/null 2>&1
  shot screenshots/config-bad-command.png bash -c "kubectl -n $NS get pod $G -o custom-columns='POD:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount,LAST_REASON:.status.containerStatuses[0].lastState.terminated.reason,EXIT:.status.containerStatuses[0].lastState.terminated.exitCode'; kubectl -n $NS get pod $G -o jsonpath='{.status.containerStatuses[0].lastState.terminated.message}{\"\\n\"}'"

  hr "STEP 5 - ROOT CAUSE"
  echo "notifier    : configMapKeyRef asks for key SMTP_HOST; the ConfigMap has"
  echo "              smtp_host. Keys are case-sensitive, so the kubelet refuses"
  echo "              to create the container (no partial env)."
  echo "web-gateway : command: [/app/start.sh] replaces the image's ENTRYPOINT."
  echo "              That file does not exist in nginx:1.27-alpine, so runc"
  echo "              fails the exec (exit 128) on every start."
}

fix() {
  OLD_PODS=$(kubectl -n $NS get pods -l issue=config -o name)
  hr "STEP 6 - FIX"
  echo "\$ kubectl diff -f fixed.yaml"
  kubectl diff -f fixed.yaml 2>&1 | grep -E '^[+-] ' | grep -v generation | sed 's/^/  /'
  echo
  kubectl apply -f fixed.yaml
  kubectl -n $NS rollout status deployment/notifier --timeout=120s
  kubectl -n $NS rollout status deployment/web-gateway --timeout=120s
  [ -n "${OLD_PODS:-}" ] && kubectl -n $NS wait --for=delete $OLD_PODS --timeout=90s >/dev/null 2>&1
}

verify() {
  hr "STEP 7 - VERIFY"
  sleep 3
  run kubectl -n $NS get pods -l issue=config -o wide
  shot screenshots/config-after.png kubectl -n $NS get pods -l issue=config -o wide
  echo
  run kubectl -n $NS logs deploy/notifier
  echo
  echo "\$ kubectl -n $NS exec deploy/notifier -- env | grep SMTP"
  kubectl -n $NS exec deploy/notifier -- env 2>&1 | grep SMTP
  echo
  echo "\$ kubectl -n $NS exec deploy/web-gateway -- curl -s -o /dev/null -w '%{http_code}' http://localhost/"
  kubectl -n $NS exec deploy/web-gateway -- curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost/
  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f fixed.yaml --ignore-not-found
  wait_gone $NS issue=config
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
