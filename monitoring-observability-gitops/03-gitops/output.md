# GitOps with Argo CD - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07 (kind cluster `devops-hw`, Kubernetes v1.37.0, Argo CD v3.5.4, Gitea 28.1.0).

## 1. `SHOTS=1 ./run.sh all` - install, repo, app, demo, history

(`SHOTS=1` only adds the two mid-demo screenshots of the Degraded state; their commands print nothing.)

```text

==============================================================
STEP 1 - Install Argo CD v3.5.4 (pinned manifest + kustomize patch) in namespace argocd
==============================================================
namespace/argocd created
objects applied: 59
customresourcedefinition.apiextensions.k8s.io/applications.argoproj.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/applicationsets.argoproj.io serverside-applied
customresourcedefinition.apiextensions.k8s.io/appprojects.argoproj.io serverside-applied
configmap/argocd-cm serverside-applied
Waiting for deployment "argocd-redis" rollout to finish: 0 of 1 updated replicas are available...
deployment "argocd-redis" successfully rolled out
Waiting for deployment "argocd-repo-server" rollout to finish: 0 of 1 updated replicas are available...
deployment "argocd-repo-server" successfully rolled out
Waiting for deployment "argocd-server" rollout to finish: 0 of 1 updated replicas are available...
deployment "argocd-server" successfully rolled out
deployment "argocd-dex-server" successfully rolled out
deployment "argocd-applicationset-controller" successfully rolled out
deployment "argocd-notifications-controller" successfully rolled out
partitioned roll out complete: 1 new pods have been updated...

NAME                                                READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                     1/1     Running   0          44s
argocd-applicationset-controller-76fd8cdd4f-f92l2   1/1     Running   0          46s
argocd-dex-server-66c78cf887-lxv2f                  1/1     Running   0          46s
argocd-notifications-controller-7fb9868fd6-m6x2v    1/1     Running   0          46s
argocd-redis-bdbdffcb4-6sshc                        1/1     Running   0          45s
argocd-repo-server-d89c7967d-hvbqx                  1/1     Running   0          44s
argocd-server-776b7cdd4d-sclg8                      1/1     Running   0          44s

--- argocd-cm (reconciliation settings from the kustomize patch) ---
timeout.reconciliation=60s  timeout.reconciliation.jitter=0s
--- image actually running ---
quay.io/argoproj/argocd:v3.5.4

==============================================================
STEP 2 - Install the Git server (Gitea, SQLite) in namespace git-server
==============================================================
namespace/git-server created
persistentvolumeclaim/gitea-data created
deployment.apps/gitea created
service/gitea created
Waiting for deployment "gitea" rollout to finish: 0 of 1 updated replicas are available...
deployment "gitea" successfully rolled out
NAME                         READY   STATUS    RESTARTS   AGE
pod/gitea-768bf475f5-m7gq6   1/1     Running   0          15s

NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/gitea   ClusterIP   10.96.156.107   <none>        3000/TCP   15s

NAME                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/gitea-data   Bound    pvc-24cfc184-a70d-4732-8f0f-3c9b07b0f7e4   1Gi        RWO            standard       <unset>                 15s

--- create the demo Git user (admin of this Gitea only) ---
2026/10/07 18:09:06 modules/setting/setting.go:133:loadCommonSettingsFrom() [W] [security] ALLOWED_HOST_LIST only restricts private hosts in the default lax mode, set EGRESS_MODE = strict to allow only the listed hosts, or lax to keep this
New user 'gitops' has been successfully created!
gitea version 28.1.0 built with go1.27.1 : bindata, timetzdata, 

==============================================================
STEP 3 - Create the GitOps repo in Gitea (the source of truth)
==============================================================
{
  "full_name": "gitops/gitops-demo",
  "private": false,
  "default_branch": "main",
  "clone_url": "http://localhost:13300/gitops/gitops-demo.git"
}

==============================================================
STEP 4 - Push the manifests (gitops-repo/app) as the first commit
==============================================================
pushed bf5094d  Initial commit: web v1, 2 replicas, nginx 1.28.0

app/configmap.yaml
app/deployment.yaml
app/service.yaml

--- what Gitea now holds ---
bf5094d7198f057b800117672029e83cec40b9ca	HEAD
bf5094d7198f057b800117672029e83cec40b9ca	refs/heads/main
  app/configmap.yaml  257 bytes
  app/deployment.yaml  1209 bytes
  app/service.yaml  207 bytes
'admin:login' logged in successfully
Context 'localhost:18443' updated

==============================================================
STEP 5 - Create the Argo CD Application (automated sync + prune + selfHeal)
==============================================================
application.argoproj.io/gitops-demo created
synced to Git HEAD bf5094d after 4s
Healthy after 6s total

APP           SYNC     HEALTH    REVISION
gitops-demo   Synced   Healthy   bf5094d7198f057b800117672029e83cec40b9ca

Name:               argocd/gitops-demo
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          gitops-demo
URL:                https://localhost:18443/applications/gitops-demo
Source:
- Repo:             http://gitea.git-server.svc.cluster.local:3000/gitops/gitops-demo.git
  Target:           main
  Path:             app
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune)
Sync Status:        Synced to main (bf5094d)
Health Status:      Healthy

GROUP  KIND        NAMESPACE    NAME         STATUS  HEALTH   HOOK  MESSAGE
apps   Deployment  gitops-demo  web          Synced  Healthy        deployment.apps/web unchanged
       ConfigMap   gitops-demo  web-content  Synced                 
       Service     gitops-demo  web          Synced  Healthy        

--- what Argo CD created (nobody ran kubectl apply on these) ---
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                SELECTOR
deployment.apps/web   2/2     2            2           3s    nginx        nginx:1.28.0-alpine   app.kubernetes.io/name=web

NAME                             DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                SELECTOR
replicaset.apps/web-85cb8cb6d7   2         2         2       3s    nginx        nginx:1.28.0-alpine   app.kubernetes.io/name=web,pod-template-hash=85cb8cb6d7

NAME                       READY   STATUS    RESTARTS   AGE   IP             NODE                NOMINATED NODE   READINESS GATES
pod/web-85cb8cb6d7-gcjs6   1/1     Running   0          3s    10.244.1.183   devops-hw-worker2   <none>           <none>
pod/web-85cb8cb6d7-qvx4w   1/1     Running   0          3s    10.244.2.216   devops-hw-worker    <none>           <none>

NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE   SELECTOR
service/web   ClusterIP   10.96.170.168   <none>        80/TCP    3s    app.kubernetes.io/name=web

NAME                    DATA   AGE
configmap/web-content   1      3s

page served: gitops-demo version=v1 message="hello from git"

==============================================================
STEP 6 - Git change #1 (replicas 2 -> 3), NO webhook: Argo CD finds it by polling
==============================================================
timeout.reconciliation = 60s, so the controller re-reads Git at most this often
 app/deployment.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
pushed 01f5d2e  Scale web to 3 replicas
Argo CD synced 01f5d2e  82s after git push   (polling)
rollout complete            97s after git push
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
web    3/3     3            3           103s

--- application-controller log: the periodic refresh that picked it up ---
2026-10-07T18:10:21Z  Refreshing app status (comparison expired, requesting refresh. reconciledAt: 2026-10-07 18:09:18 +0000 UTC, expiry: 1m0s), level (2)

==============================================================
STEP 7 - Add a Gitea push webhook -> Argo CD, so Git tells Argo CD immediately
==============================================================
secret/argocd-secret patched
{
  "id": 1,
  "type": "gitea",
  "active": true,
  "events": [
    "push"
  ],
  "url": "https://argocd-server.argocd.svc.cluster.local/api/webhook"
}

==============================================================
STEP 8 - Git change #2 (new image + new page content), WITH webhook
==============================================================
-    gitops-demo version=v1 message="hello from git"
+    gitops-demo version=v2 message="changed by a git commit"
-        gitops-demo/config-version: "v1"
+        gitops-demo/config-version: "v2"
-          image: nginx:1.28.0-alpine
+          image: nginx:1.29.0-alpine
pushed 13438cf  Upgrade nginx to 1.29.0 and publish page v2
Argo CD synced 13438cf  12s after git push   (webhook)
rollout complete            49s after git push
POD                    IMAGE                 READY
web-75d98ff5cf-6xlzz   nginx:1.29.0-alpine   true
web-75d98ff5cf-w6d44   nginx:1.29.0-alpine   true
web-75d98ff5cf-wfb7t   nginx:1.29.0-alpine   true
page served: gitops-demo version=v2 message="changed by a git commit"

--- argocd-server log: the webhook arriving ---
{"app-namespace":"argocd","application":"gitops-demo","level":"info","msg":"refreshing app from webhook","project":"default","time":"2026-10-07T18:11:20Z"}
{"level":"info","msg":"Requested app 'gitops-demo' refresh","time":"2026-10-07T18:11:20Z"}
{"level":"info","msg":"Requested app 'gitops-demo' refresh","time":"2026-10-07T18:11:20Z"}

==============================================================
STEP 9 - Drift #1: someone runs 'kubectl scale' by hand (Git says 3)
==============================================================
deployment.apps/web scaled
spec.replicas right after the manual change: 6
self-heal put it back to 3 after 6s
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
web    3/3     3            3           3m8s

--- Deployment events: scaled to 6 by hand, back to 3 by Argo CD ---
ScalingReplicaSet   Scaled up replica set web-75d98ff5cf from 3 to 6
ScalingReplicaSet   (combined from similar events): Scaled down replica set web-75d98ff5cf from 6 to 3

==============================================================
STEP 10 - Drift #2: someone edits the live ConfigMap by hand
==============================================================
configmap/web-content patched
live ConfigMap now: hot-fixed by hand in production
self-heal restored the Git version after 3s
live ConfigMap now: gitops-demo version=v2 message="changed by a git commit"

==============================================================
STEP 11 - Drift #3: someone deletes the Service
==============================================================
Service UID before: 569ca6cc-7e39-432c-9408-0dba9adf7c2f
service "web" deleted from gitops-demo namespace
Service re-created by Argo CD after 6s
Service UID after:  0be7be09-a887-4f3b-9045-939f37477a68   <- a new object

--- Argo CD events: every self-heal is a normal sync it started itself ---
OperationCompleted   Sync operation to 13438cf17c845018c68b745941ee3ed20090efac succeeded
OperationStarted     Initiated automated sync to '13438cf17c845018c68b745941ee3ed20090efac'
OperationCompleted   Partial sync operation to 13438cf17c845018c68b745941ee3ed20090efac succeeded
OperationStarted     Initiated automated sync to '13438cf17c845018c68b745941ee3ed20090efac'
OperationCompleted   Partial sync operation to 13438cf17c845018c68b745941ee3ed20090efac succeeded
OperationStarted     Initiated automated sync to '13438cf17c845018c68b745941ee3ed20090efac'
OperationCompleted   Partial sync operation to 13438cf17c845018c68b745941ee3ed20090efac succeeded

==============================================================
STEP 12 - A bad commit: typo in the image tag
==============================================================
-          image: nginx:1.29.0-alpine
+          image: nginx:1.29.0-alpne
pushed 3e53611  Bump nginx image (typo)
Argo CD synced the bad commit 3e53611 after 12s - Git is the truth, even when wrong
waiting for the Deployment's progressDeadlineSeconds (60s) to expire ...
app health is Degraded 71s after the push
APP           SYNC     HEALTH     REVISION
gitops-demo   Synced   Degraded   3e53611a72943470668b88a216a794eea756e67d

POD                    IMAGE                 READY   WAITING
web-58b8cb554b-db8cr   nginx:1.29.0-alpne    false   ImagePullBackOff
web-75d98ff5cf-6xlzz   nginx:1.29.0-alpine   true    <none>
web-75d98ff5cf-w6d44   nginx:1.29.0-alpine   true    <none>
web-75d98ff5cf-wfb7t   nginx:1.29.0-alpine   true    <none>

old pods are still serving (rolling update never removed them): gitops-demo version=v2 message="changed by a git commit"

==============================================================
STEP 13 - Roll back the GitOps way: git revert, not kubectl
==============================================================
pushed af85b3a  Revert "Bump nginx image (typo)"
Argo CD synced the revert af85b3a after 4s
app Healthy again 4s after the push
APP           SYNC     HEALTH    REVISION
gitops-demo   Synced   Healthy   af85b3a5b439a7b299b5f040430657fa674c326b
POD                    IMAGE                 READY
web-58b8cb554b-db8cr   nginx:1.29.0-alpne    false
web-75d98ff5cf-6xlzz   nginx:1.29.0-alpine   true
web-75d98ff5cf-w6d44   nginx:1.29.0-alpine   true
web-75d98ff5cf-wfb7t   nginx:1.29.0-alpine   true

==============================================================
STEP 14 - Prune: a resource removed from Git is removed from the cluster
==============================================================
pushed 6c64d4a  Add feature-flags ConfigMap
feature-flags created 2s after the push
pushed 2e677a7  Remove feature-flags ConfigMap (no longer used)
feature-flags pruned  4s after the push
NAME               DATA   AGE
kube-root-ca.crt   1      5m6s
web-content        1      5m6s

==============================================================
STEP 15 - History: Git log vs what Argo CD deployed
==============================================================
--- git log (the source of truth) ---
2e677a7  Remove feature-flags ConfigMap (no longer used)
6c64d4a  Add feature-flags ConfigMap
af85b3a  Revert "Bump nginx image (typo)"
3e53611  Bump nginx image (typo)
13438cf  Upgrade nginx to 1.29.0 and publish page v2
01f5d2e  Scale web to 3 replicas
bf5094d  Initial commit: web v1, 2 replicas, nginx 1.28.0

--- argocd app history (every revision Argo CD synced) ---
SOURCE  http://gitea.git-server.svc.cluster.local:3000/gitops/gitops-demo.git
ID      DATE                           REVISION
0       2026-10-07 23:39:17 +0530 IST  main (bf5094d)
1       2026-10-07 23:40:41 +0530 IST  main (01f5d2e)
2       2026-10-07 23:41:27 +0530 IST  main (13438cf)
3       2026-10-07 23:42:48 +0530 IST  main (3e53611)
4       2026-10-07 23:44:11 +0530 IST  main (af85b3a)
5       2026-10-07 23:44:16 +0530 IST  main (6c64d4a)
6       2026-10-07 23:44:23 +0530 IST  main (2e677a7)

--- argocd app get ---
Name:               argocd/gitops-demo
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          gitops-demo
URL:                https://localhost:18443/applications/gitops-demo
Source:
- Repo:             http://gitea.git-server.svc.cluster.local:3000/gitops/gitops-demo.git
  Target:           main
  Path:             app
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune)
Sync Status:        Synced to main (2e677a7)
Health Status:      Healthy

GROUP  KIND        NAMESPACE    NAME           STATUS     HEALTH   HOOK  MESSAGE
       ConfigMap   gitops-demo  feature-flags  Succeeded  Pruned         pruned
       ConfigMap   gitops-demo  web-content    Synced                    configmap/web-content unchanged
       Service     gitops-demo  web            Synced     Healthy        service/web unchanged
apps   Deployment  gitops-demo  web            Synced     Healthy        deployment.apps/web unchanged

--- rollback through Argo CD is refused while auto-sync is on ---
{"level":"fatal","msg":"rpc error: code = FailedPrecondition desc = rollback cannot be initiated when auto-sync is enabled","time":"2026-10-07T23:44:26+05:30"}
```

## 2. `./run.sh cleanup` - remove the demo Application, keep Argo CD and Gitea

```text

==============================================================
CLEANUP - delete the demo Application (its finalizer deletes what it created)
==============================================================
--- before: resources owned by the Application ---
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   3/3     3            3           7m31s

NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/web   ClusterIP   10.96.53.242   <none>        80/TCP    4m14s

NAME                    DATA   AGE
configmap/web-content   1      7m31s

application.argoproj.io "gitops-demo" deleted from argocd namespace
namespace "gitops-demo" deleted

namespace gitops-demo: Error from server (NotFound): namespaces "gitops-demo" not found

--- still installed for later sessions ---
NAME                                                READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                     1/1     Running   0          8m50s
argocd-applicationset-controller-76fd8cdd4f-f92l2   1/1     Running   0          8m52s
argocd-dex-server-66c78cf887-lxv2f                  1/1     Running   0          8m52s
argocd-notifications-controller-7fb9868fd6-m6x2v    1/1     Running   0          8m52s
argocd-redis-bdbdffcb4-6sshc                        1/1     Running   0          8m51s
argocd-repo-server-d89c7967d-hvbqx                  1/1     Running   0          8m50s
argocd-server-776b7cdd4d-sclg8                      1/1     Running   0          8m50s

NAME                     READY   STATUS    RESTARTS   AGE
gitea-768bf475f5-m7gq6   1/1     Running   0          8m5s

No resources found in argocd namespace.
```

## 3. Finalizer check - `./run.sh app` then `./run.sh cleanup` again

The first cleanup deleted the namespace straight after the Application, which does not prove the
finalizer did anything. So the app was created once more from the same Git HEAD and cleanup was re-run
with an extra line that counts what is left after deleting only the Application.

```text
'admin:login' logged in successfully
Context 'localhost:18443' updated

==============================================================
STEP 5 - Create the Argo CD Application (automated sync + prune + selfHeal)
==============================================================
application.argoproj.io/gitops-demo created
synced to Git HEAD 2e677a7 after 3s
Healthy after 5s total

APP           SYNC     HEALTH    REVISION
gitops-demo   Synced   Healthy   2e677a7c65987011ef22fbfde390a27e11fb7005

Name:               argocd/gitops-demo
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          gitops-demo
URL:                https://localhost:18443/applications/gitops-demo
Source:
- Repo:             http://gitea.git-server.svc.cluster.local:3000/gitops/gitops-demo.git
  Target:           main
  Path:             app
SyncWindow:         Sync Allowed
Sync Policy:        Automated (Prune)
Sync Status:        Synced to main (2e677a7)
Health Status:      Healthy

GROUP  KIND        NAMESPACE    NAME         STATUS   HEALTH   HOOK  MESSAGE
       Namespace                gitops-demo  Running  Synced         namespace/gitops-demo created
       ConfigMap   gitops-demo  web-content  Synced                  configmap/web-content created
       Service     gitops-demo  web          Synced   Healthy        service/web created
apps   Deployment  gitops-demo  web          Synced   Healthy        deployment.apps/web created

--- what Argo CD created (nobody ran kubectl apply on these) ---
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                SELECTOR
deployment.apps/web   3/3     3            3           6s    nginx        nginx:1.29.0-alpine   app.kubernetes.io/name=web

NAME                             DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                SELECTOR
replicaset.apps/web-75d98ff5cf   3         3         3       6s    nginx        nginx:1.29.0-alpine   app.kubernetes.io/name=web,pod-template-hash=75d98ff5cf

NAME                       READY   STATUS    RESTARTS   AGE   IP             NODE                NOMINATED NODE   READINESS GATES
pod/web-75d98ff5cf-7zrmd   1/1     Running   0          6s    10.244.2.8     devops-hw-worker    <none>           <none>
pod/web-75d98ff5cf-b569r   1/1     Running   0          6s    10.244.2.9     devops-hw-worker    <none>           <none>
pod/web-75d98ff5cf-tj22s   1/1     Running   0          6s    10.244.1.225   devops-hw-worker2   <none>           <none>

NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE   SELECTOR
service/web   ClusterIP   10.96.122.65   <none>        80/TCP    6s    app.kubernetes.io/name=web

NAME                    DATA   AGE
configmap/web-content   1      7s

page served: gitops-demo version=v2 message="changed by a git commit"


==============================================================
CLEANUP - delete the demo Application (its finalizer deletes what it created)
==============================================================
--- before: resources owned by the Application ---
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   3/3     3            3           7s

NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/web   ClusterIP   10.96.122.65   <none>        80/TCP    7s

NAME                    DATA   AGE
configmap/web-content   1      8s

application.argoproj.io "gitops-demo" deleted from argocd namespace
left in gitops-demo after deleting only the Application: 0 objects
namespace "gitops-demo" deleted

namespace gitops-demo: Error from server (NotFound): namespaces "gitops-demo" not found

--- still installed for later sessions ---
NAME                                                READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                     1/1     Running   0          10m
argocd-applicationset-controller-76fd8cdd4f-f92l2   1/1     Running   0          10m
argocd-dex-server-66c78cf887-lxv2f                  1/1     Running   0          10m
argocd-notifications-controller-7fb9868fd6-m6x2v    1/1     Running   0          10m
argocd-redis-bdbdffcb4-6sshc                        1/1     Running   0          10m
argocd-repo-server-d89c7967d-hvbqx                  1/1     Running   0          10m
argocd-server-776b7cdd4d-sclg8                      1/1     Running   0          10m

NAME                     READY   STATUS    RESTARTS   AGE
gitea-768bf475f5-m7gq6   1/1     Running   0          9m21s

No resources found in argocd namespace.
```
