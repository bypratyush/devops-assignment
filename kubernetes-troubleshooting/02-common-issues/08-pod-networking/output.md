# Pod networking (NetworkPolicy) - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Deploy the broken manifests
==============================================================
deployment.apps/ledger created
service/ledger created
networkpolicy.networking.k8s.io/ledger-lockdown created
networkpolicy.networking.k8s.io/ledger-allow-billing created
pod/billing created
pod/intruder created
Waiting for deployment "ledger" rollout to finish: 0 of 1 updated replicas are available...
deployment "ledger" successfully rolled out

==============================================================
STEP 2 - IDENTIFY: billing, the ONE client that should work, cannot
==============================================================
$ kubectl -n s14-issues get pods -l issue=netpol -o wide
NAME                      READY   STATUS    RESTARTS   AGE   IP             NODE                NOMINATED NODE   READINESS GATES
billing                   1/1     Running   0          14s   10.244.1.192   devops-hw-worker2   <none>           <none>
intruder                  1/1     Running   0          14s   10.244.1.193   devops-hw-worker2   <none>           <none>
ledger-588b87f7d7-lsn8q   1/1     Running   0          15s   10.244.1.191   devops-hw-worker2   <none>           <none>

$ kubectl -n s14-issues exec billing -- curl -sS -m 4 http://ledger
curl: (28) Connection timed out after 4017 milliseconds
HTTP 000 in 4.027563s
command terminated with exit code 28

Exit code 28 after the full 4s: a TIMEOUT. Nothing answered - not even
a refusal. Refused = something said no; timeout = packets vanished.

==============================================================
STEP 3 - INVESTIGATE: rule out the app and the Service
==============================================================
--- is the app itself up? (from inside its own pod) ---
$ kubectl -n s14-issues exec ledger-588b87f7d7-lsn8q -- wget -qO- http://localhost:8080/
Server address: ::1:8080
Server name: ledger-588b87f7d7-lsn8q

--- does the Service have endpoints? ---
$ kubectl -n s14-issues get endpointslices -l kubernetes.io/service-name=ledger
NAME           ADDRESSTYPE   PORTS   ENDPOINTS      AGE
ledger-8lrc5   IPv4          8080    10.244.1.191   41s

--- bypass the Service: straight to the pod IP ---
$ kubectl -n s14-issues exec billing -- curl -sS -m 4 http://10.244.1.191:8080
curl: (28) Connection timed out after 4807 milliseconds
HTTP 000 in 4.882423s
command terminated with exit code 28

App fine, endpoints fine, and the pod IP times out too. kube-proxy is
not involved any more, so something on the path to the POD is dropping
packets. In Kubernetes that means a NetworkPolicy.

==============================================================
STEP 4 - INVESTIGATE: which policies select the ledger pod?
==============================================================
$ kubectl -n s14-issues get networkpolicy
NAME                   POD-SELECTOR   AGE
ledger-allow-billing   app=ledger     54s
ledger-lockdown        app=ledger     55s

$ kubectl -n s14-issues describe networkpolicy ledger-allow-billing
Spec:
  PodSelector:     app=ledger
  Allowing ingress traffic:
    To Port: 80/TCP
    From:
      PodSelector: app=billing
  Not affecting egress traffic
  Policy Types: Ingress

billing matches 'From: PodSelector app=billing' - so why is it dropped?
Compare the allowed port with the port the pod really receives on:

$ kubectl -n s14-issues get svc ledger -o jsonpath='port={.spec.ports[0].port} targetPort={.spec.ports[0].targetPort}'
  port=80 targetPort=http
$ kubectl -n s14-issues get pod ledger-588b87f7d7-lsn8q -o jsonpath='{.spec.containers[0].ports}'
  [{"containerPort":8080,"name":"http","protocol":"TCP"}]

==============================================================
STEP 5 - ROOT CAUSE
==============================================================
The allow rule opens TCP 80, which is the SERVICE port. By the time the
packet reaches the ledger pod, kube-proxy has DNAT-ed it to the pod's
8080, and the policy is evaluated against 8080. Nothing allows 8080, the
lockdown policy applies, and the packet is dropped without a reply.

==============================================================
STEP 6 - FIX: allow the pod port (by name)
==============================================================
$ kubectl diff -f fixed.yaml
  -    - port: 80
  +    - port: http

deployment.apps/ledger unchanged
service/ledger unchanged
networkpolicy.networking.k8s.io/ledger-lockdown unchanged
networkpolicy.networking.k8s.io/ledger-allow-billing configured
pod/billing unchanged
pod/intruder unchanged

==============================================================
STEP 7 - VERIFY: billing gets in, everybody else still does not
==============================================================
billing  -> ledger (first good answer): HTTP 200

$ kubectl -n s14-issues exec billing -- curl -sS -m 4 http://ledger
HTTP 200 in 0.088833s
$ kubectl -n s14-issues exec billing -- curl -sS -m 4 http://10.244.1.191:8080
HTTP 200 in 0.129747s

$ kubectl -n s14-issues exec intruder -- curl -sS -m 4 http://ledger
HTTP 000 in 4.002701s
curl: (28) Connection timed out after 4002 milliseconds
command terminated with exit code 28

billing now works through the Service and by pod IP, while intruder is
still dropped: the policy is fixed, not removed.

==============================================================
DONE
==============================================================
```
