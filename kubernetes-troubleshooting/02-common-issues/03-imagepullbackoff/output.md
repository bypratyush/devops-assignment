# ImagePullBackOff - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Deploy the broken manifest
==============================================================
deployment.apps/orders-api created

==============================================================
STEP 2 - IDENTIFY: watch it for 100 seconds - note the GAPS growing
==============================================================
23:23:45  NAME                          READY   STATUS              RESTARTS   AGE
23:23:45  orders-api-554b44b7ff-2kzk5   0/1     ContainerCreating   0          0s
23:23:45  orders-api-554b44b7ff-2kzk5   0/1     ContainerCreating   0          0s
23:23:48  orders-api-554b44b7ff-2kzk5   0/1     ErrImagePull        0          3s
23:23:59  orders-api-554b44b7ff-2kzk5   0/1     ImagePullBackOff    0          14s
23:24:15  orders-api-554b44b7ff-2kzk5   0/1     ErrImagePull        0          30s
23:24:29  orders-api-554b44b7ff-2kzk5   0/1     ImagePullBackOff    0          44s
23:24:49  orders-api-554b44b7ff-2kzk5   0/1     ErrImagePull        0          64s
23:25:01  orders-api-554b44b7ff-2kzk5   0/1     ImagePullBackOff    0          76s

Each ErrImagePull line is one real pull attempt. The time between them
grows (kubelet back-off doubles each time, capped at 5 minutes), which
is why a fixed registry problem can take minutes to 'heal' on its own.

==============================================================
STEP 3 - INVESTIGATE: the Events, with retry counts
==============================================================
$ kubectl -n s14-issues describe pod orders-api-554b44b7ff-2kzk5
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  101s                default-scheduler  Successfully assigned s14-issues/orders-api-554b44b7ff-2kzk5 to devops-hw-worker2
  Normal   BackOff    25s (x4 over 98s)   kubelet            spec.containers{api}: Back-off pulling image "ghcr.io/devops-hw-private/orders-api:1.0"
  Warning  Failed     25s (x4 over 98s)   kubelet            spec.containers{api}: Error: ImagePullBackOff
  Normal   Pulling    12s (x4 over 101s)  kubelet            spec.containers{api}: Pulling image "ghcr.io/devops-hw-private/orders-api:1.0"
  Warning  Failed     12s (x4 over 98s)   kubelet            spec.containers{api}: Failed to pull image "ghcr.io/devops-hw-private/orders-api:1.0": failed to pull and unpack image "ghcr.io/devops-hw-private/orders-api:1.0": failed to resolve reference "ghcr.io/devops-hw-private/orders-api:1.0": failed to authorize: failed to fetch anonymous token: unexpected status from GET request to https://ghcr.io/token?scope=repository%3Adevops-hw-private%2Forders-api%3Apull&service=ghcr.io: 403 Forbidden
  Warning  Failed     12s (x4 over 98s)   kubelet            spec.containers{api}: Error: ErrImagePull

The message is what separates the causes of an image pull failure:
  'not found'                      -> wrong name or tag (see 02-errimagepull)
  '401 Unauthorized' / '403' / 'denied' -> private repo, no or wrong credentials
  '429 Too Many Requests'          -> registry rate limit (hit for real, see README)
  'i/o timeout' / 'no such host'   -> node cannot reach or resolve the registry
Here it is 403 Forbidden while fetching an ANONYMOUS token: no credentials
were even offered.

--- is any pull secret configured? (pod spec, then the service account) ---
$ kubectl -n s14-issues get pod orders-api-554b44b7ff-2kzk5 -o jsonpath='{.spec.imagePullSecrets}'
  ''
$ kubectl -n s14-issues get serviceaccount default -o jsonpath='{.imagePullSecrets}'
  ''
Both empty - the kubelet pulls anonymously.

--- reproduce the registry's answer from the laptop ---
$ curl 'https://ghcr.io/token?scope=repository:devops-hw-private/orders-api:pull&service=ghcr.io'
  {"errors":[{"code":"DENIED","message":"requested access to the resource is denied"}]}

  HTTP 403
Same 403 outside Kubernetes, so this is not a node or CNI problem.

==============================================================
STEP 4 - ROOT CAUSE
==============================================================
The image reference points at a GHCR repository that is not public, and
the pod has no imagePullSecret. Every attempt is refused, the kubelet
backs off, and the pod sits in ImagePullBackOff forever.

==============================================================
STEP 5 - FIX: use the image that is actually published
==============================================================
$ kubectl diff -f fixed.yaml
  -      - image: ghcr.io/devops-hw-private/orders-api:1.0
  +      - image: nginxdemos/nginx-hello:plain-text

deployment.apps/orders-api configured
Waiting for deployment "orders-api" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "orders-api" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "orders-api" rollout to finish: 1 old replicas are pending termination...
deployment "orders-api" successfully rolled out

(If the image really is private, the fix is credentials instead:
   kubectl -n s14-issues create secret docker-registry ghcr-pull \
     --docker-server=ghcr.io --docker-username=<user> --docker-password=<PAT>
 and 'imagePullSecrets: [{name: ghcr-pull}]' in the pod spec.)

==============================================================
STEP 6 - VERIFY
==============================================================
NAME                          READY   STATUS    RESTARTS   AGE   IP            NODE               NOMINATED NODE   READINESS GATES
orders-api-7c6bcb8899-q4wxm   1/1     Running   0          4s    10.244.2.91   devops-hw-worker   <none>           <none>

Pulled      Container image "nginxdemos/nginx-hello:plain-text" already present on machine and can be accessed by the pod
Started     Container started

$ kubectl -n s14-issues exec orders-api-7c6bcb8899-q4wxm -- wget -qO- http://localhost:8080/
Server address: ::1:8080
Server name: orders-api-7c6bcb8899-q4wxm
Date: 07/Oct/2026:17:55:32 +0000
URI: /

==============================================================
DONE
==============================================================
```
