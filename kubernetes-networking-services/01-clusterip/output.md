# clusterip - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-09-18.

```text

==============================================================
STEP 1 - Deploy the backend (3 nginx replicas)
==============================================================
deployment.apps/web-app-clusterip created
Waiting for deployment "web-app-clusterip" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "web-app-clusterip" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "web-app-clusterip" rollout to finish: 2 of 3 updated replicas are available...
deployment "web-app-clusterip" successfully rolled out

==============================================================
STEP 2 - Deploy the ClusterIP service
==============================================================
service/web-service-clusterip created

==============================================================
STEP 3 - Deploy the in-cluster client pod
==============================================================
pod/curl-client created
pod/curl-client condition met

==============================================================
STEP 4 - The 3 backend pods and their EPHEMERAL private IPs
==============================================================
NAME                                 READY   STATUS    RESTARTS   AGE   IP             NODE                NOMINATED NODE   READINESS GATES
web-app-clusterip-66865d4855-296p5   1/1     Running   0          2s    10.244.1.185   devops-hw-worker2   <none>           <none>
web-app-clusterip-66865d4855-6x9gw   1/1     Running   0          2s    10.244.2.177   devops-hw-worker    <none>           <none>
web-app-clusterip-66865d4855-zllng   1/1     Running   0          2s    10.244.1.186   devops-hw-worker2   <none>           <none>

==============================================================
STEP 5 - The service and its STABLE virtual IP
==============================================================
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE   SELECTOR
web-service-clusterip   ClusterIP   10.96.190.72   <none>        8080/TCP   1s    app=web-clusterip

ClusterIP = 10.96.190.72    (port 8080 -> targetPort 80)

==============================================================
STEP 6 - Endpoints: proof the selector matched all 3 pods
==============================================================
--- EndpointSlice (the modern API) ---
NAME                          ADDRESSTYPE   PORTS   ENDPOINTS                                AGE
web-service-clusterip-wfxbq   IPv4          80      10.244.2.177,10.244.1.185,10.244.1.186   1s

  10.244.2.177  ready=true  pod=web-app-clusterip-66865d4855-6x9gw
  10.244.1.185  ready=true  pod=web-app-clusterip-66865d4855-296p5
  10.244.1.186  ready=true  pod=web-app-clusterip-66865d4855-zllng

--- describe (human-readable view) ---
Name:                     web-service-clusterip
Namespace:                default
Labels:                   app=web-clusterip
Annotations:              <none>
Selector:                 app=web-clusterip
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.96.190.72
IPs:                      10.96.190.72
Port:                     http  8080/TCP
TargetPort:               80/TCP
Endpoints:                10.244.2.177:80,10.244.1.185:80,10.244.1.186:80
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

==============================================================
STEP 7 - TEST 1: reach the service BY NAME (CoreDNS)
==============================================================
HTTP 000 from http://web-service-clusterip:8080  (0.003023s)
command terminated with exit code 7

==============================================================
STEP 8 - TEST 2: reach the service BY ClusterIP
==============================================================
HTTP 000 from http://10.96.190.72:8080
command terminated with exit code 7

==============================================================
STEP 9 - TEST 3: reach the service BY FQDN
==============================================================
HTTP 000 from FQDN
command terminated with exit code 7

FQDN pattern:  <service>.<namespace>.svc.cluster.local

==============================================================
STEP 10 - The actual HTML the service returned
==============================================================
command terminated with exit code 7

==============================================================
STEP 11 - DNS resolution: the name really does resolve to the ClusterIP
==============================================================
Server:		10.96.0.10
Address:	10.96.0.10:53

** server can't find web-service-clusterip.cluster.local: NXDOMAIN

Name:	web-service-clusterip.default.svc.cluster.local
Address: 10.96.190.72

** server can't find web-service-clusterip.svc.cluster.local: NXDOMAIN

** server can't find web-service-clusterip.cluster.local: NXDOMAIN


** server can't find web-service-clusterip.svc.cluster.local: NXDOMAIN

10.96.190.72      web-service-clusterip.default.svc.cluster.local  web-service-clusterip.default.svc.cluster.local web-service-clusterip

Expected: web-service-clusterip resolves to 10.96.190.72

NOTE: the NXDOMAIN lines above are NORMAL. /etc/resolv.conf inside a pod has
      'search default.svc.cluster.local svc.cluster.local cluster.local', so the
      resolver tries each suffix in order and only one of them matches.

--- the pod's resolver config that makes short names work ---
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

==============================================================
STEP 12 - PROOF OF LOAD BALANCING across all 3 pods
==============================================================
The 3 nginx pods serve identical HTML, so instead of reading the response we
send 30 requests and then count them in each pod's own access log.

sent 30 requests through the service (tagged lbprobe-40763)

  web-app-clusterip-66865d4855-296p5       served 13 requests
  web-app-clusterip-66865d4855-6x9gw       served  8 requests
  web-app-clusterip-66865d4855-zllng       served  9 requests
  ----------------------------------------------------------
  TOTAL                                    served 30 requests

Traffic spread across all 3 pods => kube-proxy is load balancing at L4.

==============================================================
STEP 13 - PROOF it is INTERNAL ONLY (the defining ClusterIP property)
==============================================================
Trying to reach the ClusterIP 10.96.190.72:8080 from the laptop (outside the cluster):
  FAILED / timed out, exactly as expected.
  A ClusterIP is only routable from inside the cluster network.
  To expose it externally you need NodePort, LoadBalancer, or an Ingress.

For local debugging you can still tunnel to it:
  kubectl port-forward svc/web-service-clusterip 8080:8080   then open http://localhost:8080

==============================================================
STEP 14 - WHY ClusterIP EXISTS: pod IPs change, the service IP does not
==============================================================
--- pod IPs before deleting one ---
web-app-clusterip-66865d4855-296p5   10.244.1.185
web-app-clusterip-66865d4855-6x9gw   10.244.2.177
web-app-clusterip-66865d4855-zllng   10.244.1.186

deleting pod web-app-clusterip-66865d4855-296p5 ...
deployment "web-app-clusterip" successfully rolled out

--- pod IPs after (note the replacement pod has a NEW name and NEW IP) ---
web-app-clusterip-66865d4855-6x9gw   10.244.2.177
web-app-clusterip-66865d4855-pzshf   10.244.1.188
web-app-clusterip-66865d4855-zllng   10.244.1.186

--- but the ClusterIP is UNCHANGED ---
web-service-clusterip   10.96.190.72
  (was 10.96.190.72 before the pod was deleted)

--- and the service still answers, with endpoints re-bound automatically ---
HTTP 200 - still serving
  10.244.2.177  pod=web-app-clusterip-66865d4855-6x9gw
  10.244.1.186  pod=web-app-clusterip-66865d4855-zllng
  10.244.1.188  pod=web-app-clusterip-66865d4855-pzshf

==============================================================
DONE
==============================================================
```
