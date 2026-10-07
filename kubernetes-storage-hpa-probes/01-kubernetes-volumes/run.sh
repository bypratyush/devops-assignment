#!/usr/bin/env bash
# Session 13 - Kubernetes volumes: emptyDir, hostPath, PV/PVC, StorageClass,
# dynamic provisioning, reclaim policies and access modes. Every step really runs.
# Usage: ./run.sh [all|emptydir|hostpath|static|dynamic|retain|access|cleanup]
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
NS=s13-volumes
K="kubectl -n $NS"

ns() { kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f - >/dev/null; }

# run a throwaway pod on a node that mounts the node's /tmp and removes our demo dirs
node_cleanup() {
  local node=$1
  cat <<EOF | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata: {name: cleanup-$node, namespace: $NS}
spec:
  nodeSelector: {kubernetes.io/hostname: $node}
  restartPolicy: Never
  containers:
    - name: rm
      image: busybox:1.36
      command: ["sh", "-c", "rm -rf /host-tmp/s13-hostpath-data /host-tmp/s13-static-pv"]
      volumeMounts: [{name: t, mountPath: /host-tmp}]
  volumes: [{name: t, hostPath: {path: /tmp}}]
EOF
  kubectl -n $NS wait --for=jsonpath='{.status.phase}'=Succeeded pod/cleanup-$node --timeout=120s >/dev/null
  kubectl -n $NS delete pod cleanup-$node --wait=false >/dev/null
}

emptydir() {
  ns
  hr "STEP 1 - emptyDir: two containers, one shared scratch volume"
  $K apply -f emptydir-pod.yaml
  $K wait --for=condition=Ready pod/emptydir-demo --timeout=120s
  $K get pod emptydir-demo -o wide
  sleep 6
  echo
  echo "The writer (busybox) appends to /shared/index.html. nginx serves the SAME"
  echo "volume as /usr/share/nginx/html. Fetching it from the writer container over"
  echo "localhost (containers in a pod also share one network namespace):"
  echo
  echo "\$ kubectl exec emptydir-demo -c writer -- wget -qO- http://localhost/"
  $K exec emptydir-demo -c writer -- wget -qO- http://localhost/ | sed 's/^/  /'

  hr "STEP 2 - Where an emptyDir actually lives on the node"
  NODE=$($K get pod emptydir-demo -o jsonpath='{.spec.nodeName}')
  UID_=$($K get pod emptydir-demo -o jsonpath='{.metadata.uid}')
  echo "pod uid = $UID_   node = $NODE"
  echo
  echo "\$ docker exec $NODE ls /var/lib/kubelet/pods/$UID_/volumes/kubernetes.io~empty-dir/"
  docker exec "$NODE" ls "/var/lib/kubelet/pods/$UID_/volumes/kubernetes.io~empty-dir/" | sed 's/^/  /'
  echo
  echo "\$ docker exec $NODE head -3 .../kubernetes.io~empty-dir/shared/index.html"
  docker exec "$NODE" head -3 "/var/lib/kubelet/pods/$UID_/volumes/kubernetes.io~empty-dir/shared/index.html" | sed 's/^/  /'
  echo
  echo "A directory under the pod's UID. When the pod goes, the kubelet deletes it."

  hr "STEP 3 - medium: Memory makes it a tmpfs (RAM), the default is node disk"
  $K exec emptydir-demo -c writer -- df -h /shared /scratch | sed 's/^/  /'
  echo
  echo "/scratch is tmpfs, capped by sizeLimit 16Mi, and its usage counts against the"
  echo "container's memory limit. /shared is on the node's own filesystem."

  hr "STEP 4 - emptyDir SURVIVES a container restart"
  BEFORE=$($K exec emptydir-demo -c writer -- head -1 /shared/index.html)
  echo "first line before: $BEFORE"
  echo "stopping nginx inside the 'web' container (container exits, kubelet restarts it)..."
  $K exec emptydir-demo -c web -- nginx -s stop >/dev/null 2>&1
  for _ in $(seq 1 30); do
    R=$($K get pod emptydir-demo -o jsonpath='{.status.containerStatuses[?(@.name=="web")].restartCount}')
    [ "${R:-0}" -ge 1 ] && break
    sleep 2
  done
  $K wait --for=condition=Ready pod/emptydir-demo --timeout=60s >/dev/null
  $K get pod emptydir-demo -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[*].ready,WEB-RESTARTS:'.status.containerStatuses[?(@.name=="web")].restartCount'
  echo
  echo "first line after : $($K exec emptydir-demo -c writer -- head -1 /shared/index.html)"
  echo "lines in file    : $($K exec emptydir-demo -c writer -- wc -l /shared/index.html | awk '{print $1}')"
  echo
  echo "Same first line - the volume belongs to the POD, not the container."

  hr "STEP 5 - emptyDir is LOST when the pod is deleted"
  $K delete pod emptydir-demo --wait=true
  $K apply -f emptydir-pod.yaml >/dev/null
  $K wait --for=condition=Ready pod/emptydir-demo --timeout=120s >/dev/null
  NEW_UID=$($K get pod emptydir-demo -o jsonpath='{.metadata.uid}')
  echo "re-created the pod from the same YAML (new uid $NEW_UID)"
  echo
  echo "first line now : $($K exec emptydir-demo -c writer -- head -1 /shared/index.html)"
  echo "lines in file  : $($K exec emptydir-demo -c writer -- wc -l /shared/index.html | awk '{print $1}')"
  echo
  echo "old pod's directory on $NODE (the kubelet's housekeeping removes it a few"
  echo "seconds after the pod is gone, so poll for it):"
  for i in $(seq 1 60); do
    docker exec "$NODE" test -d "/var/lib/kubelet/pods/$UID_" || break
    sleep 1
  done
  echo "  gone after ~${i}s:"
  docker exec "$NODE" ls "/var/lib/kubelet/pods/$UID_" 2>&1 | sed 's/^/  /'
  echo
  echo "Fresh file, old data gone. Good for caches and scratch space, never for data you need."
  $K delete pod emptydir-demo --wait=false >/dev/null
}

hostpath() {
  ns
  hr "STEP 6 - hostPath: a directory on the NODE, mounted into the pod"
  $K apply -f hostpath-pod.yaml
  $K wait --for=condition=Ready pod/hostpath-demo pod/hostpath-other-node --timeout=120s
  $K get pods hostpath-demo hostpath-other-node -o wide
  echo
  echo "The pod wrote a line. Reading it straight off the node (a kind node is a container):"
  echo "\$ docker exec devops-hw-worker cat /tmp/s13-hostpath-data/visits.log"
  docker exec devops-hw-worker cat /tmp/s13-hostpath-data/visits.log | sed 's/^/  /'

  hr "STEP 7 - hostPath survives pod deletion (it is the node's disk)"
  $K delete pod hostpath-demo --wait=true
  $K apply -f hostpath-pod.yaml >/dev/null
  $K wait --for=condition=Ready pod/hostpath-demo --timeout=120s >/dev/null
  # Ready only means the container started; give its echo a moment to run
  for _ in $(seq 1 15); do
    [ "$($K exec hostpath-demo -- wc -l /host-data/visits.log | awk '{print $1}')" -ge 2 ] && break
    sleep 1
  done
  echo "re-created hostpath-demo; the new pod appended its own line:"
  echo "\$ kubectl exec hostpath-demo -- cat /host-data/visits.log"
  $K exec hostpath-demo -- cat /host-data/visits.log | sed 's/^/  /'

  hr "STEP 8 - ...but only on THAT node"
  echo "hostpath-other-node mounts the same path on devops-hw-worker2:"
  echo "\$ kubectl exec hostpath-other-node -- ls -la /host-data"
  $K exec hostpath-other-node -- ls -la /host-data | sed 's/^/  /'
  echo
  echo "\$ docker exec devops-hw-worker2 ls -la /tmp/s13-hostpath-data"
  docker exec devops-hw-worker2 ls -la /tmp/s13-hostpath-data | sed 's/^/  /'
  echo
  echo "Empty. If the scheduler moves the pod to another node, the data does not follow."
  echo "hostPath also gives the pod access to the node's filesystem, which is why"
  echo "Pod Security 'baseline' and 'restricted' forbid it. Use it for node agents"
  echo "(log collectors reading /var/log), not for application data."
  $K delete pod hostpath-demo hostpath-other-node --wait=false >/dev/null
}

static() {
  ns
  hr "STEP 9 - Static provisioning: an admin creates a PersistentVolume by hand"
  kubectl apply -f static-pv.yaml
  kubectl get pv s13-static-pv
  echo
  echo "STATUS Available = exists, not claimed by anyone yet. PVs are cluster-scoped"
  echo "(no namespace); PVCs are namespaced."

  hr "STEP 10 - The default-StorageClass trap"
  echo "A claim WITHOUT storageClassName:"
  $K apply -f static-pvc-trap.yaml
  sleep 3
  $K get pvc s13-trap-pvc
  echo
  kubectl get pv s13-static-pv --no-headers | sed 's/^/  PV still: /'
  echo
  echo "The admission controller filled in STORAGECLASS 'standard' (the default class),"
  echo "so this claim waits for dynamic provisioning and ignores my PV completely."
  echo "To bind a hand-made PV the claim must name the same class (or \"\")."
  $K delete -f static-pvc-trap.yaml --wait=true >/dev/null

  hr "STEP 11 - The PersistentVolumeClaim binds to the PV"
  $K apply -f static-pvc.yaml
  for _ in $(seq 1 20); do
    [ "$($K get pvc s13-static-pvc -o jsonpath='{.status.phase}')" = "Bound" ] && break
    sleep 1
  done
  kubectl get pv s13-static-pv
  $K get pvc s13-static-pvc
  echo
  echo "Asked for 500Mi, got CAPACITY 1Gi: a claim binds to a WHOLE PV, the"
  echo "smallest one that satisfies it. Binding is 1:1."

  hr "STEP 12 - A pod uses the claim; data outlives the pod"
  $K apply -f pv-pod.yaml
  $K wait --for=condition=Ready pod/pv-demo --timeout=120s
  $K get pod pv-demo -o wide
  echo
  echo "No nodeSelector in pv-pod.yaml, yet it landed on devops-hw-worker: the"
  echo "scheduler honoured the PV's nodeAffinity."
  echo
  $K exec pv-demo -- sh -c 'echo "order #1001 saved at $(date +%T) by $(hostname)" >> /data/orders.txt; cat /data/orders.txt' | sed 's/^/  /'
  echo
  echo "deleting the pod..."
  $K delete pod pv-demo --wait=true
  $K apply -f pv-pod.yaml >/dev/null
  $K wait --for=condition=Ready pod/pv-demo --timeout=120s >/dev/null
  echo "new pod started; reading the file:"
  $K exec pv-demo -- cat /data/orders.txt | sed 's/^/  /'
  echo
  echo "On the node:"
  echo "\$ docker exec devops-hw-worker cat /tmp/s13-static-pv/orders.txt"
  docker exec devops-hw-worker cat /tmp/s13-static-pv/orders.txt | sed 's/^/  /'

  hr "STEP 13 - Reclaim policy Retain: delete the claim, the PV and data stay"
  $K delete pod pv-demo --wait=true >/dev/null
  $K delete pvc s13-static-pvc --wait=true
  sleep 2
  kubectl get pv s13-static-pv
  echo
  docker exec devops-hw-worker cat /tmp/s13-static-pv/orders.txt | sed 's/^/  still on the node: /'
  echo
  echo "STATUS Released: the data is kept, but the PV still remembers its old claim"
  echo "(spec.claimRef), so no new claim can bind it until an admin cleans up."
  kubectl get pv s13-static-pv -o jsonpath='  claimRef -> {.spec.claimRef.namespace}/{.spec.claimRef.name}{"\n"}'
  kubectl delete pv s13-static-pv >/dev/null
}

dynamic() {
  ns
  hr "STEP 14 - StorageClass: the recipe for creating volumes on demand"
  kubectl get storageclass
  echo
  kubectl get storageclass standard -o jsonpath='  provisioner      : {.provisioner}{"\n"}  reclaimPolicy    : {.reclaimPolicy}{"\n"}  volumeBindingMode: {.volumeBindingMode}{"\n"}  default class    : {.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}'

  hr "STEP 15 - Dynamic provisioning: a claim, and no PV yet"
  $K apply -f dynamic-pvc.yaml
  sleep 4
  $K get pvc s13-dynamic-pvc
  echo
  $K get events --field-selector involvedObject.name=s13-dynamic-pvc -o custom-columns=REASON:.reason,MESSAGE:.message
  echo
  echo "Pending is CORRECT here. WaitForFirstConsumer delays creating the volume until"
  echo "a pod needs it, so the volume is made on the node the pod is scheduled to."

  hr "STEP 16 - The first consumer arrives, the provisioner creates the PV"
  $K apply -f dynamic-pod.yaml
  $K wait --for=condition=Ready pod/dynamic-demo --timeout=120s
  $K get pvc s13-dynamic-pvc
  PV=$($K get pvc s13-dynamic-pvc -o jsonpath='{.spec.volumeName}')
  echo
  kubectl get pv "$PV"
  echo
  NODE=$($K get pod dynamic-demo -o jsonpath='{.spec.nodeName}')
  VPATH=$(kubectl get pv "$PV" -o jsonpath='{.spec.hostPath.path}{.spec.local.path}')
  echo "  pod node : $NODE"
  echo "  PV path  : $VPATH"
  echo "  PV node  : $(kubectl get pv "$PV" -o jsonpath='{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}')"
  echo
  $K exec dynamic-demo -- sh -c 'echo "provisioned for me at $(date +%T)" > /data/hello.txt'
  echo "\$ docker exec $NODE ls -la $VPATH"
  docker exec "$NODE" ls -la "$VPATH" | sed 's/^/  /'
  echo
  echo "Nobody wrote a PV. The provisioner (local-path, in namespace local-path-storage)"
  echo "saw the claim, made a directory on $NODE and created PV $PV."

  hr "STEP 17 - Data survives the pod; reclaim policy Delete removes it with the claim"
  $K delete pod dynamic-demo --wait=true >/dev/null
  $K apply -f dynamic-pod.yaml >/dev/null
  $K wait --for=condition=Ready pod/dynamic-demo --timeout=120s >/dev/null
  echo "after deleting and re-creating the pod:"
  $K exec dynamic-demo -- cat /data/hello.txt | sed 's/^/  /'
  echo
  echo "now deleting the pod AND the claim..."
  $K delete pod dynamic-demo --wait=true >/dev/null
  $K delete pvc s13-dynamic-pvc --wait=true
  for _ in $(seq 1 30); do
    kubectl get pv "$PV" >/dev/null 2>&1 || break
    sleep 1
  done
  kubectl get pv "$PV" 2>&1 | sed 's/^/  /'
  docker exec "$NODE" ls -la "$VPATH" 2>&1 | sed 's/^/  /'
  echo
  echo "reclaimPolicy: Delete (the default for dynamic classes) - the PV object AND"
  echo "the data on the node are gone. Great for scratch environments, dangerous for"
  echo "a production database."
}

retain() {
  ns
  hr "STEP 18 - My own StorageClass with reclaimPolicy: Retain"
  $K apply -f storageclass-retain.yaml
  $K wait --for=condition=Ready pod/retain-demo --timeout=120s >/dev/null
  kubectl get storageclass s13-local-retain
  echo
  PV=$($K get pvc s13-retain-pvc -o jsonpath='{.spec.volumeName}')
  kubectl get pv "$PV"
  NODE=$($K get pod retain-demo -o jsonpath='{.spec.nodeName}')
  VPATH=$(kubectl get pv "$PV" -o jsonpath='{.spec.hostPath.path}{.spec.local.path}')

  hr "STEP 19 - Delete the claim: the PV is Released, the data stays"
  $K delete pod retain-demo --wait=true >/dev/null
  $K delete pvc s13-retain-pvc --wait=true
  sleep 2
  kubectl get pv "$PV"
  echo
  echo "\$ docker exec $NODE cat $VPATH/keep.txt"
  docker exec "$NODE" cat "$VPATH/keep.txt" | sed 's/^/  /'
  echo
  echo "Same provisioner as 'standard', different policy, different outcome. This is"
  echo "what you want for anything you cannot afford to lose by a mistyped delete."

  hr "STEP 20 - Cleaning up a retained volume on purpose"
  echo "Switching the Released PV to Delete hands it back to the provisioner:"
  kubectl patch pv "$PV" -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'
  for _ in $(seq 1 30); do
    kubectl get pv "$PV" >/dev/null 2>&1 || break
    sleep 1
  done
  kubectl get pv "$PV" 2>&1 | sed 's/^/  /'
  docker exec "$NODE" ls "$VPATH" 2>&1 | sed 's/^/  /'
  kubectl delete storageclass s13-local-retain >/dev/null
}

access() {
  ns
  hr "STEP 21 - Access modes are enforced by the storage: RWX on local-path"
  $K apply -f rwx-pvc.yaml
  for _ in $(seq 1 30); do
    $K get events --field-selector involvedObject.name=s13-rwx-pvc,reason=ProvisioningFailed --no-headers 2>/dev/null | grep -q . && break
    sleep 2
  done
  $K get pvc s13-rwx-pvc
  $K get pod rwx-demo
  echo
  $K get events --field-selector involvedObject.name=s13-rwx-pvc,reason=ProvisioningFailed -o custom-columns=REASON:.reason,MESSAGE:.message | head -2
  echo
  echo "The pod stays Pending forever. A node-local directory cannot be mounted"
  echo "read-write by pods on several nodes; RWX needs NFS, CephFS, EFS, Azure Files..."
  $K delete -f rwx-pvc.yaml --wait=false >/dev/null

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  ns
  # pods first, then claims: a PV cannot finish deleting while a claim uses it
  # (kubernetes.io/pv-protection finalizer)
  kubectl -n $NS delete pod --all --wait=true
  kubectl -n $NS delete pvc --all --wait=true
  # remove the hostPath / static-PV directories this demo created on the nodes
  node_cleanup devops-hw-worker
  node_cleanup devops-hw-worker2
  kubectl delete pv s13-static-pv --ignore-not-found
  kubectl delete storageclass s13-local-retain --ignore-not-found
  kubectl delete namespace $NS --ignore-not-found
}

case "${1:-all}" in
  emptydir) emptydir ;; hostpath) hostpath ;; static) static ;;
  dynamic) dynamic ;; retain) retain ;; access) access ;; cleanup) cleanup ;;
  all) emptydir; hostpath; static; dynamic; retain; access ;;
  *) echo "usage: $0 [all|emptydir|hostpath|static|dynamic|retain|access|cleanup]"; exit 1 ;;
esac
