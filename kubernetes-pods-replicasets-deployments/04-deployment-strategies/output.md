# deployment-strategies - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-09-18.

```text
pod/strategy-client created

==============================================================
STRATEGY 1 - Recreate:  kill everything, then start the new version
==============================================================
deployment "app-recreate" successfully rolled out

--- steady state ---
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
app-recreate   3/3     3            3           1s

--- updating the image (watching availableReplicas the whole time) ---
deployment "app-recreate" successfully rolled out
  (availability samples captured by kubectl --watch)

  desired replicas          : 3
  MINIMUM available during  : 0

  >>> IT HIT ZERO. Every pod was terminated before any new pod started.
      That is a real, measured OUTAGE.

  Use Recreate when two versions MUST NOT run at once - e.g. a database
  schema migration, or a singleton that takes an exclusive lock.

==============================================================
STRATEGY 2 - RollingUpdate:  replace gradually, stay available (DEFAULT)
==============================================================
deployment "app-rolling" successfully rolled out

--- steady state ---
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
app-rolling   4/4     4            4           3s

  maxUnavailable: 1  -> never more than 1 pod BELOW desired
  maxSurge:       1  -> never more than 1 pod ABOVE desired
  so with replicas=4 availability should never drop below 3.

--- updating the image (watching availableReplicas the whole time) ---
deployment "app-rolling" successfully rolled out
  (availability samples captured by kubectl --watch)

  desired replicas          : 4
  MINIMUM available during  : 3   (maxUnavailable=1 guarantees >= 3)

  >>> NEVER hit zero. The app served traffic throughout.
      Same cluster, same image change as Recreate - different outcome.

==============================================================
STRATEGY 3 - Blue/Green:  two full environments, one instant switch
==============================================================
deployment "app-blue" successfully rolled out
deployment "app-green" successfully rolled out

--- both environments are running at full size, simultaneously ---
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
app-blue    3/3     3            3           1s
app-green   3/3     3            3           1s

  app-blue-65cfdb6b6-npm84           Running
  app-blue-65cfdb6b6-x9v66           Running
  app-blue-65cfdb6b6-xsqvr           Running
  app-green-5dd684bf9b-cz8lh         Running
  app-green-5dd684bf9b-sl44r         Running
  app-green-5dd684bf9b-x974s         Running

--- the Service currently selects version=blue ---
  selector: {"app":"bg-app","version":"blue"}

  10 requests through the service:
     5     app-blue-65cfdb6b6-npm84
     1     app-blue-65cfdb6b6-x9v66
     3     app-blue-65cfdb6b6-xsqvr

--- THE SWITCH: patch the selector to version=green ---
  $ kubectl patch svc bg-service -p '{"spec":{"selector":{"app":"bg-app","version":"green"}}}'
  selector: {"app":"bg-app","version":"green"}

  10 requests through the SAME service name:
     3     app-green-5dd684bf9b-cz8lh
     4     app-green-5dd684bf9b-sl44r
     3     app-green-5dd684bf9b-x974s

  >>> 100% of traffic moved from blue to green in ONE atomic operation.
      Rollback is the same command with version=blue - instant, because
      the blue pods were never torn down.

  Cost: you run DOUBLE the pods for the whole switchover window.

==============================================================
STRATEGY 4 - Canary:  send a small slice of real traffic to the new version
==============================================================
deployment "app-stable" successfully rolled out
deployment "app-canary" successfully rolled out

--- 9 stable pods + 1 canary pod, behind ONE service ---
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
app-canary   1/1     1            1           3s
app-stable   9/9     9            9           3s

  The Service selects only 'app: canary-app' and ignores 'track',
  so BOTH deployments are endpoints of the same service:
  selector: {"app":"canary-app"}
  endpoints: 10

--- sending 100 requests and counting which track served them ---

  requests sent      : 100
  responses counted  : 100

  stable :  92 / 100  (92%)
  canary :   8 / 100  (8%)

  Expected ~90/10, because traffic splits by REPLICA COUNT (9 vs 1).
  It is proportional, not exact - kube-proxy picks a backend at random
  per connection, so small samples vary.

--- promoting the canary: scale it up, scale stable down ---
  after scaling to 5/5 -> stable 48, canary 52 (~50/50)

  >>> Traffic share is controlled purely by the replica ratio.
      For percentage control independent of pod count you need a service
      mesh (Istio, Linkerd) or an ingress that supports weighted routing.

==============================================================
SUMMARY - measured, on this cluster
==============================================================
  Strategy        Downtime   Pods needed   Rollback        Two versions live?
  --------------  ---------  ------------  --------------  ------------------
  Recreate        YES (0     N             redeploy old    never
                  available)                               (that is the point)
  RollingUpdate   none       N + maxSurge  rollout undo    briefly, during roll
  Blue/Green      none       2 x N         flip selector   yes, both full size
  Canary          none       N + canary    scale canary    yes, by ratio
                                           to 0

  Default to RollingUpdate. Reach for the others deliberately:
    Recreate    - versions cannot coexist (schema migration, exclusive lock)
    Blue/Green  - you need instant, atomic rollback and can afford 2x pods
    Canary      - you want real production traffic to validate a release
```
