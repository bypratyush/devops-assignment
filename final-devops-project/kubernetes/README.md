# Kubernetes

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Only the bootstrap lives here. Everything else is in the Helm chart
([../helm/lostfound](../helm/lostfound/)), because the same objects are needed in
dev and prod with different values, and Argo CD deploys the chart.

| File | Why it is separate from the chart |
|---|---|
| [namespace.yaml](namespace.yaml) | The namespace must exist (with its Pod Security labels) before anything is installed into it. Argo CD re-creates the same labels via `managedNamespaceMetadata`. |

One more object is created by hand, on purpose, and is **not** in Git:

```bash
kubectl -n lostfound create secret generic lostfound-db --from-literal=DB_PASSWORD="$(openssl rand -hex 16)"
```

## What the chart creates (prod values)

| Requirement | Object | Detail |
|---|---|---|
| Deployment | `lostfound-backend`, `lostfound-frontend` | 2 replicas each, `maxUnavailable: 0`, non-root, read-only root filesystem, all capabilities dropped |
| Service | `lostfound-backend` (8000), `lostfound-frontend` (80), `lostfound-db` (headless) | all ClusterIP; only the Ingress is exposed |
| ConfigMap | `lostfound-config` | APP_ENV, LOG_LEVEL, CAMPUS_NOTICE, DB host/name/user. A `checksum/config` pod annotation rolls the pods when it changes |
| Secret | `lostfound-db` | DB_PASSWORD, used by Postgres and the backend (`existingSecret` in prod) |
| Ingress | `lostfound` | host `lostfound.local`: `/api` -> backend, `/` -> frontend |
| HPA | `lostfound-backend` | 2-6 replicas at 60% CPU, scale-down stabilisation 60s |
| Probes | backend | startup + liveness on `/health` (no DB), readiness on `/ready` (checks the DB) |
| Storage | `lostfound-db` StatefulSet | `volumeClaimTemplates` -> PVC `data-lostfound-db-0`, 2Gi, `standard` (local-path) |
| Monitoring | `ServiceMonitor` | scrapes `/metrics`, see [../monitoring](../monitoring/) |

Why liveness and readiness use different endpoints: if the database goes down,
`/ready` fails and the pods are taken out of the Service, but `/health` still
passes, so Kubernetes does not restart every backend pod in a loop for a problem
that a restart cannot fix.

## The running result

```text
$ kubectl -n lostfound get deploy,sts,svc,ingress,hpa,pvc
NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/lostfound-backend    2/2     2            2           15m
deployment.apps/lostfound-frontend   2/2     2            2           15m

NAME                            READY   AGE
statefulset.apps/lostfound-db   1/1     15m

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/lostfound-backend    ClusterIP   10.96.7.69      <none>        8000/TCP   15m
service/lostfound-db         ClusterIP   None            <none>        5432/TCP   15m
service/lostfound-frontend   ClusterIP   10.96.217.239   <none>        80/TCP     15m

NAME                                  CLASS   HOSTS             ADDRESS     PORTS   AGE
ingress.networking.k8s.io/lostfound   nginx   lostfound.local   localhost   80      15m

NAME                                                    REFERENCE                      TARGETS       MINPODS   MAXPODS   REPLICAS
horizontalpodautoscaler.autoscaling/lostfound-backend   Deployment/lostfound-backend   cpu: 4%/60%   2         6         2

NAME                                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
persistentvolumeclaim/data-lostfound-db-0   Bound    pvc-16f7144b-7b95-4970-9793-f9bc78396968   2Gi        RWO            standard
```

The PVC is 46 minutes old while everything else is 15: it survived the handover
from `helm install` to Argo CD (see [../gitops](../gitops/README.md)).
