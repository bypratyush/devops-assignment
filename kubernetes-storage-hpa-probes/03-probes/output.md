# Probes - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Liveness: the app hangs 20s after every start
==============================================================
pod/liveness-demo created

watching RESTARTS (probe: 'cat /tmp/healthy' every 5s, 2 misses -> restart)
  t(s)     RESTARTS STATUS             READY
  0        0        Running            true
  9        0        Running            true
  23       0        Running            true
  33       0        Running            true
  41       1        Running            true
  50       1        Running            true
  58       1        Running            true
  67       1        Running            true
  76       2        Running            true
  84       2        Running            true
  93       2        Running            true
  101      2        Running            true
  110      3        Running            true

==============================================================
STEP 2 - Why it was restarted: the probe failures are in the events
==============================================================
TYPE      REASON      COUNT   MESSAGE
Warning   Unhealthy   6       Liveness probe failed: cat: can't open '/tmp/healthy': No such file or directory
Normal    Killing     3       Container app failed liveness probe, will be restarted
Normal    Started     4       Container started

--- last state of the container ---
  lastState: reason=Error exitCode=137

--- the log of the PREVIOUS (killed) container ---
  18:04:58 started, healthy
  18:05:18 simulating a hang: health file removed

The process never exited by itself - it was 'running' but useless. Only the
liveness probe noticed. Each kill is a fresh container (new /tmp), so it is
healthy again for 20s, then killed again, with a growing back-off between.

==============================================================
STEP 3 - Readiness: 3 nginx pods behind a Service, all Ready
==============================================================
deployment.apps/readiness-demo created
service/readiness-demo created
pod/client created
Waiting for deployment "readiness-demo" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "readiness-demo" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "readiness-demo" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "readiness-demo" rollout to finish: 2 of 3 updated replicas are available...
deployment "readiness-demo" successfully rolled out
NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE                NOMINATED NODE   READINESS GATES
readiness-demo-5765b48ccd-4c4sm   1/1     Running   0          9s    10.244.1.161   devops-hw-worker2   <none>           <none>
readiness-demo-5765b48ccd-59mlg   1/1     Running   0          9s    10.244.1.160   devops-hw-worker2   <none>           <none>
readiness-demo-5765b48ccd-x44k8   1/1     Running   0          9s    10.244.2.204   devops-hw-worker    <none>           <none>

  10.244.1.161  ready=true  readiness-demo-5765b48ccd-4c4sm
  10.244.2.204  ready=true  readiness-demo-5765b48ccd-x44k8
  10.244.1.160  ready=true  readiness-demo-5765b48ccd-59mlg

30 requests through the Service, counted by which pod answered:
    11 readiness-demo-5765b48ccd-4c4sm
     7 readiness-demo-5765b48ccd-59mlg
    12 readiness-demo-5765b48ccd-x44k8

==============================================================
STEP 4 - Make ONE pod not ready (delete its /ready file)
==============================================================
$ kubectl exec readiness-demo-5765b48ccd-4c4sm -- rm /usr/share/nginx/html/ready
NAME                              READY   STATUS    RESTARTS   AGE
readiness-demo-5765b48ccd-4c4sm   0/1     Running   0          22s
readiness-demo-5765b48ccd-59mlg   1/1     Running   0          22s
readiness-demo-5765b48ccd-x44k8   1/1     Running   0          22s

  10.244.1.161  ready=false  readiness-demo-5765b48ccd-4c4sm
  10.244.2.204  ready=true  readiness-demo-5765b48ccd-x44k8
  10.244.1.160  ready=true  readiness-demo-5765b48ccd-59mlg

30 requests through the Service again:
    16 readiness-demo-5765b48ccd-59mlg
    14 readiness-demo-5765b48ccd-x44k8

readiness-demo-5765b48ccd-4c4sm is still Running with RESTARTS 0 - readiness never restarts anything.
It is just taken out of the Service until it reports ready again.

==============================================================
STEP 5 - The probe failure as Kubernetes recorded it
==============================================================
REASON      COUNT   MESSAGE
Unhealthy   2       Readiness probe failed: Get "http://10.244.1.161:80/ready": dial tcp 10.244.1.161:80: connect: connection refused
Unhealthy   3       Readiness probe failed: HTTP probe failed with statuscode: 404

==============================================================
STEP 6 - Recover: put the file back, the pod rejoins by itself
==============================================================
pod/readiness-demo-5765b48ccd-4c4sm condition met
  10.244.1.161  ready=true  readiness-demo-5765b48ccd-4c4sm
  10.244.2.204  ready=true  readiness-demo-5765b48ccd-x44k8
  10.244.1.160  ready=true  readiness-demo-5765b48ccd-59mlg

    10 readiness-demo-5765b48ccd-4c4sm
    10 readiness-demo-5765b48ccd-59mlg
    10 readiness-demo-5765b48ccd-x44k8

==============================================================
STEP 7 - Startup probe: the same slow app, with and without one
==============================================================
NAME                READY   STATUS             RESTARTS      AGE
slow-no-startup     0/1     CrashLoopBackOff   5 (14s ago)   2m27s
slow-with-startup   1/1     Running            0             2m27s

--- slow-no-startup: liveness probe fires during the warm-up ---
REASON      COUNT   MESSAGE
Unhealthy   18      Liveness probe failed: Get "http://10.244.2.193:80/": dial tcp 10.244.2.193:80: connect: connection refused
Killing     6       Container web failed liveness probe, will be restarted

  previous container log: 18:05:46 warming up (30s)...

--- slow-with-startup: startup probe fails while warming up, then passes ---
REASON      COUNT   MESSAGE
Started     1       Container started
Unhealthy   6       Startup probe failed: Get "http://10.244.2.194:80/": dial tcp 10.244.2.194:80: connect: connection refused

  log: 18:03:49 warming up (30s)...
  log: 18:04:19 ready, starting nginx
  log: 2026/10/07 18:04:20 [notice] 1#1: using the "epoll" event method

Same image, same liveness probe. Without a startup probe the liveness probe
kills the container before it finishes starting, forever. With one, liveness
is held off until startup succeeds (here after ~30s, within its 60s budget).

==============================================================
DONE
==============================================================
```
