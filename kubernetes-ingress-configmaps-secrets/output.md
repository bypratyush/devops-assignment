# Ingress, ConfigMaps and Secrets - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-09-18.

```text

==============================================================
SETUP
==============================================================
configmap/app-config created
secret/app-secret created
deployment.apps/config-demo created
service/config-demo-svc created
deployment.apps/second-app created
service/second-app-svc created
ingress.networking.k8s.io/demo-ingress created
deployment "config-demo" successfully rolled out
deployment "second-app" successfully rolled out

==============================================================
1. CONFIGMAP - non-secret configuration, kept out of the image
==============================================================
NAME         DATA   AGE
app-config   4      1s


--- its contents ---
error: error parsing jsonpath {range $k,$v := .data}  {$k} = {$v}{"\n"}{end}, unrecognized character in action: U+002C ','

  The point: ONE image, many environments. The image has no environment
  baked in, so the same artifact you tested is the one you ship.

==============================================================
2. CONSUMING A CONFIGMAP AS ENVIRONMENT VARIABLES
==============================================================
  pod: config-demo-694d8cf9d9-87l46

$ kubectl exec config-demo-694d8cf9d9-87l46 -- env | grep -E 'APP_ENV|LOG_LEVEL|FEATURE_FLAG'
  LOG_LEVEL=info
  APP_ENV=production
  FEATURE_FLAG=enabled

  Two ways, both used in app.yaml:
    configMapKeyRef  one specific key -> one env var
    envFrom          EVERY key in the ConfigMap becomes an env var

==============================================================
3. CONSUMING A CONFIGMAP AS FILES (a mounted volume)
==============================================================
$ kubectl exec config-demo-694d8cf9d9-87l46 -- ls /etc/app-config
  APP_ENV
  FEATURE_FLAG
  LOG_LEVEL
  app.properties

$ kubectl exec config-demo-694d8cf9d9-87l46 -- cat /etc/app-config/app.properties
  server.port=8080
  server.timeout=30
  cache.enabled=true

  Each KEY becomes a FILE, each VALUE its content. This is how you inject
  a whole config file (nginx.conf, application.yml) without rebuilding.

==============================================================
4. THE UPDATE BEHAVIOUR THAT CATCHES EVERYONE
==============================================================
Changing LOG_LEVEL from info to debug in the ConfigMap:
  patched. Now waiting for the kubelet to sync the mounted volume...


--- the MOUNTED FILE updated itself, with no restart ---
  server.port=8080
  server.timeout=60
  cache.enabled=false


--- but the ENVIRONMENT VARIABLE did NOT ---
  LOG_LEVEL=info
  still 'info', even though the ConfigMap now says 'debug'.

  >>> THE RULE:
      Mounted volumes  update live (kubelet re-syncs, ~60s by default).
      Environment vars are injected ONCE at container start and NEVER
      change. To pick them up you must restart the pods:
          kubectl rollout restart deployment/config-demo

  This is the single most common ConfigMap surprise in production.

==============================================================
5. SECRETS - and what they are actually NOT
==============================================================
NAME         TYPE     DATA   AGE
app-secret   Opaque   2      4s


--- the stored value ---
  stored : c3VwM3JzM2NyM3Q=

--- decoding it - anyone with read access can do this ---
  decoded: sup3rs3cr3t

  >>> A Secret is BASE64-ENCODED, NOT ENCRYPTED.
      Base64 is an encoding, not a cipher. Anyone who can read the
      Secret object can read the value, and by default it is stored
      in etcd in plain text.

      To make Secrets actually secret you need:
        - encryption at rest in etcd (EncryptionConfiguration)
        - RBAC that restricts who can 'get secrets'
        - or an external store: Vault, AWS/GCP Secrets Manager,
          External Secrets Operator, Sealed Secrets

      NEVER commit a Secret manifest with real values to git.

==============================================================
6. CONSUMING A SECRET
==============================================================
$ kubectl exec config-demo-694d8cf9d9-87l46 -- env | grep DB_PASSWORD
  DB_PASSWORD=sup3rs3cr3t

$ kubectl exec config-demo-694d8cf9d9-87l46 -- ls /etc/app-secret
  API_KEY
  DB_PASSWORD
$ kubectl exec config-demo-694d8cf9d9-87l46 -- cat /etc/app-secret/API_KEY
  ak_live_9f8e7d6c5b4a

  Prefer FILES over env vars for secrets: env vars leak into crash dumps,
  child processes, 'docker inspect' and logging of the process table.

==============================================================
7. INGRESS - one entry point, HTTP routing to many services
==============================================================
NAME           CLASS   HOSTS                                 ADDRESS   PORTS   AGE
demo-ingress   nginx   app.local,second.local,shared.local             80      5s


--- the rules ---
Rules:
  Host          Path  Backends
  ----          ----  --------
  app.local     
                /   config-demo-svc:80 (10.244.1.199:8080)
  second.local  
                /   second-app-svc:80 (10.244.1.200:8080)
  shared.local  
                /one   config-demo-svc:80 (10.244.1.199:8080)
                /two   second-app-svc:80 (10.244.1.200:8080)
Annotations:    nginx.ingress.kubernetes.io/rewrite-target: /

  A Service is L4 (TCP). An Ingress is L7 (HTTP): it can route on
  HOSTNAME and PATH, terminate TLS, and rewrite URLs.

==============================================================
8. THE INGRESS CONTROLLER - the piece that does the work
==============================================================
  ingress-nginx-controller-746c8469d8-7lzqh      Running

  An Ingress OBJECT is only a rule. Nothing happens without a CONTROLLER
  watching for Ingress objects and configuring a real proxy. Here that is
  ingress-nginx; on a cloud it might be an ALB or GCE controller.

  ingressClassName: nginx  is what says WHICH controller should act.

==============================================================
9. HOST-BASED ROUTING, tested for real
==============================================================
This kind cluster maps host port 80 -> the ingress controller,
so curl with a Host header reaches it exactly as a browser would.

  curl -H 'Host: app.local    ' http://localhost/   ->  served by config-demo-694d8cf9d9-87l46
  curl -H 'Host: second.local ' http://localhost/   ->  served by second-app-85984cb765-vrzlq

  Same IP, same port, different backend - chosen purely by the Host header.

==============================================================
10. PATH-BASED ROUTING
==============================================================
  curl -H 'Host: shared.local' http://localhost/one  ->  served by config-demo-694d8cf9d9-87l46
  curl -H 'Host: shared.local' http://localhost/two  ->  served by second-app-85984cb765-vrzlq

  One hostname, two paths, two different Deployments. This is how you put
  /api and /app behind a single domain without a public IP per service.

  pathType: Prefix   matches /one and /one/anything
  pathType: Exact    matches ONLY /one

==============================================================
11. WHY THIS BEATS A LoadBalancer PER SERVICE
==============================================================
    Without Ingress: every service needs its own LoadBalancer.
      10 services = 10 cloud load balancers = 10 public IPs = 10x the bill.

    With Ingress:   ONE LoadBalancer -> the ingress controller -> every service.
      10 services = 1 load balancer, 1 IP, 1 TLS certificate, one place for
      auth, rate limiting, redirects and rewrites.

==============================================================
DONE
==============================================================
```
