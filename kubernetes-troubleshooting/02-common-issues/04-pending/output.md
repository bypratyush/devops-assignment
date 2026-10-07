# Pending - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Deploy the broken manifests
==============================================================
deployment.apps/report-builder created
deployment.apps/search-indexer created

==============================================================
STEP 2 - IDENTIFY: Pending, with no node and no IP
==============================================================
NAME                              READY   STATUS    RESTARTS   AGE   IP       NODE     NOMINATED NODE   READINESS GATES
report-builder-6d846cccc9-f7slv   0/1     Pending   0          10s   <none>   <none>   <none>           <none>
search-indexer-6d66dd8f45-s45m5   0/1     Pending   0          10s   <none>   <none>   <none>           <none>

NODE is <none>: the pod was never scheduled, so the kubelet never saw it.
That means no image pull, no container and no logs:

$ kubectl -n s14-issues logs report-builder-6d846cccc9-f7slv

==============================================================
STEP 3 - INVESTIGATE: the scheduler explains itself in the Events
==============================================================
$ kubectl -n s14-issues describe pod report-builder-6d846cccc9-f7slv
    Requests:
      cpu:        64
      memory:     32Mi
Events:
  Type     Reason            Age               From               Message
  ----     ------            ----              ----               -------
  Warning  FailedScheduling  1s (x9 over 10s)  default-scheduler  0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.

$ kubectl -n s14-issues describe pod search-indexer-6d66dd8f45-s45m5
Node-Selectors:              disktype=ssd
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  11s   default-scheduler  0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 node(s) didn't match Pod's node affinity/selector. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.

Read the message as a tally over all 3 nodes:
  - the control-plane is excluded by its NoSchedule taint (normal)
  - the 2 workers are excluded for 'Insufficient cpu' / not matching
    the node selector
  - 'preemption: ... not helpful': evicting lower-priority pods would
    not make room either, so it will stay Pending forever

==============================================================
STEP 4 - INVESTIGATE: compare the ask with what the nodes have
==============================================================
$ kubectl get nodes -o custom-columns=NAME,CPU,MEMORY,TAINTS
NAME                      ALLOCATABLE_CPU   ALLOCATABLE_MEM   TAINTS
devops-hw-control-plane   15                8125796Ki         node-role.kubernetes.io/control-plane
devops-hw-worker          15                8125796Ki         <none>
devops-hw-worker2         15                8125796Ki         <none>

$ kubectl describe node devops-hw-worker   (Allocated resources)
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests    Limits
  --------           --------    ------
  cpu                290m (1%)   600m (4%)
  memory             410Mi (5%)  416Mi (5%)

$ kubectl get nodes -L disktype
NAME                      STATUS   ROLES           AGE   VERSION   DISKTYPE
devops-hw-control-plane   Ready    control-plane   19d   v1.37.0   
devops-hw-worker          Ready    <none>          19d   v1.37.0   
devops-hw-worker2         Ready    <none>          19d   v1.37.0   

64 CPUs requested vs 15 allocatable per node; and the DISKTYPE column is
empty on every node, so 'disktype=ssd' can never match.

==============================================================
STEP 5 - ROOT CAUSE
==============================================================
report-builder : requests.cpu=64 is larger than any node. Requests are
                 a scheduling RESERVATION, not usage - the scheduler will
                 not place a pod whose request does not fit.
search-indexer : nodeSelector disktype=ssd matches zero nodes.

==============================================================
STEP 6 - FIX
==============================================================
$ kubectl diff -f fixed.yaml
  -            cpu: "64"
  +            cpu: 500m
  -            cpu: "64"
  +            cpu: 100m
  -      nodeSelector:
  -        disktype: ssd

deployment.apps/report-builder configured
deployment.apps/search-indexer configured
Waiting for deployment "report-builder" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "report-builder" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "report-builder" rollout to finish: 1 old replicas are pending termination...
deployment "report-builder" successfully rolled out
Waiting for deployment "search-indexer" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "search-indexer" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "search-indexer" rollout to finish: 1 old replicas are pending termination...
deployment "search-indexer" successfully rolled out

==============================================================
STEP 7 - VERIFY: scheduled, on a real node, Running
==============================================================
NAME                              READY   STATUS    RESTARTS   AGE   IP            NODE                NOMINATED NODE   READINESS GATES
report-builder-c4c579bf-6dr7b     1/1     Running   0          6s    10.244.2.95   devops-hw-worker    <none>           <none>
search-indexer-8688fdfbd7-wdtwp   1/1     Running   0          6s    10.244.1.74   devops-hw-worker2   <none>           <none>

Scheduled   Successfully assigned s14-issues/report-builder-c4c579bf-6dr7b to devops-hw-worker

$ kubectl -n s14-issues logs deploy/report-builder
building reports

==============================================================
DONE
==============================================================
```
