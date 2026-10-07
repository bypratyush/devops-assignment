# Troubleshooting - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
SETUP - namespace s12-trouble
==============================================================
namespace/s12-trouble created

==============================================================
ISSUE 1 - app gets 'password authentication failed' with the right password
==============================================================
secret/db-server-secret created
deployment.apps/postgres created
service/postgres created
Waiting for deployment "postgres" rollout to finish: 0 of 1 updated replicas are available...
deployment "postgres" successfully rolled out
secret/app-db-secret created
deployment.apps/app created
Waiting for deployment "app" rollout to finish: 0 out of 1 new replicas have been updated...
Waiting for deployment "app" rollout to finish: 0 of 1 updated replicas are available...
deployment "app" successfully rolled out

--- IDENTIFY: the app's own log ---
  18:26:07 psql: error: connection to server at "postgres" (10.96.109.23), port 5432 failed: FATAL:  password authentication failed for user "yatri_admin"
  18:26:13 psql: error: connection to server at "postgres" (10.96.109.23), port 5432 failed: FATAL:  password authentication failed for user "yatri_admin"
  18:26:18 psql: error: connection to server at "postgres" (10.96.109.23), port 5432 failed: FATAL:  password authentication failed for user "yatri_admin"

--- INVESTIGATE: the database is up and the user exists ---
NAME                        READY   STATUS    RESTARTS   AGE
postgres-7cfdc44884-qlcv8   1/1     Running   0          87s
  user: yatri_admin

--- INVESTIGATE: what is REALLY in the two secrets? (base64 -d | xxd) ---
  db-server-secret POSTGRES_PASSWORD:
    00000000: 6d79 7061 7373 776f 7264                 mypassword
  app-db-secret DB_PASSWORD (raw: bXlwYXNzd29yZAo=):
    00000000: 6d79 7061 7373 776f 7264 0a              mypassword.
  length inside the app container: 11 bytes (expected 10)

--- the two ways the value could have been encoded ---
  echo "mypassword" | base64     -> bXlwYXNzd29yZAo=
  echo -n "mypassword" | base64  -> bXlwYXNzd29yZA==

ROOT CAUSE: the Secret was encoded with plain 'echo', which appends 0x0a. The app
sends 'mypassword\n' (11 bytes); postgres correctly rejects it. kubectl get secret
and even 'base64 -d' on screen look right - only xxd/wc show the extra byte.

--- FIX: re-encode with echo -n, then restart the app (env vars are read only at start) ---
secret/app-db-secret configured
deployment.apps/app restarted
Waiting for deployment "app" rollout to finish: 0 out of 1 new replicas have been updated...
Waiting for deployment "app" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "app" rollout to finish: 1 old replicas are pending termination...
deployment "app" successfully rolled out

--- VERIFY ---
  00000000: 6d79 7061 7373 776f 7264                 mypassword
  18:26:29 connected as: yatri_admin
  18:26:34 connected as: yatri_admin

==============================================================
ISSUE 2 - Ingress returns 503 for backend.s12.local
==============================================================
deployment.apps/yatri-backend created
Waiting for deployment spec update to be observed...
Waiting for deployment "yatri-backend" rollout to finish: 0 out of 2 new replicas have been updated...
Waiting for deployment "yatri-backend" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "yatri-backend" rollout to finish: 1 of 2 updated replicas are available...
deployment "yatri-backend" successfully rolled out
service/broken-backend-service created
ingress.networking.k8s.io/backend created

--- IDENTIFY ---
  curl -H 'Host: backend.s12.local' http://localhost/ -> HTTP 503
  <head><title>503 Service Temporarily Unavailable</title></head>

--- INVESTIGATE: Ingress -> Service -> endpoints -> pods ---
NAME      CLASS   HOSTS               ADDRESS   PORTS   AGE
backend   nginx   backend.s12.local             80      8s
  Rules:
    Host               Path  Backends
    ----               ----  --------
    backend.s12.local  

  Selector:                 app=wrong-backend-name
  Port:                     http  80/TCP
  TargetPort:               8080/TCP
  Endpoints:                

NAME                           ADDRESSTYPE   PORTS     ENDPOINTS   AGE
broken-backend-service-2gz69   IPv4          <unset>   <unset>     8s

NAME                             READY   STATUS    RESTARTS   AGE   LABELS
yatri-backend-7d67b79d98-n4z58   1/1     Running   0          14s   app=yatri-backend,pod-template-hash=7d67b79d98,tier=api
yatri-backend-7d67b79d98-qd9tc   1/1     Running   0          14s   app=yatri-backend,pod-template-hash=7d67b79d98,tier=api

--- the controller says the same thing ---
  W1007 18:26:44.375807      11 controller.go:1216] Service "s12-trouble/broken-backend-service" does not have any active Endpoint.
  W1007 18:26:47.707951      11 controller.go:1216] Service "s12-trouble/broken-backend-service" does not have any active Endpoint.

ROOT CAUSE: the Service selector is app=wrong-backend-name; the pods are
app=yatri-backend. No pod matches, the EndpointSlice is empty, and ingress-nginx
has no upstream to send to, so it answers 503.

--- FIX: correct the selector ---
service/broken-backend-service configured

--- VERIFY ---
NAME                           ADDRESSTYPE   PORTS   ENDPOINTS                 AGE
broken-backend-service-2gz69   IPv4          8080    10.244.1.27,10.244.2.44   14s
  HTTP 200  served by yatri-backend-7d67b79d98-qd9tc
  HTTP 200  served by yatri-backend-7d67b79d98-n4z58
  HTTP 200  served by yatri-backend-7d67b79d98-n4z58

==============================================================
ISSUE 3 - pod never starts: CreateContainerConfigError
==============================================================
configmap/app-settings created
deployment.apps/settings-app created

--- IDENTIFY ---
NAME                            READY   STATUS                       RESTARTS   AGE
settings-app-7677748d99-sfpbs   0/1     CreateContainerConfigError   0          10s

--- INVESTIGATE: describe -> events ---
    ----     ------     ----             ----               -------
    Normal   Scheduled  10s              default-scheduler  Successfully assigned s12-trouble/settings-app-7677748d99-sfpbs to devops-hw-worker2
    Normal   Pulled     8s (x2 over 9s)  kubelet            spec.containers{app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
    Warning  Failed     8s (x2 over 9s)  kubelet            spec.containers{app}: Error: couldn't find key DB_HOST in ConfigMap s12-trouble/app-settings

--- INVESTIGATE: what keys does the ConfigMap really have? ---
  db_host = postgres.s12-trouble.svc.cluster.local
  log_level = info
  the pod asks for: DB_HOST

ROOT CAUSE: configMapKeyRef asks for key DB_HOST; the ConfigMap only has db_host.
Keys are case-sensitive, and a missing non-optional key blocks container creation
(it is not a crash - the container never exists, so there are no logs).
  kubectl logs: Error from server (BadRequest): container "app" in pod "settings-app-7677748d99-sfpbs" is waiting to start: CreateContainerConfigError

--- FIX: reference the key that exists ---
configmap/app-settings unchanged
deployment.apps/settings-app configured
Waiting for deployment "settings-app" rollout to finish: 0 out of 1 new replicas have been updated...
Waiting for deployment "settings-app" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "settings-app" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "settings-app" rollout to finish: 1 old replicas are pending termination...
deployment "settings-app" successfully rolled out

--- VERIFY ---
NAME                            READY   STATUS        RESTARTS   AGE
settings-app-7677748d99-sfpbs   0/1     Terminating   0          17s
settings-app-9747fdb59-vjgzs    1/1     Running       0          6s
  DB_HOST=postgres.s12-trouble.svc.cluster.local LOG_LEVEL=info

==============================================================
DONE
==============================================================
```
