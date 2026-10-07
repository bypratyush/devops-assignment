# Helm Mini Project (Notes App) - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - The chart
==============================================================
  notes-chart/.helmignore
  notes-chart/Chart.yaml
  notes-chart/templates/_helpers.tpl
  notes-chart/templates/configmap.yaml
  notes-chart/templates/deployment.yaml
  notes-chart/templates/ingress.yaml
  notes-chart/templates/NOTES.txt
  notes-chart/templates/pdb.yaml
  notes-chart/templates/service.yaml
  notes-chart/values-prod.yaml
  notes-chart/values.schema.json
  notes-chart/values.yaml

$ helm lint ./notes-chart
==> Linting ./notes-chart
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
$ helm lint ./notes-chart -f ./notes-chart/values-prod.yaml
==> Linting ./notes-chart
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

==============================================================
STEP 2 - Bad values are rejected before anything reaches the cluster
==============================================================
values.schema.json - replicas must be >= 1, environment must be a known one:
$ helm lint ./notes-chart --set replicaCount=0 --set app.environment=prod
==> Linting ./notes-chart
[INFO] Chart.yaml: icon is recommended
[ERROR] values.yaml: - at '/app/environment': value must be one of 'development', 'staging', 'production'
- at '/replicaCount': minimum: got 0, want 1

[ERROR] templates/: values don't meet the specifications of the schema(s) in the following chart(s):
notes-chart:
- at '/replicaCount': minimum: got 0, want 1
- at '/app/environment': value must be one of 'development', 'staging', 'production'


Error: 1 chart(s) linted, 1 chart(s) failed

required in a template - an ingress with no host makes no sense:
$ helm template notes ./notes-chart --set ingress.host=null
Error: execution error at (notes-chart/templates/ingress.yaml:11:15): ingress.host is required when ingress.enabled=true

Use --debug flag to render out invalid YAML

==============================================================
STEP 3 - helm template: dev vs prod rendered from the same chart
==============================================================
Both rendered with the same release name, so every difference below comes
from values-prod.yaml and nothing else ('<' dev, '>' prod):
$ diff <(helm template notes ./notes-chart) <(helm template notes ./notes-chart -f ./notes-chart/values-prod.yaml)
1a2,21
> # Source: notes-chart/templates/pdb.yaml
> apiVersion: policy/v1
> kind: PodDisruptionBudget
> metadata:
>   name: notes
>   labels:
>     app.kubernetes.io/name: notes-chart
>     app.kubernetes.io/instance: notes
>     helm.sh/chart: notes-chart-0.1.0
>     app.kubernetes.io/version: "1.0.0"
>     app.kubernetes.io/managed-by: Helm
>     environment: production
> spec:
>   minAvailable: 2
>   selector:
>     matchLabels:
>       app.kubernetes.io/name: notes-chart
>       app.kubernetes.io/instance: notes
> 
> ---
14c34
<     environment: development
---
>     environment: production
17,18c37,38
<   ENVIRONMENT: "development"
<   LOG_LEVEL: "debug"
---
>   ENVIRONMENT: "production"
>   LOG_LEVEL: "warn"
33c53
<     environment: development
---
>     environment: production
36,39c56,60
<     === notes-app [DEVELOPMENT] ===
<     DEV - data here is fake and gets reset
<     1. Finish the Session 15 Helm homework
<     2. Read up on values precedence
---
>     === notes-app [PRODUCTION] ===
>     PRODUCTION
>     1. Release notes-chart 0.1.0 to production
>     2. Check the PodDisruptionBudget before draining nodes
>     3. On-call: Pratyush
49c70
<         add_header X-Environment development;
---
>         add_header X-Environment production;
69c90
<     environment: development
---
>     environment: production
92c113
<     environment: development
---
>     environment: production
94c115
<   replicas: 1
---
>   replicas: 3
107c128
<         environment: development
---
>         environment: production
112c133
<         checksum/config: 21baa6256cac28908a6cedd88873e28a250506a8b75225eb791f9e55b99bcb03
---
>         checksum/config: 97c4dd37d1a6ea6c4d9d2fd4632f6749cbd9669e59faf30dcb2d6782312ffb99
116c137
<           image: "nginx:1.25-alpine"
---
>           image: "nginx:1.27-alpine"
140a162,164
>               cpu: 250m
>               memory: 128Mi
>             requests:
143,145d166
<             requests:
<               cpu: 25m
<               memory: 16Mi
170c191
<     environment: development
---
>     environment: production
174c195
<     - host: "notes-dev.local"
---
>     - host: "notes.local"

==============================================================
STEP 4 - INSTALL dev (chart defaults = values.yaml)
==============================================================
$ helm install notes-dev ./notes-chart -n notes-dev --create-namespace --wait --timeout 120s
NAME: notes-dev
LAST DEPLOYED: Wed Oct  7 23:54:45 2026
NAMESPACE: notes-dev
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
NOTES:
Notes app "notes-dev" - revision 1 in namespace notes-dev

  environment : development
  replicas    : 1
  image       : nginx:1.25-alpine
  notes       : 2

Open it:
  curl -H "Host: notes-dev.local" http://localhost/      (through ingress-nginx)
  kubectl -n notes-dev port-forward svc/notes-dev 8080:80

==============================================================
STEP 5 - INSTALL prod (values.yaml + values-prod.yaml)
==============================================================
$ helm install notes-prod ./notes-chart -n notes-prod --create-namespace -f ./notes-chart/values-prod.yaml --wait --timeout 120s
NAME: notes-prod
LAST DEPLOYED: Wed Oct  7 23:54:55 2026
NAMESPACE: notes-prod
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
NOTES:
Notes app "notes-prod" - revision 1 in namespace notes-prod

  environment : production
  replicas    : 3
  image       : nginx:1.27-alpine
  notes       : 3
  PDB         : minAvailable 2

Open it:
  curl -H "Host: notes.local" http://localhost/      (through ingress-nginx)
  kubectl -n notes-prod port-forward svc/notes-prod 8080:80

==============================================================
STEP 6 - Same chart, two environments: what actually differs
==============================================================
$ helm list -A --filter '^notes-'
NAME      	NAMESPACE 	REVISION	UPDATED                             	STATUS  	CHART            	APP VERSION
notes-dev 	notes-dev 	1       	2026-10-07 23:54:45.741466 +0530 IST	deployed	notes-chart-0.1.0	1.0.0      
notes-prod	notes-prod	1       	2026-10-07 23:54:55.635722 +0530 IST	deployed	notes-chart-0.1.0	1.0.0      

$ kubectl get deploy,svc,ingress,pdb -n notes-dev
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/notes-dev   1/1     1            1           18s

NAME                TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/notes-dev   ClusterIP   10.96.19.8   <none>        80/TCP    18s

NAME                                  CLASS   HOSTS             ADDRESS   PORTS   AGE
ingress.networking.k8s.io/notes-dev   nginx   notes-dev.local             80      18s

$ kubectl get deploy,svc,ingress,pdb -n notes-prod
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/notes-prod   3/3     3            3           8s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/notes-prod   ClusterIP   10.96.196.140   <none>        80/TCP    8s

NAME                                   CLASS   HOSTS         ADDRESS   PORTS   AGE
ingress.networking.k8s.io/notes-prod   nginx   notes.local             80      8s

NAME                                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
poddisruptionbudget.policy/notes-prod   2               N/A               1                     8s

--- side by side (read from the live objects) ---
  NAMESPACE   REPLICAS  IMAGE              REQUESTS              LIMITS                ENV           PDB
  notes-dev   1         nginx:1.25-alpine  25m/16Mi              100m/64Mi             development/debug none
  notes-prod  3         nginx:1.27-alpine  100m/64Mi             250m/128Mi            production/warn minAvailable=2

--- env vars inside one pod of each (from the -config ConfigMap) ---
$ kubectl exec -n notes-dev deploy/notes-dev -- printenv APP_NAME ENVIRONMENT LOG_LEVEL
notes-app
development
debug
$ kubectl exec -n notes-prod deploy/notes-prod -- printenv APP_NAME ENVIRONMENT LOG_LEVEL
notes-app
production
warn

--- through ingress-nginx from the Mac: curl -H 'Host: notes-dev.local' http://localhost/ ---
  HTTP/1.1 200 OK
  X-Served-By: notes-dev-76b6bdcc75-srj8m
  X-Environment: development
  | === notes-app [DEVELOPMENT] ===
  | DEV - data here is fake and gets reset
  | 1. Finish the Session 15 Helm homework
  | 2. Read up on values precedence
  | -- release notes-dev, chart notes-chart-0.1.0

--- curl -H 'Host: notes.local' http://localhost/ ---
  HTTP/1.1 200 OK
  X-Served-By: notes-prod-649c598766-vs47c
  X-Environment: production
  | === notes-app [PRODUCTION] ===
  | PRODUCTION
  | 1. Release notes-chart 0.1.0 to production
  | 2. Check the PodDisruptionBudget before draining nodes
  | 3. On-call: Pratyush
  | -- release notes-prod, chart notes-chart-0.1.0

--- prod has 3 replicas: 12 requests, grouped by the pod that answered ---
  4 notes-prod-649c598766-jxrvj
  8 notes-prod-649c598766-vs47c

==============================================================
STEP 7 - UPGRADE dev (revision 2): one more note, 2 replicas
==============================================================
$ helm upgrade notes-dev ./notes-chart -n notes-dev --set replicaCount=2 --set-json 'notes=["Finish the Session 15 Helm homework","Read up on values precedence","Rollback creates a NEW revision"]' --wait --timeout 120s | head -n 7
Release "notes-dev" has been upgraded. Happy Helming!
NAME: notes-dev
LAST DEPLOYED: Wed Oct  7 23:55:09 2026
NAMESPACE: notes-dev
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete

  HTTP/1.1 200 OK
  X-Served-By: notes-dev-788fd99cd8-w4xgz
  X-Environment: development
  | === notes-app [DEVELOPMENT] ===
  | DEV - data here is fake and gets reset
  | 1. Finish the Session 15 Helm homework
  | 2. Read up on values precedence
  | 3. Rollback creates a NEW revision
  | -- release notes-dev, chart notes-chart-0.1.0

$ helm history notes-dev -n notes-dev
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION     
1       	Wed Oct  7 23:54:45 2026	superseded	notes-chart-0.1.0	1.0.0      	Install complete
2       	Wed Oct  7 23:55:09 2026	deployed  	notes-chart-0.1.0	1.0.0      	Upgrade complete

==============================================================
STEP 8 - A BAD UPGRADE: prod values applied to the dev release by mistake
==============================================================
(the instructor's step 11 command - harmless with one release, wrong once
 a separate prod release exists)
$ helm upgrade notes-dev ./notes-chart -n notes-dev -f ./notes-chart/values-prod.yaml --wait --timeout 120s
level=WARN msg="upgrade failed" name=notes-dev error="server-side apply failed for object notes-dev/notes-dev networking.k8s.io/v1, Kind=Ingress: admission webhook \"validate.nginx.ingress.kubernetes.io\" denied the request: host \"notes.local\" and path \"/\" is already defined in ingress notes-prod/notes-prod"
Error: UPGRADE FAILED: server-side apply failed for object notes-dev/notes-dev networking.k8s.io/v1, Kind=Ingress: admission webhook "validate.nginx.ingress.kubernetes.io" denied the request: host "notes.local" and path "/" is already defined in ingress notes-prod/notes-prod
exit code: 1

Helm says FAILED - so did nothing change? Let the Deployment finish and look:
deployment "notes-dev" successfully rolled out

$ helm history notes-dev -n notes-dev
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION                                                                                                                                                                                                                                                                             
1       	Wed Oct  7 23:54:45 2026	superseded	notes-chart-0.1.0	1.0.0      	Install complete                                                                                                                                                                                                                                                                        
2       	Wed Oct  7 23:55:09 2026	deployed  	notes-chart-0.1.0	1.0.0      	Upgrade complete                                                                                                                                                                                                                                                                        
3       	Wed Oct  7 23:55:20 2026	failed    	notes-chart-0.1.0	1.0.0      	Upgrade "notes-dev" failed: server-side apply failed for object notes-dev/notes-dev networking.k8s.io/v1, Kind=Ingress: admission webhook "validate.nginx.ingress.kubernetes.io" denied the request: host "notes.local" and path "/" is already defined in ingress notes-prod/notes-prod

  NAMESPACE   REPLICAS  IMAGE              REQUESTS              LIMITS                ENV           PDB
  notes-dev   3         nginx:1.27-alpine  100m/64Mi             250m/128Mi            production/warn minAvailable=2
  notes-prod  3         nginx:1.27-alpine  100m/64Mi             250m/128Mi            production/warn minAvailable=2

  HTTP/1.1 200 OK
  X-Served-By: notes-dev-5bdf9db858-w2f2b
  X-Environment: production
  | === notes-app [PRODUCTION] ===
  | PRODUCTION
  | 1. Release notes-chart 0.1.0 to production
  | 2. Check the PodDisruptionBudget before draining nodes
  | 3. On-call: Pratyush
  | -- release notes-dev, chart notes-chart-0.1.0

>>> The webhook rejected only the Ingress (notes.local belongs to prod).
    The ConfigMaps, the Deployment and a brand-new PDB were applied BEFORE
    that, so the dev URL now serves a 3-replica PRODUCTION config even
    though Helm marked the revision failed. Helm upgrades are not
    transactions.

==============================================================
STEP 9 - ROLLBACK dev to revision 2
==============================================================
$ helm rollback notes-dev 2 -n notes-dev --wait --timeout 120s
Rollback was a success! Happy Helming!

$ helm history notes-dev -n notes-dev
REVISION	UPDATED                 	STATUS    	CHART            	APP VERSION	DESCRIPTION                                                                                                                                                                                                                                                                             
1       	Wed Oct  7 23:54:45 2026	superseded	notes-chart-0.1.0	1.0.0      	Install complete                                                                                                                                                                                                                                                                        
2       	Wed Oct  7 23:55:09 2026	superseded	notes-chart-0.1.0	1.0.0      	Upgrade complete                                                                                                                                                                                                                                                                        
3       	Wed Oct  7 23:55:20 2026	failed    	notes-chart-0.1.0	1.0.0      	Upgrade "notes-dev" failed: server-side apply failed for object notes-dev/notes-dev networking.k8s.io/v1, Kind=Ingress: admission webhook "validate.nginx.ingress.kubernetes.io" denied the request: host "notes.local" and path "/" is already defined in ingress notes-prod/notes-prod
4       	Wed Oct  7 23:55:49 2026	deployed  	notes-chart-0.1.0	1.0.0      	Rollback to 2                                                                                                                                                                                                                                                                           

  NAMESPACE   REPLICAS  IMAGE              REQUESTS              LIMITS                ENV           PDB
  notes-dev   2         nginx:1.25-alpine  25m/16Mi              100m/64Mi             development/debug none
  notes-prod  3         nginx:1.27-alpine  100m/64Mi             250m/128Mi            production/warn minAvailable=2

  HTTP/1.1 200 OK
  X-Served-By: notes-dev-788fd99cd8-kpwp6
  X-Environment: development
  | === notes-app [DEVELOPMENT] ===
  | DEV - data here is fake and gets reset
  | 1. Finish the Session 15 Helm homework
  | 2. Read up on values precedence
  | 3. Rollback creates a NEW revision
  | -- release notes-dev, chart notes-chart-0.1.0

prod was never touched - each release has its own history:
$ helm history notes-prod -n notes-prod
REVISION	UPDATED                 	STATUS  	CHART            	APP VERSION	DESCRIPTION     
1       	Wed Oct  7 23:54:55 2026	deployed	notes-chart-0.1.0	1.0.0      	Install complete

==============================================================
STEP 10 - helm get: values and NOTES per environment
==============================================================
$ helm get values notes-dev -n notes-dev
USER-SUPPLIED VALUES:
notes:
- Finish the Session 15 Helm homework
- Read up on values precedence
- Rollback creates a NEW revision
replicaCount: 2
$ helm get values notes-prod -n notes-prod
USER-SUPPLIED VALUES:
app:
  banner: PRODUCTION
  environment: production
  logLevel: warn
image:
  tag: 1.27-alpine
ingress:
  host: notes.local
notes:
- Release notes-chart 0.1.0 to production
- Check the PodDisruptionBudget before draining nodes
- 'On-call: Pratyush'
podDisruptionBudget:
  enabled: true
  minAvailable: 2
replicaCount: 3
resources:
  limits:
    cpu: 250m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 64Mi

$ helm get notes notes-prod -n notes-prod
NOTES:
Notes app "notes-prod" - revision 1 in namespace notes-prod

  environment : production
  replicas    : 3
  image       : nginx:1.27-alpine
  notes       : 3
  PDB         : minAvailable 2

Open it:
  curl -H "Host: notes.local" http://localhost/      (through ingress-nginx)
  kubectl -n notes-prod port-forward svc/notes-prod 8080:80


==============================================================
STEP 11 - Why the chart does not hard-code nodePort (the instructor's values do)
==============================================================
nodePorts are cluster-wide. Two releases asking for 30090:
$ helm install nodeport-a ./notes-chart -n notes-dev --set service.type=NodePort --set service.nodePort=30090 --set ingress.enabled=false | grep -E '^(STATUS|Error)'
STATUS: deployed
$ helm install nodeport-b ./notes-chart -n notes-prod --set service.type=NodePort --set service.nodePort=30090 --set ingress.enabled=false --dry-run=server | grep -E '^(STATUS|DESCRIPTION|Error)'
STATUS: pending-install
DESCRIPTION: Dry run complete
$ helm install nodeport-b ./notes-chart -n notes-prod --set service.type=NodePort --set service.nodePort=30090 --set ingress.enabled=false
Error: INSTALLATION FAILED: server-side apply failed for object notes-prod/nodeport-b /v1, Kind=Service: Service "nodeport-b" is invalid: spec.ports[0].nodePort: Invalid value: 30090: provided port is already allocated

>>> --dry-run=server said fine; the real install failed. A dry run does not
    allocate ports, so it cannot see the clash.

==============================================================
CLEANUP
==============================================================
release "notes-dev" uninstalled
release "notes-prod" uninstalled
namespace "notes-dev" deleted
namespace "notes-prod" deleted
```
