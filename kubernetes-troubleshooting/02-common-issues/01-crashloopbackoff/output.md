# CrashLoopBackOff - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Deploy the broken manifests
==============================================================
deployment.apps/orders-worker created
deployment.apps/thumbnailer created

==============================================================
STEP 2 - IDENTIFY: watch the pods for 100 seconds
==============================================================
(each line is prefixed with the time it arrived)
23:29:01  NAME                             READY   STATUS              RESTARTS   AGE
23:29:01  orders-worker-7d5f5f5b78-8rrpt   0/1     ContainerCreating   0          0s
23:29:01  thumbnailer-6b6d99b78c-nntfr     0/1     ContainerCreating   0          0s
23:29:02  thumbnailer-6b6d99b78c-nntfr     0/1     ContainerCreating   0          1s
23:29:02  thumbnailer-6b6d99b78c-nntfr     1/1     Running             0          1s
23:29:02  orders-worker-7d5f5f5b78-8rrpt   0/1     ContainerCreating   0          1s
23:29:03  orders-worker-7d5f5f5b78-8rrpt   1/1     Running             0          2s
23:29:04  thumbnailer-6b6d99b78c-nntfr     0/1     OOMKilled           0          3s
23:29:04  thumbnailer-6b6d99b78c-nntfr     1/1     Running             1 (0s ago)   3s
23:29:06  thumbnailer-6b6d99b78c-nntfr     0/1     OOMKilled           1 (2s ago)   5s
23:29:12  orders-worker-7d5f5f5b78-8rrpt   0/1     Error               0            11s
23:29:13  orders-worker-7d5f5f5b78-8rrpt   1/1     Running             1 (1s ago)   12s
23:29:17  thumbnailer-6b6d99b78c-nntfr     0/1     CrashLoopBackOff    1 (11s ago)   16s
23:29:17  thumbnailer-6b6d99b78c-nntfr     1/1     Running             2 (11s ago)   16s
23:29:19  thumbnailer-6b6d99b78c-nntfr     0/1     OOMKilled           2 (13s ago)   18s
23:29:22  orders-worker-7d5f5f5b78-8rrpt   0/1     Error               1 (10s ago)   21s
23:29:35  orders-worker-7d5f5f5b78-8rrpt   0/1     CrashLoopBackOff    1 (13s ago)   34s
23:29:36  orders-worker-7d5f5f5b78-8rrpt   1/1     Running             2 (14s ago)   35s
23:29:41  thumbnailer-6b6d99b78c-nntfr     0/1     CrashLoopBackOff    2 (23s ago)   40s
23:29:41  thumbnailer-6b6d99b78c-nntfr     1/1     Running             3 (23s ago)   40s
23:29:44  thumbnailer-6b6d99b78c-nntfr     0/1     OOMKilled           3 (26s ago)   43s
23:29:46  orders-worker-7d5f5f5b78-8rrpt   0/1     Error               2 (24s ago)   45s
23:30:07  orders-worker-7d5f5f5b78-8rrpt   0/1     CrashLoopBackOff    2 (22s ago)   66s
23:30:07  orders-worker-7d5f5f5b78-8rrpt   1/1     Running             3 (22s ago)   66s
23:30:17  orders-worker-7d5f5f5b78-8rrpt   0/1     Error               3 (32s ago)   76s
23:30:32  thumbnailer-6b6d99b78c-nntfr     0/1     CrashLoopBackOff    3 (49s ago)   91s
23:30:32  thumbnailer-6b6d99b78c-nntfr     1/1     Running             4 (49s ago)   91s
23:30:34  thumbnailer-6b6d99b78c-nntfr     0/1     OOMKilled           4 (51s ago)   93s

Status flips Running/Error/OOMKilled -> CrashLoopBackOff, and RESTARTS
keeps climbing. CrashLoopBackOff is not the error, it is the kubelet
WAITING (10s, 20s, 40s ... capped at 5m) before the next restart.

==============================================================
STEP 3 - INVESTIGATE orders-worker: describe
==============================================================
$ kubectl -n s14-issues describe pod orders-worker-7d5f5f5b78-8rrpt   (State / Last State / Events)
    State:          Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Wed, 07 Oct 2026 23:30:07 +0530
      Finished:     Wed, 07 Oct 2026 23:30:16 +0530
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Wed, 07 Oct 2026 23:29:36 +0530
      Finished:     Wed, 07 Oct 2026 23:29:45 +0530
    Ready:          False
    Restart Count:  3
  ...
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  101s                default-scheduler  Successfully assigned s14-issues/orders-worker-7d5f5f5b78-8rrpt to devops-hw-worker2
  Normal   Pulled     35s (x4 over 100s)  kubelet            spec.containers{worker}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal   Created    35s (x4 over 100s)  kubelet            spec.containers{worker}: Container created
  Normal   Started    35s (x4 over 99s)   kubelet            spec.containers{worker}: Container started
  Warning  BackOff    25s (x3 over 80s)   kubelet            spec.containers{worker}: Back-off restarting failed container worker in pod orders-worker-7d5f5f5b78-8rrpt_s14-issues(f4c0f635-7c99-4459-b5f2-2abbd2668e40)

describe says WHAT happened (exit code 1, restarted N times) but not WHY.

==============================================================
STEP 4 - INVESTIGATE orders-worker: logs, current and --previous
==============================================================
Waiting for a moment when the container has just been RESTARTED and is
running again, because that is when the two commands differ...
NAME                             READY   STATUS    RESTARTS      AGE
orders-worker-7d5f5f5b78-8rrpt   1/1     Running   4 (57s ago)   2m12s

$ kubectl -n s14-issues logs orders-worker-7d5f5f5b78-8rrpt
orders-worker v1.4 starting
reading configuration from environment
QUEUE_URL not set yet, retry 1/3 in 3s

$ kubectl -n s14-issues logs orders-worker-7d5f5f5b78-8rrpt --previous
orders-worker v1.4 starting
reading configuration from environment
QUEUE_URL not set yet, retry 1/3 in 3s
QUEUE_URL not set yet, retry 2/3 in 3s
QUEUE_URL not set yet, retry 3/3 in 3s
FATAL: QUEUE_URL is not set - cannot connect to the order queue

Plain 'logs' shows the CURRENT attempt, which has not reached the error
yet. '--previous' shows the attempt that crashed, and the app says
exactly what is wrong: QUEUE_URL is not set.

--- confirm from the spec: what env does the container actually get? ---
$ kubectl -n s14-issues get deploy orders-worker -o jsonpath='{.spec.template.spec.containers[0].env}'
  env = ''   (empty: nothing is injected)

==============================================================
STEP 5 - INVESTIGATE thumbnailer: the logs do NOT explain it
==============================================================
$ kubectl -n s14-issues logs thumbnailer-6b6d99b78c-nntfr
thumbnailer starting, warming a 150 MB image cache

It printed 'starting' and then silence - no stack trace, no error line.
Something outside the process killed it. describe shows who:

$ kubectl -n s14-issues describe pod thumbnailer-6b6d99b78c-nntfr
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Wed, 07 Oct 2026 23:29:41 +0530
      Finished:     Wed, 07 Oct 2026 23:29:43 +0530
    Ready:          False
    Restart Count:  4
    Limits:
      cpu:     200m
      memory:  64Mi

--- the same facts as one line per pod (jsonpath / custom-columns) ---
POD                              RESTARTS   LAST_REASON   EXIT_CODE   MEM_LIMIT
orders-worker-7d5f5f5b78-8rrpt   4          Error         1           32Mi
thumbnailer-6b6d99b78c-nntfr     4          OOMKilled     137         64Mi

--- warnings only, newest last ---
LAST SEEN               TYPE      REASON             OBJECT                                 MESSAGE
57s (x3 over 112s)      Warning   BackOff            Pod/orders-worker-7d5f5f5b78-8rrpt     Back-off restarting failed container worker in pod orders-worker-7d5f5f5b78-8rrpt_s14-issues(f4c0f635-7c99-4459-b5f2-2abbd2668e40)
40s (x4 over 2m8s)      Warning   BackOff            Pod/thumbnailer-6b6d99b78c-nntfr       Back-off restarting failed container thumbnailer in pod thumbnailer-6b6d99b78c-nntfr_s14-issues(9040f76b-c2e4-44a8-aff0-ee7bb056134e)

==============================================================
STEP 6 - ROOT CAUSE
==============================================================
orders-worker : exit code 1  = the APP chose to exit. Its own log line says
                QUEUE_URL is missing; the Deployment has no env section.
thumbnailer   : exit code 137 = 128 + 9 (SIGKILL), reason OOMKilled. The
                kernel killed it for exceeding the 64Mi memory limit while
                warming a 150 MB cache. Nothing in the app is 'wrong'.

==============================================================
STEP 7 - FIX: see exactly what will change, then apply
==============================================================
$ kubectl diff -f fixed.yaml
  +        env:
  +        - name: QUEUE_URL
  +          value: redis://orders-queue.s14-issues.svc.cluster.local:6379/0
  -            memory: 64Mi
  +            memory: 256Mi
  -            memory: 32Mi
  +            memory: 192Mi

deployment.apps/orders-worker configured
deployment.apps/thumbnailer configured
Waiting for deployment "orders-worker" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "orders-worker" rollout to finish: 1 old replicas are pending termination...
deployment "orders-worker" successfully rolled out
deployment "thumbnailer" successfully rolled out

==============================================================
STEP 8 - VERIFY: Running, and STAYS running
==============================================================
NAME                             READY   STATUS        RESTARTS      AGE
orders-worker-5f977dcc55-4tvnq   1/1     Running       0             6s
orders-worker-7d5f5f5b78-8rrpt   1/1     Terminating   4 (64s ago)   2m19s
thumbnailer-9b66b87f-jlms4       1/1     Running       0             6s

waiting 40s - a crash loop would have restarted at least once by now...
NAME                             READY   STATUS    RESTARTS   AGE
orders-worker-5f977dcc55-4tvnq   1/1     Running   0          46s
thumbnailer-9b66b87f-jlms4       1/1     Running   0          46s

$ kubectl -n s14-issues logs deploy/orders-worker --tail=3
polling redis://orders-queue.s14-issues.svc.cluster.local:6379/0 for new orders
polling redis://orders-queue.s14-issues.svc.cluster.local:6379/0 for new orders
polling redis://orders-queue.s14-issues.svc.cluster.local:6379/0 for new orders

$ kubectl -n s14-issues logs deploy/thumbnailer
thumbnailer starting, warming a 150 MB image cache
cache warm, serving

==============================================================
DONE
==============================================================
```
