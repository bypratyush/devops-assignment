# Service connectivity - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Deploy the broken manifests
==============================================================
deployment.apps/catalog-api created
service/catalog created
pod/shop-frontend created
Waiting for deployment "catalog-api" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "catalog-api" rollout to finish: 1 of 2 updated replicas are available...
deployment "catalog-api" successfully rolled out
pod/shop-frontend condition met

==============================================================
STEP 2 - IDENTIFY: the frontend cannot reach the catalog
==============================================================
NAME                           READY   STATUS    RESTARTS   AGE   IP             NODE                NOMINATED NODE   READINESS GATES
catalog-api-77ff5c6475-gf6rk   1/1     Running   0          2s    10.244.2.162   devops-hw-worker    <none>           <none>
catalog-api-77ff5c6475-qc66v   1/1     Running   0          2s    10.244.1.137   devops-hw-worker2   <none>           <none>
shop-frontend                  1/1     Running   0          1s    10.244.2.161   devops-hw-worker    <none>           <none>

$ kubectl -n s14-issues exec shop-frontend -- curl -sS -m 5 http://catalog
curl: (7) Failed to connect to catalog port 80 after 1 ms: Couldn't connect to server
HTTP 000
command terminated with exit code 7

Every pod is Running and Ready, yet the call fails. So the problem is
between the client and the pods: DNS, the Service, or the network.

==============================================================
STEP 3 - INVESTIGATE layer 1: DNS? Service? Endpoints?
==============================================================

--- DNS first - does the name resolve? ---
Name:	catalog.s14-issues.svc.cluster.local
Address: 10.96.118.60
Yes - it resolves to the Service's ClusterIP. DNS is fine.

--- the Service and what it selects ---
$ kubectl -n s14-issues get svc catalog -o wide
NAME      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE   SELECTOR
catalog   ClusterIP   10.96.118.60   <none>        80/TCP    2s    app=catalog

$ kubectl -n s14-issues get endpointslices -l kubernetes.io/service-name=catalog
NAME            ADDRESSTYPE   PORTS     ENDPOINTS   AGE
catalog-gcnwk   IPv4          <unset>   <unset>     2s

$ kubectl -n s14-issues describe svc catalog
Selector:                 app=catalog
TargetPort:               80/TCP
Endpoints:                

ENDPOINTS is <unset> / empty: the Service matched ZERO pods.

--- compare the selector with the real pod labels ---
$ kubectl -n s14-issues get pods -l issue=svc --show-labels
NAME                           READY   STATUS    RESTARTS   AGE   LABELS
catalog-api-77ff5c6475-gf6rk   1/1     Running   0          2s    app=catalog-api,issue=svc,pod-template-hash=77ff5c6475
catalog-api-77ff5c6475-qc66v   1/1     Running   0          2s    app=catalog-api,issue=svc,pod-template-hash=77ff5c6475
shop-frontend                  1/1     Running   0          1s    app=shop-frontend,issue=svc

$ kubectl -n s14-issues get pods -l app=catalog        (what the Service asks for)
No resources found in s14-issues namespace.
$ kubectl -n s14-issues get pods -l app=catalog-api    (what the pods actually have)
NAME                           READY   STATUS    RESTARTS   AGE
catalog-api-77ff5c6475-gf6rk   1/1     Running   0          3s
catalog-api-77ff5c6475-qc66v   1/1     Running   0          3s

==============================================================
STEP 4 - FIX layer 1 and re-test (patch the selector only)
==============================================================
$ kubectl -n s14-issues patch svc catalog -p '{"spec":{"selector":{"app":"catalog-api"}}}'
service/catalog patched

$ kubectl -n s14-issues get endpointslices -l kubernetes.io/service-name=catalog
NAME            ADDRESSTYPE   PORTS   ENDPOINTS                   AGE
catalog-gcnwk   IPv4          80      10.244.2.162,10.244.1.137   6s

$ kubectl -n s14-issues exec shop-frontend -- curl -sS -m 5 http://catalog
curl: (7) Failed to connect to catalog port 80 after 1 ms: Couldn't connect to server
HTTP 000
command terminated with exit code 7

Progress: the EndpointSlice now lists both pod IPs - but curl fails
exactly as before (exit 7, refused in a few ms). The SYMPTOM did not
change: with no endpoints kube-proxy rejects the connection itself, and
now something at the pod end refuses it. Only the endpoints check could
tell those two apart. Note the PORTS column of the EndpointSlice: 80.

==============================================================
STEP 5 - INVESTIGATE layer 2: which port does the app really use?
==============================================================
$ kubectl -n s14-issues get pod catalog-api-77ff5c6475-gf6rk -o jsonpath='{.spec.containers[0].ports}'
[{"containerPort":8080,"name":"http","protocol":"TCP"}]

$ kubectl -n s14-issues exec catalog-api-77ff5c6475-gf6rk -- netstat -tln
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      
tcp        0      0 :::8080                 :::*                    LISTEN      

Bypass the Service and hit the pod IP directly on both ports:
$ kubectl -n s14-issues exec shop-frontend -- curl -sS -m 5 http://10.244.2.162:80
HTTP 000
curl: (7) Failed to connect to 10.244.2.162 port 80 after 0 ms: Couldn't connect to server
command terminated with exit code 7
$ kubectl -n s14-issues exec shop-frontend -- curl -sS -m 5 http://10.244.2.162:8080
HTTP 200

==============================================================
STEP 6 - ROOT CAUSE
==============================================================
1. selector app=catalog did not match the pods (app=catalog-api), so the
   EndpointSlice was empty and kube-proxy had nowhere to send traffic.
2. targetPort 80, but nginx-hello listens on 8080, so once endpoints
   existed every connection was refused by the pod.

==============================================================
STEP 7 - FIX: apply the corrected manifest
==============================================================
$ kubectl diff -f fixed.yaml
  -    targetPort: 80
  +    targetPort: http

deployment.apps/catalog-api unchanged
service/catalog configured
pod/shop-frontend unchanged

==============================================================
STEP 8 - VERIFY
==============================================================
$ kubectl -n s14-issues get endpointslices -l kubernetes.io/service-name=catalog
NAME            ADDRESSTYPE   PORTS   ENDPOINTS                   AGE
catalog-gcnwk   IPv4          8080    10.244.2.162,10.244.1.137   11s

$ kubectl -n s14-issues describe svc catalog
Selector:                 app=catalog-api
TargetPort:               http/TCP
Endpoints:                10.244.2.162:8080,10.244.1.137:8080

first call after the change: HTTP 200

6 requests through the Service - which pod answered each one:
  catalog-api-77ff5c6475-gf6rk
  catalog-api-77ff5c6475-qc66v
  catalog-api-77ff5c6475-gf6rk
  catalog-api-77ff5c6475-gf6rk
  catalog-api-77ff5c6475-gf6rk
  catalog-api-77ff5c6475-qc66v

==============================================================
DONE
==============================================================
```
