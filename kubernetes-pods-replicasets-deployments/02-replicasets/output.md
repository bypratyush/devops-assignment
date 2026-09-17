# replicasets - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-09-18.

```text

==============================================================
STEP 1 - Create a ReplicaSet with 3 replicas
==============================================================
replicaset.apps/web-rs created
replicaset.apps/web-rs condition met

==============================================================
STEP 2 - The ReplicaSet and the pods it created
==============================================================
NAME     DESIRED   CURRENT   READY   AGE
web-rs   3         3         3       0s

NAME           READY   STATUS    RESTARTS   AGE   IP             NODE                NOMINATED NODE   READINESS GATES
web-rs-cc77p   1/1     Running   0          0s    10.244.2.139   devops-hw-worker    <none>           <none>
web-rs-kjg6d   1/1     Running   0          0s    10.244.1.154   devops-hw-worker2   <none>           <none>
web-rs-t8gf2   1/1     Running   0          0s    10.244.2.140   devops-hw-worker    <none>           <none>

Pod names = <replicaset-name>-<random suffix>. They are interchangeable
and have no stable identity (contrast with a StatefulSet).

==============================================================
STEP 3 - Ownership: each pod records who created it
==============================================================
  web-rs-cc77p  ownedBy=ReplicaSet/web-rs
  web-rs-kjg6d  ownedBy=ReplicaSet/web-rs
  web-rs-t8gf2  ownedBy=ReplicaSet/web-rs

This ownerReference is how garbage collection works: delete the
ReplicaSet and the pods it owns are deleted with it.

==============================================================
STEP 4 - SELF-HEALING: delete a pod and watch it come back
==============================================================
before:
  web-rs-cc77p             Running  1s
  web-rs-kjg6d             Running  1s
  web-rs-t8gf2             Running  1s

deleting web-rs-cc77p ...

after:
  web-rs-ghbdt             Running  1s
  web-rs-kjg6d             Running  2s
  web-rs-t8gf2             Running  2s

>>> Still 3 pods. A REPLACEMENT was created automatically (note the new
    name and the very low AGE). This is exactly what a bare Pod could
    not do in task 01.

==============================================================
STEP 5 - Scaling
==============================================================
$ kubectl scale rs/web-rs --replicas=5
NAME     DESIRED   CURRENT   READY   AGE
web-rs   5         5         5       3s
  pods now: 5

$ kubectl scale rs/web-rs --replicas=2
NAME     DESIRED   CURRENT   READY   AGE
web-rs   2         2         2       7s
  pods now: 3
  (restored to 3)

==============================================================
STEP 6 - It selects on LABELS, so it ADOPTS matching stray pods
==============================================================
Deterministic demo: delete the ReplicaSet, create a BARE pod carrying
the label app=web-rs, and only THEN recreate the ReplicaSet.

pod/orphan-pod created

--- before the ReplicaSet exists: one bare pod, owned by nobody ---
  orphan-pod               Running
  ownerReferences: <none>

Now creating the ReplicaSet with replicas=3 ...
replicaset.apps/web-rs created

--- after ---
  orphan-pod               Running   age=2s
  web-rs-8vgxm             Running   age=1s
  web-rs-spxdx             Running   age=1s

--- orphan-pod is still alive, and is now OWNED by the ReplicaSet ---
  orphan-pod ownedBy = ReplicaSet/web-rs

>>> Total pods matching the selector: 3 (not 4).
    The ReplicaSet ADOPTED the existing pod and created only 2 more.

Lesson: a ReplicaSet owns every pod matching its selector, whether or
not it created it. Overlapping selectors between two controllers make
them fight over the same pods - a real and very confusing production bug.

==============================================================
STEP 7 - WHY YOU STILL DON'T USE ReplicaSets DIRECTLY
==============================================================
Current image on the running pods:
  orphan-pod  nginx:1.25-alpine
  web-rs-8vgxm  nginx:1.25-alpine
  web-rs-spxdx  nginx:1.25-alpine

Now change the ReplicaSet's image to nginx:1.27-alpine:

--- the ReplicaSet template says: ---
  template image: nginx:1.27-alpine

--- but the RUNNING PODS still say: ---
  orphan-pod  nginx:1.25-alpine
  web-rs-8vgxm  nginx:1.25-alpine
  web-rs-spxdx  nginx:1.25-alpine

>>> NOTHING WAS UPDATED. A ReplicaSet only guarantees the COUNT of pods,
    not their content. The new image is used only when a pod happens to
    be recreated - so your fleet ends up in a mixed, unpredictable state.

There is no rollout, no rollback, no revision history, no controlled
replacement. That gap is precisely what a DEPLOYMENT fills (task 03).

==============================================================
DONE
==============================================================
```
