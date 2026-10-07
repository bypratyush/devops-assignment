# Object comparison - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
SETUP - a Deployment, a DaemonSet and a StatefulSet in namespace s11-compare
==============================================================
namespace/s11-compare created
deployment.apps/web created
daemonset.apps/node-agent created
service/db created
statefulset.apps/db created
pod/client created
Waiting for deployment "web" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "web" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "web" rollout to finish: 2 of 3 updated replicas are available...
deployment "web" successfully rolled out
Waiting for daemon set "node-agent" rollout to finish: 0 of 3 updated pods are available...
Waiting for daemon set "node-agent" rollout to finish: 1 of 3 updated pods are available...
Waiting for daemon set "node-agent" rollout to finish: 2 of 3 updated pods are available...
daemon set "node-agent" successfully rolled out
Waiting for 3 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 1 pods to be ready...
Waiting for 1 pods to be ready...
partitioned roll out complete: 3 new pods have been updated...
pod/client condition met

==============================================================
A1. Deployment -> ReplicaSet -> Pod: the ownership chain
==============================================================
NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/web-646b7f45dd   3         3         3       13s

NAME                       READY   STATUS    RESTARTS   AGE
pod/web-646b7f45dd-gfffc   1/1     Running   0          13s
pod/web-646b7f45dd-gqxx2   1/1     Running   0          13s
pod/web-646b7f45dd-jsfw5   1/1     Running   0          13s

--- who owns whom (metadata.ownerReferences) ---
KIND         NAME                   OWNER-KIND   OWNER
ReplicaSet   web-646b7f45dd         Deployment   web
Pod          web-646b7f45dd-gfffc   ReplicaSet   web-646b7f45dd
Pod          web-646b7f45dd-gqxx2   ReplicaSet   web-646b7f45dd
Pod          web-646b7f45dd-jsfw5   ReplicaSet   web-646b7f45dd

  The Deployment has no owner. It owns one ReplicaSet; the ReplicaSet owns the pods.
  Nobody creates the ReplicaSet by hand - the Deployment controller does.

==============================================================
A2. The pod-template-hash label ties the levels together
==============================================================
  ReplicaSet name : web-646b7f45dd   (= <deployment>-<pod-template-hash>)
  RS selector     : {"app":"web","pod-template-hash":"646b7f45dd"}
  pod web-646b7f45dd-gfffc  labels={"app":"web","pod-template-hash":"646b7f45dd"}
  pod web-646b7f45dd-gqxx2  labels={"app":"web","pod-template-hash":"646b7f45dd"}
  pod web-646b7f45dd-jsfw5  labels={"app":"web","pod-template-hash":"646b7f45dd"}

==============================================================
A3. Scaling: you scale the Deployment, it rewrites the ReplicaSet
==============================================================
$ kubectl scale deployment web --replicas=5
deployment.apps/web scaled
NAME             DESIRED   CURRENT   READY   AGE
web-646b7f45dd   5         5         5       15s

--- now scale the ReplicaSet DIRECTLY to 1, behind the Deployment's back ---
$ kubectl scale rs web-646b7f45dd --replicas=1
replicaset.apps/web-646b7f45dd scaled
NAME             DESIRED   CURRENT   READY   AGE
web-646b7f45dd   5         5         5       18s

NAME                   READY   STATUS    RESTARTS   AGE
web-646b7f45dd-5gqcq   1/1     Running   0          3s
web-646b7f45dd-bnqfb   1/1     Running   0          3s
web-646b7f45dd-clv9t   1/1     Running   0          3s
web-646b7f45dd-g8djp   1/1     Running   0          3s
web-646b7f45dd-jsfw5   1/1     Running   0          18s

  DESIRED is back to 5: the Deployment owns the ReplicaSet's spec.replicas and
  reconciled it. But look at the pod AGEs: in those 3 seconds the ReplicaSet
  really did delete 4 pods and the Deployment made it start 4 new ones.
  Editing the ReplicaSet does not stick, and it is not harmless either.
  (scaled back to 3)

==============================================================
A4. Rolling update: a NEW ReplicaSet per pod template
==============================================================
$ kubectl set image deployment/web nginx=nginx:1.27-alpine
deployment.apps/web image updated
Waiting for deployment "web" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "web" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "web" rollout to finish: 1 old replicas are pending termination...
deployment "web" successfully rolled out

NAME             DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES              SELECTOR
web-5c6f4bf8d6   3         3         3       3s    nginx        nginx:1.27-alpine   app=web,pod-template-hash=5c6f4bf8d6
web-646b7f45dd   0         0         0       24s   nginx        nginx:1.25-alpine   app=web,pod-template-hash=646b7f45dd

  Two ReplicaSets now: the new one at 3, the old one kept at 0 for rollback.
  A ReplicaSet on its own cannot do this - changing its template updates nothing
  that is already running.

--- rollout history ---
deployment.apps/web 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>


--- the pods now belong to the NEW ReplicaSet ---
KIND   NAME                   OWNER-KIND   OWNER
Pod    web-5c6f4bf8d6-fsmxg   ReplicaSet   web-5c6f4bf8d6
Pod    web-5c6f4bf8d6-lnbqr   ReplicaSet   web-5c6f4bf8d6
Pod    web-5c6f4bf8d6-tvktp   ReplicaSet   web-5c6f4bf8d6

==============================================================
A5. Self-healing is the ReplicaSet's job
==============================================================
$ kubectl delete pod web-5c6f4bf8d6-fsmxg
pod "web-5c6f4bf8d6-fsmxg" deleted from s11-compare namespace
KIND   NAME                   OWNER-KIND   OWNER
Pod    web-5c6f4bf8d6-lnbqr   ReplicaSet   web-5c6f4bf8d6
Pod    web-5c6f4bf8d6-tvktp   ReplicaSet   web-5c6f4bf8d6
Pod    web-5c6f4bf8d6-wkr8s   ReplicaSet   web-5c6f4bf8d6

  The replacement is owned by the ReplicaSet, not the Deployment: the RS noticed
  3 desired / 2 actual and created one. The Deployment only manages RS objects.

==============================================================
B1. Pod NAMES and PLACEMENT tell you which controller made them
==============================================================
NAME                   READY   STATUS    RESTARTS   AGE   IP             NODE                      NOMINATED NODE   READINESS GATES
db-0                   1/1     Running   0          25s   10.244.2.176   devops-hw-worker          <none>           <none>
db-1                   1/1     Running   0          21s   10.244.1.148   devops-hw-worker2         <none>           <none>
db-2                   1/1     Running   0          16s   10.244.2.179   devops-hw-worker          <none>           <none>
node-agent-7lfrd       1/1     Running   0          25s   10.244.1.146   devops-hw-worker2         <none>           <none>
node-agent-hg72f       1/1     Running   0          25s   10.244.0.9     devops-hw-control-plane   <none>           <none>
node-agent-mnp6n       1/1     Running   0          25s   10.244.2.173   devops-hw-worker          <none>           <none>
web-5c6f4bf8d6-lnbqr   1/1     Running   0          3s    10.244.2.185   devops-hw-worker          <none>           <none>
web-5c6f4bf8d6-tvktp   1/1     Running   0          4s    10.244.1.151   devops-hw-worker2         <none>           <none>
web-5c6f4bf8d6-wkr8s   1/1     Running   0          1s    10.244.2.186   devops-hw-worker          <none>           <none>

  web-<rs-hash>-<random>  Deployment : random names, scheduler picks the nodes
  node-agent-<random>     DaemonSet  : exactly one per node, no replicas field
  db-0, db-1, db-2        StatefulSet: ordinal names that never change

==============================================================
B2. DaemonSet: one per node, and it cannot be 'scaled'
==============================================================
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-agent   3         3         3       3            3           <none>          25s

  devops-hw-control-plane    node-agent pods: 1
  devops-hw-worker           node-agent pods: 1
  devops-hw-worker2          node-agent pods: 1

$ kubectl scale daemonset node-agent --replicas=5
  Error from server (NotFound): the server could not find the requested resource

  NotFound = the DaemonSet API has no /scale subresource at all. The node count
  IS the replica count: add a node and a pod appears on it.
  (Narrow it with a nodeSelector/affinity, widen it with tolerations.)

==============================================================
B3. StatefulSet: created in order, one at a time
==============================================================
NAME   CREATED                NODE
db-0   2026-10-07T18:03:09Z   devops-hw-worker
db-1   2026-10-07T18:03:13Z   devops-hw-worker2
db-2   2026-10-07T18:03:18Z   devops-hw-worker

  db-1 is not created until db-0 is Running and Ready, db-2 waits for db-1.
  A Deployment creates all its pods at once.

==============================================================
B4. StatefulSet storage: one PVC per pod, and it follows the pod
==============================================================
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
data-db-0   Bound    pvc-0f89fde1-6987-43e0-b275-1509b0eef787   64Mi       RWO            standard       <unset>                 25s
data-db-1   Bound    pvc-3cbfcf16-2295-444f-b4c2-fbde56876a09   64Mi       RWO            standard       <unset>                 21s
data-db-2   Bound    pvc-b2b0da62-4bf3-475a-af0c-d9c8882fead8   64Mi       RWO            standard       <unset>                 16s

  volumeClaimTemplates gave each pod its OWN claim: data-db-0, data-db-1, data-db-2.
  A Deployment's pods would all share whatever single claim the template names.

--- write something into db-0's volume, then delete the pod ---
written by db-0 at 18:03:35
pod "db-0" deleted from s11-compare namespace

  before: db-0  ip=10.244.2.176  node=devops-hw-worker
  after : db-0  ip=10.244.2.188  node=devops-hw-worker  claim=data-db-0
  file  : written by db-0 at 18:03:35

  Same name, same claim, same data. (Same node too: local-path volumes live on one
  node's disk, so the PV's nodeAffinity pins the pod there.)

--- the same experiment on a Deployment pod ---
written by web-5c6f4bf8d6-lnbqr
  deleted web-5c6f4bf8d6-lnbqr, replacement is web-5c6f4bf8d6-xtjp2 (a new random name)
  file  : cat: can't open '/tmp/identity.txt': No such file or directory
command terminated with exit code 1

==============================================================
B5. StatefulSet scale-down keeps the storage
==============================================================
$ kubectl scale statefulset db --replicas=2
statefulset.apps/db scaled
NAME   READY   STATUS    RESTARTS   AGE
db-0   1/1     Running   0          4s
db-1   1/1     Running   0          27s

NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
data-db-0   Bound    pvc-0f89fde1-6987-43e0-b275-1509b0eef787   64Mi       RWO            standard       <unset>                 31s
data-db-1   Bound    pvc-3cbfcf16-2295-444f-b4c2-fbde56876a09   64Mi       RWO            standard       <unset>                 27s
data-db-2   Bound    pvc-b2b0da62-4bf3-475a-af0c-d9c8882fead8   64Mi       RWO            standard       <unset>                 22s

  db-2 is gone (highest ordinal first) but data-db-2 is still Bound. Kubernetes
  never deletes StatefulSet data on scale-down; scaling back up re-attaches it.
  scaled back to 3: db-2 uses claim data-db-2

==============================================================
B6. Networking: per-pod DNS names only for the StatefulSet
==============================================================
  db-0.db.s11-compare.svc.cluster.local -> 10.244.2.188
  db-1.db.s11-compare.svc.cluster.local -> 10.244.1.148
  db-2.db.s11-compare.svc.cluster.local -> 10.244.2.190

  Through the headless Service 'db' every StatefulSet pod is addressable by name.
  Deployment pods only get reached through a normal Service (Part C).
  DaemonSet pods are usually reached per node (hostPort/hostNetwork) or not at all.

==============================================================
C1. Add a Service in front of the Deployment's pods
==============================================================
service/web created
pod/stray-web created
NAME   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE   SELECTOR
web    ClusterIP   10.96.99.252   <none>        80/TCP    4s    app=web

  10.244.1.151  ready=true  pod=web-5c6f4bf8d6-tvktp
  10.244.2.189  ready=true  pod=web-5c6f4bf8d6-xtjp2
  10.244.2.186  ready=true  pod=web-5c6f4bf8d6-wkr8s
  10.244.1.153  ready=true  pod=stray-web

NAME             DESIRED   CURRENT   READY   AGE
web-5c6f4bf8d6   3         3         3       15s
web-646b7f45dd   0         0         0       36s

  The Service has 4 endpoints; the ReplicaSet manages 3 pods. stray-web is a bare
  pod carrying app=web: the Service selects it (selector app=web), the ReplicaSet
  does not (its selector also needs pod-template-hash). Two independent label queries.

==============================================================
C2. Neither object knows the other exists
==============================================================
  Service web    ownerReferences: ''   selector: {"app":"web"}
  ReplicaSet web-5c6f4bf8d6  mentions a Service? 0 times

  ReplicaSet = keep N copies alive.  Service = give them one stable address.

==============================================================
C3. Pods are replaced: their IPs change, the ClusterIP does not
==============================================================

--- before ---
  ClusterIP: 10.96.99.252
  stray-web              10.244.1.153
  web-5c6f4bf8d6-tvktp   10.244.1.151
  web-5c6f4bf8d6-wkr8s   10.244.2.186
  web-5c6f4bf8d6-xtjp2   10.244.2.189

$ kubectl delete pods -l app=web,pod-template-hash    (every ReplicaSet pod at once)
pod "web-5c6f4bf8d6-tvktp" deleted from s11-compare namespace
pod "web-5c6f4bf8d6-wkr8s" deleted from s11-compare namespace
pod "web-5c6f4bf8d6-xtjp2" deleted from s11-compare namespace

--- after ---
  ClusterIP: 10.96.99.252
  stray-web              10.244.1.153
  web-5c6f4bf8d6-n9qmf   10.244.1.154
  web-5c6f4bf8d6-qlbfk   10.244.2.191
  web-5c6f4bf8d6-sn2qd   10.244.2.192

--- the EndpointSlice was rewritten by the endpointslice controller ---
  10.244.1.153  ready=true  pod=stray-web
  10.244.2.191  ready=true  pod=web-5c6f4bf8d6-qlbfk
  10.244.2.192  ready=true  pod=web-5c6f4bf8d6-sn2qd
  10.244.1.154  ready=true  pod=web-5c6f4bf8d6-n9qmf

--- and clients never noticed ---
  http://web -> HTTP 200  (served by 10.96.99.252:80, the VIP)
  http://web -> HTTP 200  (served by 10.96.99.252:80, the VIP)
  http://web -> HTTP 200  (served by 10.96.99.252:80, the VIP)

==============================================================
C4. How a request actually reaches a pod
==============================================================
1) DNS: the name resolves to the ClusterIP, never to a pod
  Name:	web.s11-compare.svc.cluster.local
  Address: 10.96.99.252

2) kube-proxy turned the Service + EndpointSlice into iptables NAT rules on EVERY node.
   On devops-hw-worker (read-only iptables-save):
  -A KUBE-SEP-CISMZ23HQSZ6RDHC -p tcp -m comment --comment "s11-compare/web" -m tcp -j DNAT --to-destination 10.244.2.192:80
  -A KUBE-SEP-GGPFKOT3GZQELAAZ -p tcp -m comment --comment "s11-compare/web" -m tcp -j DNAT --to-destination 10.244.1.153:80
  -A KUBE-SEP-U5VXLVRUYKI2MYEE -p tcp -m comment --comment "s11-compare/web" -m tcp -j DNAT --to-destination 10.244.1.154:80
  -A KUBE-SEP-XJO4MPNWJDJWPIW3 -p tcp -m comment --comment "s11-compare/web" -m tcp -j DNAT --to-destination 10.244.2.191:80
  -A KUBE-SERVICES -d 10.96.99.252/32 -p tcp -m comment --comment "s11-compare/web cluster IP" -m tcp --dport 80 -j KUBE-SVC-UOOQVBDHNTKI3TCP
  -A KUBE-SVC-UOOQVBDHNTKI3TCP ! -s 10.244.0.0/16 -d 10.96.99.252/32 -p tcp -m comment --comment "s11-compare/web cluster IP" -m tcp --dport 80 -j KUBE-MARK-MASQ
  -A KUBE-SVC-UOOQVBDHNTKI3TCP -m comment --comment "s11-compare/web -> 10.244.1.153:80" -m statistic --mode random --probability 0.25000000000 -j KUBE-SEP-GGPFKOT3GZQELAAZ
  -A KUBE-SVC-UOOQVBDHNTKI3TCP -m comment --comment "s11-compare/web -> 10.244.1.154:80" -m statistic --mode random --probability 0.33333333349 -j KUBE-SEP-U5VXLVRUYKI2MYEE
  -A KUBE-SVC-UOOQVBDHNTKI3TCP -m comment --comment "s11-compare/web -> 10.244.2.191:80" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-XJO4MPNWJDJWPIW3
  -A KUBE-SVC-UOOQVBDHNTKI3TCP -m comment --comment "s11-compare/web -> 10.244.2.192:80" -j KUBE-SEP-CISMZ23HQSZ6RDHC

3) The packet to 10.96.99.252:80 is DNAT-ed to one pod IP:80, chosen by the 'statistic
   mode random' rules above: 1/4, else 1/3 of the rest, else 1/2, else the last
   one - an even 25% each. KUBE-MARK-MASQ marks off-cluster sources for SNAT.
   The ReplicaSet is not involved anywhere in this path.

==============================================================
DONE
==============================================================
```
