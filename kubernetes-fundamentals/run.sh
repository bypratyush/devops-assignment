#!/usr/bin/env bash
# Kubernetes Fundamentals - architecture, objects, namespaces, labels, the API.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }

verify() {
  hr "1. THE CLUSTER"
  kubectl cluster-info | head -3
  echo
  kubectl get nodes -o wide
  echo
  kubectl version -o json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print('  client:', d['clientVersion']['gitVersion']); print('  server:', d['serverVersion']['gitVersion'])" 2>/dev/null

  hr "2. CONTROL PLANE vs WORKER NODES"
  echo "  CONTROL PLANE - decides what should run where"
  echo "    kube-apiserver          the ONLY way in. Everything talks to this."
  echo "    etcd                    key-value store: the entire cluster state"
  echo "    kube-scheduler          assigns pods to nodes"
  echo "    kube-controller-manager runs the control loops (deployment, replicaset...)"
  echo
  echo "  EVERY NODE - actually runs the workloads"
  echo "    kubelet                 starts/stops containers, reports status"
  echo "    kube-proxy              programs the network rules for Services"
  echo "    container runtime       containerd, CRI-O"
  echo
  sub "these are real pods in this cluster"
  kubectl get pods -n kube-system -o custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase' --no-headers | sort | head -14
  echo
  sub "the runtime actually in use"
  kubectl get nodes -o jsonpath='{range .items[*]}  {.metadata.name}  {.status.nodeInfo.containerRuntimeVersion}  kubelet={.status.nodeInfo.kubeletVersion}{"\n"}{end}'

  hr "3. THE DECLARATIVE MODEL - the single most important idea"
  echo "  You do NOT tell Kubernetes what to DO. You declare what you WANT,"
  echo "  and controllers continuously work to make reality match."
  echo
  echo "    DESIRED STATE  (your YAML, stored in etcd)"
  echo "          |"
  echo "    controller compares  <-------------------+"
  echo "          |                                   |"
  echo "    ACTUAL STATE  (what is really running) ---+"
  echo
  echo "  This reconciliation loop is why a deleted pod comes back, why a failed"
  echo "  node's pods are rescheduled, and why 'kubectl apply' is idempotent."
  echo
  sub "imperative vs declarative"
  echo "  imperative : kubectl run nginx --image=nginx        (do this now)"
  echo "  declarative: kubectl apply -f deployment.yaml       (make it so)"
  echo "  Production uses declarative YAML in git. Imperative is for exploration."

  hr "4. EVERY OBJECT HAS THE SAME FOUR TOP-LEVEL FIELDS"
  cat <<'YAML'
    apiVersion: apps/v1     which API group and version
    kind: Deployment        what type of object
    metadata:               name, namespace, labels, annotations
      name: my-app
    spec:                   YOUR desired state - you write this
      replicas: 3
    status:                 ACTUAL state - Kubernetes writes this, never you
YAML
  sub "spec vs status on a real object"
  kubectl create deployment fundamentals-demo --image=nginx:1.25-alpine --replicas=2 >/dev/null 2>&1 || true
  kubectl rollout status deployment/fundamentals-demo --timeout=120s | tail -1
  kubectl get deployment fundamentals-demo -o jsonpath='  spec.replicas   (desired) : {.spec.replicas}{"\n"}  status.replicas (actual)  : {.status.replicas}{"\n"}  status.readyReplicas      : {.status.readyReplicas}{"\n"}'

  hr "5. NAMESPACES - virtual clusters inside the cluster"
  kubectl get namespaces
  echo
  echo "  default          where your objects go if you do not say otherwise"
  echo "  kube-system      the control plane's own components"
  echo "  kube-public      world-readable cluster info"
  echo "  kube-node-lease  node heartbeats"
  echo
  kubectl create namespace demo-ns >/dev/null 2>&1 || true
  kubectl create deployment ns-demo --image=nginx:1.25-alpine -n demo-ns >/dev/null 2>&1 || true
  sleep 2
  sub "the same object name can exist in two namespaces"
  kubectl get deploy -n demo-ns --no-headers | awk '{printf "  demo-ns:  %s\n", $1}'
  kubectl get deploy -n default --no-headers | awk '{printf "  default:  %s\n", $1}'
  echo
  echo "  Namespaces scope NAMES, and are the unit for RBAC and ResourceQuotas."
  echo "  They do NOT isolate the network by default - a pod in one namespace can"
  echo "  reach a pod in another unless a NetworkPolicy stops it."
  echo
  sub "namespaced vs cluster-scoped resources"
  echo "  namespaced     : pods, deployments, services, configmaps, secrets"
  echo "  cluster-scoped : nodes, namespaces, persistentvolumes, clusterroles"
  kubectl api-resources --namespaced=false --no-headers 2>/dev/null | awk '{print "    " $1}' | head -6

  hr "6. LABELS AND SELECTORS - how everything is wired together"
  kubectl get pods -n default --show-labels --no-headers | head -3 | sed 's/^/  /'
  echo
  echo "  Labels are arbitrary key=value pairs. SELECTORS query them."
  echo "  This is the ONLY mechanism connecting Services to Pods, Deployments to"
  echo "  their Pods, and NetworkPolicies to their targets. There are no"
  echo "  foreign keys or IDs anywhere in Kubernetes - it is all label matching."
  echo
  sub "selecting with -l"
  kubectl get pods -l app=fundamentals-demo --no-headers 2>/dev/null | awk '{printf "  %s\n", $1}'
  echo
  echo "  kubectl get pods -l app=web,env=prod      AND"
  echo "  kubectl get pods -l 'env in (dev,stage)'  set-based"
  echo "  kubectl get pods -l '!canary'             does NOT have the label"
  echo
  sub "annotations are the other half"
  echo "  labels      : for SELECTING. Short, indexed, queryable."
  echo "  annotations : for METADATA. Arbitrary, not queryable. Tools read them"
  echo "                (ingress config, last-applied-configuration, checksums)."

  hr "7. THE API IS THE PRODUCT"
  sub "how many kinds of object does this cluster know about?"
  kubectl api-resources --no-headers 2>/dev/null | wc -l | xargs printf "  %s resource types\n"
  echo
  kubectl api-resources --no-headers 2>/dev/null | awk '{printf "  %-26s %-14s %s\n", $1, $(NF-1), $NF}' | head -10
  echo
  echo "  kubectl is only an HTTP client for the API server. Proof:"
  sub "kubectl get pods -v=6  (shows the actual REST call)"
  # newer kubectl logs this as: verb="GET" url="https://..." status="200 OK"
  kubectl get pods -n default -v=6 2>&1 | grep 'round_trippers' | head -1 \
    | sed -E 's/.*verb="([A-Z]+)" url="([^"]+)" status="([^"]+)".*/  \1 \2   -> \3/' 
  echo
  echo "  Everything - kubectl, the dashboard, controllers, operators - is a"
  echo "  client of that one API. That is why RBAC on the API secures everything."

  hr "8. THE COMMANDS YOU WILL ACTUALLY USE"
  cat <<'CMDS'
    kubectl get <kind> [-n ns] [-o wide|yaml|json] [--show-labels] [-l sel]
    kubectl describe <kind>/<name>        human-readable + EVENTS at the bottom
    kubectl logs <pod> [-c container] [-f] [--previous]
    kubectl exec -it <pod> -- sh
    kubectl apply -f file.yaml            declarative create-or-update
    kubectl delete -f file.yaml
    kubectl edit <kind>/<name>            opens $EDITOR, applies on save
    kubectl explain deployment.spec       FIELD DOCUMENTATION, offline
    kubectl api-resources                 what kinds exist
    kubectl get events --sort-by=.lastTimestamp
    kubectl config get-contexts           which cluster am I pointed at
CMDS
  sub "kubectl explain - the built-in documentation"
  kubectl explain deployment.spec.replicas 2>/dev/null | head -6 | sed 's/^/  /'
  sub "events are the first place to look when something is wrong"
  kubectl get events -n default --sort-by=.lastTimestamp 2>/dev/null | tail -5 | sed 's/^/  /'

  hr "CLEANUP"
  kubectl delete deployment fundamentals-demo --ignore-not-found >/dev/null
  kubectl delete namespace demo-ns --ignore-not-found >/dev/null 2>&1 &
  echo "  demo objects removed"

  hr "DONE"
}

case "${1:-all}" in
  all|verify) verify ;;
  cleanup)
    kubectl delete deployment fundamentals-demo --ignore-not-found >/dev/null
    kubectl delete namespace demo-ns --ignore-not-found >/dev/null
    echo "cleaned" ;;
  *) echo "usage: $0 [all|cleanup]"; exit 1 ;;
esac
