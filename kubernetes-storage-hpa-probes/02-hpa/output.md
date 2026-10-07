# HPA Hands-on - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Is the Metrics API there? (the HPA cannot work without it)
==============================================================
NAME                     SERVICE                      AVAILABLE   AGE
v1beta1.metrics.k8s.io   kube-system/metrics-server   True        29m

NAME                      CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
devops-hw-control-plane   4596m        30%      1694Mi          21%         
devops-hw-worker          1524m        10%      553Mi           6%          
devops-hw-worker2         2024m        13%      429Mi           5%          

==============================================================
STEP 2 - Deploy the application and its Service
==============================================================
namespace/s13-hpa created
deployment.apps/cpu-app created
service/cpu-app created
Waiting for deployment "cpu-app" rollout to finish: 0 out of 1 new replicas have been updated...
Waiting for deployment "cpu-app" rollout to finish: 0 of 1 updated replicas are available...
deployment "cpu-app" successfully rolled out
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES               SELECTOR
deployment.apps/cpu-app   1/1     1            1           8s    app          python:3.12-alpine   app=cpu-app

NAME              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE   SELECTOR
service/cpu-app   ClusterIP   10.96.190.47   <none>        80/TCP    8s    app=cpu-app

NAME                          READY   STATUS    RESTARTS   AGE   IP             NODE                NOMINATED NODE   READINESS GATES
pod/cpu-app-bb456686b-9vm8x   1/1     Running   0          7s    10.244.1.179   devops-hw-worker2   <none>           <none>

==============================================================
STEP 3 - Configure the HPA (hpa.yml)
==============================================================
horizontalpodautoscaler.autoscaling/cpu-app created

right after creation:
NAME      REFERENCE            TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
cpu-app   Deployment/cpu-app   cpu: <unknown>/50%   1         5         1          0s

waiting for the first metrics to arrive...
NAME      REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
cpu-app   Deployment/cpu-app   cpu: 3%/50%   1         5         1          31s

==============================================================
STEP 4 - Verify the HPA at rest
==============================================================
NAME      REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
cpu-app   Deployment/cpu-app   cpu: 3%/50%   1         5         1          31s

NAME                      READY   STATUS    RESTARTS   AGE
cpu-app-bb456686b-9vm8x   1/1     Running   0          38s

$ kubectl top pods -n s13-hpa
NAME                      CPU(cores)   MEMORY(bytes)   
cpu-app-bb456686b-9vm8x   3m           17Mi            

Name:                                                  cpu-app
Namespace:                                             s13-hpa
Labels:                                                <none>
Annotations:                                           <none>
CreationTimestamp:                                     Wed, 07 Oct 2026 23:38:40 +0530
Reference:                                             Deployment/cpu-app
Metrics:                                               ( current / target )
  resource cpu on pods  (as a percentage of request):  3% (3m) / 50%
Min replicas:                                          1
Max replicas:                                          5
Behavior:
  Scale Up:
    Stabilization Window: 0 seconds
    Select Policy: Max
    Policies:
      - Type: Pods     Value: 4    Period: 15 seconds
      - Type: Percent  Value: 100  Period: 15 seconds
  Scale Down:
    Stabilization Window: 60 seconds
    Select Policy: Max
    Policies:
      - Type: Percent  Value: 100  Period: 15 seconds
Deployment pods:       1 current / 1 desired
Conditions:
  Type            Status  Reason              Message
  ----            ------  ------              -------
  AbleToScale     True    ReadyForNewScale    recommended size matches current size
  ScalingActive   True    ValidMetricFound    the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  False   DesiredWithinRange  the desired count is within the acceptable range
Events:

TARGETS 'cpu: x%/50%' = average CPU as a % of the 100m request / the target.
Idle, so 1 replica (minReplicas).

==============================================================
STEP 5 - Start a timestamped 'kubectl get hpa -w' in the background
==============================================================
watching in the background (pid 56050)

==============================================================
STEP 6 - Deploy the load generator
==============================================================
deployment.apps/load-generator created
Waiting for deployment "load-generator" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "load-generator" rollout to finish: 1 of 2 updated replicas are available...
deployment "load-generator" successfully rolled out
NAME                             READY   STATUS    RESTARTS   AGE
load-generator-6f8d7848d-6lqxr   1/1     Running   0          1s
load-generator-6f8d7848d-ttrh7   1/1     Running   0          1s

Two busybox pods, each looping 'wget http://cpu-app' = two requests in flight.

==============================================================
STEP 7 - Observe CPU utilisation and pod scaling under load
==============================================================
[23:39:28] cpu 3% of request (target 50%)   replicas current=1 desired=1
[23:39:43] cpu 65% of request (target 50%)   replicas current=1 desired=2
[23:39:59] cpu 201% of request (target 50%)   replicas current=2 desired=4
[23:40:14] cpu 173% of request (target 50%)   replicas current=4 desired=5
             cpu-app-bb456686b-5sj6l   156m   19Mi   
             cpu-app-bb456686b-9vm8x   191m   17Mi   
[23:40:30] cpu 111% of request (target 50%)   replicas current=5 desired=5
             cpu-app-bb456686b-5sj6l   120m   19Mi   
             cpu-app-bb456686b-9vm8x   103m   17Mi   
             cpu-app-bb456686b-xsghd   58m    11Mi   
             cpu-app-bb456686b-zwl45   104m   11Mi   
[23:41:15] cpu 70% of request (target 50%)   replicas current=5 desired=5
             cpu-app-bb456686b-5sj6l   139m   21Mi   
             cpu-app-bb456686b-9vm8x   61m    14Mi   
             cpu-app-bb456686b-w9q7r   48m    11Mi   
             cpu-app-bb456686b-xsghd   60m    11Mi   
             cpu-app-bb456686b-zwl45   71m    12Mi   
[23:41:33] cpu 87% of request (target 50%)   replicas current=5 desired=5
             cpu-app-bb456686b-5sj6l   67m    21Mi   
             cpu-app-bb456686b-9vm8x   53m    14Mi   
             cpu-app-bb456686b-w9q7r   28m    11Mi   
             cpu-app-bb456686b-xsghd   171m   11Mi   
             cpu-app-bb456686b-zwl45   119m   13Mi   

reached 5 replicas in about 142s of load

==============================================================
STEP 8 - The scaled-up state
==============================================================
NAME      REFERENCE            TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
cpu-app   Deployment/cpu-app   cpu: 87%/50%   1         5         5          2m55s

NAME                             READY   STATUS    RESTARTS   AGE     IP             NODE                NOMINATED NODE   READINESS GATES
cpu-app-bb456686b-5sj6l          1/1     Running   0          115s    10.244.2.219   devops-hw-worker    <none>           <none>
cpu-app-bb456686b-9vm8x          1/1     Running   0          3m2s    10.244.1.179   devops-hw-worker2   <none>           <none>
cpu-app-bb456686b-w9q7r          1/1     Running   0          84s     10.244.2.221   devops-hw-worker    <none>           <none>
cpu-app-bb456686b-xsghd          1/1     Running   0          99s     10.244.2.220   devops-hw-worker    <none>           <none>
cpu-app-bb456686b-zwl45          1/1     Running   0          99s     10.244.1.189   devops-hw-worker2   <none>           <none>
load-generator-6f8d7848d-6lqxr   1/1     Running   0          2m23s   10.244.1.182   devops-hw-worker2   <none>           <none>
load-generator-6f8d7848d-ttrh7   1/1     Running   0          2m23s   10.244.2.215   devops-hw-worker    <none>           <none>

$ kubectl top pods -n s13-hpa
NAME                             CPU(cores)   MEMORY(bytes)   
cpu-app-bb456686b-5sj6l          61m          21Mi            
cpu-app-bb456686b-9vm8x          108m         16Mi            
cpu-app-bb456686b-w9q7r          61m          11Mi            
cpu-app-bb456686b-xsghd          68m          12Mi            
cpu-app-bb456686b-zwl45          63m          12Mi            
load-generator-6f8d7848d-6lqxr   31m          0Mi             
load-generator-6f8d7848d-ttrh7   51m          0Mi             

Conditions:
  Type            Status  Reason            Message
  ----            ------  ------            -------
  AbleToScale     True    ReadyForNewScale  recommended size matches current size
  ScalingActive   True    ValidMetricFound  the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  True    TooManyReplicas   the desired replica count is more than the maximum replica count
  ScaledToZero    False   NotScaledToZero   the HPA controller did not scale the workload to zero
Events:

==============================================================
STEP 9 - Stop the load and observe the scale-down
==============================================================
deployment.apps/load-generator scaled
[23:41:56] cpu 70% of request (target 50%)   replicas current=5 desired=5
[23:42:12] cpu 50% of request (target 50%)   replicas current=5 desired=5
[23:42:28] cpu 33% of request (target 50%)   replicas current=5 desired=5
[23:42:43] cpu 19% of request (target 50%)   replicas current=5 desired=5
[23:42:59] cpu 9% of request (target 50%)   replicas current=5 desired=5
[23:43:15] cpu 14% of request (target 50%)   replicas current=5 desired=4
[23:43:31] cpu 16% of request (target 50%)   replicas current=4 desired=2
[23:43:46] cpu 7% of request (target 50%)   replicas current=2 desired=2
[23:44:01] cpu 19% of request (target 50%)   replicas current=2 desired=2
[23:44:16] cpu 5% of request (target 50%)   replicas current=2 desired=2
[23:44:32] cpu 6% of request (target 50%)   replicas current=2 desired=1

back to 1 replica(s) 171s after the load stopped
(stabilizationWindowSeconds: 60 in hpa.yml; with the default 300 the
 scale-down would only start about 5 minutes after the CPU dropped)
NAME                      READY   STATUS    RESTARTS   AGE
cpu-app-bb456686b-9vm8x   1/1     Running   0          6m4s

==============================================================
STEP 10 - The whole 'kubectl get hpa -w' timeline
==============================================================
23:39:12  NAME      REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
23:39:12  cpu-app   Deployment/cpu-app   cpu: 3%/50%   1         5         1          32s
23:39:40  cpu-app   Deployment/cpu-app   cpu: 65%/50%   1         5         1          60s
23:39:56  cpu-app   Deployment/cpu-app   cpu: 201%/50%   1         5         2          76s
23:40:11  cpu-app   Deployment/cpu-app   cpu: 173%/50%   1         5         4          91s
23:40:26  cpu-app   Deployment/cpu-app   cpu: 111%/50%   1         5         5          106s
23:40:42  cpu-app   Deployment/cpu-app   cpu: 79%/50%    1         5         5          2m2s
23:40:59  cpu-app   Deployment/cpu-app   cpu: 70%/50%    1         5         5          2m19s
23:41:16  cpu-app   Deployment/cpu-app   cpu: 75%/50%    1         5         5          2m36s
23:41:32  cpu-app   Deployment/cpu-app   cpu: 87%/50%    1         5         5          2m52s
23:41:56  cpu-app   Deployment/cpu-app   cpu: 70%/50%    1         5         5          3m16s
23:42:12  cpu-app   Deployment/cpu-app   cpu: 50%/50%    1         5         5          3m32s
23:42:27  cpu-app   Deployment/cpu-app   cpu: 33%/50%    1         5         5          3m47s
23:42:43  cpu-app   Deployment/cpu-app   cpu: 19%/50%    1         5         5          4m3s
23:42:58  cpu-app   Deployment/cpu-app   cpu: 9%/50%     1         5         5          4m18s
23:43:13  cpu-app   Deployment/cpu-app   cpu: 14%/50%    1         5         5          4m33s
23:43:28  cpu-app   Deployment/cpu-app   cpu: 16%/50%    1         5         4          4m48s
23:43:43  cpu-app   Deployment/cpu-app   cpu: 7%/50%     1         5         2          5m3s
23:43:58  cpu-app   Deployment/cpu-app   cpu: 19%/50%    1         5         2          5m18s
23:44:14  cpu-app   Deployment/cpu-app   cpu: 5%/50%     1         5         2          5m33s
23:44:29  cpu-app   Deployment/cpu-app   cpu: 6%/50%     1         5         2          5m49s

==============================================================
STEP 11 - kubectl describe hpa: the HPA's own record of what it did
==============================================================
Name:                                                  cpu-app
Namespace:                                             s13-hpa
Labels:                                                <none>
Annotations:                                           <none>
CreationTimestamp:                                     Wed, 07 Oct 2026 23:38:40 +0530
Reference:                                             Deployment/cpu-app
Metrics:                                               ( current / target )
  resource cpu on pods  (as a percentage of request):  6% (6m) / 50%
Min replicas:                                          1
Max replicas:                                          5
Behavior:
  Scale Up:
    Stabilization Window: 0 seconds
    Select Policy: Max
    Policies:
      - Type: Pods     Value: 4    Period: 15 seconds
      - Type: Percent  Value: 100  Period: 15 seconds
  Scale Down:
    Stabilization Window: 60 seconds
    Select Policy: Max
    Policies:
      - Type: Percent  Value: 100  Period: 15 seconds
Deployment pods:       2 current / 1 desired
Conditions:
  Type            Status  Reason              Message
  ----            ------  ------              -------
  AbleToScale     True    SucceededRescale    the HPA controller was able to update the target scale to 1
  ScalingActive   True    ValidMetricFound    the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  False   DesiredWithinRange  the desired count is within the acceptable range
  ScaledToZero    False   NotScaledToZero     the HPA controller did not scale the workload to zero
Events:
  Type     Reason                        Age    From                       Message
  ----     ------                        ----   ----                       -------
  Warning  FailedGetResourceMetric       5m59s  horizontal-pod-autoscaler  failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedComputeMetricsReplicas  5m59s  horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedGetResourceMetric       5m44s  horizontal-pod-autoscaler  failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
  Warning  FailedComputeMetricsReplicas  5m44s  horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
  Normal   SuccessfulRescale             4m59s  horizontal-pod-autoscaler  New size: 2; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             4m43s  horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             4m28s  horizontal-pod-autoscaler  New size: 5; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             86s    horizontal-pod-autoscaler  New size: 4; reason: All metrics below target
  Normal   SuccessfulRescale             71s    horizontal-pod-autoscaler  New size: 2; reason: All metrics below target
  Normal   SuccessfulRescale             10s    horizontal-pod-autoscaler  New size: 1; reason: All metrics below target

==============================================================
DONE
==============================================================
```
