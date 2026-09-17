# daemonset - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-09-18.

```text

==============================================================
STEP 1 - The cluster we are working with
==============================================================
NAME                      STATUS   ROLES           AGE   VERSION
devops-hw-control-plane   Ready    control-plane   80m   v1.37.0
devops-hw-worker          Ready    <none>          80m   v1.37.0
devops-hw-worker2         Ready    <none>          80m   v1.37.0

  3 nodes total: 1 control-plane + 2 workers

==============================================================
STEP 2 - Create a DaemonSet (note: there is NO replicas field)
==============================================================
  kind: DaemonSet
  (no 'replicas:' anywhere - the node count IS the replica count)

daemonset.apps/node-agent created
daemon set "node-agent" successfully rolled out

==============================================================
STEP 3 - One pod per node... but only 2 of 3
==============================================================
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-agent   2         2         2       2            2           <none>          2s

  node-agent-skkzw             Running    devops-hw-worker
  node-agent-t8cln             Running    devops-hw-worker2

>>> DESIRED is 2, not 3. The control-plane node was skipped.

==============================================================
STEP 4 - WHY: the control-plane node is TAINTED
==============================================================
  NODE                      TAINTS
  devops-hw-control-plane   node-role.kubernetes.io/control-plane
  devops-hw-worker          <none>
  devops-hw-worker2         <none>

  Taints:             node-role.kubernetes.io/control-plane:NoSchedule
  Unschedulable:      false

  A taint REPELS pods. NoSchedule means 'nothing may be scheduled here
  unless it explicitly tolerates this taint'. That is how Kubernetes
  keeps ordinary workloads off the control plane.

==============================================================
STEP 5 - Add a TOLERATION and the DaemonSet covers every node
==============================================================
        tolerations:
          - key: node-role.kubernetes.io/control-plane
            operator: Exists
            effect: NoSchedule

daemonset.apps/node-agent-all created
daemon set "node-agent-all" successfully rolled out

NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-agent-all   3         3         3       3            3           <none>          2s

  node-agent-all-b68p7               Running    devops-hw-worker
  node-agent-all-xgzvx               Running    devops-hw-worker2
  node-agent-all-zwlk8               Running    devops-hw-control-plane

>>> DESIRED is now 3 - including the control-plane node.
    This is exactly how kube-proxy and CNI plugins get onto every node.

--- proof: the real system DaemonSets do the same thing ---
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kindnet      3         3         3       3            3           kubernetes.io/os=linux   80m
kube-proxy   3         3         3       3            3           kubernetes.io/os=linux   80m

==============================================================
STEP 6 - Restricting a DaemonSet with nodeSelector
==============================================================
daemonset.apps/node-agent-ssd created
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-agent-ssd   0         0         0       0            0           disktype=ssd    4s

>>> DESIRED is 0 - no node carries the label disktype=ssd yet.

Labelling devops-hw-worker with disktype=ssd ...
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-agent-ssd   1         1         1       1            1           disktype=ssd    10s

  node-agent-ssd-zd28n               Running    devops-hw-worker

>>> A pod appeared the moment the node matched - no redeploy needed.
    The DaemonSet controller reacts to NODE changes, not just pod ones.

Removing the label again ...
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-agent-ssd   0         0         0       0            0           disktype=ssd    16s

>>> Back to 0. The pod was removed automatically.

==============================================================
STEP 7 - Self-healing, same as a ReplicaSet
==============================================================
deleting node-agent-skkzw (on devops-hw-worker) ...
daemon set "node-agent" successfully rolled out

  node-agent-t4ww4             Running    devops-hw-worker
  node-agent-t8cln             Running    devops-hw-worker2

>>> Replaced on the SAME node. A DaemonSet's job is node coverage.

==============================================================
STEP 8 - DaemonSet vs Deployment
==============================================================
                      Deployment                DaemonSet
  replicas            you choose N              implicit: one per eligible node
  scheduling          scheduler picks nodes     pinned, one per node
  scaling             kubectl scale             add/remove NODES
  new node joins      nothing happens           a pod appears automatically
  typical use         app workloads             per-node agents: logs, metrics,
                                                CNI, storage, security

==============================================================
DONE
==============================================================
```
