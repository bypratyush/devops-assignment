# loadbalancer - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Deploy the backend (3 replicas)
==============================================================
deployment.apps/web-app-loadbalancer created
Waiting for deployment "web-app-loadbalancer" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "web-app-loadbalancer" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "web-app-loadbalancer" rollout to finish: 2 of 3 updated replicas are available...
deployment "web-app-loadbalancer" successfully rolled out
pod/lb-client created
pod/lb-client condition met

==============================================================
STEP 2 - First, WITHOUT a load balancer controller
==============================================================
Removing the MetalLB address pool to show the default kind behaviour:
service/web-service-loadbalancer created

waiting a few seconds...
NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
web-service-loadbalancer   LoadBalancer   10.96.25.107   <pending>     80:30452/TCP   0s

>>> EXTERNAL-IP is <pending>, and it will stay that way forever.

WHY: 'type: LoadBalancer' does not create a load balancer by itself.
     It just asks an EXTERNAL controller to provide one:
       - on EKS/GKE/AKS the cloud controller manager provisions a real
         cloud LB (an AWS NLB, a GCP forwarding rule, ...)
       - on bare metal or kind there is no such controller, so nothing
         ever answers the request

--- the service's events say exactly this ---
Events:                   <none>

==============================================================
STEP 3 - Install the missing piece (MetalLB address pool)
==============================================================
MetalLB is already installed in namespace metallb-system:
  controller-6d6c78c64c-7xr42    Running
  speaker-6qw4n                  Running
  speaker-87xcp                  Running
  speaker-hln7p                  Running

Now giving it a pool of IPs to hand out, from kind's own Docker network:
ipaddresspool.metallb.io/kind-pool created
l2advertisement.metallb.io/kind-l2 created

NAME        AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
kind-pool   true          false             ["192.168.96.200-192.168.96.250"]

==============================================================
STEP 4 - The EXTERNAL-IP is allocated
==============================================================
NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
web-service-loadbalancer   LoadBalancer   10.96.25.107   192.168.96.200   80:30452/TCP   1s

EXTERNAL-IP = 192.168.96.200   (allocated by MetalLB from 192.168.96.200-250)

==============================================================
STEP 5 - A LoadBalancer is a SUPERSET of NodePort and ClusterIP
==============================================================
  ClusterIP : 10.96.25.107
  NodePort  : 30452
  ExternalIP: 192.168.96.200

All three exist at once. Kubernetes layers them:
  ClusterIP     <- always allocated
  + NodePort    <- added automatically for LoadBalancer
  + External IP <- added by the LB controller

==============================================================
STEP 6 - Reaching the external IP FROM INSIDE the Docker network
==============================================================
waiting for MetalLB L2 advertisement to converge...
  answered after ~2s

  http://192.168.96.200  ->  HTTP 200

--- the HTML it served ---
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }

==============================================================
STEP 7 - And from a kind NODE (also on the Docker network)
==============================================================
  from control-plane node: HTTP 200

==============================================================
STEP 8 - From macOS: NOT reachable, and that is a Docker Desktop limit
==============================================================
Trying http://192.168.96.200 from the host:
  TIMED OUT.

This is NOT a Kubernetes failure. Docker Desktop on macOS runs containers
inside a Linux VM, and the 192.168.96.0/20 Docker network is not routed
from the host. On Linux (where Docker runs natively) this same IP would
be curl-able directly, and on a real cloud the EXTERNAL-IP would be a
public address.

To reach it from macOS anyway:
  kubectl port-forward svc/web-service-loadbalancer 9090:80

==============================================================
STEP 9 - Load balancing across the 3 pods
==============================================================
sent 30 requests to the EXTERNAL IP (tagged lbprobe-19947)

  web-app-loadbalancer-5db87c7b9-2rg5j       served  9 requests
  web-app-loadbalancer-5db87c7b9-rx867       served 10 requests
  web-app-loadbalancer-5db87c7b9-vsh6v       served 11 requests
  ------------------------------------------------------------
  TOTAL                                      served 30 requests

==============================================================
DONE
==============================================================
```
