# metrics-server install - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./install-metrics-server.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Before: is there a Metrics API at all?
==============================================================
$ kubectl top nodes
error: Metrics API not available

$ kubectl get apiservice v1beta1.metrics.k8s.io
Error from server (NotFound): apiservices.apiregistration.k8s.io "v1beta1.metrics.k8s.io" not found

==============================================================
STEP 2 - Apply the upstream metrics-server manifest (v0.9.0)
==============================================================
serviceaccount/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
service/metrics-server created
deployment.apps/metrics-server created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created

==============================================================
STEP 3 - Add --kubelet-insecure-tls (kind only)
==============================================================
deployment.apps/metrics-server patched
Waiting for deployment "metrics-server" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "metrics-server" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "metrics-server" rollout to finish: 1 old replicas are pending termination...
deployment "metrics-server" successfully rolled out

  --cert-dir=/tmp
  --secure-port=10250
  --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
  --kubelet-use-node-status-port
  --metric-resolution=15s
  --kubelet-insecure-tls

==============================================================
STEP 4 - Wait for the APIService to report Available
==============================================================
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io condition met
NAME                     SERVICE                      AVAILABLE   AGE
v1beta1.metrics.k8s.io   kube-system/metrics-server   True        41s

==============================================================
STEP 5 - After: kubectl top works
==============================================================
$ kubectl top nodes
NAME                      CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
devops-hw-control-plane   124m         0%       1128Mi          14%         
devops-hw-worker          56m          0%       345Mi           4%          
devops-hw-worker2         84m          0%       272Mi           3%          

$ kubectl top pods -n kube-system
NAME                                     CPU(cores)   MEMORY(bytes)   
coredns-559f6c778d-djbjl                 2m           28Mi            
coredns-559f6c778d-kn29k                 2m           24Mi            
etcd-devops-hw-control-plane             16m          64Mi            
kindnet-9ct97                            1m           27Mi            
kindnet-q569g                            4m           28Mi            
kube-apiserver-devops-hw-control-plane   33m          307Mi           
kube-proxy-7pjlj                         2m           33Mi            
kube-proxy-g5p89                         3m           32Mi            
kube-proxy-tqnkd                         3m           31Mi            
kube-scheduler-devops-hw-control-plane   6m           49Mi            
metrics-server-84c99cb944-vqmln          3m           15Mi            

==============================================================
DONE
==============================================================
```
