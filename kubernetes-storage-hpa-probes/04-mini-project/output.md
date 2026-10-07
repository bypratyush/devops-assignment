# Mini Project - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Namespace
==============================================================
namespace/production-webapp created

==============================================================
STEP 2 - PersistentVolumeClaim
==============================================================
persistentvolumeclaim/web-data created
NAME       STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
web-data   Pending                                      standard       <unset>                 2s

Pending until a pod uses it: the default class 'standard' is WaitForFirstConsumer.

==============================================================
STEP 3 - Deployment and Service
==============================================================
deployment.apps/web-app created
service/web-service created
Waiting for deployment "web-app" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "web-app" rollout to finish: 1 of 2 updated replicas are available...
deployment "web-app" successfully rolled out
NAME                      READY   STATUS    RESTARTS   AGE   IP             NODE               NOMINATED NODE   READINESS GATES
web-app-d45775485-4xwss   1/1     Running   0          13s   10.244.2.250   devops-hw-worker   <none>           <none>
web-app-d45775485-bsw6d   1/1     Running   0          13s   10.244.2.251   devops-hw-worker   <none>           <none>

NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
web-data   Bound    pvc-15ed0315-5fd8-4a73-9c2a-d6b7f2b1686b   500Mi      RWO            standard       <unset>                 16s

PV pvc-15ed0315-5fd8-4a73-9c2a-d6b7f2b1686b lives on node: devops-hw-worker
Both replicas are on that node. RWO means 'one NODE', and the local-path PV
has nodeAffinity, so the scheduler had to co-locate every replica with it.
NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
web-service   ClusterIP   10.96.87.159   <none>        80/TCP    13s

NAME                ADDRESSTYPE   PORTS   ENDPOINTS                   AGE
web-service-584hp   IPv4          80      10.244.2.250,10.244.2.251   13s

==============================================================
STEP 4 - Horizontal Pod Autoscaler
==============================================================
horizontalpodautoscaler.autoscaling/web-app-hpa created
waiting for the first CPU metrics...
NAME          REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
web-app-hpa   Deployment/web-app   cpu: 1%/50%   2         5         2          30s

==============================================================
STEP 5 - Task 1: storage persistence
==============================================================
$ kubectl exec web-app-d45775485-4xwss -- sh -c 'echo "Student: Pratyush Mohanty (24BCS10238)" > /data/student.txt'
$ kubectl exec web-app-d45775485-4xwss -- cat /data/student.txt
Student: Pratyush Mohanty (24BCS10238)

and from the OTHER replica (same PV, same node):
$ kubectl exec web-app-d45775485-bsw6d -- cat /data/student.txt
Student: Pratyush Mohanty (24BCS10238)

$ kubectl delete pod web-app-d45775485-4xwss
pod "web-app-d45775485-4xwss" deleted from production-webapp namespace

NAME                      READY   STATUS    RESTARTS   AGE
web-app-d45775485-bsw6d   1/1     Running   0          56s
web-app-d45775485-vpht2   1/1     Running   0          10s

$ kubectl exec web-app-d45775485-vpht2 -- cat /data/student.txt     (the replacement pod)
Student: Pratyush Mohanty (24BCS10238)

The pod was replaced; the data was not.

==============================================================
STEP 6 - Task 2: Service verification through port-forward
==============================================================
$ kubectl port-forward -n production-webapp svc/web-service 18080:80 &
$ curl http://localhost:18080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
HTTP 200

==============================================================
STEP 7 - The three probes, as the kubelet sees them
==============================================================
    Liveness:     http-get http://:80/ delay=5s timeout=2s period=5s #success=1 #failure=3
    Readiness:    http-get http://:80/ delay=5s timeout=2s period=5s #success=1 #failure=2
    Startup:      http-get http://:80/ delay=0s timeout=1s period=2s #success=1 #failure=30

NAME                      READY   RESTARTS   STARTED
web-app-d45775485-bsw6d   true    0          true
web-app-d45775485-vpht2   true    0          true

==============================================================
STEP 8 - Task 3: the course's load generator (one busybox wget loop)
==============================================================
pod/load-generator created
pod/load-generator condition met
[23:47:40] cpu 3% (target 50%)   replicas current=2 desired=2
[23:47:56] cpu 43% (target 50%)   replicas current=2 desired=2
[23:48:11] cpu 42% (target 50%)   replicas current=2 desired=2
[23:48:26] cpu 33% (target 50%)   replicas current=2 desired=2
[23:48:41] cpu 48% (target 50%)   replicas current=2 desired=2
[23:48:57] cpu 45% (target 50%)   replicas current=2 desired=2
[23:49:12] cpu 38% (target 50%)   replicas current=2 desired=2
[23:49:27] cpu 42% (target 50%)   replicas current=2 desired=2

$ kubectl top pods -n production-webapp
NAME                      CPU(cores)   MEMORY(bytes)   
load-generator            578m         3Mi             
web-app-d45775485-bsw6d   42m          12Mi            
web-app-d45775485-vpht2   42m          12Mi            

Still 2 replicas at 42%. nginx serving a static page is cheap, so one loop
keeps the pods around the 50% target, and the HPA only acts when
current/target is outside 1.0 +/- 0.1 (its default tolerance).

==============================================================
STEP 9 - More load: 3 extra copies of the same loop (load-generator-extra.yaml)
==============================================================
deployment.apps/load-generator-extra created
Waiting for deployment "load-generator-extra" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "load-generator-extra" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "load-generator-extra" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "load-generator-extra" rollout to finish: 2 of 3 updated replicas are available...
deployment "load-generator-extra" successfully rolled out
[23:49:53] cpu 34% (target 50%)   replicas current=2 desired=2
[23:50:09] cpu 26% (target 50%)   replicas current=2 desired=2
[23:50:32] cpu 61% (target 50%)   replicas current=2 desired=3
[23:50:47] cpu 48% (target 50%)   replicas current=3 desired=3
[23:51:03] cpu 44% (target 50%)   replicas current=3 desired=3
[23:51:18] cpu 42% (target 50%)   replicas current=3 desired=3
[23:51:34] cpu 42% (target 50%)   replicas current=3 desired=3
[23:51:49] cpu 43% (target 50%)   replicas current=3 desired=3
[23:52:05] cpu 46% (target 50%)   replicas current=3 desired=3
[23:52:21] cpu 53% (target 50%)   replicas current=3 desired=3
[23:52:36] cpu 44% (target 50%)   replicas current=3 desired=3
[23:52:51] cpu 50% (target 50%)   replicas current=3 desired=3
[23:53:06] cpu 56% (target 50%)   replicas current=3 desired=4
[23:53:22] cpu 58% (target 50%)   replicas current=4 desired=4
[23:53:37] cpu 40% (target 50%)   replicas current=4 desired=4
[23:53:52] cpu 38% (target 50%)   replicas current=4 desired=4
[23:54:08] cpu 38% (target 50%)   replicas current=4 desired=4
[23:54:23] cpu 35% (target 50%)   replicas current=4 desired=4
[23:54:40] cpu 31% (target 50%)   replicas current=4 desired=4
[23:54:57] cpu 31% (target 50%)   replicas current=4 desired=4

4 replicas after 320s of the heavier load

NAME                                   READY   STATUS    RESTARTS   AGE     IP             NODE                NOMINATED NODE   READINESS GATES
load-generator                         1/1     Running   0          7m33s   10.244.1.223   devops-hw-worker2   <none>           <none>
load-generator-extra-8ff49c8cd-gp5vx   1/1     Running   0          5m27s   10.244.1.229   devops-hw-worker2   <none>           <none>
load-generator-extra-8ff49c8cd-q76ww   1/1     Running   0          5m27s   10.244.2.15    devops-hw-worker    <none>           <none>
load-generator-extra-8ff49c8cd-rqs5g   1/1     Running   0          5m27s   10.244.1.230   devops-hw-worker2   <none>           <none>
web-app-d45775485-9knh7                1/1     Running   0          2m6s    10.244.2.27    devops-hw-worker    <none>           <none>
web-app-d45775485-bsw6d                1/1     Running   0          8m32s   10.244.2.251   devops-hw-worker    <none>           <none>
web-app-d45775485-vpht2                1/1     Running   0          7m46s   10.244.2.5     devops-hw-worker    <none>           <none>
web-app-d45775485-vql96                1/1     Running   0          4m39s   10.244.2.19    devops-hw-worker    <none>           <none>

$ kubectl top pods -n production-webapp
NAME                                   CPU(cores)   MEMORY(bytes)   
load-generator                         329m         1Mi             
load-generator-extra-8ff49c8cd-gp5vx   170m         1Mi             
load-generator-extra-8ff49c8cd-q76ww   141m         0Mi             
load-generator-extra-8ff49c8cd-rqs5g   168m         1Mi             
web-app-d45775485-9knh7                27m          11Mi            
web-app-d45775485-bsw6d                21m          11Mi            
web-app-d45775485-vpht2                24m          11Mi            
web-app-d45775485-vql96                26m          13Mi            

nodes of the web-app pods (the PV lives on devops-hw-worker):
     4 devops-hw-worker

==============================================================
STEP 10 - Stop all load; scale-down uses the DEFAULT 5-minute window here
==============================================================
pod "load-generator" deleted from production-webapp namespace
deployment.apps "load-generator-extra" deleted from production-webapp namespace
[23:55:22] cpu 30% (target 50%)   replicas current=4 desired=4
[23:55:42] cpu 15% (target 50%)   replicas current=4 desired=4
[23:56:05] cpu 4% (target 50%)   replicas current=4 desired=4
[23:56:26] cpu 5% (target 50%)   replicas current=4 desired=4
[23:56:46] cpu 3% (target 50%)   replicas current=4 desired=4
[23:57:06] cpu 3% (target 50%)   replicas current=4 desired=4
[23:57:26] cpu 1% (target 50%)   replicas current=4 desired=4
[23:57:47] cpu 1% (target 50%)   replicas current=4 desired=4
[23:58:07] cpu 1% (target 50%)   replicas current=4 desired=4
[23:58:27] cpu 1% (target 50%)   replicas current=4 desired=4
[23:58:47] cpu 1% (target 50%)   replicas current=4 desired=4
[23:59:07] cpu 1% (target 50%)   replicas current=4 desired=3
[23:59:27] cpu 1% (target 50%)   replicas current=3 desired=3
[23:59:47] cpu 1% (target 50%)   replicas current=3 desired=3
[00:00:07] cpu 1% (target 50%)   replicas current=3 desired=3
[00:00:28] cpu 1% (target 50%)   replicas current=3 desired=2

back to 2 replicas 326s after the load stopped
(hpa.yaml sets no behavior, so the default scaleDown stabilizationWindowSeconds
 of 300s applies: the HPA keeps the highest recommendation of the last 5 minutes)

==============================================================
STEP 11 - 'kubectl get hpa -w' timeline and the HPA's events
==============================================================
23:47:25  NAME          REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
23:47:25  web-app-hpa   Deployment/web-app   cpu: 1%/50%   2         5         2          45s
23:47:25  web-app-hpa   Deployment/web-app   cpu: 2%/50%   2         5         2          45s
23:47:40  web-app-hpa   Deployment/web-app   cpu: 3%/50%   2         5         2          60s
23:47:55  web-app-hpa   Deployment/web-app   cpu: 43%/50%   2         5         2          75s
23:48:11  web-app-hpa   Deployment/web-app   cpu: 42%/50%   2         5         2          91s
23:48:26  web-app-hpa   Deployment/web-app   cpu: 33%/50%   2         5         2          106s
23:48:42  web-app-hpa   Deployment/web-app   cpu: 48%/50%   2         5         2          2m2s
23:48:57  web-app-hpa   Deployment/web-app   cpu: 45%/50%   2         5         2          2m17s
23:49:12  web-app-hpa   Deployment/web-app   cpu: 38%/50%   2         5         2          2m32s
23:49:27  web-app-hpa   Deployment/web-app   cpu: 42%/50%   2         5         2          2m47s
23:49:44  web-app-hpa   Deployment/web-app   cpu: 34%/50%   2         5         2          3m3s
23:49:59  web-app-hpa   Deployment/web-app   cpu: 26%/50%   2         5         2          3m19s
23:50:18  web-app-hpa   Deployment/web-app   cpu: 61%/50%   2         5         2          3m38s
23:50:34  web-app-hpa   Deployment/web-app   cpu: 48%/50%   2         5         3          3m54s
23:50:50  web-app-hpa   Deployment/web-app   cpu: 44%/50%   2         5         3          4m10s
23:51:05  web-app-hpa   Deployment/web-app   cpu: 42%/50%   2         5         3          4m25s
23:51:21  web-app-hpa   Deployment/web-app   cpu: 42%/50%   2         5         3          4m41s
23:51:36  web-app-hpa   Deployment/web-app   cpu: 43%/50%   2         5         3          4m56s
23:51:51  web-app-hpa   Deployment/web-app   cpu: 46%/50%   2         5         3          5m11s
23:52:07  web-app-hpa   Deployment/web-app   cpu: 53%/50%   2         5         3          5m27s
23:52:22  web-app-hpa   Deployment/web-app   cpu: 44%/50%   2         5         3          5m42s
23:52:37  web-app-hpa   Deployment/web-app   cpu: 50%/50%   2         5         3          5m57s
23:52:52  web-app-hpa   Deployment/web-app   cpu: 56%/50%   2         5         3          6m12s
23:53:07  web-app-hpa   Deployment/web-app   cpu: 58%/50%   2         5         4          6m27s
23:53:22  web-app-hpa   Deployment/web-app   cpu: 40%/50%   2         5         4          6m42s
23:53:37  web-app-hpa   Deployment/web-app   cpu: 38%/50%   2         5         4          6m57s
23:54:08  web-app-hpa   Deployment/web-app   cpu: 35%/50%   2         5         4          7m28s
23:54:26  web-app-hpa   Deployment/web-app   cpu: 31%/50%   2         5         4          7m46s
23:54:58  web-app-hpa   Deployment/web-app   cpu: 24%/50%   2         5         4          8m18s
23:55:13  web-app-hpa   Deployment/web-app   cpu: 30%/50%   2         5         4          8m33s
23:55:28  web-app-hpa   Deployment/web-app   cpu: 15%/50%   2         5         4          8m48s
23:55:45  web-app-hpa   Deployment/web-app   cpu: 1%/50%    2         5         4          9m5s
23:55:59  web-app-hpa   Deployment/web-app   cpu: 4%/50%    2         5         4          9m19s
23:56:14  web-app-hpa   Deployment/web-app   cpu: 5%/50%    2         5         4          9m34s
23:56:29  web-app-hpa   Deployment/web-app   cpu: 3%/50%    2         5         4          9m49s
23:57:14  web-app-hpa   Deployment/web-app   cpu: 1%/50%    2         5         4          10m
23:59:00  web-app-hpa   Deployment/web-app   cpu: 1%/50%    2         5         4          12m
23:59:15  web-app-hpa   Deployment/web-app   cpu: 1%/50%    2         5         3          12m
00:00:15  web-app-hpa   Deployment/web-app   cpu: 1%/50%    2         5         3          13m

Conditions:
  Type            Status  Reason              Message
  ----            ------  ------              -------
  AbleToScale     True    SucceededRescale    the HPA controller was able to update the target scale to 2
  ScalingActive   True    ValidMetricFound    the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  False   DesiredWithinRange  the desired count is within the acceptable range
  ScaledToZero    False   NotScaledToZero     the HPA controller did not scale the workload to zero
Events:
  Type     Reason                        Age    From                       Message
  ----     ------                        ----   ----                       -------
  Warning  FailedGetResourceMetric       13m    horizontal-pod-autoscaler  failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedComputeMetricsReplicas  13m    horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedGetResourceMetric       13m    horizontal-pod-autoscaler  failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
  Warning  FailedComputeMetricsReplicas  13m    horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
  Normal   SuccessfulRescale             10m    horizontal-pod-autoscaler  New size: 3; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             7m37s  horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             89s    horizontal-pod-autoscaler  New size: 3; reason: All metrics below target
  Normal   SuccessfulRescale             14s    horizontal-pod-autoscaler  New size: 2; reason: All metrics below target

==============================================================
STEP 12 - Challenge 2: readiness gating (readinessProbe path -> /does-not-exist)
==============================================================
deployment.apps/web-app patched
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5945bfc776-lblqx   0/1     Running   0          13s
web-app-5945bfc776-t522q   0/1     Running   0          13s

--- EndpointSlice: the pod IPs are listed, but marked not ready ---
  10.244.2.47  ready=false  web-app-5945bfc776-lblqx
  10.244.2.46  ready=false  web-app-5945bfc776-t522q

--- describe svc: only READY addresses count as endpoints ---
Endpoints:                

Unhealthy   Readiness probe failed: HTTP probe failed with statuscode: 404
Unhealthy   Readiness probe failed: HTTP probe failed with statuscode: 404

$ kubectl exec web-app-5945bfc776-lblqx -- curl http://web-service     (from inside one of the pods)
HTTP 000command terminated with exit code 7
, curl exit code 7

STATUS Running, READY 0/1, RESTARTS 0, and the Service has no ready endpoints:
the pods are alive but receive no traffic. Readiness never restarts anything.

restoring the readiness path...
Waiting for deployment "web-app" rollout to finish: 0 out of 2 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 2 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 2 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 2 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 2 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "web-app" rollout to finish: 1 of 2 updated replicas are available...
deployment "web-app" successfully rolled out

==============================================================
STEP 13 - Challenge 3: liveness restart loop (livenessProbe path -> /crash)
==============================================================
deployment.apps/web-app patched
  t(s)   pod / READY / RESTARTS
  0      web-app-85d86b65d-2wft4  1/1  Running  0
  0      web-app-85d86b65d-dgn2j  1/1  Running  0
  12     web-app-85d86b65d-2wft4  0/1  Running  1
  12     web-app-85d86b65d-dgn2j  0/1  Running  1
  24     web-app-85d86b65d-2wft4  1/1  Running  1
  24     web-app-85d86b65d-dgn2j  1/1  Running  1
  36     web-app-85d86b65d-2wft4  1/1  Running  2
  36     web-app-85d86b65d-dgn2j  1/1  Running  2
  48     web-app-85d86b65d-2wft4  0/1  Running  3
  48     web-app-85d86b65d-dgn2j  0/1  Running  3
  60     web-app-85d86b65d-2wft4  1/1  Running  3
  60     web-app-85d86b65d-dgn2j  1/1  Running  3
  73     web-app-85d86b65d-2wft4  0/1  CrashLoopBackOff  3
  73     web-app-85d86b65d-dgn2j  0/1  CrashLoopBackOff  3
  85     web-app-85d86b65d-2wft4  0/1  CrashLoopBackOff  3
  85     web-app-85d86b65d-dgn2j  0/1  CrashLoopBackOff  3

Events:
  Normal   Killing    31s (x4 over 91s)   kubelet            spec.containers{nginx}: Container nginx failed liveness probe, will be restarted
  Warning  Unhealthy  1s (x13 over 101s)  kubelet            spec.containers{nginx}: Liveness probe failed: HTTP probe failed with statuscode: 404

Each new container gets initialDelaySeconds 5 + 3 failures x periodSeconds 5
before the kubelet restarts it, so RESTARTS climbs every 15-25s. The readiness
probe still passes in between, so the pod also flaps in and out of the Service.

restoring the liveness path...
Waiting for deployment "web-app" rollout to finish: 0 out of 2 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 2 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 2 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 2 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "web-app" rollout to finish: 1 of 2 updated replicas are available...
deployment "web-app" successfully rolled out
NAME                      READY   STATUS    RESTARTS   AGE
web-app-d45775485-p5nt4   1/1     Running   0          9s
web-app-d45775485-t24lv   1/1     Running   0          9s

==============================================================
DONE
==============================================================
```
