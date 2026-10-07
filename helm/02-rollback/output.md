# Helm Rollback Workflow - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 0 - Lint, and see exactly what each values file changes
==============================================================
$ helm lint ./rollback-web -f values-v2.yaml -f values-v3-bad.yaml
==> Linting ./rollback-web
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

v1 (chart defaults) -> v2:
$ diff <(helm template web ./rollback-web) <(helm template web ./rollback-web -f values-v2.yaml) | grep -E '^[<>] .*(image:|site version|message|containerPort)'
<     site version : v1
<     message      : First release of the site
>     site version : v2
>     message      : New homepage, now on nginx 1.27
<           image: "nginx:1.25-alpine"
>           image: "nginx:1.27-alpine"

v2 -> v3-bad:
$ diff <(helm template web ./rollback-web -f values-v2.yaml) <(helm template web ./rollback-web -f values-v3-bad.yaml)
72c72
<               containerPort: 80
---
>               containerPort: 8080

==============================================================
STEP 1 - INSTALL (revision 1: page v1, nginx 1.25)
==============================================================
$ helm install web ./rollback-web -n helm-rollback --create-namespace --wait --timeout 90s --description 'v1: first release, nginx 1.25'
NAME: web
LAST DEPLOYED: Wed Oct  7 23:44:35 2026
NAMESPACE: helm-rollback
STATUS: deployed
REVISION: 1
DESCRIPTION: v1: first release, nginx 1.25
TEST SUITE: None
NOTES:
web revision 1: page v1 on nginx:1.25-alpine (3 replicas, containerPort 80)

Check it from inside the cluster:
  kubectl -n helm-rollback run tmp --rm -i --restart=Never --image=curlimages/curl:8.5.0 -- curl -s http://web/

==============================================================
STEP 2 - VERIFY revision 1
==============================================================
--- helm history ---
REVISION	UPDATED                 	STATUS  	CHART             	APP VERSION	DESCRIPTION                  
1       	Wed Oct  7 23:44:35 2026	deployed	rollback-web-0.1.0	1.25-alpine	v1: first release, nginx 1.25

--- pods ---
  POD                    IMAGE              PORT  READY  RESTARTS
  web-7c98bb87d5-gtkv7   nginx:1.25-alpine  80    true   0
  web-7c98bb87d5-lmmzf   nginx:1.25-alpine  80    true   0
  web-7c98bb87d5-wqzpz   nginx:1.25-alpine  80    true   0

--- 10 requests through Service/web ---
  10 page v1  served by nginx/1.25.5

==============================================================
STEP 3 - UPGRADE (revision 2: page v2, nginx 1.27)
==============================================================
$ helm upgrade web ./rollback-web -n helm-rollback -f values-v2.yaml --wait --timeout 90s --description 'v2: new page, nginx 1.27'
Release "web" has been upgraded. Happy Helming!
NAME: web
LAST DEPLOYED: Wed Oct  7 23:44:49 2026
NAMESPACE: helm-rollback
STATUS: deployed
REVISION: 2
DESCRIPTION: v2: new page, nginx 1.27
TEST SUITE: None
NOTES:
web revision 2: page v2 on nginx:1.27-alpine (3 replicas, containerPort 80)

Check it from inside the cluster:
  kubectl -n helm-rollback run tmp --rm -i --restart=Never --image=curlimages/curl:8.5.0 -- curl -s http://web/

==============================================================
STEP 4 - VERIFY revision 2
==============================================================
--- helm history ---
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	DESCRIPTION                  
1       	Wed Oct  7 23:44:35 2026	superseded	rollback-web-0.1.0	1.25-alpine	v1: first release, nginx 1.25
2       	Wed Oct  7 23:44:49 2026	deployed  	rollback-web-0.1.0	1.25-alpine	v2: new page, nginx 1.27     

--- pods ---
  POD                    IMAGE              PORT  READY  RESTARTS
  web-8c684fd59-2gct8    nginx:1.27-alpine  80    true   0
  web-8c684fd59-8wncq    nginx:1.27-alpine  80    true   0
  web-8c684fd59-dp6x6    nginx:1.27-alpine  80    true   0

--- 10 requests through Service/web ---
  10 page v2  served by nginx/1.27.5

==============================================================
STEP 5 - UPGRADE AGAIN (revision 3: containerPort 8080 - the bad one)
==============================================================
$ helm upgrade web ./rollback-web -n helm-rollback -f values-v3-bad.yaml --wait --timeout 45s --description 'v3: move to port 8080'
level=WARN msg="upgrade failed" name=web error="resource Deployment/helm-rollback/web not ready. status: InProgress, message: Updated: 1/3\ncontext deadline exceeded"
Error: UPGRADE FAILED: resource Deployment/helm-rollback/web not ready. status: InProgress, message: Updated: 1/3
context deadline exceeded
exit code: 1

==============================================================
STEP 6 - VERIFY revision 3 - Helm says failed; what do users see?
==============================================================
--- helm history ---
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	DESCRIPTION                                                                                                     
1       	Wed Oct  7 23:44:35 2026	superseded	rollback-web-0.1.0	1.25-alpine	v1: first release, nginx 1.25                                                                                   
2       	Wed Oct  7 23:44:49 2026	deployed  	rollback-web-0.1.0	1.25-alpine	v2: new page, nginx 1.27                                                                                        
3       	Wed Oct  7 23:45:13 2026	failed    	rollback-web-0.1.0	1.25-alpine	Upgrade "web" failed: resource Deployment/helm-rollback/web not ready. status: InProgress, message: Updated: ...

--- pods ---
  POD                    IMAGE              PORT  READY  RESTARTS
  web-555b95879f-lpdd7   nginx:1.27-alpine  8080  false  1
  web-8c684fd59-2gct8    nginx:1.27-alpine  80    true   0
  web-8c684fd59-8wncq    nginx:1.27-alpine  80    true   0
  web-8c684fd59-dp6x6    nginx:1.27-alpine  80    true   0

--- 10 requests through Service/web ---
  10 page v2  served by nginx/1.27.5

--- helm status ---
$ helm status web -n helm-rollback | head -n 7
NAME: web
LAST DEPLOYED: Wed Oct  7 23:45:13 2026
NAMESPACE: helm-rollback
STATUS: failed
REVISION: 3
DESCRIPTION: Upgrade "web" failed: resource Deployment/helm-rollback/web not ready. status: InProgress, message: Updated: 1/3
context deadline exceeded

--- why the new pod never becomes Ready ---
  Liveness probe failed: Get "http://10.244.1.218:8080/": dial tcp 10.244.1.218:8080: connect: connection refused
  Readiness probe failed: Get "http://10.244.1.218:8080/": dial tcp 10.244.1.218:8080: connect: connection refused

>>> Helm marked revision 3 FAILED, but users never noticed: the rolling
    update only added ONE surge pod (maxSurge 25% of 3 -> 1, maxUnavailable
    -> 0) and it never became Ready, so the three v2 pods kept serving.
    The Deployment is stuck half-way, though - that is what rollback fixes.

==============================================================
STEP 7 - What exactly differs between revision 2 and revision 3?
==============================================================
$ helm get values web -n helm-rollback --revision 2
USER-SUPPLIED VALUES:
image:
  tag: 1.27-alpine
page:
  message: New homepage, now on nginx 1.27
  version: v2
$ helm get values web -n helm-rollback --revision 3
USER-SUPPLIED VALUES:
containerPort: 8080
image:
  tag: 1.27-alpine
page:
  message: New homepage, now on nginx 1.27
  version: v2

$ diff <(helm get manifest web -n helm-rollback --revision 2) <(helm get manifest web -n helm-rollback --revision 3)
72c72
<               containerPort: 80
---
>               containerPort: 8080

==============================================================
STEP 8 - ROLLBACK to revision 2
==============================================================
$ helm rollback web 2 -n helm-rollback --wait --timeout 90s
Rollback was a success! Happy Helming!

==============================================================
STEP 9 - VERIFY after the rollback
==============================================================
--- helm history ---
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	DESCRIPTION                                                                                                     
1       	Wed Oct  7 23:44:35 2026	superseded	rollback-web-0.1.0	1.25-alpine	v1: first release, nginx 1.25                                                                                   
2       	Wed Oct  7 23:44:49 2026	superseded	rollback-web-0.1.0	1.25-alpine	v2: new page, nginx 1.27                                                                                        
3       	Wed Oct  7 23:45:13 2026	failed    	rollback-web-0.1.0	1.25-alpine	Upgrade "web" failed: resource Deployment/helm-rollback/web not ready. status: InProgress, message: Updated: ...
4       	Wed Oct  7 23:46:00 2026	deployed  	rollback-web-0.1.0	1.25-alpine	Rollback to 2                                                                                                   

--- pods ---
  POD                    IMAGE              PORT  READY  RESTARTS
  web-8c684fd59-2gct8    nginx:1.27-alpine  80    true   0
  web-8c684fd59-8wncq    nginx:1.27-alpine  80    true   0
  web-8c684fd59-dp6x6    nginx:1.27-alpine  80    true   0

--- 10 requests through Service/web ---
  10 page v2  served by nginx/1.27.5

$ helm history web -n helm-rollback --show-rollback-revision
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	ROLLBACK	DESCRIPTION                                                                                                     
1       	Wed Oct  7 23:44:35 2026	superseded	rollback-web-0.1.0	1.25-alpine	        	v1: first release, nginx 1.25                                                                                   
2       	Wed Oct  7 23:44:49 2026	superseded	rollback-web-0.1.0	1.25-alpine	        	v2: new page, nginx 1.27                                                                                        
3       	Wed Oct  7 23:45:13 2026	failed    	rollback-web-0.1.0	1.25-alpine	        	Upgrade "web" failed: resource Deployment/helm-rollback/web not ready. status: InProgress, message: Updated: ...
4       	Wed Oct  7 23:46:00 2026	deployed  	rollback-web-0.1.0	1.25-alpine	2       	Rollback to 2                                                                                                   

Revision 4 is a NEW revision whose content is revision 2's:
$ diff <(helm get manifest web -n helm-rollback --revision 2) <(helm get manifest web -n helm-rollback --revision 4) && echo '  manifests of revision 2 and 4 are identical'
  manifests of revision 2 and 4 are identical
$ kubectl get secrets -n helm-rollback -l owner=helm,name=web
NAME                        TYPE                 DATA   AGE
sh.helm.release.v1.web.v1   helm.sh/release.v1   1      86s
sh.helm.release.v1.web.v2   helm.sh/release.v1   1      72s
sh.helm.release.v1.web.v3   helm.sh/release.v1   1      48s
sh.helm.release.v1.web.v4   helm.sh/release.v1   1      1s

==============================================================
STEP 10 - BONUS: let Helm roll back by itself (--rollback-on-failure)
==============================================================
Helm 4 renamed --atomic to --rollback-on-failure; the old flag still works but warns:
$ helm upgrade web ./rollback-web -n helm-rollback -f values-v2.yaml --atomic --dry-run=client | head -n 1
Flag --atomic has been deprecated, use --rollback-on-failure instead
Release "web" has been upgraded. Happy Helming!
  (client dry run - nothing was changed)

Now a real bad upgrade - a typo in the image tag - with automatic rollback:
$ helm upgrade web ./rollback-web -n helm-rollback -f values-v2.yaml --set image.tag=1.27-alpinee --rollback-on-failure --timeout 40s --description 'v5: typo in image tag'
level=WARN msg="upgrade failed" name=web error="resource Deployment/helm-rollback/web not ready. status: InProgress, message: Updated: 1/3\ncontext deadline exceeded"
Error: UPGRADE FAILED: release web failed, and has been rolled back due to rollback-on-failure being set: resource Deployment/helm-rollback/web not ready. status: InProgress, message: Updated: 1/3
context deadline exceeded

$ kubectl get events -n helm-rollback --field-selector reason=Failed -o custom-columns=MESSAGE:.message --no-headers | sort -u
Error: ErrImagePull
Error: ImagePullBackOff
Failed to pull image "nginx:1.27-alpinee": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:1.27-alpinee": failed to resolve reference "docker.io/library/nginx:1.27-alpinee": docker.io/library/nginx:1.27-alpinee: not found

--- helm history ---
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	DESCRIPTION                                                                                                     
1       	Wed Oct  7 23:44:35 2026	superseded	rollback-web-0.1.0	1.25-alpine	v1: first release, nginx 1.25                                                                                   
2       	Wed Oct  7 23:44:49 2026	superseded	rollback-web-0.1.0	1.25-alpine	v2: new page, nginx 1.27                                                                                        
3       	Wed Oct  7 23:45:13 2026	failed    	rollback-web-0.1.0	1.25-alpine	Upgrade "web" failed: resource Deployment/helm-rollback/web not ready. status: InProgress, message: Updated: ...
4       	Wed Oct  7 23:46:00 2026	superseded	rollback-web-0.1.0	1.25-alpine	Rollback to 2                                                                                                   
5       	Wed Oct  7 23:46:02 2026	failed    	rollback-web-0.1.0	1.25-alpine	Upgrade "web" failed: resource Deployment/helm-rollback/web not ready. status: InProgress, message: Updated: ...
6       	Wed Oct  7 23:46:42 2026	deployed  	rollback-web-0.1.0	1.25-alpine	Rollback to 4                                                                                                   

--- pods ---
  POD                    IMAGE              PORT  READY  RESTARTS
  web-8c684fd59-2gct8    nginx:1.27-alpine  80    true   0
  web-8c684fd59-8wncq    nginx:1.27-alpine  80    true   0
  web-8c684fd59-dp6x6    nginx:1.27-alpine  80    true   0

--- 10 requests through Service/web ---
  10 page v2  served by nginx/1.27.5

==============================================================
DONE - final history
==============================================================
$ helm history web -n helm-rollback --show-rollback-revision
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	ROLLBACK	DESCRIPTION                                                                                                     
1       	Wed Oct  7 23:44:35 2026	superseded	rollback-web-0.1.0	1.25-alpine	        	v1: first release, nginx 1.25                                                                                   
2       	Wed Oct  7 23:44:49 2026	superseded	rollback-web-0.1.0	1.25-alpine	        	v2: new page, nginx 1.27                                                                                        
3       	Wed Oct  7 23:45:13 2026	failed    	rollback-web-0.1.0	1.25-alpine	        	Upgrade "web" failed: resource Deployment/helm-rollback/web not ready. status: InProgress, message: Updated: ...
4       	Wed Oct  7 23:46:00 2026	superseded	rollback-web-0.1.0	1.25-alpine	2       	Rollback to 2                                                                                                   
5       	Wed Oct  7 23:46:02 2026	failed    	rollback-web-0.1.0	1.25-alpine	        	Upgrade "web" failed: resource Deployment/helm-rollback/web not ready. status: InProgress, message: Updated: ...
6       	Wed Oct  7 23:46:42 2026	deployed  	rollback-web-0.1.0	1.25-alpine	4       	Rollback to 4                                                                                                   

==============================================================
CLEANUP
==============================================================
release "web" uninstalled
namespace "helm-rollback" deleted
```
