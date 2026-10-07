# Troubleshooting Challenge - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Commands run by hand on 2026-10-07/08. Each fault is a commit pushed to the in-cluster Gitea that Argo CD synced; `pushsync` = push, ask Argo CD to refresh, wait until the sync operation for that commit has Succeeded.

## Incident 0 - Pod Security (real, found while building)

```text
$ kubectl -n lostfound get pods,statefulset
NAME                                     READY   STATUS             RESTARTS      AGE
pod/lostfound-backend-6c5cb5894d-gz4xb   0/1     CrashLoopBackOff   3 (25s ago)   5m10s
pod/lostfound-backend-6c5cb5894d-lzq7x   0/1     CrashLoopBackOff   3 (20s ago)   5m11s
pod/lostfound-frontend-74d55b5cf-8sj2w   1/1     Running            0             5m11s
pod/lostfound-frontend-74d55b5cf-rfqqd   1/1     Running            0             5m11s

NAME                            READY   AGE
statefulset.apps/lostfound-db   0/1     5m11s

$ kubectl -n lostfound describe statefulset lostfound-db | tail -5
Events:
  Type     Reason            Age                     From                    Message
  ----     ------            ----                    ----                    -------
  Normal   SuccessfulCreate  5m10s                   statefulset-controller  Create Claim data-lostfound-db-0 Pod lostfound-db-0 in StatefulSet lostfound-db success
  Warning  FailedCreate      2m24s (x16 over 5m10s)  statefulset-controller  Create Pod lostfound-db-0 in StatefulSet lostfound-db failed error: pods "lostfound-db-0" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "postgres" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "postgres" must set securityContext.capabilities.drop=["ALL"]), seccompProfile (pod or container "postgres" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")

$ kubectl -n lostfound logs deploy/lostfound-backend --tail=4
Found 2 pods, using pod/lostfound-backend-6c5cb5894d-lzq7x
    raise last_exc
sqlalchemy.exc.OperationalError: (psycopg.OperationalError) failed to resolve host 'lostfound-db': [Errno -2] Name or service not known
(Background on this error at: https://sqlalche.me/e/21/e3q8)
migrations failed after 15 attempts, giving up
```

## Fault 1

```text
################ FAULT 1 - image tag that does not exist ################
$ git log --oneline -1; git show --stat HEAD | tail -2
8dfab38 Release backend and frontend 1.0.1
 final-devops-project/helm/lostfound/values-prod.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

>>> Argo CD synced 8dfab38: successfully synced (all tasks run)

$ kubectl -n argocd get application lostfound -o custom-columns=SYNC:.status.sync.status,HEALTH:.status.health.status
SYNC     HEALTH
Synced   Progressing

$ kubectl -n lostfound get pods
NAME                                 READY   STATUS             RESTARTS   AGE
lostfound-backend-5c96bd94bf-62pqt   0/1     ImagePullBackOff   0          23s
lostfound-backend-67b6959d96-2ffxd   1/1     Running            0          112s
lostfound-backend-67b6959d96-4hn7p   1/1     Running            0          92s
lostfound-backend-67b6959d96-6t4k5   1/1     Running            0          88s
lostfound-backend-67b6959d96-ddcxc   1/1     Running            0          102s
lostfound-backend-67b6959d96-llt2q   1/1     Running            0          95s
lostfound-backend-67b6959d96-pnjct   1/1     Running            0          106s
lostfound-db-0                       1/1     Running            0          4m2s
lostfound-frontend-74d55b5cf-vwg5k   1/1     Running            0          4m2s
lostfound-frontend-74d55b5cf-vx9wh   1/1     Running            0          4m2s
lostfound-frontend-7cf89597d-qq752   0/1     ImagePullBackOff   0          23s

$ curl -s -o /dev/null -w 'site still up? HTTP %{http_code}
' -H 'Host: lostfound.local' http://localhost/api/stats
site still up? HTTP 200

$ kubectl -n lostfound describe pod lostfound-backend-5c96bd94bf-62pqt | sed -n '/^Events:/,$p' | tail -6
  Normal   Scheduled  23s               default-scheduler  Successfully assigned lostfound/lostfound-backend-5c96bd94bf-62pqt to devops-hw-worker2
  Normal   BackOff    19s               kubelet            spec.containers{backend}: Back-off pulling image "ghcr.io/bypratyush/lostfound-backend:1.0.1"
  Warning  Failed     19s               kubelet            spec.containers{backend}: Error: ImagePullBackOff
  Normal   Pulling    6s (x2 over 22s)  kubelet            spec.containers{backend}: Pulling image "ghcr.io/bypratyush/lostfound-backend:1.0.1"
  Warning  Failed     6s (x2 over 19s)  kubelet            spec.containers{backend}: Failed to pull image "ghcr.io/bypratyush/lostfound-backend:1.0.1": failed to pull and unpack image "ghcr.io/bypratyush/lostfound-backend:1.0.1": failed to resolve reference "ghcr.io/bypratyush/lostfound-backend:1.0.1": failed to authorize: failed to fetch anonymous token: unexpected status from GET request to https://ghcr.io/token?scope=repository%3Abypratyush%2Flostfound-backend%3Apull&service=ghcr.io: 403 Forbidden
  Warning  Failed     6s (x2 over 19s)  kubelet            spec.containers{backend}: Error: ErrImagePull

$ kubectl -n lostfound get deploy lostfound-backend -o jsonpath='{.spec.template.spec.containers[0].image}{"
"}'
ghcr.io/bypratyush/lostfound-backend:1.0.1

$ docker exec devops-hw-worker crictl images | grep lostfound
ghcr.io/bypratyush/lostfound-backend                     1.0.0                104cc30454fd8       66.5MB
ghcr.io/bypratyush/lostfound-frontend                    1.0.0                0b4eb816bbd65       23.2MB

---- fix: roll back in Git ----
$ git revert --no-edit HEAD | head -1
[main 7cb3f19] Revert "Release backend and frontend 1.0.1"

>>> Argo CD synced 7cb3f19: successfully synced (all tasks run)

$ kubectl -n lostfound rollout status deploy/lostfound-backend --timeout=120s | tail -1
deployment "lostfound-backend" successfully rolled out

$ kubectl -n lostfound rollout status deploy/lostfound-frontend --timeout=120s | tail -1
deployment "lostfound-frontend" successfully rolled out

$ kubectl -n lostfound get pods
NAME                                 READY   STATUS    RESTARTS   AGE
lostfound-backend-67b6959d96-2ffxd   1/1     Running   0          2m17s
lostfound-backend-67b6959d96-4hn7p   1/1     Running   0          117s
lostfound-backend-67b6959d96-6t4k5   1/1     Running   0          113s
lostfound-backend-67b6959d96-ddcxc   1/1     Running   0          2m7s
lostfound-backend-67b6959d96-llt2q   1/1     Running   0          2m
lostfound-backend-67b6959d96-pnjct   1/1     Running   0          2m11s
lostfound-db-0                       1/1     Running   0          4m27s
lostfound-frontend-74d55b5cf-vwg5k   1/1     Running   0          4m27s
lostfound-frontend-74d55b5cf-vx9wh   1/1     Running   0          4m27s

$ kubectl -n argocd get application lostfound -o custom-columns=SYNC:.status.sync.status,HEALTH:.status.health.status
SYNC     HEALTH
Synced   Healthy

```

## Fault 2

```text
################ FAULT 2 - backend Service selects no pods ################
$ git show HEAD | grep '^[-+] '
-    {{- include "lostfound.selector" (list . "backend") | nindent 4 }}
+    {{- include "lostfound.selector" (list . "api") | nindent 4 }}

>>> Argo CD synced 0f03e95: successfully synced (all tasks run)

$ curl -s -o /dev/null -w 'GET / (frontend)      -> HTTP %{http_code}
' -H 'Host: lostfound.local' http://localhost/
GET / (frontend)      -> HTTP 200

$ curl -s -w '
GET /api/stats        -> HTTP %{http_code}
' -H 'Host: lostfound.local' http://localhost/api/stats | tail -2

GET /api/stats        -> HTTP 503

$ kubectl -n argocd get application lostfound -o custom-columns=SYNC:.status.sync.status,HEALTH:.status.health.status
SYNC     HEALTH
Synced   Healthy

$ kubectl -n lostfound get pods -l app.kubernetes.io/component=backend
NAME                                 READY   STATUS    RESTARTS   AGE
lostfound-backend-67b6959d96-2ffxd   1/1     Running   0          2m39s
lostfound-backend-67b6959d96-4hn7p   1/1     Running   0          2m19s
lostfound-backend-67b6959d96-6t4k5   1/1     Running   0          2m15s
lostfound-backend-67b6959d96-ddcxc   1/1     Running   0          2m29s
lostfound-backend-67b6959d96-llt2q   1/1     Running   0          2m22s
lostfound-backend-67b6959d96-pnjct   1/1     Running   0          2m33s

$ kubectl -n lostfound get endpointslices -l kubernetes.io/service-name=lostfound-backend
NAME                      ADDRESSTYPE   PORTS     ENDPOINTS   AGE
lostfound-backend-txqr7   IPv4          <unset>   <unset>     4m50s

$ kubectl -n lostfound get svc lostfound-backend -o jsonpath='{.spec.selector}{"
"}'
{"app.kubernetes.io/component":"api","app.kubernetes.io/instance":"lostfound","app.kubernetes.io/name":"lostfound"}

$ kubectl -n lostfound get pods -l app.kubernetes.io/component=backend --show-labels | awk 'NR<=2{print $1, $NF}'
NAME LABELS
lostfound-backend-67b6959d96-2ffxd app.kubernetes.io/component=backend,app.kubernetes.io/instance=lostfound,app.kubernetes.io/name=lostfound,pod-template-hash=67b6959d96

$ kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=200 | grep -m2 'lostfound-lostfound-backend'
192.168.96.1 - - [07/Oct/2026:18:48:23 +0000] "GET /api/items/6 HTTP/1.1" 503 190 "-" "curl/8.7.1" 89 0.000 [lostfound-lostfound-backend-http] [] - - - - 7e4913af5525be85bbf0cbc84fd5ddce
192.168.96.1 - - [07/Oct/2026:18:48:23 +0000] "GET /api/items?q=library HTTP/1.1" 503 190 "-" "curl/8.7.1" 97 0.000 [lostfound-lostfound-backend-http] [] - - - - 9039b63e3b59d87217193b9f22474c67

$ curl -s http://localhost:19090/api/v1/alerts | python3 -c 'import json,sys; [print("  %-24s %s" % (a["labels"]["alertname"], a["state"])) for a in json.load(sys.stdin)["data"]["alerts"] if a["labels"]["alertname"].startswith("LostFound")]'
  LostFoundBackendDown     firing

---- fix: revert the selector change ----
$ git revert --no-edit HEAD | head -1
[main 9b68c4c] Revert "Rename backend component to api in Service"

>>> Argo CD synced 9b68c4c: successfully synced (all tasks run)

$ kubectl -n lostfound get endpointslices -l kubernetes.io/service-name=lostfound-backend
NAME                      ADDRESSTYPE   PORTS   ENDPOINTS                 AGE
lostfound-backend-txqr7   IPv4          8000    10.244.2.62,10.244.2.61   7m20s

$ curl -s -w '
GET /api/stats -> HTTP %{http_code}
' -H 'Host: lostfound.local' http://localhost/api/stats
{"total":475,"lost_open":2,"found_open":471,"claimed":1,"closed":1}
GET /api/stats -> HTTP 200

```

## Fault 3 - first run (reverted after 200s, before the alert fired)

```text
################ FAULT 3 - Prometheus silently stops scraping the app ################
$ git show HEAD | grep '^[-+] '
+    labels:
+      release: prometheus

>>> Argo CD synced 70480f2: successfully synced (all tasks run)

$ curl -s -o /dev/null -w 'app itself -> HTTP %{http_code}
' -H 'Host: lostfound.local' http://localhost/api/stats
app itself -> HTTP 200

waiting for the operator to regenerate the scrape config and for the alert's for: 1m ...

$ curl -s 'http://localhost:19090/api/v1/targets?state=active' | python3 -c 'import json,sys; t=[x for x in json.load(sys.stdin)["data"]["activeTargets"] if "lostfound" in x["scrapePool"]]; print("  lostfound targets:", len(t))'
  lostfound targets: 0

$ curl -s http://localhost:19090/api/v1/alerts | python3 -c 'import json,sys; [print("  %-24s %s since %s" % (a["labels"]["alertname"], a["state"], a["activeAt"][11:19])) for a in json.load(sys.stdin)["data"]["alerts"] if a["labels"]["alertname"].startswith("LostFound")]'

$ kubectl -n lostfound get servicemonitor lostfound-backend -o jsonpath='{.metadata.labels.release}{"
"}'
prometheus

$ kubectl -n monitoring get prometheus monitoring-kube-prometheus-prometheus -o jsonpath='{.spec.serviceMonitorSelector}{"
"}'
{"matchLabels":{"release":"monitoring"}}

---- fix: revert ----
$ git revert --no-edit HEAD | head -1
[main 331bdfa] Revert "Label ServiceMonitor for the prometheus release"

>>> Argo CD synced 331bdfa: successfully synced (all tasks run)

$ curl -s 'http://localhost:19090/api/v1/targets?state=active' | python3 -c 'import json,sys; [print("  %-48s %-22s %s" % (x["scrapePool"], x["labels"]["pod"], x["health"])) for x in json.load(sys.stdin)["data"]["activeTargets"] if "lostfound" in x["scrapePool"]]'
  serviceMonitor/lostfound/lostfound-backend/0     lostfound-backend-67b6959d96-pnjct unknown
  serviceMonitor/lostfound/lostfound-backend/0     lostfound-backend-67b6959d96-llt2q up

```

## Fault 3 - second run

```text
################ FAULT 3 (second run, waiting long enough) ################
$ git revert --no-edit HEAD | head -1
[main 0fa3dca] Revert "Revert "Label ServiceMonitor for the prometheus release""

>>> Argo CD synced 0fa3dca: successfully synced (all tasks run)

00:26:28  fault is live; watching targets and the LostFoundBackendDown alert
00:26:28  +0s  targets=2 alert=inactive
00:26:48  +20s  targets=0 alert=inactive
00:31:56  +328s  targets=0 alert=pending
00:32:57  +389s  targets=0 alert=firing

$ kubectl -n lostfound get servicemonitor lostfound-backend -o jsonpath='{.metadata.labels.release}{"\n"}'
prometheus

$ kubectl -n monitoring get prometheus monitoring-kube-prometheus-prometheus -o jsonpath='{.spec.serviceMonitorSelector}{"\n"}'
{"matchLabels":{"release":"monitoring"}}

---- fix: revert ----
$ git revert --no-edit HEAD | head -1
[main b13e588] Revert "Revert "Revert "Label ServiceMonitor for the prometheus release"""

>>> Argo CD synced b13e588: successfully synced (all tasks run)

00:33:04  +0s  targets_up=0 alert=firing
00:33:14  +10s  targets_up=1 alert=firing
00:33:19  +15s  targets_up=2 alert=firing
00:33:24  +20s  targets_up=2 alert=inactive
DONE
```
