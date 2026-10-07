# ContainerCreating - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Deploy the broken manifest
==============================================================
deployment.apps/invoice-service created

==============================================================
STEP 2 - IDENTIFY: scheduled, but never gets past ContainerCreating
==============================================================
NAME                               READY   STATUS              RESTARTS   AGE   IP       NODE               NOMINATED NODE   READINESS GATES
invoice-service-785bd959d6-khk6q   0/1     ContainerCreating   0          45s   <none>   devops-hw-worker   <none>           <none>

Unlike Pending, NODE is set: the scheduler did its job. The kubelet on
that node is stuck preparing the pod. 45 seconds for a 2 MB busybox
image that is already cached is not 'slow', it is stuck.

==============================================================
STEP 3 - INVESTIGATE: describe -> Volumes and Events
==============================================================
$ kubectl -n s14-issues describe pod invoice-service-785bd959d6-khk6q
Volumes:
  config:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      invoice-config
    Optional:  false
  db-creds:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  invoice-db
    Optional:    false
    Optional:                false
Events:
  Type     Reason       Age                From               Message
  ----     ------       ----               ----               -------
  Normal   Scheduled    45s                default-scheduler  Successfully assigned s14-issues/invoice-service-785bd959d6-khk6q to devops-hw-worker
  Warning  FailedMount  14s (x7 over 45s)  kubelet            MountVolume.SetUp failed for volume "config" : configmap "invoice-config" not found
  Warning  FailedMount  14s (x7 over 45s)  kubelet            MountVolume.SetUp failed for volume "db-creds" : secret "invoice-db" not found

--- check whether the referenced objects exist ---
$ kubectl -n s14-issues get configmap invoice-config
Error from server (NotFound): configmaps "invoice-config" not found
$ kubectl -n s14-issues get secret invoice-db
Error from server (NotFound): secrets "invoice-db" not found

$ kubectl -n s14-issues get configmaps,secrets
NAME                         DATA   AGE
configmap/kube-root-ca.crt   1      6m44s

--- no container yet, so nothing to exec into or read logs from ---
$ kubectl -n s14-issues logs invoice-service-785bd959d6-khk6q
Error from server (BadRequest): container "invoice" in pod "invoice-service-785bd959d6-khk6q" is waiting to start: ContainerCreating

==============================================================
STEP 4 - ROOT CAUSE
==============================================================
The pod mounts ConfigMap 'invoice-config' and Secret 'invoice-db'.
Neither exists in namespace s14-issues, so MountVolume.SetUp fails and the
kubelet will not start a container with half its volumes missing.
(A missing key referenced from an ENV var fails differently - see
 09-configuration, CreateContainerConfigError.)

==============================================================
STEP 5 - FIX: create the missing ConfigMap and Secret
==============================================================
pod before the fix: invoice-service-785bd959d6-khk6q
configmap/invoice-config created
secret/invoice-db created
deployment.apps/invoice-service unchanged

The Deployment is unchanged ('unchanged' above), so no new pod is
created. Watching the SAME pod recover as the kubelet retries the mount:
23:28:41  NAME                               READY   STATUS              RESTARTS   AGE
23:28:41  invoice-service-785bd959d6-khk6q   0/1     ContainerCreating   0          46s
23:28:59  invoice-service-785bd959d6-khk6q   0/1     ContainerCreating   0          64s
23:29:00  invoice-service-785bd959d6-khk6q   1/1     Running             0          65s

==============================================================
STEP 6 - VERIFY
==============================================================
NAME                               READY   STATUS    RESTARTS   AGE    IP             NODE               NOMINATED NODE   READINESS GATES
invoice-service-785bd959d6-khk6q   1/1     Running   0          2m1s   10.244.2.117   devops-hw-worker   <none>           <none>

$ kubectl -n s14-issues logs invoice-service-785bd959d6-khk6q
invoice-service starting
settings: currency=INR tax.rate=18 
db password file present: yes

$ kubectl -n s14-issues exec invoice-service-785bd959d6-khk6q -- ls /etc/invoice /etc/invoice-db
/etc/invoice:
settings.properties

/etc/invoice-db:
password

Scheduled     1     Successfully assigned s14-issues/invoice-service-785bd959d6-khk6q to devops-hw-worker
FailedMount   7     MountVolume.SetUp failed for volume "config" : configmap "invoice-config" not found
FailedMount   7     MountVolume.SetUp failed for volume "db-creds" : secret "invoice-db" not found
Pulled        1     Container image "busybox:1.36" already present on machine and can be accessed by the pod
Created       1     Container created
Started       1     Container started

==============================================================
DONE
==============================================================
```
