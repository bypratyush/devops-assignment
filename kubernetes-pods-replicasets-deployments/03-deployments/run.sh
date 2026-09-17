#!/usr/bin/env bash
# Deployments - rollouts, history and rollback. What ReplicaSets could not do.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
DEP=web-deploy

# List only LIVE pods. custom-columns prints <none> when deletionTimestamp is
# unset, so awk can drop pods that are mid-termination and would otherwise make
# a completed rollout look incomplete. (kubectl jsonpath has no '!' operator.)
images() {
  kubectl get pods -l app=web-deploy --no-headers \
    -o custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[0].image,PHASE:.status.phase,DEL:.metadata.deletionTimestamp' \
    | awk '$4=="<none>" {printf "  %-34s %-22s %s\n", $1, $2, $3}'
}

# rollout status prints a line per poll; keep only the final verdict.
rollout() { kubectl rollout status deployment/$DEP --timeout=180s | tail -1; }

# Change the image AND its change-cause in ONE patch. Annotating separately
# attaches the message to whichever revision is current at that moment, which
# mislabels the history.
set_image() {
  kubectl patch deployment/$DEP -p "{
    \"metadata\":{\"annotations\":{\"kubernetes.io/change-cause\":\"$2\"}},
    \"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"nginx\",\"image\":\"$1\"}]}}}
  }" >/dev/null
}

deploy() {
  hr "STEP 1 - Create the Deployment"
  kubectl apply -f deployment.yaml
  kubectl annotate deployment/$DEP \
    kubernetes.io/change-cause="initial deploy: nginx 1.25-alpine" --overwrite >/dev/null
  rollout
}

verify() {
  hr "STEP 2 - THE HIERARCHY: Deployment -> ReplicaSet -> Pods"
  kubectl get deploy $DEP
  echo
  kubectl get rs -l app=web-deploy
  echo
  kubectl get pods -l app=web-deploy --no-headers | awk '{printf "  %-34s %s\n", $1, $3}'
  echo
  echo "You created ONE object. Kubernetes created three levels:"
  echo "  Deployment  web-deploy               <- you manage this"
  echo "   |_ ReplicaSet  web-deploy-<hash>    <- created for you, one per revision"
  echo "       |_ Pods    web-deploy-<hash>-*  <- created by the ReplicaSet"
  echo
  echo "The hash is derived from the POD TEMPLATE. Change the template and you"
  echo "get a different hash => a NEW ReplicaSet. That is the whole mechanism."

  hr "STEP 3 - The rollout a ReplicaSet could not do"
  echo "Current pods:"
  images
  echo
  echo "\$ kubectl set image deployment/$DEP nginx=nginx:1.27-alpine"
  set_image nginx:1.27-alpine "upgrade nginx to 1.27-alpine"
  rollout
  sleep 3
  echo
  echo "Pods after the rollout:"
  images
  echo
  echo ">>> EVERY pod is now on 1.27-alpine, replaced gradually with no downtime."
  echo "    In task 02 the identical change to a ReplicaSet updated NOTHING."

  hr "STEP 4 - Two ReplicaSets now exist: the new one and the old one"
  kubectl get rs -l app=web-deploy
  echo
  echo "The old ReplicaSet is kept at 0 replicas. It is not garbage - it is the"
  echo "saved previous revision, and it is what makes rollback instant."

  hr "STEP 5 - Rollout history"
  echo "\$ kubectl rollout history deployment/$DEP"
  kubectl rollout history deployment/$DEP
  echo
  echo "CHANGE-CAUSE comes from the kubernetes.io/change-cause annotation."
  echo "It must be set in the SAME patch as the change, or it labels the wrong"
  echo "revision. Set it on every change or your history is unlabelled numbers."

  hr "STEP 6 - A BAD deploy, and rolling back"
  echo "Deploying a broken image tag on purpose:"
  set_image nginx:1.27-does-not-exist "BAD: typo in image tag"
  echo
  echo "Polling for the failure (macOS has no coreutils 'timeout'):"
  BAD=""
  for _ in $(seq 1 40); do
    BAD=$(kubectl get pods -l app=web-deploy --no-headers 2>/dev/null \
          | awk '$3 ~ /ImagePullBackOff|ErrImagePull/ {print $1; exit}')
    [ -n "$BAD" ] && break
    sleep 2
  done
  echo "  failing pod: ${BAD:-<none detected>}"
  echo
  echo "--- the rollout is stuck ---"
  kubectl rollout status deployment/$DEP --timeout=5s 2>&1 | tail -1 | sed 's/^/  /'
  echo
  echo "--- pod states ---"
  kubectl get pods -l app=web-deploy --no-headers | awk '{printf "  %-34s %s\n", $1, $3}'
  echo
  echo "--- the reason ---"
  if [ -n "$BAD" ]; then
    kubectl describe pod "$BAD" | grep -E 'Failed to pull|not found' | head -1 | cut -c1-150 | sed 's/^/  /'
  fi
  echo
  echo ">>> CRITICAL: the OLD pods are still Running and still serving traffic."
  echo "    maxUnavailable=1 meant the rollout STALLED rather than taking the"
  echo "    app down. A rolling update protects you from your own bad deploy."
  echo
  echo "--- rolling back ---"
  echo "\$ kubectl rollout undo deployment/$DEP"
  kubectl rollout undo deployment/$DEP 2>/dev/null >/dev/null
  rollout
  sleep 3
  echo
  images
  echo
  echo ">>> Back on 1.27-alpine, the last known-good revision."

  hr "STEP 7 - History after the rollback"
  kubectl rollout history deployment/$DEP
  echo
  echo "Note the gaps. Revision numbers only ever increase, and when a rollback"
  echo "REUSES an existing ReplicaSet that ReplicaSet is renumbered to the new"
  echo "revision - so the number it had before disappears from the list."
  echo "The CONTENT is what matters, not the numbering."
  echo
  echo "Inspect what a revision actually contains before rolling back to it:"
  echo "\$ kubectl rollout history deployment/$DEP --revision=1"
  kubectl rollout history deployment/$DEP --revision=1 2>/dev/null | grep -E 'Image:|revision' | sed 's/^/  /'

  hr "STEP 8 - Scaling"
  echo "\$ kubectl scale deployment/$DEP --replicas=6"
  kubectl scale deployment/$DEP --replicas=6 >/dev/null
  rollout
  kubectl get deploy $DEP
  kubectl scale deployment/$DEP --replicas=4 >/dev/null
  rollout >/dev/null
  echo "  (restored to 4)"
  echo
  echo "Other rollout controls:"
  echo "  kubectl rollout pause deployment/$DEP    batch several edits, then resume"
  echo "  kubectl rollout resume deployment/$DEP"
  echo "  kubectl rollout restart deployment/$DEP  recreate all pods without any"
  echo "                                           spec change (see step 9)"

  hr "STEP 9 - rollout restart, the one people forget"
  echo "pods before:"
  kubectl get pods -l app=web-deploy --no-headers | awk '{printf "  %s\n", $1}' | head -4
  kubectl rollout restart deployment/$DEP >/dev/null
  rollout
  sleep 3
  echo "pods after:"
  kubectl get pods -l app=web-deploy --no-headers | awk '{printf "  %s\n", $1}' | head -4
  echo
  echo "All pods replaced, same image, no spec change. This is how you make pods"
  echo "pick up a changed ConfigMap or Secret that is consumed as env vars."

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f deployment.yaml --ignore-not-found
}

case "${1:-all}" in
  deploy) deploy ;; verify) verify ;; cleanup) cleanup ;;
  all) deploy; verify ;;
  *) echo "usage: $0 [deploy|verify|cleanup]"; exit 1 ;;
esac
