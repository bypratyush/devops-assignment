# GitOps - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Commands run by hand on 2026-10-07/08 against the kind cluster `devops-hw` (Argo CD 3.5.4, Gitea in `git-server`).

## 1. Helm release handed over to Argo CD

```text
$ helm -n lostfound uninstall lostfound
release "lostfound" uninstalled

$ kubectl -n lostfound get pvc,secret
NAME                                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/data-lostfound-db-0   Bound    pvc-16f7144b-7b95-4970-9793-f9bc78396968   2Gi        RWO            standard       <unset>                 30m

NAME                  TYPE     DATA   AGE
secret/lostfound-db   Opaque   1      30m

$ kubectl apply -f gitops/application-local.yaml
application.argoproj.io/lostfound created

$ kubectl -n argocd get application lostfound
NAME        SYNC STATUS   HEALTH STATUS
lostfound   Synced        Degraded

$ kubectl -n lostfound rollout status deploy/lostfound-backend --timeout=180s
deployment "lostfound-backend" successfully rolled out

$ kubectl -n lostfound get pods,svc,ingress,hpa,servicemonitor
NAME                                     READY   STATUS    RESTARTS   AGE
pod/lostfound-backend-6c5cb5894d-rv65w   1/1     Running   0          22s
pod/lostfound-backend-6c5cb5894d-wdd8q   1/1     Running   0          22s
pod/lostfound-db-0                       1/1     Running   0          22s
pod/lostfound-frontend-74d55b5cf-vwg5k   1/1     Running   0          22s
pod/lostfound-frontend-74d55b5cf-vx9wh   1/1     Running   0          22s

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/lostfound-backend    ClusterIP   10.96.7.69      <none>        8000/TCP   22s
service/lostfound-db         ClusterIP   None            <none>        5432/TCP   22s
service/lostfound-frontend   ClusterIP   10.96.217.239   <none>        80/TCP     22s

NAME                                  CLASS   HOSTS             ADDRESS   PORTS   AGE
ingress.networking.k8s.io/lostfound   nginx   lostfound.local             80      22s

NAME                                                    REFERENCE                      TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/lostfound-backend   Deployment/lostfound-backend   cpu: <unknown>/60%   2         6         2          22s

NAME                                                     AGE
servicemonitor.monitoring.coreos.com/lostfound-backend   22s

$ curl -s -H 'Host: lostfound.local' http://localhost/api/stats
{"total":6,"lost_open":2,"found_open":2,"claimed":1,"closed":1}
```

## 2. A config change through Git

The first wait loop here was wrong: it waited for `status.sync.revision` (the revision Argo CD has *compared*), so it reported success while the app was still OutOfSync. The second block waits for the sync operation itself.

```text
$ curl -s -H 'Host: lostfound.local' http://localhost/api/info
{"app":"Campus Lost & Found","version":"1.0.0","environment":"prod","pod":"lostfound-backend-6c5cb5894d-rv65w","notice":"Help desk is open 9am - 5pm, Block A ground floor"}
$ git diff --stat; git diff | grep '^[-+] '
 final-devops-project/helm/lostfound/values-prod.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
-  campusNotice: "Help desk is open 9am - 5pm, Block A ground floor"
+  campusNotice: "Exam week: help desk open till 8pm, Block A ground floor"

$ git push -q origin main; git log --oneline -1
176c7eb Extend help desk hours notice for exam week

$ kubectl -n argocd annotate application lostfound argocd.argoproj.io/refresh=normal --overwrite
application.argoproj.io/lostfound annotated

Argo CD synced revision 176c7eb after 2s

$ kubectl -n lostfound rollout status deploy/lostfound-backend --timeout=120s
deployment "lostfound-backend" successfully rolled out

rollout finished 2s after the push

$ curl -s -H 'Host: lostfound.local' http://localhost/api/info
{"app":"Campus Lost & Found","version":"1.0.0","environment":"prod","pod":"lostfound-backend-6c5cb5894d-wxnbm","notice":"Help desk is open 9am - 5pm, Block A ground floor"}
$ kubectl -n argocd get application lostfound -o custom-columns=SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision
SYNC        HEALTH    REVISION
OutOfSync   Healthy   176c7eb3f9fedd61887fb6bf8cc11b4e3359e1dc


00:15:54  Synced Succeeded 176c7eb3f9fedd61887fb6bf8cc11b4e3359e1dc

$ kubectl -n lostfound rollout status deploy/lostfound-backend --timeout=180s
Waiting for deployment "lostfound-backend" rollout to finish: 2 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 2 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 2 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 3 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 3 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 3 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 3 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 4 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 4 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 4 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 4 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 5 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 5 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 5 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 5 out of 6 new replicas have been updated...
Waiting for deployment "lostfound-backend" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "lostfound-backend" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "lostfound-backend" rollout to finish: 1 old replicas are pending termination...
deployment "lostfound-backend" successfully rolled out

$ kubectl -n argocd get application lostfound -o jsonpath='{.status.operationState.startedAt}  ->  {.status.operationState.finishedAt}  {.status.operationState.message}'
2026-10-07T18:45:42Z  ->  2026-10-07T18:45:45Z  successfully synced (all tasks run)
$ curl -s -H 'Host: lostfound.local' http://localhost/api/info
{"app":"Campus Lost & Found","version":"1.0.0","environment":"prod","pod":"lostfound-backend-67b6959d96-llt2q","notice":"Exam week: help desk open till 8pm, Block A ground floor"}
```
