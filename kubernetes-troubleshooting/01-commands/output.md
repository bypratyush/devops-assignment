# kubectl troubleshooting commands - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
SETUP - deploy the practice workload
==============================================================
namespace/s14-commands created
deployment.apps/web created
service/web created
pod/multi created
pod/flaky created
pod/cpu-burner created
pod/not-ready created
Waiting for deployment "web" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "web" rollout to finish: 1 of 2 updated replicas are available...
deployment "web" successfully rolled out
pod/multi condition met
pod/cpu-burner condition met
waiting 60s so 'flaky' has crashed and been restarted once...

==============================================================
1. kubectl get - WHAT exists and what state is it in?
==============================================================
$ kubectl -n s14-commands get pods
NAME                   READY   STATUS    RESTARTS      AGE
cpu-burner             1/1     Running   0             70s
flaky                  1/1     Running   1 (15s ago)   70s
multi                  2/2     Running   0             70s
not-ready              0/1     Running   0             69s
web-74f55b4568-5pfzg   1/1     Running   0             70s
web-74f55b4568-vklxz   1/1     Running   0             70s

READY 0/1 or a growing RESTARTS column is the first thing to look for.

--- -o wide: add IP, NODE (where did it land? is it on the same node as X?) ---
$ kubectl -n s14-commands get pods -o wide
NAME                   READY   STATUS    RESTARTS      AGE   IP            NODE                NOMINATED NODE   READINESS GATES
cpu-burner             1/1     Running   0             71s   10.244.1.11   devops-hw-worker2   <none>           <none>
flaky                  1/1     Running   1 (16s ago)   71s   10.244.1.12   devops-hw-worker2   <none>           <none>
multi                  2/2     Running   0             71s   10.244.1.9    devops-hw-worker2   <none>           <none>
not-ready              0/1     Running   0             70s   10.244.1.13   devops-hw-worker2   <none>           <none>
web-74f55b4568-5pfzg   1/1     Running   0             71s   10.244.2.38   devops-hw-worker    <none>           <none>
web-74f55b4568-vklxz   1/1     Running   0             71s   10.244.1.10   devops-hw-worker2   <none>           <none>

--- several kinds at once ---
$ kubectl -n s14-commands get deploy,rs,svc,endpointslices
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   2/2     2            2           73s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/web-74f55b4568   2         2         2       73s

NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/web   ClusterIP   10.96.24.220   <none>        80/TCP    73s

NAME                                       ADDRESSTYPE   PORTS   ENDPOINTS                 AGE
endpointslice.discovery.k8s.io/web-vwbr4   IPv4          80      10.244.2.38,10.244.1.10   73s

--- labels, and selecting by label (exactly what a Service does) ---
$ kubectl -n s14-commands get pods --show-labels
NAME                   READY   STATUS    RESTARTS      AGE   LABELS
cpu-burner             1/1     Running   0             73s   app=cpu-burner
flaky                  1/1     Running   1 (18s ago)   73s   app=flaky
multi                  2/2     Running   0             73s   app=multi
not-ready              0/1     Running   0             72s   app=not-ready
web-74f55b4568-5pfzg   1/1     Running   0             73s   app=web,pod-template-hash=74f55b4568,tier=frontend
web-74f55b4568-vklxz   1/1     Running   0             73s   app=web,pod-template-hash=74f55b4568,tier=frontend

$ kubectl -n s14-commands get pods -l app=web
NAME                   READY   STATUS    RESTARTS   AGE
web-74f55b4568-5pfzg   1/1     Running   0          74s
web-74f55b4568-vklxz   1/1     Running   0          74s

$ kubectl -n s14-commands get pods -l app in (multi,flaky)
NAME    READY   STATUS    RESTARTS      AGE
flaky   1/1     Running   1 (19s ago)   74s
multi   2/2     Running   0             74s

--- field selector: filter on status, not labels ---
$ kubectl -n s14-commands get pods --field-selector=status.phase=Running,metadata.name!=cpu-burner
NAME                   READY   STATUS    RESTARTS      AGE
flaky                  1/1     Running   1 (19s ago)   74s
multi                  2/2     Running   0             74s
not-ready              0/1     Running   0             73s
web-74f55b4568-5pfzg   1/1     Running   0             74s
web-74f55b4568-vklxz   1/1     Running   0             74s

--- sort by restart count (the noisy pod floats to the bottom) ---
$ kubectl -n s14-commands get pods --sort-by=.status.containerStatuses[0].restartCount
NAME                   READY   STATUS    RESTARTS      AGE
cpu-burner             1/1     Running   0             74s
multi                  2/2     Running   0             74s
not-ready              0/1     Running   0             73s
web-74f55b4568-5pfzg   1/1     Running   0             74s
web-74f55b4568-vklxz   1/1     Running   0             74s
flaky                  1/1     Running   1 (19s ago)   74s

--- -o yaml: the full object, including status the API server added ---
$ kubectl -n s14-commands get pod web-74f55b4568-5pfzg -o yaml | grep -A6 '^status:'
status:
  allocatedResources:
    cpu: 20m
    memory: 16Mi
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2026-10-07T18:24:56Z"

--- -o jsonpath: one field, for scripts ---
$ kubectl -n s14-commands get pod flaky -o jsonpath='{.status.containerStatuses[0].restartCount}'
1
$ kubectl -n s14-commands get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}'
cpu-burner	devops-hw-worker2
flaky	devops-hw-worker2
multi	devops-hw-worker2
not-ready	devops-hw-worker2
web-74f55b4568-5pfzg	devops-hw-worker
web-74f55b4568-vklxz	devops-hw-worker2

--- -o custom-columns: your own table ---
$ kubectl -n s14-commands get pods -o custom-columns=POD:.metadata.name,IMAGE:.spec.containers[*].image,RESTARTS:.status.containerStatuses[*].restartCount,NODE:.spec.nodeName
POD                    IMAGE                       RESTARTS   NODE
cpu-burner             busybox:1.36                0          devops-hw-worker2
flaky                  busybox:1.36                1          devops-hw-worker2
multi                  busybox:1.36,busybox:1.36   0,0        devops-hw-worker2
not-ready              busybox:1.36                0          devops-hw-worker2
web-74f55b4568-5pfzg   nginx:1.27-alpine           0          devops-hw-worker
web-74f55b4568-vklxz   nginx:1.27-alpine           0          devops-hw-worker2

--- -w: watch changes live (a scale-up happens 2s into the watch) ---
23:56:10  NAME                   READY   STATUS    RESTARTS   AGE
23:56:10  web-74f55b4568-5pfzg   1/1     Running   0          77s
23:56:10  web-74f55b4568-vklxz   1/1     Running   0          77s
23:56:12  web-74f55b4568-5pl46   0/1     Pending   0          0s
23:56:13  web-74f55b4568-5pl46   0/1     Pending   0          1s
23:56:13  web-74f55b4568-5pl46   0/1     ContainerCreating   0          1s
23:56:14  web-74f55b4568-5pl46   0/1     ContainerCreating   0          2s
23:56:15  web-74f55b4568-5pl46   1/1     Running             0          3s
23:56:20  web-74f55b4568-5pfzg   1/1     Running             0          87s

--- nodes and services with -o wide ---
$ kubectl get nodes -o wide
NAME                      STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION             CONTAINER-RUNTIME
devops-hw-control-plane   Ready    control-plane   20d   v1.37.0   192.168.96.2   <none>        Debian GNU/Linux 13 (trixie)   6.12.76-linuxkit (arm64)   containerd://2.3.4
devops-hw-worker          Ready    <none>          20d   v1.37.0   192.168.96.3   <none>        Debian GNU/Linux 13 (trixie)   6.12.76-linuxkit (arm64)   containerd://2.3.4
devops-hw-worker2         Ready    <none>          20d   v1.37.0   192.168.96.4   <none>        Debian GNU/Linux 13 (trixie)   6.12.76-linuxkit (arm64)   containerd://2.3.4

$ kubectl -n s14-commands get svc -o wide
NAME   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE   SELECTOR
web    ClusterIP   10.96.24.220   <none>        80/TCP    91s   app=web

svc -o wide adds the SELECTOR column - compare it with --show-labels.

==============================================================
2. kubectl describe - the DETAILS and the recent Events for one object
==============================================================
$ kubectl -n s14-commands describe pod flaky   (trimmed to the useful parts)
Node:             devops-hw-worker2/192.168.96.4
IP:               10.244.1.12
    State:          Running
      Started:      Wed, 07 Oct 2026 23:56:02 +0530
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Wed, 07 Oct 2026 23:55:02 +0530
      Finished:     Wed, 07 Oct 2026 23:55:48 +0530
    Ready:          True
    Restart Count:  1
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Events:
  Type    Reason     Age                From               Message
  ----    ------     ----               ----               -------
  Normal  Scheduled  92s                default-scheduler  Successfully assigned s14-commands/flaky to devops-hw-worker2
  Normal  Pulled     33s (x2 over 87s)  kubelet            spec.containers{flaky}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal  Created    33s (x2 over 86s)  kubelet            spec.containers{flaky}: Container created
  Normal  Started    23s (x2 over 83s)  kubelet            spec.containers{flaky}: Container started

--- describe a Deployment: strategy, replica counts, ReplicaSets, events ---
Selector:               app=web
Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
StrategyType:           RollingUpdate
RollingUpdateStrategy:  25% max unavailable, 25% max surge
OldReplicaSets:  <none>
NewReplicaSet:   web-74f55b4568 (2/2 replicas created)
  Normal  ScalingReplicaSet  94s   deployment-controller  Scaled up replica set web-74f55b4568 from 0 to 2
  Normal  ScalingReplicaSet  15s   deployment-controller  Scaled up replica set web-74f55b4568 from 2 to 3
  Normal  ScalingReplicaSet  4s    deployment-controller  Scaled down replica set web-74f55b4568 from 3 to 2

--- describe a Service: is anything behind it? ---
Selector:                 app=web
Type:                     ClusterIP
IP:                       10.96.24.220
Port:                     <unset>  80/TCP
TargetPort:               http/TCP
Endpoints:                10.244.2.38:80,10.244.1.10:80

--- describe a node: what is already reserved on it ---
$ kubectl describe node devops-hw-worker | sed -n '/Allocated resources/,/memory/p'
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests      Limits
  --------           --------      ------
  cpu                1090m (7%)    3150m (21%)
  memory             1050Mi (13%)  1984Mi (25%)

==============================================================
3. kubectl logs - what the APPLICATION says
==============================================================
$ kubectl -n s14-commands logs web-74f55b4568-5pfzg --tail=3
2026/10/07 18:24:59 [notice] 1#1: start worker process 46
2026/10/07 18:24:59 [notice] 1#1: start worker process 47
2026/10/07 18:24:59 [notice] 1#1: start worker process 48

--- --timestamps (when did each line happen?) ---
$ kubectl -n s14-commands logs multi -c app --tail=3 --timestamps
2026-10-07T18:26:24.530939842Z [app] handled request 41
2026-10-07T18:26:26.545563801Z [app] handled request 42
2026-10-07T18:26:28.532916219Z [app] handled request 43

--- two containers: logs needs -c, or --all-containers ---
$ kubectl -n s14-commands logs multi --tail=3
Defaulted container "app" out of: app, sidecar
[app] handled request 41
[app] handled request 42
[app] handled request 43

$ kubectl -n s14-commands logs multi -c sidecar --tail=3
[sidecar] shipped log batch 27
[sidecar] shipped log batch 28
[sidecar] shipped log batch 29

$ kubectl -n s14-commands logs multi --all-containers --prefix --tail=2
[pod/multi/app] [app] handled request 42
[pod/multi/app] [app] handled request 43
[pod/multi/sidecar] [sidecar] shipped log batch 28
[pod/multi/sidecar] [sidecar] shipped log batch 29

--- --since: only the last N seconds ---
$ kubectl -n s14-commands logs multi -c app --since=5s
[app] handled request 42
[app] handled request 43

--- -f: follow (stream) - captured for 7 seconds, each line time-stamped on arrival ---
23:56:30  [app] handled request 44
23:56:32  [app] handled request 45
23:56:34  [app] handled request 46
23:56:36  [app] handled request 47

--- --previous: the container instance BEFORE the last restart ---
$ kubectl -n s14-commands get pod flaky
NAME    READY   STATUS    RESTARTS      AGE
flaky   1/1     Running   1 (50s ago)   105s

$ kubectl -n s14-commands logs flaky
run started at 18:26:03

$ kubectl -n s14-commands logs flaky --previous
run started at 18:25:02
lost connection to cache, exiting

The current run has not failed yet; --previous shows the run that did,
including the stderr line explaining why.

--- by label or through a Deployment (kubectl picks the pods for you) ---
$ kubectl -n s14-commands logs -l app=web --tail=1 --prefix
[pod/web-74f55b4568-5pfzg/nginx] 2026/10/07 18:24:59 [notice] 1#1: start worker process 48
[pod/web-74f55b4568-vklxz/nginx] 2026/10/07 18:24:59 [notice] 1#1: start worker process 48

$ kubectl -n s14-commands logs deploy/web --tail=1
Found 2 pods, using pod/web-74f55b4568-5pfzg
2026/10/07 18:24:59 [notice] 1#1: start worker process 48

==============================================================
4. kubectl exec - look from INSIDE the container
==============================================================
$ kubectl -n s14-commands exec web-74f55b4568-5pfzg -- nginx -v
nginx version: nginx/1.27.5

$ kubectl -n s14-commands exec web-74f55b4568-5pfzg -- cat /etc/resolv.conf
search s14-commands.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

$ kubectl -n s14-commands exec web-74f55b4568-5pfzg -- env | grep -E 'HOSTNAME|WEB_SERVICE'
HOSTNAME=web-74f55b4568-5pfzg
WEB_SERVICE_HOST=10.96.24.220
WEB_SERVICE_PORT=80

--- is the process listening where we think? (-c picks the container) ---
$ kubectl -n s14-commands exec web-74f55b4568-5pfzg -- netstat -tlnp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      1/nginx: master pro
tcp        0      0 :::80                   :::*                    LISTEN      1/nginx: master pro

$ kubectl -n s14-commands exec multi -c sidecar -- ps
PID   USER     TIME  COMMAND
    1 root      0:00 sh -c i=0; while true; do i=$((i+1)); echo "[sidecar] shipped log batch $i"; sleep 3; done
   11 root      0:00 ps

--- test connectivity from a pod's point of view ---
$ kubectl -n s14-commands exec multi -c app -- wget -qO- -T 3 http://web | grep -i title
<title>Welcome to nginx!</title>

Interactive shell (not capturable in a script): kubectl -n s14-commands exec -it web-74f55b4568-5pfzg -- sh

==============================================================
5. events - what KUBERNETES tried to do
==============================================================
$ kubectl events -n s14-commands --types=Warning | tail -4
LAST SEEN            TYPE      REASON      OBJECT          MESSAGE
1s (x24 over 105s)   Warning   Unhealthy   Pod/not-ready   Readiness probe failed: dial tcp 10.244.1.13:8080: connect: connection refused

--- events for one object only ---
$ kubectl events -n s14-commands --for pod/flaky
LAST SEEN            TYPE     REASON      OBJECT      MESSAGE
115s                 Normal   Scheduled   Pod/flaky   Successfully assigned s14-commands/flaky to devops-hw-worker2
56s (x2 over 110s)   Normal   Pulled      Pod/flaky   Container image "busybox:1.36" already present on machine and can be accessed by the pod
56s (x2 over 109s)   Normal   Created     Pod/flaky   Container created
46s (x2 over 106s)   Normal   Started     Pod/flaky   Container started

--- the older form: get events, sorted, filtered ---
$ kubectl -n s14-commands get events --sort-by=.lastTimestamp | tail -6
34s         Normal    Pulled              pod/web-74f55b4568-5pl46    Container image "nginx:1.27-alpine" already present on machine and can be accessed by the pod
33s         Normal    Started             pod/web-74f55b4568-5pl46    Container started
25s         Normal    Killing             pod/web-74f55b4568-5pl46    Stopping container nginx
25s         Normal    SuccessfulDelete    replicaset/web-74f55b4568   Deleted pod: web-74f55b4568-5pl46
25s         Normal    ScalingReplicaSet   deployment/web              Scaled down replica set web-74f55b4568 from 3 to 2
2s          Warning   Unhealthy           pod/not-ready               Readiness probe failed: dial tcp 10.244.1.13:8080: connect: connection refused

$ kubectl -n s14-commands get events --field-selector type=Warning | tail -4
LAST SEEN   TYPE      REASON      OBJECT          MESSAGE
2s          Warning   Unhealthy   pod/not-ready   Readiness probe failed: dial tcp 10.244.1.13:8080: connect: connection refused

Events are kept for 1 hour by default (kube-apiserver --event-ttl), so
for an incident from yesterday they are already gone.

==============================================================
6. kubectl explain - the API docs, offline, for the exact cluster version
==============================================================
$ kubectl explain pod.spec.containers.livenessProbe | head -20
KIND:       Pod
VERSION:    v1

FIELD: livenessProbe <Probe>


DESCRIPTION:
    Periodic probe of container liveness. Container will be restarted if the
    probe fails. Cannot be updated. More info:
    https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
    Probe describes a health check to be performed against a container to
    determine whether it is alive or ready to receive traffic.
    
FIELDS:
  exec	<ExecAction>
    Exec specifies a command to execute in the container.

  failureThreshold	<integer>
    Minimum consecutive failures for the probe to be considered failed after
    having succeeded. Defaults to 3. Minimum value is 1.

--- a single field ---
$ kubectl explain service.spec.ports.targetPort
KIND:       Service
VERSION:    v1

FIELD: targetPort <IntOrString>


DESCRIPTION:
    Number or name of the port to access on the pods targeted by the service.
    Number must be in the range 1 to 65535. Name must be an IANA_SVC_NAME. If
    this is a string, it will be looked up as a named port in the target Pod's
    container ports. If this is not specified, the value of the 'port' field is
    used (an identity map). This field is ignored for services with
    clusterIP=None, and should be omitted or set equal to the 'port' field. More
    info:
    https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service
    IntOrString is a type that can hold an int32 or a string.  When used in JSON
    or YAML marshalling and unmarshalling, it produces or consumes the inner
    type.  This allows you to have, for example, a JSON field that can accept a
    name or number.
    


--- --recursive: the shape of a whole sub-tree ---
$ kubectl explain deployment.spec.strategy --recursive
FIELDS:
  rollingUpdate	<RollingUpdateDeployment>
    maxSurge	<IntOrString>
    maxUnavailable	<IntOrString>
  type	<string>
  enum: Recreate, RollingUpdate


==============================================================
7. kubectl top - live CPU / memory (needs metrics-server)
==============================================================
$ kubectl top nodes
NAME                      CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
devops-hw-control-plane   3525m        23%      1710Mi          21%         
devops-hw-worker          1493m        9%       959Mi           12%         
devops-hw-worker2         1794m        11%      832Mi           10%         

$ kubectl -n s14-commands top pods --sort-by=cpu
NAME                   CPU(cores)   MEMORY(bytes)   
cpu-burner             144m         0Mi             
multi                  5m           0Mi             
not-ready              0m           0Mi             
web-74f55b4568-5pfzg   0m           13Mi            
web-74f55b4568-vklxz   0m           12Mi            

$ kubectl -n s14-commands top pods multi --containers
POD     NAME      CPU(cores)   MEMORY(bytes)   
multi   app       2m           0Mi             
multi   sidecar   3m           0Mi             

cpu-burner sits at its 150m LIMIT - it is being throttled, not crashing.
CPU over the limit is throttled; MEMORY over the limit is OOMKilled.

$ kubectl top pods -n kube-system --sort-by=memory | head -6
NAME                                              CPU(cores)   MEMORY(bytes)   
kube-apiserver-devops-hw-control-plane            1621m        870Mi           
kube-controller-manager-devops-hw-control-plane   110m         96Mi            
etcd-devops-hw-control-plane                      213m         81Mi            
kube-scheduler-devops-hw-control-plane            68m          50Mi            
metrics-server-84c99cb944-vqmln                   39m          33Mi            

==============================================================
DONE
==============================================================
```
