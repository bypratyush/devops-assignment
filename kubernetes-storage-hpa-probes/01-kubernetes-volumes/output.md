# Kubernetes Volumes - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - emptyDir: two containers, one shared scratch volume
==============================================================
pod/emptydir-demo created
pod/emptydir-demo condition met
NAME            READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
emptydir-demo   2/2     Running   0          1s    10.244.2.49   devops-hw-worker   <none>           <none>

The writer (busybox) appends to /shared/index.html. nginx serves the SAME
volume as /usr/share/nginx/html. Fetching it from the writer container over
localhost (containers in a pod also share one network namespace):

$ kubectl exec emptydir-demo -c writer -- wget -qO- http://localhost/
  pod started 17:51:29 on emptydir-demo
  writer tick 17:51:29
  writer tick 17:51:34

==============================================================
STEP 2 - Where an emptyDir actually lives on the node
==============================================================
pod uid = 6a33e5cd-e475-4113-9629-c748aa5ec11a   node = devops-hw-worker

$ docker exec devops-hw-worker ls /var/lib/kubelet/pods/6a33e5cd-e475-4113-9629-c748aa5ec11a/volumes/kubernetes.io~empty-dir/
  ram-scratch
  shared

$ docker exec devops-hw-worker head -3 .../kubernetes.io~empty-dir/shared/index.html
  pod started 17:51:29 on emptydir-demo
  writer tick 17:51:29
  writer tick 17:51:34

A directory under the pod's UID. When the pod goes, the kubelet deletes it.

==============================================================
STEP 3 - medium: Memory makes it a tmpfs (RAM), the default is node disk
==============================================================
  Filesystem                Size      Used Available Use% Mounted on
  /dev/vda1               910.7G    121.3G    743.1G  14% /shared
  tmpfs                    16.0M         0     16.0M   0% /scratch

/scratch is tmpfs, capped by sizeLimit 16Mi, and its usage counts against the
container's memory limit. /shared is on the node's own filesystem.

==============================================================
STEP 4 - emptyDir SURVIVES a container restart
==============================================================
first line before: pod started 17:51:29 on emptydir-demo
stopping nginx inside the 'web' container (container exits, kubelet restarts it)...
NAME            READY       WEB-RESTARTS
emptydir-demo   true,true   1

first line after : pod started 17:51:29 on emptydir-demo
lines in file    : 3

Same first line - the volume belongs to the POD, not the container.

==============================================================
STEP 5 - emptyDir is LOST when the pod is deleted
==============================================================
pod "emptydir-demo" deleted from s13-volumes namespace
re-created the pod from the same YAML (new uid 846bcf79-46aa-4924-b0ba-f6732e09b0fa)

first line now : pod started 17:51:43 on emptydir-demo
lines in file  : 2

old pod's directory on devops-hw-worker (the kubelet's housekeeping removes it a few
seconds after the pod is gone, so poll for it):
  gone after ~1s:
  ls: cannot access '/var/lib/kubelet/pods/6a33e5cd-e475-4113-9629-c748aa5ec11a': No such file or directory

Fresh file, old data gone. Good for caches and scratch space, never for data you need.

==============================================================
STEP 6 - hostPath: a directory on the NODE, mounted into the pod
==============================================================
pod/hostpath-demo created
pod/hostpath-other-node created
pod/hostpath-demo condition met
pod/hostpath-other-node condition met
NAME                  READY   STATUS    RESTARTS   AGE   IP            NODE                NOMINATED NODE   READINESS GATES
hostpath-demo         1/1     Running   0          1s    10.244.2.53   devops-hw-worker    <none>           <none>
hostpath-other-node   1/1     Running   0          1s    10.244.1.49   devops-hw-worker2   <none>           <none>

The pod wrote a line. Reading it straight off the node (a kind node is a container):
$ docker exec devops-hw-worker cat /tmp/s13-hostpath-data/visits.log
  written by pod hostpath-demo at 17:51:45

==============================================================
STEP 7 - hostPath survives pod deletion (it is the node's disk)
==============================================================
pod "hostpath-demo" deleted from s13-volumes namespace
re-created hostpath-demo; the new pod appended its own line:
$ kubectl exec hostpath-demo -- cat /host-data/visits.log
  written by pod hostpath-demo at 17:51:45
  written by pod hostpath-demo at 17:51:50

==============================================================
STEP 8 - ...but only on THAT node
==============================================================
hostpath-other-node mounts the same path on devops-hw-worker2:
$ kubectl exec hostpath-other-node -- ls -la /host-data
  total 4
  drwxr-xr-x    2 root     root            40 Oct  7 17:51 .
  drwxr-xr-x    1 root     root          4096 Oct  7 17:51 ..

$ docker exec devops-hw-worker2 ls -la /tmp/s13-hostpath-data
  total 0
  drwxr-xr-x 2 root root 40 Oct  7 17:51 .
  drwxrwxrwt 3 root root 60 Oct  7 17:51 ..

Empty. If the scheduler moves the pod to another node, the data does not follow.
hostPath also gives the pod access to the node's filesystem, which is why
Pod Security 'baseline' and 'restricted' forbid it. Use it for node agents
(log collectors reading /var/log), not for application data.

==============================================================
STEP 9 - Static provisioning: an admin creates a PersistentVolume by hand
==============================================================
persistentvolume/s13-static-pv created
NAME            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
s13-static-pv   1Gi        RWO            Retain           Available           manual         <unset>                          0s

STATUS Available = exists, not claimed by anyone yet. PVs are cluster-scoped
(no namespace); PVCs are namespaced.

==============================================================
STEP 10 - The default-StorageClass trap
==============================================================
A claim WITHOUT storageClassName:
persistentvolumeclaim/s13-trap-pvc created
NAME           STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
s13-trap-pvc   Pending                                      standard       <unset>                 3s

  PV still: s13-static-pv   1Gi   RWO   Retain   Available         manual   <unset>         3s

The admission controller filled in STORAGECLASS 'standard' (the default class),
so this claim waits for dynamic provisioning and ignores my PV completely.
To bind a hand-made PV the claim must name the same class (or "").

==============================================================
STEP 11 - The PersistentVolumeClaim binds to the PV
==============================================================
persistentvolumeclaim/s13-static-pvc created
NAME            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                        STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
s13-static-pv   1Gi        RWO            Retain           Bound    s13-volumes/s13-static-pvc   manual         <unset>                          4s
NAME             STATUS   VOLUME          CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
s13-static-pvc   Bound    s13-static-pv   1Gi        RWO            manual         <unset>                 0s

Asked for 500Mi, got CAPACITY 1Gi: a claim binds to a WHOLE PV, the
smallest one that satisfies it. Binding is 1:1.

==============================================================
STEP 12 - A pod uses the claim; data outlives the pod
==============================================================
pod/pv-demo created
pod/pv-demo condition met
NAME      READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
pv-demo   1/1     Running   0          3s    10.244.2.57   devops-hw-worker   <none>           <none>

No nodeSelector in pv-pod.yaml, yet it landed on devops-hw-worker: the
scheduler honoured the PV's nodeAffinity.

  order #1001 saved at 17:51:58 by pv-demo

deleting the pod...
pod "pv-demo" deleted from s13-volumes namespace
new pod started; reading the file:
  order #1001 saved at 17:51:58 by pv-demo

On the node:
$ docker exec devops-hw-worker cat /tmp/s13-static-pv/orders.txt
  order #1001 saved at 17:51:58 by pv-demo

==============================================================
STEP 13 - Reclaim policy Retain: delete the claim, the PV and data stay
==============================================================
persistentvolumeclaim "s13-static-pvc" deleted from s13-volumes namespace
NAME            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                        STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
s13-static-pv   1Gi        RWO            Retain           Released   s13-volumes/s13-static-pvc   manual         <unset>                          18s

  still on the node: order #1001 saved at 17:51:58 by pv-demo

STATUS Released: the data is kept, but the PV still remembers its old claim
(spec.claimRef), so no new claim can bind it until an admin cleans up.
  claimRef -> s13-volumes/s13-static-pvc

==============================================================
STEP 14 - StorageClass: the recipe for creating volumes on demand
==============================================================
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  19d

  provisioner      : rancher.io/local-path
  reclaimPolicy    : Delete
  volumeBindingMode: WaitForFirstConsumer
  default class    : true

==============================================================
STEP 15 - Dynamic provisioning: a claim, and no PV yet
==============================================================
persistentvolumeclaim/s13-dynamic-pvc created
NAME              STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
s13-dynamic-pvc   Pending                                      standard       <unset>                 4s

REASON                 MESSAGE
WaitForFirstConsumer   waiting for first consumer to be created before binding

Pending is CORRECT here. WaitForFirstConsumer delays creating the volume until
a pod needs it, so the volume is made on the node the pod is scheduled to.

==============================================================
STEP 16 - The first consumer arrives, the provisioner creates the PV
==============================================================
pod/dynamic-demo created
pod/dynamic-demo condition met
NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
s13-dynamic-pvc   Bound    pvc-0e31a6df-2f06-4b91-b40b-45008e6762b0   200Mi      RWO            standard       <unset>                 9s

NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                         STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-0e31a6df-2f06-4b91-b40b-45008e6762b0   200Mi      RWO            Delete           Bound    s13-volumes/s13-dynamic-pvc   standard       <unset>                          3s

  pod node : devops-hw-worker
  PV path  : /var/local-path-provisioner/pvc-0e31a6df-2f06-4b91-b40b-45008e6762b0_s13-volumes_s13-dynamic-pvc
  PV node  : devops-hw-worker

$ docker exec devops-hw-worker ls -la /var/local-path-provisioner/pvc-0e31a6df-2f06-4b91-b40b-45008e6762b0_s13-volumes_s13-dynamic-pvc
  total 12
  drwxrwxrwx 2 root root 4096 Oct  7 17:52 .
  drwxr-xr-x 3 root root 4096 Oct  7 17:52 ..
  -rw-r--r-- 1 root root   31 Oct  7 17:52 hello.txt

Nobody wrote a PV. The provisioner (local-path, in namespace local-path-storage)
saw the claim, made a directory on devops-hw-worker and created PV pvc-0e31a6df-2f06-4b91-b40b-45008e6762b0.

==============================================================
STEP 17 - Data survives the pod; reclaim policy Delete removes it with the claim
==============================================================
after deleting and re-creating the pod:
  provisioned for me at 17:52:19

now deleting the pod AND the claim...
persistentvolumeclaim "s13-dynamic-pvc" deleted from s13-volumes namespace
  Error from server (NotFound): persistentvolumes "pvc-0e31a6df-2f06-4b91-b40b-45008e6762b0" not found
  ls: cannot access '/var/local-path-provisioner/pvc-0e31a6df-2f06-4b91-b40b-45008e6762b0_s13-volumes_s13-dynamic-pvc': No such file or directory

reclaimPolicy: Delete (the default for dynamic classes) - the PV object AND
the data on the node are gone. Great for scratch environments, dangerous for
a production database.

==============================================================
STEP 18 - My own StorageClass with reclaimPolicy: Retain
==============================================================
storageclass.storage.k8s.io/s13-local-retain created
persistentvolumeclaim/s13-retain-pvc created
pod/retain-demo created
NAME               PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
s13-local-retain   rancher.io/local-path   Retain          WaitForFirstConsumer   false                  6s

NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                        STORAGECLASS       VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-9946c663-e0a7-4a84-9722-7bfa7a8b2a28   100Mi      RWO            Retain           Bound    s13-volumes/s13-retain-pvc   s13-local-retain   <unset>                          3s

==============================================================
STEP 19 - Delete the claim: the PV is Released, the data stays
==============================================================
persistentvolumeclaim "s13-retain-pvc" deleted from s13-volumes namespace
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                        STORAGECLASS       VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-9946c663-e0a7-4a84-9722-7bfa7a8b2a28   100Mi      RWO            Retain           Released   s13-volumes/s13-retain-pvc   s13-local-retain   <unset>                          8s

$ docker exec devops-hw-worker cat /var/local-path-provisioner/pvc-9946c663-e0a7-4a84-9722-7bfa7a8b2a28_s13-volumes_s13-retain-pvc/keep.txt
  important data

Same provisioner as 'standard', different policy, different outcome. This is
what you want for anything you cannot afford to lose by a mistyped delete.

==============================================================
STEP 20 - Cleaning up a retained volume on purpose
==============================================================
Switching the Released PV to Delete hands it back to the provisioner:
persistentvolume/pvc-9946c663-e0a7-4a84-9722-7bfa7a8b2a28 patched
  Error from server (NotFound): persistentvolumes "pvc-9946c663-e0a7-4a84-9722-7bfa7a8b2a28" not found
  ls: cannot access '/var/local-path-provisioner/pvc-9946c663-e0a7-4a84-9722-7bfa7a8b2a28_s13-volumes_s13-retain-pvc': No such file or directory

==============================================================
STEP 21 - Access modes are enforced by the storage: RWX on local-path
==============================================================
persistentvolumeclaim/s13-rwx-pvc created
pod/rwx-demo created
NAME          STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
s13-rwx-pvc   Pending                                      standard       <unset>                 0s
NAME       READY   STATUS    RESTARTS   AGE
rwx-demo   0/1     Pending   0          0s

REASON               MESSAGE
ProvisioningFailed   failed to provision volume with StorageClass "standard": NodePath only supports ReadWriteOnce and ReadWriteOncePod (1.22+) access modes

The pod stays Pending forever. A node-local directory cannot be mounted
read-write by pods on several nodes; RWX needs NFS, CephFS, EFS, Azure Files...

==============================================================
DONE
==============================================================
```
