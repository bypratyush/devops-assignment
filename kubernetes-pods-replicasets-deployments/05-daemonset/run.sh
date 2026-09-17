#!/usr/bin/env bash
# DaemonSets - one pod per node, automatically.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

verify() {
  hr "STEP 1 - The cluster we are working with"
  kubectl get nodes
  NODES=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
  echo
  echo "  $NODES nodes total: 1 control-plane + 2 workers"

  hr "STEP 2 - Create a DaemonSet (note: there is NO replicas field)"
  grep -vE '^\s*#' daemonset.yaml | grep -E 'kind:|replicas' | sed 's/^/  /'
  echo "  (no 'replicas:' anywhere - the node count IS the replica count)"
  echo
  kubectl apply -f daemonset.yaml
  kubectl rollout status daemonset/node-agent --timeout=180s | tail -1

  hr "STEP 3 - One pod per node... but only 2 of 3"
  kubectl get daemonset node-agent
  echo
  kubectl get pods -l app=node-agent -o wide --no-headers | awk '{printf "  %-28s %-10s %s\n", $1, $3, $7}'
  echo
  echo ">>> DESIRED is 2, not 3. The control-plane node was skipped."

  hr "STEP 4 - WHY: the control-plane node is TAINTED"
  kubectl get nodes -o custom-columns='NODE:.metadata.name,TAINTS:.spec.taints[*].key' 2>/dev/null | sed 's/^/  /'
  echo
  kubectl describe node "$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')" \
    | grep -A1 '^Taints:' | sed 's/^/  /'
  echo
  echo "  A taint REPELS pods. NoSchedule means 'nothing may be scheduled here"
  echo "  unless it explicitly tolerates this taint'. That is how Kubernetes"
  echo "  keeps ordinary workloads off the control plane."

  hr "STEP 5 - Add a TOLERATION and the DaemonSet covers every node"
  grep -A3 'tolerations:' daemonset-tolerating.yaml | sed 's/^/  /'
  echo
  kubectl apply -f daemonset-tolerating.yaml
  kubectl rollout status daemonset/node-agent-all --timeout=180s | tail -1
  echo
  kubectl get daemonset node-agent-all
  echo
  kubectl get pods -l app=node-agent-all -o wide --no-headers | awk '{printf "  %-34s %-10s %s\n", $1, $3, $7}'
  echo
  echo ">>> DESIRED is now 3 - including the control-plane node."
  echo "    This is exactly how kube-proxy and CNI plugins get onto every node."
  echo
  echo "--- proof: the real system DaemonSets do the same thing ---"
  kubectl get daemonset -n kube-system

  hr "STEP 6 - Restricting a DaemonSet with nodeSelector"
  kubectl apply -f daemonset-selector.yaml
  sleep 4
  kubectl get daemonset node-agent-ssd
  echo
  echo ">>> DESIRED is 0 - no node carries the label disktype=ssd yet."
  echo
  TARGET=$(kubectl get nodes -o jsonpath='{.items[1].metadata.name}')
  echo "Labelling $TARGET with disktype=ssd ..."
  kubectl label node "$TARGET" disktype=ssd --overwrite >/dev/null
  sleep 6
  kubectl get daemonset node-agent-ssd
  echo
  kubectl get pods -l app=node-agent-ssd -o wide --no-headers | awk '{printf "  %-34s %-10s %s\n", $1, $3, $7}'
  echo
  echo ">>> A pod appeared the moment the node matched - no redeploy needed."
  echo "    The DaemonSet controller reacts to NODE changes, not just pod ones."
  echo
  echo "Removing the label again ..."
  kubectl label node "$TARGET" disktype- >/dev/null
  sleep 6
  kubectl get daemonset node-agent-ssd
  echo
  echo ">>> Back to 0. The pod was removed automatically."

  hr "STEP 7 - Self-healing, same as a ReplicaSet"
  VICTIM=$(kubectl get pods -l app=node-agent -o jsonpath='{.items[0].metadata.name}')
  NODE=$(kubectl get pod "$VICTIM" -o jsonpath='{.spec.nodeName}')
  echo "deleting $VICTIM (on $NODE) ..."
  kubectl delete pod "$VICTIM" --wait=true >/dev/null
  kubectl rollout status daemonset/node-agent --timeout=120s | tail -1
  echo
  kubectl get pods -l app=node-agent -o wide --no-headers | awk '{printf "  %-28s %-10s %s\n", $1, $3, $7}'
  echo
  echo ">>> Replaced on the SAME node. A DaemonSet's job is node coverage."

  hr "STEP 8 - DaemonSet vs Deployment"
  cat <<'TABLE'
                      Deployment                DaemonSet
  replicas            you choose N              implicit: one per eligible node
  scheduling          scheduler picks nodes     pinned, one per node
  scaling             kubectl scale             add/remove NODES
  new node joins      nothing happens           a pod appears automatically
  typical use         app workloads             per-node agents: logs, metrics,
                                                CNI, storage, security
TABLE

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  kubectl delete -f daemonset.yaml -f daemonset-tolerating.yaml -f daemonset-selector.yaml --ignore-not-found
  for n in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    kubectl label node "$n" disktype- >/dev/null 2>&1 || true
  done
}

case "${1:-all}" in
  all|verify) verify ;;
  cleanup) cleanup ;;
  *) echo "usage: $0 [all|cleanup]"; exit 1 ;;
esac
