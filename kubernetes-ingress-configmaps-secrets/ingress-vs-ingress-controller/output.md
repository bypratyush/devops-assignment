# Ingress vs Ingress Controller - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
SETUP - an app and a Service in namespace s12-ingress
==============================================================
namespace/s12-ingress created
deployment.apps/hello created
service/hello created
Waiting for deployment "hello" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "hello" rollout to finish: 1 of 2 updated replicas are available...
deployment "hello" successfully rolled out

==============================================================
1. The Ingress CONTROLLER is a real program running in a pod
==============================================================
NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ingress-nginx-controller   1/1     1            1           19d

NAME                                            READY   STATUS    RESTARTS        AGE
pod/ingress-nginx-controller-746c8469d8-7lzqh   1/1     Running   32 (4d7h ago)   19d

NAME                                         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
service/ingress-nginx-controller             NodePort    10.96.159.44   <none>        80:32007/TCP,443:31472/TCP   19d
service/ingress-nginx-controller-admission   ClusterIP   10.96.60.175   <none>        443/TCP                      19d

--- what runs inside it ---
  PID   USER     TIME  COMMAND
     11 www-data  5:09 /nginx-ingress-controller --election-id=ingress-nginx-leader --controller-class=k8s.io/ingress-nginx --ingress-class=nginx --conf
     33 www-data  0:01 nginx: master process /usr/bin/nginx -c /etc/nginx/nginx.conf

  A Go process (/nginx-ingress-controller) watches the API server and writes
  nginx.conf; a normal nginx master/worker set actually proxies the traffic.

--- the flags that decide WHICH Ingress objects it takes ---
  --controller-class=k8s.io/ingress-nginx
  --ingress-class=nginx
  --watch-ingress-without-class=true
  --publish-status-address=localhost

==============================================================
2. The IngressClass: the link between an Ingress and a controller
==============================================================
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       19d

  IngressClass 'nginx' -> spec.controller = k8s.io/ingress-nginx
  default class?       -> '' (annotation not set)
  An Ingress names a class; the class names a controller; the controller pod
  only acts on Ingresses whose class points at its --controller-class.

==============================================================
3. Two Ingress objects, identical except ingressClassName
==============================================================
ingress.networking.k8s.io/routed created
ingress.networking.k8s.io/orphan created
NAME     CLASS     HOSTS              ADDRESS     PORTS   AGE
orphan   traefik   orphan.s12.local               80      18s
routed   nginx     routed.s12.local   localhost   80      18s

  routed (class nginx)  : ADDRESS filled in - a controller claimed it and wrote its status
  orphan (class traefik): no ADDRESS - no IngressClass 'traefik', no controller, nobody
                          ever looks at it. The API server accepted it anyway.

==============================================================
4. Does it route?
==============================================================
  curl -H 'Host: routed.s12.local    ' http://localhost/  ->  HTTP 200  served by hello-794b94bfb5-ptg9p
  curl -H 'Host: orphan.s12.local    ' http://localhost/  ->  HTTP 404  (<head>404 Not Found</head>)

  The orphan request still reaches ingress-nginx (port 80 belongs to it), but
  the controller has no rule for that host, so its default server answers 404.

==============================================================
5. Events and controller logs: who touched what
==============================================================

--- kubectl describe ingress routed (events) ---
  Events:
    Type    Reason  Age               From                      Message
    ----    ------  ----              ----                      -------
    Normal  Sync    7s (x2 over 19s)  nginx-ingress-controller  Scheduled for sync

--- kubectl describe ingress orphan (events) ---
  Events:             <none>

--- controller log lines about namespace s12-ingress ---
  I1007 18:24:59.060594      11 main.go:107] "successfully validated configuration, accepting" ingress="s12-ingress/routed"
  I1007 18:24:59.073151      11 store.go:440] "Found valid IngressClass" ingress="s12-ingress/routed" ingressclass="nginx"
  I1007 18:24:59.121482      11 main.go:107] "successfully validated configuration, accepting" ingress="s12-ingress/orphan"
  I1007 18:24:59.137086      11 store.go:436] "Ignoring ingress because of error while validating ingress class" ingress="s12-ingress/orphan" error="no object matching key \"traefik\" in local store"

==============================================================
6. What the controller GENERATED from the routed Ingress (inside its pod)
==============================================================

--- nginx.conf: the server block for routed.s12.local ---
  1077:	## start server routed.s12.local
  1078-	server {
  1079:		server_name routed.s12.local ;
  1080-		
  1081-		http2 on;
  			set $namespace      "s12-ingress";
  			set $ingress_name   "routed";
  			set $service_name   "hello";
  			set $service_port   "80";

--- nginx.conf: anything for orphan.s12.local? ---
  matches: 0

--- the pod IPs are NOT in nginx.conf - they are pushed to Lua at runtime (/dbg backends) ---
        "address": "10.244.1.7",
        "port": "8080"
        "address": "10.244.2.37",
        "port": "8080"
    "port": 80,
            "port": 80,
  pod: hello-794b94bfb5-ptg9p   10.244.1.7
  pod: hello-794b94bfb5-txjjt   10.244.2.37

  Endpoint changes do not even need an nginx reload; Ingress rule changes do.

==============================================================
7. Fix the orphan: point it at a class that has a controller
==============================================================
$ kubectl patch ingress orphan -p '{"spec":{"ingressClassName":"nginx"}}'
ingress.networking.k8s.io/orphan patched
NAME     CLASS   HOSTS              ADDRESS     PORTS   AGE
orphan   nginx   orphan.s12.local   localhost   80      78s
routed   nginx   routed.s12.local   localhost   80      78s
  curl -H 'Host: orphan.s12.local    ' http://localhost/  ->  HTTP 200  served by hello-794b94bfb5-ptg9p
  nginx.conf matches for orphan.s12.local now: 3

==============================================================
8. And an Ingress with NO class at all?
==============================================================
ingress.networking.k8s.io/classless created
NAME        CLASS    HOSTS                 ADDRESS     PORTS   AGE
classless   <none>   classless.s12.local   localhost   80      58s
  curl -H 'Host: classless.s12.local ' http://localhost/  ->  HTTP 200  served by hello-794b94bfb5-ptg9p

  Served - but only because this ingress-nginx runs with
  --watch-ingress-without-class=true. Without that flag (and with no IngressClass
  marked default) it would sit exactly like 'orphan' did.

==============================================================
DONE
==============================================================
```
