# Helm Commands - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - helm version (client only - Helm 3+ has no server side)
==============================================================
$ helm version
version.BuildInfo{Version:"v4.3.0", GitCommit:"bec5b06ed841fe5269972d864d5177944fd5970f", GitTreeState:"clean", GoVersion:"go1.27.1", KubeClientVersion:"v1.37"}

==============================================================
STEP 2 - helm create: scaffold a chart
==============================================================
$ helm create pratyush-web
Creating pratyush-web

What the scaffold contains:
  pratyush-web
  pratyush-web/.helmignore
  pratyush-web/Chart.yaml
  pratyush-web/charts
  pratyush-web/templates
  pratyush-web/templates/_helpers.tpl
  pratyush-web/templates/deployment.yaml
  pratyush-web/templates/hpa.yaml
  pratyush-web/templates/httproute.yaml
  pratyush-web/templates/ingress.yaml
  pratyush-web/templates/NOTES.txt
  pratyush-web/templates/service.yaml
  pratyush-web/templates/serviceaccount.yaml
  pratyush-web/templates/tests
  pratyush-web/templates/tests/test-connection.yaml
  pratyush-web/values.yaml

My committed ./pratyush-web started as exactly this. Files I changed or added:
  Files pratyush-web/Chart.yaml and ./pratyush-web/Chart.yaml differ
  Only in pratyush-web: charts
  Files pratyush-web/templates/NOTES.txt and ./pratyush-web/templates/NOTES.txt differ
  Only in ./pratyush-web/templates: configmap.yaml
  Files pratyush-web/templates/deployment.yaml and ./pratyush-web/templates/deployment.yaml differ
  Files pratyush-web/templates/tests/test-connection.yaml and ./pratyush-web/templates/tests/test-connection.yaml differ
  Files pratyush-web/values.yaml and ./pratyush-web/values.yaml differ

(charts/ is empty in a fresh scaffold; git does not track empty dirs and
 this chart has no dependencies, so I dropped it.)

==============================================================
STEP 3 - helm lint: catch mistakes before the cluster sees them
==============================================================
$ helm lint ./pratyush-web
==> Linting ./pratyush-web
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

$ helm lint ./pratyush-web -f values-staging.yaml --strict
==> Linting ./pratyush-web
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

A broken copy - one template with an unclosed {{ action:
$ helm lint broken-web
==> Linting broken-web
[INFO] Chart.yaml: icon is recommended
[ERROR] templates/: parse error at (pratyush-web/templates/configmap.yaml:16): unclosed action started at pratyush-web/templates/configmap.yaml:15

Error: 1 chart(s) linted, 1 chart(s) failed
exit code: 1

==============================================================
STEP 4 - helm template: render locally, no cluster involved
==============================================================
$ helm template pratyush-web ./pratyush-web -s templates/configmap.yaml
---
# Source: pratyush-web/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: pratyush-web-page
  labels:
    helm.sh/chart: pratyush-web-0.1.0
    app.kubernetes.io/name: pratyush-web
    app.kubernetes.io/instance: pratyush-web
    app.kubernetes.io/version: "1.25-alpine"
    app.kubernetes.io/managed-by: Helm
data:
  index.html: |
    message     : Hello from Pratyush's first Helm chart
    environment : dev
    owner       : Pratyush Mohanty (24BCS10238)
    release     : pratyush-web (revision 1) in namespace default
    chart       : pratyush-web-0.1.0



Same chart, three sets of values - only the rendered fields change:
$ helm template pratyush-web ./pratyush-web | grep -E 'replicas:|image: "nginx'
  replicas: 2
          image: "nginx:1.25-alpine"
$ helm template pratyush-web ./pratyush-web -f values-staging.yaml | grep -E 'replicas:|image: "nginx'
  replicas: 2
          image: "nginx:1.27-alpine"
$ helm template pratyush-web ./pratyush-web -f values-staging.yaml --set replicaCount=4 | grep -E 'replicas:|image: "nginx'
  replicas: 4
          image: "nginx:1.27-alpine"

Precedence: --set beats -f, and -f beats the chart's values.yaml:
$ helm template pratyush-web ./pratyush-web -f values-staging.yaml --set web.environment=from-set-flag -s templates/configmap.yaml | grep -E 'message|environment'
    message     : Staging build - now on nginx 1.27
    environment : from-set-flag

==============================================================
STEP 5 - helm install --dry-run: everything except actually installing
==============================================================
$ helm install pratyush-web ./pratyush-web -n helm-demo --dry-run=client | head -n 8
NAME: pratyush-web
LAST DEPLOYED: Wed Oct  7 23:24:20 2026
NAMESPACE: helm-demo
STATUS: pending-install
REVISION: 1
DESCRIPTION: Dry run complete
HOOKS:
---
  ... (hooks, full manifest and NOTES follow)

--debug additionally prints the values the templates were rendered with:
$ helm install pratyush-web ./pratyush-web -n helm-demo --dry-run=client --debug --set replicaCount=3 | sed -n '/^USER-SUPPLIED/,/^COMPUTED/p'
level=DEBUG msg="Original chart version" version=""
level=DEBUG msg="Chart path" path=/Users/pratyushmohanty/Devops-assignment/helm/01-commands/pratyush-web
level=DEBUG msg="number of dependencies in the chart" chart=pratyush-web dependencies=0
USER-SUPPLIED VALUES:
replicaCount: 3

COMPUTED VALUES:

Helm 4: a bare --dry-run still works but is deprecated:
$ helm install pratyush-web ./pratyush-web -n helm-demo --dry-run | head -n 1
level=WARN msg="--dry-run is deprecated and should be replaced with '--dry-run=client'"
NAME: pratyush-web

--dry-run=server also sends the objects to the API server for validation:
$ helm install pratyush-web ./pratyush-web -n helm-demo --dry-run=server | grep -E '^(STATUS|DESCRIPTION):'
STATUS: pending-install
DESCRIPTION: Dry run complete

Nothing was persisted:
$ helm list -n helm-demo
NAME	NAMESPACE	REVISION	UPDATED	STATUS	CHART	APP VERSION
$ kubectl get ns helm-demo
Error from server (NotFound): namespaces "helm-demo" not found

==============================================================
STEP 6 - helm install: create the release (revision 1)
==============================================================
$ helm install pratyush-web ./pratyush-web -n helm-demo --create-namespace --wait --timeout 120s
NAME: pratyush-web
LAST DEPLOYED: Wed Oct  7 23:24:20 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
NOTES:
Release "pratyush-web" (revision 1) is in namespace helm-demo.
Serving "Hello from Pratyush's first Helm chart" [dev]
with 2 replica(s) of nginx:1.25-alpine.

Quick check from inside the cluster:
  kubectl -n helm-demo run tmp --rm -i --restart=Never --image=curlimages/curl:8.5.0 -- curl -s http://pratyush-web:80/

1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace helm-demo -l "app.kubernetes.io/name=pratyush-web,app.kubernetes.io/instance=pratyush-web" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace helm-demo $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace helm-demo port-forward $POD_NAME 8080:$CONTAINER_PORT

$ kubectl get deploy,svc,cm -n helm-demo -l app.kubernetes.io/instance=pratyush-web
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/pratyush-web   2/2     2            2           12s

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/pratyush-web   ClusterIP   10.96.143.122   <none>        80/TCP    12s

NAME                          DATA   AGE
configmap/pratyush-web-page   1      12s

What the Service actually serves (curl from a client pod in helm-demo):
  | message     : Hello from Pratyush's first Helm chart
  | environment : dev
  | owner       : Pratyush Mohanty (24BCS10238)
  | release     : pratyush-web (revision 1) in namespace helm-demo
  | chart       : pratyush-web-0.1.0
  | Server: nginx/1.25.5

==============================================================
STEP 7 - helm list: which releases exist
==============================================================
$ helm list -n helm-demo
NAME        	NAMESPACE	REVISION	UPDATED                             	STATUS  	CHART             	APP VERSION
pratyush-web	helm-demo	1       	2026-10-07 23:24:20.689644 +0530 IST	deployed	pratyush-web-0.1.0	1.25-alpine

$ helm list -A
NAME        	NAMESPACE	REVISION	UPDATED                             	STATUS  	CHART             	APP VERSION
pratyush-web	helm-demo	1       	2026-10-07 23:24:20.689644 +0530 IST	deployed	pratyush-web-0.1.0	1.25-alpine

$ helm list -A -q
pratyush-web

==============================================================
STEP 8 - helm status: state, resources and NOTES of one release
==============================================================
$ helm status pratyush-web -n helm-demo
NAME: pratyush-web
LAST DEPLOYED: Wed Oct  7 23:24:20 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
RESOURCES:
==> v1/Pod(related)
NAME                            READY   STATUS    RESTARTS   AGE
pratyush-web-6b947d79ff-9zrwb   1/1     Running   0          14s
pratyush-web-6b947d79ff-ln64m   1/1     Running   0          14s

==> v1/ServiceAccount
NAME           AGE
pratyush-web   14s

==> v1/ConfigMap
NAME                DATA   AGE
pratyush-web-page   1      14s

==> v1/Service
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
pratyush-web   ClusterIP   10.96.143.122   <none>        80/TCP    14s

==> v1/Deployment
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
pratyush-web   2/2     2            2           14s


NOTES:
Release "pratyush-web" (revision 1) is in namespace helm-demo.
Serving "Hello from Pratyush's first Helm chart" [dev]
with 2 replica(s) of nginx:1.25-alpine.

Quick check from inside the cluster:
  kubectl -n helm-demo run tmp --rm -i --restart=Never --image=curlimages/curl:8.5.0 -- curl -s http://pratyush-web:80/

1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace helm-demo -l "app.kubernetes.io/name=pratyush-web,app.kubernetes.io/instance=pratyush-web" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace helm-demo $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace helm-demo port-forward $POD_NAME 8080:$CONTAINER_PORT

Helm 3 needed --show-resources for the RESOURCES block; Helm 4 always prints it
and the flag is gone:
$ helm status pratyush-web -n helm-demo --show-resources
Error: unknown flag: --show-resources

==============================================================
STEP 9 - helm get: download what Helm stored for the release
==============================================================
$ helm get values pratyush-web -n helm-demo
USER-SUPPLIED VALUES:
null
  (null = I passed no overrides; the chart defaults were used)

$ helm get values pratyush-web -n helm-demo --all | grep -A3 -E '^(replicaCount|web):'
replicaCount: 2
resources:
  limits:
    cpu: 100m
--
web:
  environment: dev
  message: Hello from Pratyush's first Helm chart
  owner: Pratyush Mohanty (24BCS10238)

$ helm get manifest pratyush-web -n helm-demo | grep -E '^(# Source|kind):'
# Source: pratyush-web/templates/serviceaccount.yaml
kind: ServiceAccount
# Source: pratyush-web/templates/configmap.yaml
kind: ConfigMap
# Source: pratyush-web/templates/service.yaml
kind: Service
# Source: pratyush-web/templates/deployment.yaml
kind: Deployment

$ helm get notes pratyush-web -n helm-demo | head -n 4
NOTES:
Release "pratyush-web" (revision 1) is in namespace helm-demo.
Serving "Hello from Pratyush's first Helm chart" [dev]
with 2 replica(s) of nginx:1.25-alpine.

$ helm get hooks pratyush-web -n helm-demo | grep -E 'Source|helm.sh/hook'
# Source: pratyush-web/templates/tests/test-connection.yaml
    "helm.sh/hook": test

$ helm get metadata pratyush-web -n helm-demo
NAME: pratyush-web
CHART: pratyush-web
VERSION: 0.1.0
APP_VERSION: 1.25-alpine
ANNOTATIONS: 
LABELS: modifiedAt=1791395672,name=pratyush-web,owner=helm,status=deployed,version=1
DEPENDENCIES: 
NAMESPACE: helm-demo
REVISION: 1
STATUS: deployed
DEPLOYED_AT: 2026-10-07T23:24:20+05:30
APPLY_METHOD: server-side apply

$ helm get all pratyush-web -n helm-demo | grep -E '^[A-Z][A-Z -]+:'
NAME: pratyush-web
LAST DEPLOYED: Wed Oct  7 23:24:20 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 1
CHART: pratyush-web
VERSION: 0.1.0
DESCRIPTION: Install complete
USER-SUPPLIED VALUES:
COMPUTED VALUES:
HOOKS:
MANIFEST:
NOTES:
  (section headers only - 'get all' is values + hooks + manifest + notes in one)

==============================================================
STEP 10 - helm upgrade --set (revision 2)
==============================================================
$ helm upgrade pratyush-web ./pratyush-web -n helm-demo --set replicaCount=3 --set 'web.message=Upgraded with --set' --wait --timeout 120s | head -n 7
Release "pratyush-web" has been upgraded. Happy Helming!
NAME: pratyush-web
LAST DEPLOYED: Wed Oct  7 23:24:37 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 2
DESCRIPTION: Upgrade complete

$ kubectl get deploy pratyush-web -n helm-demo
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
pratyush-web   3/3     3            3           23s
  | message     : Upgraded with --set
  | environment : dev
  | owner       : Pratyush Mohanty (24BCS10238)
  | release     : pratyush-web (revision 2) in namespace helm-demo
  | chart       : pratyush-web-0.1.0
  | Server: nginx/1.25.5
$ helm get values pratyush-web -n helm-demo
USER-SUPPLIED VALUES:
replicaCount: 3
web:
  message: Upgraded with --set

==============================================================
STEP 11 - helm upgrade -f values-staging.yaml (revision 3)
==============================================================
$ helm upgrade pratyush-web ./pratyush-web -n helm-demo -f values-staging.yaml --wait --timeout 120s | head -n 7
Release "pratyush-web" has been upgraded. Happy Helming!
NAME: pratyush-web
LAST DEPLOYED: Wed Oct  7 23:24:43 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 3
DESCRIPTION: Upgrade complete

$ kubectl get deploy pratyush-web -n helm-demo -o wide
NAME           READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS     IMAGES              SELECTOR
pratyush-web   2/2     2            2           46s   pratyush-web   nginx:1.27-alpine   app.kubernetes.io/instance=pratyush-web,app.kubernetes.io/name=pratyush-web
  | message     : Staging build - now on nginx 1.27
  | environment : staging
  | owner       : Pratyush Mohanty (24BCS10238)
  | release     : pratyush-web (revision 3) in namespace helm-demo
  | chart       : pratyush-web-0.1.0
  | Server: nginx/1.27.5
$ helm get values pratyush-web -n helm-demo
USER-SUPPLIED VALUES:
image:
  tag: 1.27-alpine
replicaCount: 2
web:
  environment: staging
  message: Staging build - now on nginx 1.27

>>> The --set values from revision 2 are GONE (replicas 3 -> 2, message replaced).
    A plain 'helm upgrade' starts again from the chart defaults plus only the
    overrides given on THIS command line.

==============================================================
STEP 12 - helm upgrade --reuse-values (revision 4)
==============================================================
$ helm upgrade pratyush-web ./pratyush-web -n helm-demo --reuse-values --set replicaCount=4 --wait --timeout 120s | head -n 7
Release "pratyush-web" has been upgraded. Happy Helming!
NAME: pratyush-web
LAST DEPLOYED: Wed Oct  7 23:25:07 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 4
DESCRIPTION: Upgrade complete

$ helm get values pratyush-web -n helm-demo
USER-SUPPLIED VALUES:
image:
  tag: 1.27-alpine
replicaCount: 4
web:
  environment: staging
  message: Staging build - now on nginx 1.27
$ kubectl get deploy pratyush-web -n helm-demo
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
pratyush-web   4/4     4            4           60s
>>> --reuse-values kept the staging values and merged replicaCount=4 on top.

==============================================================
STEP 13 - helm history: every revision is kept
==============================================================
$ helm history pratyush-web -n helm-demo
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	DESCRIPTION     
1       	Wed Oct  7 23:24:20 2026	superseded	pratyush-web-0.1.0	1.25-alpine	Install complete
2       	Wed Oct  7 23:24:37 2026	superseded	pratyush-web-0.1.0	1.25-alpine	Upgrade complete
3       	Wed Oct  7 23:24:43 2026	superseded	pratyush-web-0.1.0	1.25-alpine	Upgrade complete
4       	Wed Oct  7 23:25:07 2026	deployed  	pratyush-web-0.1.0	1.25-alpine	Upgrade complete

Where that history lives - one Secret per revision, in the release namespace:
$ kubectl get secrets -n helm-demo -l owner=helm
NAME                                 TYPE                 DATA   AGE
sh.helm.release.v1.pratyush-web.v1   helm.sh/release.v1   1      60s
sh.helm.release.v1.pratyush-web.v2   helm.sh/release.v1   1      43s
sh.helm.release.v1.pratyush-web.v3   helm.sh/release.v1   1      37s
sh.helm.release.v1.pratyush-web.v4   helm.sh/release.v1   1      13s

Each Secret holds the whole release (chart, values, rendered manifest) as
base64 + gzip'd JSON:
$ kubectl get secret sh.helm.release.v1.pratyush-web.v2 -n helm-demo -o jsonpath='{.data.release}' | base64 -d | base64 -d | gunzip | python3 -c 'import json,sys; r=json.load(sys.stdin); print(sorted(r)); print("config =", r["config"])'
['apply_method', 'chart', 'config', 'hooks', 'info', 'manifest', 'name', 'namespace', 'version']
config = {'replicaCount': 3, 'web': {'message': 'Upgraded with --set'}}

==============================================================
STEP 14 - helm rollback to revision 1 (creates revision 5)
==============================================================
$ helm rollback pratyush-web 1 -n helm-demo --wait --timeout 120s
Rollback was a success! Happy Helming!

$ helm history pratyush-web -n helm-demo
REVISION	UPDATED                 	STATUS    	CHART             	APP VERSION	DESCRIPTION     
1       	Wed Oct  7 23:24:20 2026	superseded	pratyush-web-0.1.0	1.25-alpine	Install complete
2       	Wed Oct  7 23:24:37 2026	superseded	pratyush-web-0.1.0	1.25-alpine	Upgrade complete
3       	Wed Oct  7 23:24:43 2026	superseded	pratyush-web-0.1.0	1.25-alpine	Upgrade complete
4       	Wed Oct  7 23:25:07 2026	superseded	pratyush-web-0.1.0	1.25-alpine	Upgrade complete
5       	Wed Oct  7 23:25:20 2026	deployed  	pratyush-web-0.1.0	1.25-alpine	Rollback to 1   

  | message     : Hello from Pratyush's first Helm chart
  | environment : dev
  | owner       : Pratyush Mohanty (24BCS10238)
  | release     : pratyush-web (revision 1) in namespace helm-demo
  | chart       : pratyush-web-0.1.0
  | Server: nginx/1.25.5
$ helm get values pratyush-web -n helm-demo
USER-SUPPLIED VALUES:
null

>>> The page says 'revision 1' while the release is at revision 5: rollback
    re-applies the manifest STORED for revision 1, it does not re-render it.

==============================================================
STEP 15 - helm test: run the chart's test hook (templates/tests/)
==============================================================
$ helm test pratyush-web -n helm-demo --logs
NAME: pratyush-web
LAST DEPLOYED: Wed Oct  7 23:25:20 2026
NAMESPACE: helm-demo
STATUS: deployed
REVISION: 5
DESCRIPTION: Rollback to 1
TEST SUITE:     pratyush-web-test-connection
Last Started:   Wed Oct  7 23:25:45 2026
Last Completed: Wed Oct  7 23:25:47 2026
Phase:          Succeeded

POD LOGS: pratyush-web-test-connection (wget)
message     : Hello from Pratyush's first Helm chart
environment : dev
owner       : Pratyush Mohanty (24BCS10238)
release     : pratyush-web (revision 1) in namespace helm-demo
chart       : pratyush-web-0.1.0


==============================================================
STEP 16 - helm uninstall --keep-history
==============================================================
$ helm uninstall pratyush-web -n helm-demo --keep-history --wait
release "pratyush-web" uninstalled

$ kubectl get all,cm,sa -n helm-demo
NAME                               READY   STATUS      RESTARTS   AGE
pod/curl                           1/1     Running     0          76s
pod/pratyush-web-test-connection   0/1     Completed   0          4s

NAME                         DATA   AGE
configmap/kube-root-ca.crt   1      89s

NAME                     AGE
serviceaccount/default   89s
  The Deployment, Service, ConfigMap and ServiceAccount are gone. Two pods remain:
  - curl: I created it with kubectl, so Helm never owned it
  - pratyush-web-test-connection: a test HOOK; hook resources are not tracked
    as part of the release, so uninstall leaves them behind

$ helm list -n helm-demo
NAME        	NAMESPACE	REVISION	UPDATED                             	STATUS     	CHART             	APP VERSION
pratyush-web	helm-demo	5       	2026-10-07 23:25:20.620101 +0530 IST	uninstalled	pratyush-web-0.1.0	1.25-alpine
$ helm list -n helm-demo --deployed
NAME	NAMESPACE	REVISION	UPDATED	STATUS	CHART	APP VERSION
$ helm history pratyush-web -n helm-demo
REVISION	UPDATED                 	STATUS     	CHART             	APP VERSION	DESCRIPTION            
1       	Wed Oct  7 23:24:20 2026	superseded 	pratyush-web-0.1.0	1.25-alpine	Install complete       
2       	Wed Oct  7 23:24:37 2026	superseded 	pratyush-web-0.1.0	1.25-alpine	Upgrade complete       
3       	Wed Oct  7 23:24:43 2026	superseded 	pratyush-web-0.1.0	1.25-alpine	Upgrade complete       
4       	Wed Oct  7 23:25:07 2026	superseded 	pratyush-web-0.1.0	1.25-alpine	Upgrade complete       
5       	Wed Oct  7 23:25:20 2026	uninstalled	pratyush-web-0.1.0	1.25-alpine	Uninstallation complete

Because history was kept, the release can be brought back:
$ helm rollback pratyush-web 4 -n helm-demo --wait --timeout 120s
Rollback was a success! Happy Helming!
$ helm list -n helm-demo
NAME        	NAMESPACE	REVISION	UPDATED                             	STATUS  	CHART             	APP VERSION
pratyush-web	helm-demo	6       	2026-10-07 23:25:49.581863 +0530 IST	deployed	pratyush-web-0.1.0	1.25-alpine
  | message     : Staging build - now on nginx 1.27
  | environment : staging
  | owner       : Pratyush Mohanty (24BCS10238)
  | release     : pratyush-web (revision 4) in namespace helm-demo
  | chart       : pratyush-web-0.1.0
  | Server: nginx/1.27.5

==============================================================
STEP 17 - helm uninstall (plain): resources AND history removed
==============================================================
$ helm uninstall pratyush-web -n helm-demo --wait
release "pratyush-web" uninstalled
$ helm history pratyush-web -n helm-demo
Error: release: not found
$ kubectl get secrets -n helm-demo -l owner=helm
No resources found in helm-demo namespace.

==============================================================
STEP 18 - helm repo add / list / update
==============================================================
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
"prometheus-community" has been added to your repositories
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
"ingress-nginx" has been added to your repositories
$ helm repo list
NAME                	URL                                               
prometheus-community	https://prometheus-community.github.io/helm-charts
ingress-nginx       	https://kubernetes.github.io/ingress-nginx        
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "ingress-nginx" chart repository
...Successfully got an update from the "prometheus-community" chart repository
Update Complete. ⎈Happy Helming!⎈

==============================================================
STEP 19 - helm search repo: search the repos added locally
==============================================================
$ helm search repo nginx
NAME                                          	CHART VERSION	APP VERSION	DESCRIPTION                                       
ingress-nginx/ingress-nginx                   	4.15.1       	1.15.1     	Ingress controller for Kubernetes using NGINX a...
prometheus-community/prometheus-nginx-exporter	1.23.1       	1.5.3      	A Helm chart for NGINX Prometheus Exporter        

$ helm search repo ingress-nginx/ingress-nginx --versions | head -n 5
NAME                       	CHART VERSION	APP VERSION	DESCRIPTION                                       
ingress-nginx/ingress-nginx	4.15.1       	1.15.1     	Ingress controller for Kubernetes using NGINX a...
ingress-nginx/ingress-nginx	4.15.0       	1.15.0     	Ingress controller for Kubernetes using NGINX a...
ingress-nginx/ingress-nginx	4.14.5       	1.14.5     	Ingress controller for Kubernetes using NGINX a...
ingress-nginx/ingress-nginx	4.14.4       	1.14.4     	Ingress controller for Kubernetes using NGINX a...

$ helm search repo kube-prometheus-stack
NAME                                      	CHART VERSION	APP VERSION	DESCRIPTION                                       
prometheus-community/kube-prometheus-stack	92.1.0       	v0.94.1    	kube-prometheus-stack collects Kubernetes manif...

helm show reads a chart without installing it:
$ helm show chart ingress-nginx/ingress-nginx | grep -E '^(name|version|appVersion|kubeVersion|description):'
appVersion: 1.15.1
description: Ingress controller for Kubernetes using NGINX as a reverse proxy and
kubeVersion: '>=1.21.0-0'
name: ingress-nginx
version: 4.15.1

==============================================================
STEP 20 - helm search hub: search Artifact Hub (no repo needed)
==============================================================
$ helm search hub nginx --max-col-width 45 | head -n 8
URL                                          	CHART VERSION  	APP VERSION                                  	DESCRIPTION                                  
https://artifacthub.io/packages/helm/cloud...	0.16.12        	1.31.6                                       	Nginx is a high-performance HTTP server an...
https://artifacthub.io/packages/helm/quenc...	0.0.15         	1.30.5                                       	High-performance web server, reverse proxy...
https://artifacthub.io/packages/helm/kraka...	1.0.0          	1.19.0                                       	Nginx Helm chart for Kubernetes              
https://artifacthub.io/packages/helm/dhine...	25.2.1         	1.31.6                                       	NGINX Open Source is a web server that can...
https://artifacthub.io/packages/helm/bitna...	25.2.1         	1.31.6                                       	NGINX Open Source is a web server that can...
https://artifacthub.io/packages/helm/niceo...	1.31.1+niceos.2	1.31.1                                       	Bitnami-compatible NGINX Helm chart for Ni...
https://artifacthub.io/packages/helm/bitna...	13.2.12        	1.23.2                                       	NGINX Open Source is a web server that can...
  ...
$ helm search hub nginx | tail -n +2 | wc -l | tr -d ' '
304
  (charts matching 'nginx' on Artifact Hub)

==============================================================
STEP 21 - helm repo remove
==============================================================
$ helm repo remove prometheus-community ingress-nginx
"prometheus-community" has been removed from your repositories
"ingress-nginx" has been removed from your repositories
$ helm repo list
no repositories to show

==============================================================
CLEANUP
==============================================================
release "pratyush-web" uninstalled
namespace "helm-demo" deleted
namespace helm-demo and repos removed
```
