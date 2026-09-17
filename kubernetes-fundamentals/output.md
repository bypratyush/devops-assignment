# Kubernetes Fundamentals - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-09-18.

```text

==============================================================
1. THE CLUSTER
==============================================================
Kubernetes control plane is running at https://127.0.0.1:54986
CoreDNS is running at https://127.0.0.1:54986/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy


NAME                      STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION             CONTAINER-RUNTIME
devops-hw-control-plane   Ready    control-plane   75m   v1.37.0   192.168.96.4   <none>        Debian GNU/Linux 13 (trixie)   6.12.76-linuxkit (arm64)   containerd://2.3.4
devops-hw-worker          Ready    <none>          75m   v1.37.0   192.168.96.3   <none>        Debian GNU/Linux 13 (trixie)   6.12.76-linuxkit (arm64)   containerd://2.3.4
devops-hw-worker2         Ready    <none>          75m   v1.37.0   192.168.96.2   <none>        Debian GNU/Linux 13 (trixie)   6.12.76-linuxkit (arm64)   containerd://2.3.4

  client: v1.36.1
  server: v1.37.0

==============================================================
2. CONTROL PLANE vs WORKER NODES
==============================================================
  CONTROL PLANE - decides what should run where
    kube-apiserver          the ONLY way in. Everything talks to this.
    etcd                    key-value store: the entire cluster state
    kube-scheduler          assigns pods to nodes
    kube-controller-manager runs the control loops (deployment, replicaset...)

  EVERY NODE - actually runs the workloads
    kubelet                 starts/stops containers, reports status
    kube-proxy              programs the network rules for Services
    container runtime       containerd, CRI-O


--- these are real pods in this cluster ---
coredns-559f6c778d-djbjl                          devops-hw-control-plane   Running
coredns-559f6c778d-kn29k                          devops-hw-control-plane   Running
etcd-devops-hw-control-plane                      devops-hw-control-plane   Running
kindnet-9ct97                                     devops-hw-worker2         Running
kindnet-q569g                                     devops-hw-control-plane   Running
kindnet-xd667                                     devops-hw-worker          Running
kube-apiserver-devops-hw-control-plane            devops-hw-control-plane   Running
kube-controller-manager-devops-hw-control-plane   devops-hw-control-plane   Running
kube-proxy-7pjlj                                  devops-hw-worker2         Running
kube-proxy-g5p89                                  devops-hw-control-plane   Running
kube-proxy-tqnkd                                  devops-hw-worker          Running
kube-scheduler-devops-hw-control-plane            devops-hw-control-plane   Running


--- the runtime actually in use ---
  devops-hw-control-plane  containerd://2.3.4  kubelet=v1.37.0
  devops-hw-worker  containerd://2.3.4  kubelet=v1.37.0
  devops-hw-worker2  containerd://2.3.4  kubelet=v1.37.0

==============================================================
3. THE DECLARATIVE MODEL - the single most important idea
==============================================================
  You do NOT tell Kubernetes what to DO. You declare what you WANT,
  and controllers continuously work to make reality match.

    DESIRED STATE  (your YAML, stored in etcd)
          |
    controller compares  <-------------------+
          |                                   |
    ACTUAL STATE  (what is really running) ---+

  This reconciliation loop is why a deleted pod comes back, why a failed
  node's pods are rescheduled, and why 'kubectl apply' is idempotent.


--- imperative vs declarative ---
  imperative : kubectl run nginx --image=nginx        (do this now)
  declarative: kubectl apply -f deployment.yaml       (make it so)
  Production uses declarative YAML in git. Imperative is for exploration.

==============================================================
4. EVERY OBJECT HAS THE SAME FOUR TOP-LEVEL FIELDS
==============================================================
    apiVersion: apps/v1     which API group and version
    kind: Deployment        what type of object
    metadata:               name, namespace, labels, annotations
      name: my-app
    spec:                   YOUR desired state - you write this
      replicas: 3
    status:                 ACTUAL state - Kubernetes writes this, never you

--- spec vs status on a real object ---
deployment "fundamentals-demo" successfully rolled out
  spec.replicas   (desired) : 2
  status.replicas (actual)  : 2
  status.readyReplicas      : 2

==============================================================
5. NAMESPACES - virtual clusters inside the cluster
==============================================================
NAME                 STATUS   AGE
default              Active   75m
ingress-nginx        Active   6m39s
kube-node-lease      Active   75m
kube-public          Active   75m
kube-system          Active   75m
local-path-storage   Active   75m
metallb-system       Active   73m

  default          where your objects go if you do not say otherwise
  kube-system      the control plane's own components
  kube-public      world-readable cluster info
  kube-node-lease  node heartbeats


--- the same object name can exist in two namespaces ---
  demo-ns:  ns-demo
  default:  config-demo
  default:  fundamentals-demo
  default:  second-app

  Namespaces scope NAMES, and are the unit for RBAC and ResourceQuotas.
  They do NOT isolate the network by default - a pod in one namespace can
  reach a pod in another unless a NetworkPolicy stops it.


--- namespaced vs cluster-scoped resources ---
  namespaced     : pods, deployments, services, configmaps, secrets
  cluster-scoped : nodes, namespaces, persistentvolumes, clusterroles
    componentstatuses
    namespaces
    nodes
    persistentvolumes
    mutatingadmissionpolicies
    mutatingadmissionpolicybindings

==============================================================
6. LABELS AND SELECTORS - how everything is wired together
==============================================================
  config-demo-694d8cf9d9-kfhzw        1/1   Running   0     3m17s   app=config-demo,pod-template-hash=694d8cf9d9
  fundamentals-demo-78cf7d4bb-4mm8n   1/1   Running   0     3s      app=fundamentals-demo,pod-template-hash=78cf7d4bb
  fundamentals-demo-78cf7d4bb-8vrx5   1/1   Running   0     3s      app=fundamentals-demo,pod-template-hash=78cf7d4bb

  Labels are arbitrary key=value pairs. SELECTORS query them.
  This is the ONLY mechanism connecting Services to Pods, Deployments to
  their Pods, and NetworkPolicies to their targets. There are no
  foreign keys or IDs anywhere in Kubernetes - it is all label matching.


--- selecting with -l ---
  fundamentals-demo-78cf7d4bb-4mm8n
  fundamentals-demo-78cf7d4bb-8vrx5

  kubectl get pods -l app=web,env=prod      AND
  kubectl get pods -l 'env in (dev,stage)'  set-based
  kubectl get pods -l '!canary'             does NOT have the label


--- annotations are the other half ---
  labels      : for SELECTING. Short, indexed, queryable.
  annotations : for METADATA. Arbitrary, not queryable. Tools read them
                (ingress config, last-applied-configuration, checksums).

==============================================================
7. THE API IS THE PRODUCT
==============================================================

--- how many kinds of object does this cluster know about? ---
  78 resource types

  bindings                   true           Binding
  componentstatuses          false          ComponentStatus
  configmaps                 true           ConfigMap
  endpoints                  true           Endpoints
  events                     true           Event
  limitranges                true           LimitRange
  namespaces                 false          Namespace
  nodes                      false          Node
  persistentvolumeclaims     true           PersistentVolumeClaim
  persistentvolumes          false          PersistentVolume

  kubectl is only an HTTP client for the API server. Proof:

--- kubectl get pods -v=6  (shows the actual REST call) ---
  GET https://127.0.0.1:54986/api/v1/namespaces/default/pods?limit=500   -> 200 OK

  Everything - kubectl, the dashboard, controllers, operators - is a
  client of that one API. That is why RBAC on the API secures everything.

==============================================================
8. THE COMMANDS YOU WILL ACTUALLY USE
==============================================================
    kubectl get <kind> [-n ns] [-o wide|yaml|json] [--show-labels] [-l sel]
    kubectl describe <kind>/<name>        human-readable + EVENTS at the bottom
    kubectl logs <pod> [-c container] [-f] [--previous]
    kubectl exec -it <pod> -- sh
    kubectl apply -f file.yaml            declarative create-or-update
    kubectl delete -f file.yaml
    kubectl edit <kind>/<name>            opens $EDITOR, applies on save
    kubectl explain deployment.spec       FIELD DOCUMENTATION, offline
    kubectl api-resources                 what kinds exist
    kubectl get events --sort-by=.lastTimestamp
    kubectl config get-contexts           which cluster am I pointed at

--- kubectl explain - the built-in documentation ---
  GROUP:      apps
  KIND:       Deployment
  VERSION:    v1
  
  FIELD: replicas <integer>
  

--- events are the first place to look when something is wrong ---
  2s          Normal    Created                  pod/fundamentals-demo-78cf7d4bb-4mm8n    Container created
  2s          Normal    Started                  pod/fundamentals-demo-78cf7d4bb-8vrx5    Container started
  2s          Normal    Created                  pod/fundamentals-demo-78cf7d4bb-8vrx5    Container created
  2s          Normal    Pulled                   pod/fundamentals-demo-78cf7d4bb-8vrx5    Container image "nginx:1.25-alpine" already present on machine and can be accessed by the pod
  2s          Normal    Pulled                   pod/fundamentals-demo-78cf7d4bb-4mm8n    Container image "nginx:1.25-alpine" already present on machine and can be accessed by the pod

==============================================================
CLEANUP
==============================================================
  demo objects removed

==============================================================
DONE
==============================================================
```
