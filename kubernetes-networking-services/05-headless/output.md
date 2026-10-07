# headless - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Deploy the headless service and a StatefulSet
==============================================================
service/web-service-headless created
statefulset.apps/web-stateful created
pod/headless-dns-client created
Waiting for 3 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 2 pods to be ready...
Waiting for 1 pods to be ready...
Waiting for 1 pods to be ready...
partitioned roll out complete: 3 new pods have been updated...
pod/headless-dns-client condition met

==============================================================
STEP 2 - The service has NO ClusterIP
==============================================================
NAME                   TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
web-service-headless   ClusterIP   None         <none>        80/TCP    4s

>>> CLUSTER-IP is 'None'. That is what 'headless' means.
    No virtual IP, no kube-proxy rules, no L4 load balancing.

==============================================================
STEP 3 - StatefulSet pods have STABLE, ORDERED names
==============================================================
NAME             READY   STATUS    RESTARTS   AGE   IP            NODE                NOMINATED NODE   READINESS GATES
web-stateful-0   1/1     Running   0          4s    10.244.1.34   devops-hw-worker2   <none>           <none>
web-stateful-1   1/1     Running   0          2s    10.244.2.36   devops-hw-worker    <none>           <none>
web-stateful-2   1/1     Running   0          2s    10.244.1.36   devops-hw-worker2   <none>           <none>

Names are web-stateful-0, -1, -2 - an ordinal index, not a random hash.
A Deployment would give you names like web-app-66865d4855-xxnrh.
Delete web-stateful-1 and it comes back as web-stateful-1, every time.

==============================================================
STEP 4 - Endpoints still exist (unlike ExternalName)
==============================================================
NAME                         ADDRESSTYPE   PORTS   ENDPOINTS                             AGE
web-service-headless-5dzh6   IPv4          80      10.244.1.34,10.244.2.36,10.244.1.36   4s

  10.244.1.34  hostname=web-stateful-0  pod=web-stateful-0
  10.244.2.36  hostname=web-stateful-1  pod=web-stateful-1
  10.244.1.36  hostname=web-stateful-2  pod=web-stateful-2

==============================================================
STEP 5 - THE KEY DIFFERENCE: DNS returns ALL pod IPs, not one VIP
==============================================================
$ nslookup web-service-headless.default.svc.cluster.local
  Name:	web-service-headless.default.svc.cluster.local
  Address: 10.244.2.36
  Name:	web-service-headless.default.svc.cluster.local
  Address: 10.244.1.34
  Name:	web-service-headless.default.svc.cluster.local
  Address: 10.244.1.36

Three A records - one per pod. A normal ClusterIP service would return
exactly ONE address (the virtual IP). The client now sees every backend
and can choose for itself.

==============================================================
STEP 6 - Every pod gets its OWN stable DNS name
==============================================================
Pattern:  <pod-name>.<service-name>.<namespace>.svc.cluster.local

  web-stateful-0.web-service-headless                  -> 10.244.1.34
  web-stateful-1.web-service-headless                  -> 10.244.2.36
  web-stateful-2.web-service-headless                  -> 10.244.1.36

This is what a Deployment CANNOT give you. It is the reason StatefulSets
and headless services go together.

==============================================================
STEP 7 - Addressing a SPECIFIC pod by name
==============================================================
  curl http://web-stateful-0.web-service-headless:80  ->  HTTP 200
  curl http://web-stateful-1.web-service-headless:80  ->  HTTP 200
  curl http://web-stateful-2.web-service-headless:80  ->  HTTP 200

Each request goes to that exact pod - no load balancing in between.

==============================================================
STEP 8 - Stable identity survives a pod deletion
==============================================================
before:  web-stateful-1  ip=10.244.2.36
deleting web-stateful-1 ...
after:   web-stateful-1  ip=10.244.2.37

The NAME came back identical (web-stateful-1) even though the IP changed.
Its DNS record follows it:
  Name:	web-stateful-1.web-service-headless.default.svc.cluster.local
  Address: 10.244.2.37

A peer that had written down 'web-stateful-1' in its config still finds it.
That is why databases and Kafka use this: peers reference each other by
STABLE NAME, and the cluster survives rescheduling.

==============================================================
STEP 9 - Ordered, one-at-a-time scaling
==============================================================
$ kubectl scale statefulset web-stateful --replicas=5
Waiting for 2 pods to be ready...
Waiting for 1 pods to be ready...
Waiting for 1 pods to be ready...
partitioned roll out complete: 5 new pods have been updated...
  web-stateful-0       Running
  web-stateful-1       Running
  web-stateful-2       Running
  web-stateful-3       Running
  web-stateful-4       Running

Pods are created strictly in order 0,1,2,3,4 - each waits for the
previous one to be Ready. Scaling DOWN reverses it: 4,3,2...
scaled back to 3

==============================================================
STEP 10 - Headless vs ClusterIP, side by side
==============================================================
                        ClusterIP                 Headless (clusterIP: None)
  Virtual IP            yes, one stable VIP       none
  DNS answer            the single VIP            every ready pod IP
  Load balancing        kube-proxy, L4            none - the client decides
  Per-pod DNS           no                        yes, with a StatefulSet
  kube-proxy rules      yes                       no
  Typical use           stateless web/API         databases, Kafka, Zookeeper,
                                                  Elasticsearch, any peer-aware
                                                  or leader-elected system

==============================================================
DONE
==============================================================
```
