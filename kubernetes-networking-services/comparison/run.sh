#!/usr/bin/env bash
# Task 2 - Kubernetes object comparison, proven on a live cluster.
#   Part A: Deployment vs ReplicaSet
#   Part B: Deployment vs DaemonSet vs StatefulSet
#   Part C: ReplicaSet vs Service
# Usage: ./run.sh [deploy|verify|cleanup|all]   (default: all = deploy + verify)
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr()  { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }
NS=s11-compare
k() { kubectl -n "$NS" "$@"; }
# Wait until exactly N ReplicaSet-owned web pods exist. Terminating pods still
# show up in 'kubectl get pods', so listing too early mixes old and new pods.
settle() {
  for _ in $(seq 1 120); do
    [ "$(k get pods -l app=web,pod-template-hash --no-headers 2>/dev/null | wc -l | tr -d ' ')" = "$1" ] && return
    sleep 1
  done
  echo "  (not settled at $1 pods after 120s)"
}
OWNERS='custom-columns=KIND:.kind,NAME:.metadata.name,OWNER-KIND:.metadata.ownerReferences[0].kind,OWNER:.metadata.ownerReferences[0].name'

deploy() {
  hr "SETUP - a Deployment, a DaemonSet and a StatefulSet in namespace $NS"
  kubectl apply -f workloads.yaml
  k rollout status deployment/web --timeout=180s
  k rollout status daemonset/node-agent --timeout=180s
  k rollout status statefulset/db --timeout=300s
  k wait --for=condition=Ready pod/client --timeout=120s
}

part_a() {
  hr "A1. Deployment -> ReplicaSet -> Pod: the ownership chain"
  k get deploy,rs,pods -l app=web
  sub "who owns whom (metadata.ownerReferences)"
  k get deploy,rs,pods -l app=web -o "$OWNERS"
  echo
  echo "  The Deployment has no owner. It owns one ReplicaSet; the ReplicaSet owns the pods."
  echo "  Nobody creates the ReplicaSet by hand - the Deployment controller does."

  hr "A2. The pod-template-hash label ties the levels together"
  RS=$(k get rs -l app=web -o jsonpath='{.items[0].metadata.name}')
  echo "  ReplicaSet name : $RS   (= <deployment>-<pod-template-hash>)"
  k get rs "$RS" -o jsonpath='  RS selector     : {.spec.selector.matchLabels}{"\n"}'
  k get pods -l app=web -o jsonpath='{range .items[*]}  pod {.metadata.name}  labels={.metadata.labels}{"\n"}{end}'

  hr "A3. Scaling: you scale the Deployment, it rewrites the ReplicaSet"
  echo "\$ kubectl scale deployment web --replicas=5"
  k scale deployment web --replicas=5
  k rollout status deployment/web --timeout=120s >/dev/null
  k get rs -l app=web
  sub "now scale the ReplicaSet DIRECTLY to 1, behind the Deployment's back"
  echo "\$ kubectl scale rs $RS --replicas=1"
  k scale rs "$RS" --replicas=1
  sleep 3
  k get rs -l app=web
  echo
  k get pods -l app=web
  echo
  echo "  DESIRED is back to 5: the Deployment owns the ReplicaSet's spec.replicas and"
  echo "  reconciled it. But look at the pod AGEs: in those 3 seconds the ReplicaSet"
  echo "  really did delete 4 pods and the Deployment made it start 4 new ones."
  echo "  Editing the ReplicaSet does not stick, and it is not harmless either."
  k scale deployment web --replicas=3 >/dev/null
  k rollout status deployment/web --timeout=120s >/dev/null
  settle 3
  echo "  (scaled back to 3)"

  hr "A4. Rolling update: a NEW ReplicaSet per pod template"
  echo "\$ kubectl set image deployment/web nginx=nginx:1.27-alpine"
  k set image deployment/web nginx=nginx:1.27-alpine
  k rollout status deployment/web --timeout=180s
  settle 3
  echo
  k get rs -l app=web -o wide
  echo
  echo "  Two ReplicaSets now: the new one at 3, the old one kept at 0 for rollback."
  echo "  A ReplicaSet on its own cannot do this - changing its template updates nothing"
  echo "  that is already running."
  sub "rollout history"
  k rollout history deployment/web
  sub "the pods now belong to the NEW ReplicaSet"
  k get pods -l app=web -o "$OWNERS"

  hr "A5. Self-healing is the ReplicaSet's job"
  VICTIM=$(k get pods -l app=web -o jsonpath='{.items[0].metadata.name}')
  echo "\$ kubectl delete pod $VICTIM"
  k delete pod "$VICTIM" --wait=true
  k rollout status deployment/web --timeout=120s >/dev/null
  settle 3
  k get pods -l app=web -o "$OWNERS"
  echo
  echo "  The replacement is owned by the ReplicaSet, not the Deployment: the RS noticed"
  echo "  3 desired / 2 actual and created one. The Deployment only manages RS objects."
}

part_b() {
  hr "B1. Pod NAMES and PLACEMENT tell you which controller made them"
  k get pods -l 'app in (web,node-agent,db)' -o wide --sort-by=.metadata.labels.app
  echo
  echo "  web-<rs-hash>-<random>  Deployment : random names, scheduler picks the nodes"
  echo "  node-agent-<random>     DaemonSet  : exactly one per node, no replicas field"
  echo "  db-0, db-1, db-2        StatefulSet: ordinal names that never change"

  hr "B2. DaemonSet: one per node, and it cannot be 'scaled'"
  k get ds node-agent
  echo
  for n in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    C=$(k get pods -l app=node-agent --field-selector spec.nodeName="$n" --no-headers 2>/dev/null | wc -l | tr -d ' ')
    printf "  %-26s node-agent pods: %s\n" "$n" "$C"
  done
  echo
  echo "\$ kubectl scale daemonset node-agent --replicas=5"
  k scale daemonset node-agent --replicas=5 2>&1 | sed 's/^/  /'
  echo
  echo "  NotFound = the DaemonSet API has no /scale subresource at all. The node count"
  echo "  IS the replica count: add a node and a pod appears on it."
  echo "  (Narrow it with a nodeSelector/affinity, widen it with tolerations.)"

  hr "B3. StatefulSet: created in order, one at a time"
  k get pods -l app=db -o custom-columns=NAME:.metadata.name,CREATED:.metadata.creationTimestamp,NODE:.spec.nodeName --sort-by=.metadata.creationTimestamp
  echo
  echo "  db-1 is not created until db-0 is Running and Ready, db-2 waits for db-1."
  echo "  A Deployment creates all its pods at once."

  hr "B4. StatefulSet storage: one PVC per pod, and it follows the pod"
  k get pvc
  echo
  echo "  volumeClaimTemplates gave each pod its OWN claim: data-db-0, data-db-1, data-db-2."
  echo "  A Deployment's pods would all share whatever single claim the template names."
  sub "write something into db-0's volume, then delete the pod"
  k exec db-0 -- sh -c 'echo "written by $(hostname) at $(date +%T)" > /data/identity.txt; cat /data/identity.txt'
  NODE_BEFORE=$(k get pod db-0 -o jsonpath='{.spec.nodeName}')
  IP_BEFORE=$(k get pod db-0 -o jsonpath='{.status.podIP}')
  k delete pod db-0 --wait=true
  k wait --for=condition=Ready pod/db-0 --timeout=180s >/dev/null
  echo
  echo "  before: db-0  ip=$IP_BEFORE  node=$NODE_BEFORE"
  echo "  after : db-0  ip=$(k get pod db-0 -o jsonpath='{.status.podIP}')  node=$(k get pod db-0 -o jsonpath='{.spec.nodeName}')  claim=$(k get pod db-0 -o jsonpath='{.spec.volumes[0].persistentVolumeClaim.claimName}')"
  echo -n "  file  : "; k exec db-0 -- cat /data/identity.txt
  echo
  echo "  Same name, same claim, same data. (Same node too: local-path volumes live on one"
  echo "  node's disk, so the PV's nodeAffinity pins the pod there.)"
  sub "the same experiment on a Deployment pod"
  W=$(k get pods -l app=web -o jsonpath='{.items[0].metadata.name}')
  k exec "$W" -- sh -c 'echo "written by $(hostname)" > /tmp/identity.txt; cat /tmp/identity.txt'
  k delete pod "$W" --wait=true >/dev/null
  k rollout status deployment/web --timeout=120s >/dev/null
  settle 3
  W2=$(k get pods -l app=web --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}')
  echo "  deleted $W, replacement is $W2 (a new random name)"
  echo -n "  file  : "; k exec "$W2" -- cat /tmp/identity.txt 2>&1

  hr "B5. StatefulSet scale-down keeps the storage"
  echo "\$ kubectl scale statefulset db --replicas=2"
  k scale statefulset db --replicas=2
  k wait --for=delete pod/db-2 --timeout=120s >/dev/null 2>&1
  k get pods -l app=db
  echo
  k get pvc
  echo
  echo "  db-2 is gone (highest ordinal first) but data-db-2 is still Bound. Kubernetes"
  echo "  never deletes StatefulSet data on scale-down; scaling back up re-attaches it."
  k scale statefulset db --replicas=3 >/dev/null
  k rollout status statefulset/db --timeout=180s >/dev/null
  echo "  scaled back to 3: db-2 uses claim $(k get pod db-2 -o jsonpath='{.spec.volumes[0].persistentVolumeClaim.claimName}')"

  hr "B6. Networking: per-pod DNS names only for the StatefulSet"
  for i in 0 1 2; do
    IP=$(k exec client -- nslookup "db-$i.db.$NS.svc.cluster.local" 2>/dev/null | awk '/^Address: /{print $2; exit}')
    printf "  db-%s.db.%s.svc.cluster.local -> %s\n" "$i" "$NS" "${IP:-<no answer>}"
  done
  echo
  echo "  Through the headless Service 'db' every StatefulSet pod is addressable by name."
  echo "  Deployment pods only get reached through a normal Service (Part C)."
  echo "  DaemonSet pods are usually reached per node (hostPort/hostNetwork) or not at all."
}

part_c() {
  hr "C1. Add a Service in front of the Deployment's pods"
  kubectl apply -f service.yaml
  k wait --for=condition=Ready pod/stray-web --timeout=120s >/dev/null
  sleep 3
  k get svc web -o wide
  echo
  k get endpointslices -l kubernetes.io/service-name=web \
    -o jsonpath='{range .items[*].endpoints[*]}  {.addresses[0]}  ready={.conditions.ready}  pod={.targetRef.name}{"\n"}{end}'
  echo
  k get rs -l app=web
  echo
  echo "  The Service has 4 endpoints; the ReplicaSet manages 3 pods. stray-web is a bare"
  echo "  pod carrying app=web: the Service selects it (selector app=web), the ReplicaSet"
  echo "  does not (its selector also needs pod-template-hash). Two independent label queries."

  hr "C2. Neither object knows the other exists"
  echo "  Service web    ownerReferences: '$(k get svc web -o jsonpath='{.metadata.ownerReferences}')'   selector: $(k get svc web -o jsonpath='{.spec.selector}')"
  RS=$(k get rs -l app=web -o jsonpath='{.items[?(@.spec.replicas>0)].metadata.name}')
  echo "  ReplicaSet $RS  mentions a Service? $(k get rs "$RS" -o yaml | grep -ci 'kind: Service' || true) times"
  echo
  echo "  ReplicaSet = keep N copies alive.  Service = give them one stable address."

  hr "C3. Pods are replaced: their IPs change, the ClusterIP does not"
  CIP=$(k get svc web -o jsonpath='{.spec.clusterIP}')
  sub "before"
  echo "  ClusterIP: $CIP"
  k get pods -l app=web -o custom-columns=POD:.metadata.name,IP:.status.podIP --no-headers | sed 's/^/  /'
  echo
  echo "\$ kubectl delete pods -l app=web,pod-template-hash    (every ReplicaSet pod at once)"
  k delete pods -l app=web,pod-template-hash --wait=true
  k rollout status deployment/web --timeout=120s >/dev/null
  settle 3
  sleep 3
  sub "after"
  echo "  ClusterIP: $(k get svc web -o jsonpath='{.spec.clusterIP}')"
  k get pods -l app=web -o custom-columns=POD:.metadata.name,IP:.status.podIP --no-headers | sed 's/^/  /'
  sub "the EndpointSlice was rewritten by the endpointslice controller"
  k get endpointslices -l kubernetes.io/service-name=web \
    -o jsonpath='{range .items[*].endpoints[*]}  {.addresses[0]}  ready={.conditions.ready}  pod={.targetRef.name}{"\n"}{end}'
  sub "and clients never noticed"
  for i in 1 2 3; do
    k exec client -- curl -s -o /dev/null -w "  http://web -> HTTP %{http_code}  (served by %{remote_ip}:%{remote_port}, the VIP)\n" --max-time 5 http://web
  done

  hr "C4. How a request actually reaches a pod"
  echo "1) DNS: the name resolves to the ClusterIP, never to a pod"
  k exec client -- nslookup "web.$NS.svc.cluster.local" 2>/dev/null | grep -E '^(Name|Address: )' | sed 's/^/  /'
  echo
  echo "2) kube-proxy turned the Service + EndpointSlice into iptables NAT rules on EVERY node."
  echo "   On devops-hw-worker (read-only iptables-save):"
  docker exec devops-hw-worker iptables-save -t nat 2>/dev/null | grep "$NS/web" | grep -E -- '-A (KUBE-SERVICES|KUBE-SVC-)|DNAT' | sed 's/^/  /'
  echo
  echo "3) The packet to $CIP:80 is DNAT-ed to one pod IP:80, chosen by the 'statistic"
  echo "   mode random' rules above: 1/4, else 1/3 of the rest, else 1/2, else the last
   one - an even 25% each. KUBE-MARK-MASQ marks off-cluster sources for SNAT."
  echo "   The ReplicaSet is not involved anywhere in this path."

  hr "DONE"
}

verify() { part_a; part_b; part_c; }

cleanup() {
  hr "CLEANUP"
  kubectl delete namespace "$NS" --wait=true
}

case "${1:-all}" in
  deploy)  deploy ;;
  verify)  verify ;;
  cleanup) cleanup ;;
  all)     deploy; verify ;;
  *) echo "usage: $0 [deploy|verify|cleanup|all]"; exit 1 ;;
esac
