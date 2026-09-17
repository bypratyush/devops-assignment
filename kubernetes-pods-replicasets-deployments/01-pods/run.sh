#!/usr/bin/env bash
# Pods - the atom of Kubernetes: what they are, how to inspect them,
# how they fail, and why you should not manage them directly.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

deploy() {
  hr "STEP 1 - Create a single pod"
  kubectl apply -f pod.yaml
  kubectl wait --for=condition=Ready pod/standalone-pod --timeout=120s
}

verify() {
  hr "STEP 2 - What a pod looks like"
  kubectl get pod standalone-pod -o wide
  echo
  echo "A pod is NOT a container. It is a wrapper around one or more containers"
  echo "that share:  a network namespace (one IP, reachable over localhost),"
  echo "             storage volumes, and a lifecycle."

  hr "STEP 3 - The fields that matter"
  kubectl get pod standalone-pod -o jsonpath='  name:      {.metadata.name}{"\n"}  namespace: {.metadata.namespace}{"\n"}  node:      {.spec.nodeName}{"\n"}  podIP:     {.status.podIP}{"\n"}  phase:     {.status.phase}{"\n"}  image:     {.spec.containers[0].image}{"\n"}  restarts:  {.status.containerStatuses[0].restartCount}{"\n"}'

  hr "STEP 4 - The everyday inspection commands"
  echo "\$ kubectl describe pod standalone-pod   (events are at the bottom - read them first)"
  kubectl describe pod standalone-pod | sed -n '/Events/,$p' | head -12
  echo
  echo "\$ kubectl logs standalone-pod"
  kubectl logs standalone-pod 2>&1 | tail -3
  echo
  echo "\$ kubectl exec standalone-pod -- <cmd>"
  kubectl exec standalone-pod -- nginx -v 2>&1 | sed 's/^/  /'
  kubectl exec standalone-pod -- sh -c 'hostname; hostname -i' | sed 's/^/  /'

  hr "STEP 5 - Multi-container pod: the sidecar pattern"
  kubectl apply -f multi-container-pod.yaml
  kubectl wait --for=condition=Ready pod/sidecar-pod --timeout=120s
  echo
  kubectl get pod sidecar-pod
  echo
  echo ">>> READY shows 2/2 - two containers in ONE pod."
  echo
  echo "--- the containers ---"
  kubectl get pod sidecar-pod -o jsonpath='{range .spec.containers[*]}  {.name}  ({.image}){"\n"}{end}'
  echo
  echo "--- they share a VOLUME: the sidecar writes, nginx serves ---"
  sleep 6
  kubectl exec sidecar-pod -c web -- cat /usr/share/nginx/html/index.html | sed 's/^/  /'
  echo
  echo "--- they share an IP: curl from inside reaches the web container ---"
  kubectl exec sidecar-pod -c content-writer -- wget -qO- http://localhost:80 2>/dev/null | sed 's/^/  /'
  echo
  echo "Note '-c <container>' - with more than one container you must say which."
  echo "Logs work the same way:  kubectl logs sidecar-pod -c content-writer"

  hr "STEP 6 - FAILURE 1: ImagePullBackOff"
  kubectl apply -f failing-pod.yaml
  echo "waiting for it to fail..."
  for _ in $(seq 1 20); do
    S=$(kubectl get pod broken-pod -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null)
    case "$S" in ImagePullBackOff|ErrImagePull) break ;; esac
    sleep 2
  done
  kubectl get pod broken-pod
  echo
  echo "--- WHY (the events tell you exactly) ---"
  kubectl describe pod broken-pod | sed -n '/Events/,$p' | tail -6
  echo
  echo "Diagnosis: the image tag does not exist in the registry. Real-world causes"
  echo "are the same three every time: typo in the tag, image never pushed, or"
  echo "a private registry with no imagePullSecret."

  hr "STEP 7 - FAILURE 2: CrashLoopBackOff"
  kubectl apply -f crashing-pod.yaml
  echo "waiting for it to crash a few times..."
  for _ in $(seq 1 25); do
    S=$(kubectl get pod crashing-pod -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null)
    [ "$S" = "CrashLoopBackOff" ] && break
    sleep 2
  done
  kubectl get pod crashing-pod
  echo
  echo "--- the container's OWN output is the answer, not the pod events ---"
  echo "\$ kubectl logs crashing-pod"
  kubectl logs crashing-pod 2>&1 | sed 's/^/  /'
  echo
  echo "\$ kubectl logs crashing-pod --previous   (the run BEFORE the current backoff)"
  kubectl logs crashing-pod --previous 2>&1 | sed 's/^/  /' | head -4
  echo
  echo "CrashLoopBackOff is NOT an error in itself - it means 'the container keeps"
  echo "exiting and I am waiting longer each time before retrying'. The real error"
  echo "is always in the logs. Kubernetes backs off 10s, 20s, 40s ... up to 5min."
  echo
  echo "--- restart count climbing ---"
  kubectl get pod crashing-pod -o jsonpath='  restartCount: {.status.containerStatuses[0].restartCount}{"\n"}  lastState:    {.status.containerStatuses[0].lastState.terminated.reason} (exit {.status.containerStatuses[0].lastState.terminated.exitCode}){"\n"}'

  hr "STEP 8 - THE KEY LESSON: a bare pod is not managed by anything"
  echo "Current pods:"
  kubectl get pods --no-headers | awk '{printf "  %-20s %s\n", $1, $3}'
  echo
  echo "Deleting standalone-pod ..."
  kubectl delete pod standalone-pod --wait=true >/dev/null
  echo
  echo "--- is it back? ---"
  kubectl get pod standalone-pod 2>&1 | sed 's/^/  /'
  echo
  echo ">>> GONE. Permanently. Nothing recreates it."
  echo
  echo "That is why you almost never create a bare Pod in production. If its node"
  echo "dies, the pod dies with it and your app is simply down. You want a"
  echo "CONTROLLER watching it - which is what ReplicaSets (02) and Deployments"
  echo "(03) are for."

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f pod.yaml -f multi-container-pod.yaml -f failing-pod.yaml -f crashing-pod.yaml --ignore-not-found
}

case "${1:-all}" in
  deploy) deploy ;; verify) verify ;; cleanup) cleanup ;;
  all) deploy; verify ;;
  *) echo "usage: $0 [deploy|verify|cleanup]"; exit 1 ;;
esac
