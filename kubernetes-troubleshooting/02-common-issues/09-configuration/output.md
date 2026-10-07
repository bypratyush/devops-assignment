# Configuration issues - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Deploy the broken manifests
==============================================================
configmap/notifier-config created
deployment.apps/notifier created
deployment.apps/web-gateway created

==============================================================
STEP 2 - IDENTIFY: watch the first 40 seconds
==============================================================
23:43:51  NAME                           READY   STATUS    RESTARTS   AGE
23:43:51  notifier-7ff998c45c-d7v57      0/1     Pending   0          0s
23:43:51  web-gateway-7df6c7dc7c-5xmx9   0/1     Pending   0          0s
23:43:51  notifier-7ff998c45c-d7v57      0/1     ContainerCreating   0          0s
23:43:51  web-gateway-7df6c7dc7c-5xmx9   0/1     ContainerCreating   0          0s
23:43:52  web-gateway-7df6c7dc7c-5xmx9   0/1     ContainerCreating   0          1s
23:43:52  notifier-7ff998c45c-d7v57      0/1     ContainerCreating   0          1s
23:43:53  web-gateway-7df6c7dc7c-5xmx9   0/1     RunContainerError   0          2s
23:43:53  notifier-7ff998c45c-d7v57      0/1     CreateContainerConfigError   0          2s
23:43:54  web-gateway-7df6c7dc7c-5xmx9   0/1     RunContainerError            1 (1s ago)   3s
23:44:08  web-gateway-7df6c7dc7c-5xmx9   0/1     CrashLoopBackOff             1 (15s ago)   17s
23:44:09  web-gateway-7df6c7dc7c-5xmx9   0/1     RunContainerError            2 (1s ago)    18s

Two statuses that are NOT CrashLoopBackOff at first:
  CreateContainerConfigError - the kubelet could not even BUILD the
                               container's config (env, mounts)
  StartError / RunContainerError - the container was created but the
                               runtime could not START its process

==============================================================
STEP 3 - INVESTIGATE notifier: CreateContainerConfigError
==============================================================
$ kubectl -n s14-issues logs notifier-7ff998c45c-d7v57
Error from server (BadRequest): container "notifier" in pod "notifier-7ff998c45c-d7v57" is waiting to start: CreateContainerConfigError

$ kubectl -n s14-issues describe pod notifier-7ff998c45c-d7v57
    State:          Waiting
      Reason:       CreateContainerConfigError
    Environment:
      SMTP_HOST:  <set to the key 'SMTP_HOST' of config map 'notifier-config'>  Optional: false
      SMTP_PORT:  <set to the key 'smtp_port' of config map 'notifier-config'>  Optional: false
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Warning  Failed     12s (x4 over 40s)  kubelet            spec.containers{notifier}: Error: couldn't find key SMTP_HOST in ConfigMap s14-issues/notifier-config

--- what keys does the ConfigMap really have? ---
$ kubectl -n s14-issues get configmap notifier-config -o jsonpath='{.data}'
  {"smtp_host":"mail.internal.example","smtp_port":"587"}

==============================================================
STEP 4 - INVESTIGATE web-gateway: the process cannot start
==============================================================
$ kubectl -n s14-issues logs web-gateway-7df6c7dc7c-5xmx9

$ kubectl -n s14-issues describe pod web-gateway-7df6c7dc7c-5xmx9
    Command:
      /app/start.sh
    State:          Waiting
      Reason:       RunContainerError
    Last State:     Terminated
      Reason:       StartError
      Message:      failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "/app/start.sh": stat /app/start.sh: no such file or directory
      Exit Code:    128
      Started:      Thu, 01 Jan 1970 05:30:00 +0530
      Finished:     Wed, 07 Oct 2026 23:44:08 +0530
    Ready:          False
    Restart Count:  2
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Warning  Failed     25s (x3 over 40s)  kubelet            spec.containers{gateway}: Error: failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container 
  Warning  BackOff    24s (x2 over 39s)  kubelet            spec.containers{gateway}: Back-off restarting failed container gateway in pod web-gateway-7df6c7dc7c-5xmx9_s14-issues(c05c42e1-b975-40f8-a89b-ab172da91e26)

--- is that file in the image at all? (a throwaway pod of the same image) ---
$ kubectl -n s14-issues run probe-nginx --image=nginx:1.27-alpine --restart=Never --command -- ls -l /app/start.sh /docker-entrypoint.sh
  ls: /app/start.sh: No such file or directory
  -rwxr-xr-x    1 root     root          1620 Apr 16  2025 /docker-entrypoint.sh

==============================================================
STEP 5 - ROOT CAUSE
==============================================================
notifier    : configMapKeyRef asks for key SMTP_HOST; the ConfigMap has
              smtp_host. Keys are case-sensitive, so the kubelet refuses
              to create the container (no partial env).
web-gateway : command: [/app/start.sh] replaces the image's ENTRYPOINT.
              That file does not exist in nginx:1.27-alpine, so runc
              fails the exec (exit 128) on every start.

==============================================================
STEP 6 - FIX
==============================================================
$ kubectl diff -f fixed.yaml
  -              key: SMTP_HOST
  +              key: smtp_host
  -      - command:
  -        - /app/start.sh
  -        image: nginx:1.27-alpine
  +      - image: nginx:1.27-alpine

configmap/notifier-config unchanged
deployment.apps/notifier configured
deployment.apps/web-gateway configured
Waiting for deployment spec update to be observed...
Waiting for deployment "notifier" rollout to finish: 0 out of 1 new replicas have been updated...
Waiting for deployment "notifier" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "notifier" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "notifier" rollout to finish: 1 old replicas are pending termination...
deployment "notifier" successfully rolled out
deployment "web-gateway" successfully rolled out

==============================================================
STEP 7 - VERIFY
==============================================================
$ kubectl -n s14-issues get pods -l issue=config -o wide
NAME                          READY   STATUS    RESTARTS   AGE   IP             NODE                NOMINATED NODE   READINESS GATES
notifier-5b6bc7f845-ptsqd     1/1     Running   0          13s   10.244.1.211   devops-hw-worker2   <none>           <none>
web-gateway-5975c7dbd-6nqlx   1/1     Running   0          13s   10.244.1.212   devops-hw-worker2   <none>           <none>

$ kubectl -n s14-issues logs deploy/notifier
notifier using mail.internal.example:587

$ kubectl -n s14-issues exec deploy/notifier -- env | grep SMTP
SMTP_HOST=mail.internal.example
SMTP_PORT=587

$ kubectl -n s14-issues exec deploy/web-gateway -- curl -s -o /dev/null -w '%{http_code}' http://localhost/
HTTP 200

==============================================================
DONE
==============================================================
```
