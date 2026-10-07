# Troubleshooting mini-project - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
1. DEPLOY THE APPLICATION
==============================================================
namespace/s14-mini created
deployment.apps/troubleshooting-app created
service/troubleshooting-service created
pod/curl-client created
Waiting for deployment "troubleshooting-app" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "troubleshooting-app" rollout to finish: 1 of 2 updated replicas are available...
deployment "troubleshooting-app" successfully rolled out
pod/curl-client condition met

$ kubectl -n s14-mini get pods
NAME                                   READY   STATUS    RESTARTS   AGE
curl-client                            1/1     Running   0          1s
troubleshooting-app-59d4957864-5nrjl   1/1     Running   0          2s
troubleshooting-app-59d4957864-qxknf   1/1     Running   0          2s

$ kubectl -n s14-mini get service
NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
troubleshooting-service   ClusterIP   10.96.242.66   <none>        80/TCP    2s

==============================================================
2. CHECK THE APPLICATION
==============================================================
$ kubectl -n s14-mini get pods -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP             NODE                NOMINATED NODE   READINESS GATES
curl-client                            1/1     Running   0          1s    10.244.1.252   devops-hw-worker2   <none>           <none>
troubleshooting-app-59d4957864-5nrjl   1/1     Running   0          2s    10.244.2.32    devops-hw-worker    <none>           <none>
troubleshooting-app-59d4957864-qxknf   1/1     Running   0          2s    10.244.1.251   devops-hw-worker2   <none>           <none>

$ kubectl -n s14-mini describe pod troubleshooting-app-59d4957864-5nrjl   (trimmed)
Node:             devops-hw-worker/192.168.96.3
Status:           Running
IP:               10.244.2.32
    Image:          nginx:1.27
    State:          Running
      Started:      Wed, 07 Oct 2026 23:53:30 +0530
    Ready:          True
    Restart Count:  0
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  2s    default-scheduler  Successfully assigned s14-mini/troubleshooting-app-59d4957864-5nrjl to devops-hw-worker
  Normal  Pulled     1s    kubelet            spec.containers{app}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal  Created    1s    kubelet            spec.containers{app}: Container created
  Normal  Started    0s    kubelet            spec.containers{app}: Container started

$ kubectl -n s14-mini logs troubleshooting-app-59d4957864-5nrjl --tail=5
2026/10/07 18:23:30 [notice] 1#1: start worker process 43
2026/10/07 18:23:30 [notice] 1#1: start worker process 44
2026/10/07 18:23:30 [notice] 1#1: start worker process 45
2026/10/07 18:23:30 [notice] 1#1: start worker process 46
2026/10/07 18:23:30 [notice] 1#1: start worker process 47

--- kubectl exec ... -- bash, then 'curl localhost' (as the instructions say) ---
$ kubectl -n s14-mini exec troubleshooting-app-59d4957864-5nrjl -- bash -c 'curl -s localhost | grep -o "<title>.*</title>"'
<title>Welcome to nginx!</title>

Interactively that is: kubectl -n s14-mini exec -it troubleshooting-app-59d4957864-5nrjl -- bash   then   curl localhost

Many production images have no shell and no curl (distroless). Then
kubectl debug attaches an EPHEMERAL container that does - it shares the
pod's network namespace, so 'localhost' is still this nginx:
$ kubectl -n s14-mini debug troubleshooting-app-59d4957864-5nrjl --image=curlimages/curl:8.5.0 --container=dbg -- curl -s -o /dev/null -w 'HTTP %{http_code}' http://localhost
$ kubectl -n s14-mini logs troubleshooting-app-59d4957864-5nrjl -c dbg
HTTP 200

==============================================================
3. CHECK THE SERVICE
==============================================================
$ kubectl -n s14-mini get service
NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
troubleshooting-service   ClusterIP   10.96.242.66   <none>        80/TCP    5s

$ kubectl -n s14-mini describe service troubleshooting-service
Name:                     troubleshooting-service
Selector:                 app=troubleshooting-app
Type:                     ClusterIP
IP:                       10.96.242.66
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
Endpoints:                10.244.2.32:80,10.244.1.251:80

==============================================================
4. CHECK ENDPOINTS
==============================================================
$ kubectl -n s14-mini get endpoints troubleshooting-service
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                      ENDPOINTS                        AGE
troubleshooting-service   10.244.1.251:80,10.244.2.32:80   5s

(The Endpoints API is deprecated in favour of EndpointSlice - same data:)
$ kubectl -n s14-mini get endpointslices -l kubernetes.io/service-name=troubleshooting-service
NAME                            ADDRESSTYPE   PORTS   ENDPOINTS                  AGE
troubleshooting-service-tz27z   IPv4          80      10.244.2.32,10.244.1.251   5s

--- and the Service really answers from another pod ---
$ kubectl -n s14-mini exec curl-client -- curl -s -o /dev/null -w '%{http_code}' http://troubleshooting-service
HTTP 200

==============================================================
5. CREATE A BROKEN POD
==============================================================
pod/project-broken-pod created
23:53:34  NAME                 READY   STATUS              RESTARTS   AGE
23:53:34  project-broken-pod   0/1     ContainerCreating   0          0s
23:53:34  project-broken-pod   0/1     ContainerCreating   0          0s
23:53:37  project-broken-pod   0/1     ErrImagePull        0          3s
23:53:51  project-broken-pod   0/1     ImagePullBackOff    0          17s
23:54:05  project-broken-pod   0/1     ErrImagePull        0          31s

==============================================================
6. TROUBLESHOOT IT (no YAML changes yet)
==============================================================
$ kubectl -n s14-mini get pod project-broken-pod
NAME                 READY   STATUS         RESTARTS   AGE
project-broken-pod   0/1     ErrImagePull   0          36s

$ kubectl -n s14-mini describe pod project-broken-pod
    Image:          nginx:this-tag-does-not-exist
    State:          Waiting
      Reason:       ErrImagePull
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  36s                default-scheduler  Successfully assigned s14-mini/project-broken-pod to devops-hw-worker
  Normal   Pulling    19s (x2 over 36s)  kubelet            spec.containers{app}: Pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     17s (x2 over 34s)  kubelet            spec.containers{app}: Failed to pull image "nginx:this-tag-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:this-tag-does-not-exist": failed to resolve reference "docker.io/library/nginx:this-tag-does-not-exist": docker.io/library/nginx:this-tag-does-not-exist: not found
  Warning  Failed     17s (x2 over 34s)  kubelet            spec.containers{app}: Error: ErrImagePull
  Normal   BackOff    6s (x2 over 33s)   kubelet            spec.containers{app}: Back-off pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     6s (x2 over 33s)   kubelet            spec.containers{app}: Error: ImagePullBackOff

$ kubectl -n s14-mini logs project-broken-pod
Error from server (BadRequest): container "app" in pod "project-broken-pod" is waiting to start: image can't be pulled


--- confirm against the registry itself (manifest HEAD; 200 = tag exists) ---
(asked via mirror.gcr.io, Google's mirror of the Docker Hub library
 images, because anonymous Docker Hub requests were being rate limited)
  nginx:this-tag-does-not-exist   -> 404
  nginx:1.27                      -> 200

==============================================================
6b. FIX THE BROKEN POD
==============================================================
A pod's container IMAGE is one of the few fields you may change on a
running pod, so the quickest fix needs no delete/recreate:

$ kubectl -n s14-mini set image pod/project-broken-pod app=nginx:1.27
pod/project-broken-pod image updated
pod/project-broken-pod condition met

The declarative fix, kept in git, matches what is now live:
$ kubectl apply -f fixed-pod.yaml
pod/project-broken-pod configured

$ kubectl -n s14-mini get pod project-broken-pod -o wide
NAME                 READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
project-broken-pod   1/1     Running   0          40s   10.244.2.34   devops-hw-worker   <none>           <none>

$ kubectl -n s14-mini get pod project-broken-pod -o jsonpath='{.status.containerStatuses[0].restartCount}'
  restarts: 0

==============================================================
8. SERVICE TROUBLESHOOTING CHALLENGE - break the selector
==============================================================
$ kubectl apply -f service-broken.yaml
service/troubleshooting-service configured

$ kubectl -n s14-mini get service
NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
troubleshooting-service   ClusterIP   10.96.242.66   <none>        80/TCP    47s

$ kubectl -n s14-mini get endpoints troubleshooting-service
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                      ENDPOINTS   AGE
troubleshooting-service   <none>      47s

$ kubectl -n s14-mini exec curl-client -- curl -sS -m 5 http://troubleshooting-service
HTTP 000
curl: (7) Failed to connect to troubleshooting-service port 80 after 6 ms: Couldn't connect to server
command terminated with exit code 7

--- DNS still works, so this is not a DNS problem ---
$ kubectl -n s14-mini exec curl-client -- nslookup troubleshooting-service.s14-mini.svc.cluster.local
Name:	troubleshooting-service.s14-mini.svc.cluster.local
Address: 10.96.242.66

==============================================================
9. FIND THE ROOT CAUSE
==============================================================
$ kubectl -n s14-mini get pods --show-labels
NAME                                   READY   STATUS    RESTARTS   AGE   LABELS
curl-client                            1/1     Running   0          47s   <none>
project-broken-pod                     1/1     Running   0          42s   <none>
troubleshooting-app-59d4957864-5nrjl   1/1     Running   0          48s   app=troubleshooting-app,pod-template-hash=59d4957864
troubleshooting-app-59d4957864-qxknf   1/1     Running   0          48s   app=troubleshooting-app,pod-template-hash=59d4957864

$ kubectl -n s14-mini describe service troubleshooting-service
Selector:                 app=wrong-app
Endpoints:                

Selector app=wrong-app vs pod label app=troubleshooting-app: zero matches,
so zero endpoints, so kube-proxy rejects every connection to the ClusterIP.

--- fix: put the correct selector back ---
$ kubectl apply -f service.yaml
service/troubleshooting-service configured

$ kubectl -n s14-mini get endpoints troubleshooting-service
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                      ENDPOINTS                        AGE
troubleshooting-service   10.244.1.251:80,10.244.2.32:80   52s

$ kubectl -n s14-mini exec curl-client -- curl -s -o /dev/null -w '%{http_code}' http://troubleshooting-service
HTTP 200

==============================================================
10. FINAL CHECKLIST - kubectl get events for the whole exercise
==============================================================
$ kubectl -n s14-mini get events --sort-by=.lastTimestamp | grep -E 'Warning|project-broken-pod' | tail -8
32s         Normal    Pulling             pod/project-broken-pod                      Pulling image "nginx:this-tag-does-not-exist"
30s         Warning   Failed              pod/project-broken-pod                      Failed to pull image "nginx:this-tag-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack 
30s         Warning   Failed              pod/project-broken-pod                      Error: ErrImagePull
19s         Warning   Failed              pod/project-broken-pod                      Error: ImagePullBackOff
19s         Normal    BackOff             pod/project-broken-pod                      Back-off pulling image "nginx:this-tag-does-not-exist"
11s         Normal    Pulled              pod/project-broken-pod                      Container image "nginx:1.27" already present on machine and can be accessed by the pod
10s         Normal    Started             pod/project-broken-pod                      Container started
10s         Normal    Created             pod/project-broken-pod                      Container created

$ kubectl -n s14-mini get all
NAME                                       READY   STATUS    RESTARTS   AGE
pod/curl-client                            1/1     Running   0          54s
pod/project-broken-pod                     1/1     Running   0          49s
pod/troubleshooting-app-59d4957864-5nrjl   1/1     Running   0          55s
pod/troubleshooting-app-59d4957864-qxknf   1/1     Running   0          55s

NAME                              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/troubleshooting-service   ClusterIP   10.96.242.66   <none>        80/TCP    57s

NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/troubleshooting-app   2/2     2            2           57s

NAME                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/troubleshooting-app-59d4957864   2         2         2       57s

==============================================================
DONE
==============================================================
```
