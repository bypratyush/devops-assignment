# deployments - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-09-18.

```text

==============================================================
STEP 1 - Create the Deployment
==============================================================
deployment.apps/web-deploy created
deployment "web-deploy" successfully rolled out

==============================================================
STEP 2 - THE HIERARCHY: Deployment -> ReplicaSet -> Pods
==============================================================
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
web-deploy   4/4     4            4           4s

NAME                    DESIRED   CURRENT   READY   AGE
web-deploy-65dc5ffbbf   4         4         4       4s

  web-deploy-65dc5ffbbf-5s22q        Running
  web-deploy-65dc5ffbbf-dp447        Running
  web-deploy-65dc5ffbbf-fjpjb        Running
  web-deploy-65dc5ffbbf-z9rz7        Running

You created ONE object. Kubernetes created three levels:
  Deployment  web-deploy               <- you manage this
   |_ ReplicaSet  web-deploy-<hash>    <- created for you, one per revision
       |_ Pods    web-deploy-<hash>-*  <- created by the ReplicaSet

The hash is derived from the POD TEMPLATE. Change the template and you
get a different hash => a NEW ReplicaSet. That is the whole mechanism.

==============================================================
STEP 3 - The rollout a ReplicaSet could not do
==============================================================
Current pods:
  web-deploy-65dc5ffbbf-5s22q        nginx:1.25-alpine      Running
  web-deploy-65dc5ffbbf-dp447        nginx:1.25-alpine      Running
  web-deploy-65dc5ffbbf-fjpjb        nginx:1.25-alpine      Running
  web-deploy-65dc5ffbbf-z9rz7        nginx:1.25-alpine      Running

$ kubectl set image deployment/web-deploy nginx=nginx:1.27-alpine
deployment "web-deploy" successfully rolled out

Pods after the rollout:
  web-deploy-6fc6866f47-4fsvh        nginx:1.27-alpine      Running
  web-deploy-6fc6866f47-5b67d        nginx:1.27-alpine      Running
  web-deploy-6fc6866f47-b222z        nginx:1.27-alpine      Running
  web-deploy-6fc6866f47-kkmwc        nginx:1.27-alpine      Running

>>> EVERY pod is now on 1.27-alpine, replaced gradually with no downtime.
    In task 02 the identical change to a ReplicaSet updated NOTHING.

==============================================================
STEP 4 - Two ReplicaSets now exist: the new one and the old one
==============================================================
NAME                    DESIRED   CURRENT   READY   AGE
web-deploy-65dc5ffbbf   0         0         0       12s
web-deploy-6fc6866f47   4         4         4       8s

The old ReplicaSet is kept at 0 replicas. It is not garbage - it is the
saved previous revision, and it is what makes rollback instant.

==============================================================
STEP 5 - Rollout history
==============================================================
$ kubectl rollout history deployment/web-deploy
deployment.apps/web-deploy 
REVISION  CHANGE-CAUSE
1         initial deploy: nginx 1.25-alpine
2         upgrade nginx to 1.27-alpine


CHANGE-CAUSE comes from the kubernetes.io/change-cause annotation.
It must be set in the SAME patch as the change, or it labels the wrong
revision. Set it on every change or your history is unlabelled numbers.

==============================================================
STEP 6 - A BAD deploy, and rolling back
==============================================================
Deploying a broken image tag on purpose:

Polling for the failure (macOS has no coreutils 'timeout'):
  failing pod: web-deploy-7c4c967f79-rghpp

--- the rollout is stuck ---
  error: timed out waiting for the condition

--- pod states ---
  web-deploy-6fc6866f47-4fsvh        Running
  web-deploy-6fc6866f47-5b67d        Running
  web-deploy-6fc6866f47-kkmwc        Running
  web-deploy-7c4c967f79-rghpp        ErrImagePull
  web-deploy-7c4c967f79-wr2t8        ErrImagePull

--- the reason ---
    Warning  Failed     6s    kubelet            spec.containers{nginx}: Failed to pull image "nginx:1.27-does-not-exist": rpc error: code = NotFound de

>>> CRITICAL: the OLD pods are still Running and still serving traffic.
    maxUnavailable=1 meant the rollout STALLED rather than taking the
    app down. A rolling update protects you from your own bad deploy.

--- rolling back ---
$ kubectl rollout undo deployment/web-deploy
deployment "web-deploy" successfully rolled out

  web-deploy-6fc6866f47-4fsvh        nginx:1.27-alpine      Running
  web-deploy-6fc6866f47-4gwlk        nginx:1.27-alpine      Running
  web-deploy-6fc6866f47-5b67d        nginx:1.27-alpine      Running
  web-deploy-6fc6866f47-kkmwc        nginx:1.27-alpine      Running

>>> Back on 1.27-alpine, the last known-good revision.

==============================================================
STEP 7 - History after the rollback
==============================================================
deployment.apps/web-deploy 
REVISION  CHANGE-CAUSE
1         initial deploy: nginx 1.25-alpine
3         BAD: typo in image tag
4         upgrade nginx to 1.27-alpine


Note the gaps. Revision numbers only ever increase, and when a rollback
REUSES an existing ReplicaSet that ReplicaSet is renumbered to the new
revision - so the number it had before disappears from the list.
The CONTENT is what matters, not the numbering.

Inspect what a revision actually contains before rolling back to it:
$ kubectl rollout history deployment/web-deploy --revision=1
  deployment.apps/web-deploy with revision #1
      Image:	nginx:1.25-alpine

==============================================================
STEP 8 - Scaling
==============================================================
$ kubectl scale deployment/web-deploy --replicas=6
deployment "web-deploy" successfully rolled out
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
web-deploy   6/6     6            6           25s
  (restored to 4)

Other rollout controls:
  kubectl rollout pause deployment/web-deploy    batch several edits, then resume
  kubectl rollout resume deployment/web-deploy
  kubectl rollout restart deployment/web-deploy  recreate all pods without any
                                           spec change (see step 9)

==============================================================
STEP 9 - rollout restart, the one people forget
==============================================================
pods before:
  web-deploy-6fc6866f47-4fsvh
  web-deploy-6fc6866f47-4gwlk
  web-deploy-6fc6866f47-5b67d
  web-deploy-6fc6866f47-hxqj4
deployment "web-deploy" successfully rolled out
pods after:
  web-deploy-78db795557-7gdjl
  web-deploy-78db795557-ddnw6
  web-deploy-78db795557-sbbxs
  web-deploy-78db795557-vbkqm

All pods replaced, same image, no spec change. This is how you make pods
pick up a changed ConfigMap or Secret that is consumed as env vars.

==============================================================
DONE
==============================================================
```
