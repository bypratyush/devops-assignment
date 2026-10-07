# ErrImagePull - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Deploy the broken manifest
==============================================================
deployment.apps/storefront created

==============================================================
STEP 2 - IDENTIFY: watch the pod's first 45 seconds
==============================================================
23:22:52  NAME                          READY   STATUS              RESTARTS   AGE
23:22:52  storefront-6bccdb6547-87g4d   0/1     ContainerCreating   0          0s
23:22:52  storefront-6bccdb6547-87g4d   0/1     ContainerCreating   0          0s
23:22:54  storefront-6bccdb6547-87g4d   0/1     ErrImagePull        0          2s
23:23:06  storefront-6bccdb6547-87g4d   0/1     ImagePullBackOff    0          14s
23:23:20  storefront-6bccdb6547-87g4d   0/1     ErrImagePull        0          28s
23:23:31  storefront-6bccdb6547-87g4d   0/1     ImagePullBackOff    0          39s

Two statuses take turns:
  ErrImagePull     - a pull was just ATTEMPTED and FAILED
  ImagePullBackOff - the kubelet is WAITING before the next attempt
Same problem, two phases of the retry loop. The container never starts,
so there are no logs to read (try it below).

==============================================================
STEP 3 - INVESTIGATE: logs are empty, describe has the answer
==============================================================
$ kubectl -n s14-issues logs storefront-6bccdb6547-87g4d
Error from server (BadRequest): container "web" in pod "storefront-6bccdb6547-87g4d" is waiting to start: trying and failing to pull image

$ kubectl -n s14-issues describe pod storefront-6bccdb6547-87g4d   (Containers + Events)
    Image:          mirror.gcr.io/library/nginx:1.27-alpne
    State:          Waiting
      Reason:       ImagePullBackOff
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  46s                default-scheduler  Successfully assigned s14-issues/storefront-6bccdb6547-87g4d to devops-hw-worker
  Normal   BackOff    18s (x2 over 44s)  kubelet            spec.containers{web}: Back-off pulling image "mirror.gcr.io/library/nginx:1.27-alpne"
  Warning  Failed     18s (x2 over 44s)  kubelet            spec.containers{web}: Error: ImagePullBackOff
  Normal   Pulling    7s (x3 over 46s)   kubelet            spec.containers{web}: Pulling image "mirror.gcr.io/library/nginx:1.27-alpne"
  Warning  Failed     7s (x3 over 45s)   kubelet            spec.containers{web}: Failed to pull image "mirror.gcr.io/library/nginx:1.27-alpne": rpc error: code = NotFound desc = failed to pull and unpack image "mirror.gcr.io/library/nginx:1.27-alpne": failed to resolve reference "mirror.gcr.io/library/nginx:1.27-alpne": mirror.gcr.io/library/nginx:1.27-alpne: not found
  Warning  Failed     7s (x3 over 45s)   kubelet            spec.containers{web}: Error: ErrImagePull

--- the waiting reason and message straight from status (jsonpath) ---
ImagePullBackOff
Back-off pulling image "mirror.gcr.io/library/nginx:1.27-alpne": ErrImagePull: rpc error: code = NotFound desc
 = failed to pull and unpack image "mirror.gcr.io/library/nginx:1.27-alpne": failed to resolve reference "mirr
or.gcr.io/library/nginx:1.27-alpne": mirror.gcr.io/library/nginx:1.27-alpne: not found

==============================================================
STEP 4 - INVESTIGATE: ask the registry directly, from outside Kubernetes
==============================================================
A manifest HEAD request is what the kubelet does first. 200 = tag exists.
  HEAD mirror.gcr.io/v2/library/nginx/manifests/1.27-alpne   -> 404
  HEAD mirror.gcr.io/v2/library/nginx/manifests/1.27-alpine  -> 200

The repository is fine and reachable (no auth error, no timeout); only the
tag is wrong. That narrows it to a typo, not networking or credentials.

==============================================================
STEP 5 - ROOT CAUSE
==============================================================
The Deployment asks for nginx:1.27-alpne (typo). The registry answers
404 / 'not found', the kubelet reports ErrImagePull, then backs off
(ImagePullBackOff) and retries forever with growing delays.

==============================================================
STEP 6 - FIX: correct the tag
==============================================================
$ kubectl diff -f fixed.yaml
  -      - image: mirror.gcr.io/library/nginx:1.27-alpne
  +      - image: mirror.gcr.io/library/nginx:1.27-alpine

deployment.apps/storefront configured
Waiting for deployment "storefront" rollout to finish: 0 out of 1 new replicas have been updated...
Waiting for deployment "storefront" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "storefront" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "storefront" rollout to finish: 1 old replicas are pending termination...
deployment "storefront" successfully rolled out

==============================================================
STEP 7 - VERIFY
==============================================================
NAME                         READY   STATUS    RESTARTS   AGE   IP            NODE                NOMINATED NODE   READINESS GATES
storefront-d9796b66d-tmwqq   1/1     Running   0          5s    10.244.1.61   devops-hw-worker2   <none>           <none>

--- the pull events for the new pod ---
Pulling     Pulling image "mirror.gcr.io/library/nginx:1.27-alpine"
Pulled      Successfully pulled image "mirror.gcr.io/library/nginx:1.27-alpine" in 1.229s (1.229s including waiting). Image size: 21832241 b
Created     Container created
Started     Container started

$ kubectl -n s14-issues exec storefront-d9796b66d-tmwqq -- curl -s -o /dev/null -w '%{http_code}' http://localhost/
HTTP 200

==============================================================
DONE
==============================================================
```
