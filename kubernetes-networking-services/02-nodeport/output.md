# nodeport - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-09-18.

```text

==============================================================
STEP 1 - Deploy the backend (2 replicas)
==============================================================
deployment.apps/web-app-nodeport created
Waiting for deployment "web-app-nodeport" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "web-app-nodeport" rollout to finish: 1 of 2 updated replicas are available...
deployment "web-app-nodeport" successfully rolled out

==============================================================
STEP 2 - Deploy the NodePort service
==============================================================
service/web-service-nodeport created
pod/np-client created
pod/np-client condition met

==============================================================
STEP 3 - The service: note it has THREE ports
==============================================================
NAME                   TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE   SELECTOR
web-service-nodeport   NodePort   10.96.71.201   <none>        80:30080/TCP   1s    app=web-nodeport

  nodePort   30080  <- port opened on EVERY node, reachable from OUTSIDE
  port       80     <- the ClusterIP port, for in-cluster clients
  targetPort 80     <- the container port

A NodePort service is a SUPERSET of ClusterIP - it still got one:
  ClusterIP = 10.96.71.201

==============================================================
STEP 4 - Where the pods actually are
==============================================================
NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE                NOMINATED NODE   READINESS GATES
web-app-nodeport-6c8f48bd-nztsz   1/1     Running   0          1s    10.244.1.189   devops-hw-worker2   <none>           <none>
web-app-nodeport-6c8f48bd-qpfcn   1/1     Running   0          1s    10.244.2.178   devops-hw-worker    <none>           <none>

2 replicas across 3 nodes - so at least one node has NO pod.
That node will still answer on port 30080. That is the whole point.

==============================================================
STEP 5 - EVERY node listens on 30080, pod or no pod
==============================================================
Querying each node's internal IP from a pod inside the cluster:

  devops-hw-control-plane    192.168.96.4    pods_on_node=0   HTTP 200
  devops-hw-worker           192.168.96.3    pods_on_node=1   HTTP 200
  devops-hw-worker2          192.168.96.2    pods_on_node=1   HTTP 200

All nodes return 200. kube-proxy programmed the same rule on each one;
a node with no local pod just forwards the packet to a node that has one.

==============================================================
STEP 6 - Reaching it from OUTSIDE the cluster (the actual point)
==============================================================
This kind cluster maps hostPort 30080 -> control-plane containerPort 30080
(see lab/kind-config.yaml), so macOS can reach the NodePort directly:

  curl http://localhost:30080  ->  HTTP 200

--- the HTML it served ---
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }

Contrast with Task 01: a ClusterIP was UNREACHABLE from here.

==============================================================
STEP 7 - Load balancing across the 2 pods
==============================================================
sent 20 requests to localhost:30080 (tagged npprobe-44820)

  web-app-nodeport-6c8f48bd-nztsz        served 11 requests
  web-app-nodeport-6c8f48bd-qpfcn        served  9 requests
  --------------------------------------------------------
  TOTAL                                  served 20 requests

==============================================================
STEP 8 - The port range is enforced: 30000-32767
==============================================================
Trying to create a NodePort service on port 80:
  The Service "bad-nodeport" is invalid: spec.ports[0].nodePort: Invalid value: 80: provided port is not in the valid range. The range of valid ports is 30000-32767

The range is set by the API server's --service-node-port-range.
Omit nodePort entirely and Kubernetes allocates a free one for you.

==============================================================
STEP 9 - Internal clients can still use the ClusterIP port
==============================================================
  http://web-service-nodeport:80 (in-cluster) -> HTTP 200

In-cluster traffic should use the service NAME on port 80, not the NodePort.

==============================================================
DONE
==============================================================
```
