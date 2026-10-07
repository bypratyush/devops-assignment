# DNS issues - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Deploy the broken manifests
==============================================================
namespace/s14-shop created
deployment.apps/payments created
service/payments created
deployment.apps/checkout created
deployment.apps/report-mailer created
Waiting for deployment "payments" rollout to finish: 0 of 1 updated replicas are available...
deployment "payments" successfully rolled out
deployment "checkout" successfully rolled out
deployment "report-mailer" successfully rolled out

==============================================================
STEP 2 - IDENTIFY: both apps log failed calls to payments
==============================================================
$ kubectl -n s14-issues get pods -l issue=dns
NAME                             READY   STATUS    RESTARTS   AGE
checkout-5749d55b99-m59xr        1/1     Running   0          18s
report-mailer-79466c5848-md48x   1/1     Running   0          18s

$ kubectl -n s14-issues logs deploy/checkout --tail=2
18:07:38 payments call FAILED - curl: (6) Could not resolve host: payments
18:07:43 payments call FAILED - curl: (6) Could not resolve host: payments

$ kubectl -n s14-issues logs deploy/report-mailer --tail=2
18:07:37 payments call FAILED - curl: (6) Could not resolve host: payments.s14-shop.svc.cluster.local
18:07:43 payments call FAILED - curl: (6) Could not resolve host: payments.s14-shop.svc.cluster.local

Both say 'Could not resolve host' (curl exit 6) - but report-mailer is
already using the FULL name, so the two are probably not the same bug.

==============================================================
STEP 3 - INVESTIGATE: is cluster DNS itself healthy? (read-only checks)
==============================================================
$ kubectl -n kube-system get pods -l k8s-app=kube-dns -o wide
NAME                       READY   STATUS    RESTARTS       AGE   IP           NODE                      NOMINATED NODE   READINESS GATES
coredns-559f6c778d-djbjl   1/1     Running   3 (4d6h ago)   20d   10.244.0.4   devops-hw-control-plane   <none>           <none>
coredns-559f6c778d-kn29k   1/1     Running   3 (4d6h ago)   20d   10.244.0.2   devops-hw-control-plane   <none>           <none>

$ kubectl -n kube-system get svc kube-dns
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   20d

$ kubectl -n s14-issues exec deploy/checkout -- nslookup kubernetes.default
Server:		10.96.0.10
Address:	10.96.0.10:53

CoreDNS is up and answers from the checkout pod. So DNS works - the
NAME 'payments' is the problem for checkout.

==============================================================
STEP 4 - INVESTIGATE checkout: why does 'payments' not resolve?
==============================================================
$ kubectl -n s14-issues exec deploy/checkout -- cat /etc/resolv.conf
search s14-issues.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

$ kubectl -n s14-issues exec deploy/checkout -- nslookup payments
Server:		10.96.0.10
Address:	10.96.0.10:53
** server can't find payments.cluster.local: NXDOMAIN
** server can't find payments.s14-issues.svc.cluster.local: NXDOMAIN
** server can't find payments.svc.cluster.local: NXDOMAIN
** server can't find payments.cluster.local: NXDOMAIN
** server can't find payments.svc.cluster.local: NXDOMAIN
** server can't find payments.s14-issues.svc.cluster.local: NXDOMAIN
command terminated with exit code 1

The resolver tried payments.s14-issues.svc.cluster.local, payments.svc...
and payments.cluster.local - all NXDOMAIN. Where does payments live?

$ kubectl get svc -A --field-selector metadata.name=payments
NAMESPACE   NAME       TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
s14-shop    payments   ClusterIP   10.96.78.63   <none>        8080/TCP   20s

$ kubectl -n s14-issues exec deploy/checkout -- nslookup payments.s14-shop.svc.cluster.local
Address:	10.96.0.10:53
Name:	payments.s14-shop.svc.cluster.local
Address: 10.96.78.63
With the namespace in the name it resolves from the very same pod.

==============================================================
STEP 5 - INVESTIGATE report-mailer: even names that always exist fail
==============================================================
$ kubectl -n s14-issues exec deploy/report-mailer -- nslookup kubernetes.default.svc.cluster.local
Server:		10.96.0.99
Address:	10.96.0.99:53
** server can't find kubernetes.default.svc.cluster.local: NXDOMAIN
** server can't find kubernetes.default.svc.cluster.local: NXDOMAIN
command terminated with exit code 1

kubernetes.default ALWAYS exists, so this is not a naming mistake. Look at
the 'Server:' line: 10.96.0.99, not the kube-dns IP 10.96.0.10 from STEP 3.
And an internet name works from the same pod:

$ kubectl -n s14-issues exec deploy/report-mailer -- nslookup example.com
Server:		10.96.0.99
Name:	example.com
Address: 2606:4700:10::ac42:93f3
Name:	example.com

So SOMETHING answers on 10.96.0.99, but it knows nothing about
cluster.local. It is not a Service in this cluster:

$ kubectl get svc -A -o wide | grep -c 10.96.0.99
0

Ask a documentation-only address (192.0.2.53, TEST-NET-1) that cannot
possibly host a DNS server:
$ kubectl -n s14-issues exec deploy/report-mailer -- nslookup example.com 192.0.2.53
Server:		192.0.2.53
Name:	example.com
Address: 172.66.147.243

It answers too. Docker Desktop intercepts outbound DNS (port 53) to ANY IP
and resolves it with the Mac's own resolver. On a real cluster the same
mistake gives 'connection timed out; no servers could be reached'; here it
gives NXDOMAIN for cluster names - which LOOKS like a naming problem.

--- where does the wrong server come from? ---
$ kubectl -n s14-issues exec deploy/report-mailer -- cat /etc/resolv.conf
search s14-issues.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.99

$ kubectl -n s14-issues get deploy report-mailer -o jsonpath='{.spec.template.spec.dnsPolicy} {.spec.template.spec.dnsConfig}'
  None {"nameservers":["10.96.0.99"],"searches":["s14-issues.svc.cluster.local","svc.cluster.local","cluster.local"]}

Ask the RIGHT server explicitly, from the same pod:
$ kubectl -n s14-issues exec deploy/report-mailer -- nslookup payments.s14-shop.svc.cluster.local 10.96.0.10
Server:		10.96.0.10
Address:	10.96.0.10:53
Name:	payments.s14-shop.svc.cluster.local
Address: 10.96.78.63

==============================================================
STEP 6 - ROOT CAUSE
==============================================================
checkout      : 'payments' is a short name. The search list only expands it
                inside the pod's OWN namespace (s14-issues); the Service is
                in s14-shop. Cross-namespace calls need <svc>.<namespace>.
report-mailer : dnsPolicy None + a hand-written nameserver (10.96.0.99)
                that is not CoreDNS. Its queries never reach the cluster's
                DNS, so no cluster name can resolve, short or full.

==============================================================
STEP 7 - FIX
==============================================================
$ kubectl diff -f fixed.yaml
  -          value: http://payments:8080
  +          value: http://payments.s14-shop:8080
  -      dnsConfig:
  -        nameservers:
  -        - 10.96.0.99
  -        searches:
  -        - s14-issues.svc.cluster.local
  -        - svc.cluster.local
  -        - cluster.local
  -      dnsPolicy: None
  +      dnsPolicy: ClusterFirst

namespace/s14-shop unchanged
deployment.apps/payments unchanged
service/payments unchanged
deployment.apps/checkout configured
deployment.apps/report-mailer configured
Waiting for deployment "checkout" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "checkout" rollout to finish: 1 old replicas are pending termination...
deployment "checkout" successfully rolled out
deployment "report-mailer" successfully rolled out

==============================================================
STEP 8 - VERIFY
==============================================================
$ kubectl -n s14-issues get pods -l issue=dns
NAME                            READY   STATUS    RESTARTS   AGE
checkout-7b74dcfbbb-2xsb7       1/1     Running   0          46s
report-mailer-d8ddd8f64-mdn5c   1/1     Running   0          46s

$ kubectl -n s14-issues logs deploy/checkout --tail=2
18:08:38 payments OK - Server name: payments-bd95bfd4-dvbmr
18:08:43 payments OK - Server name: payments-bd95bfd4-dvbmr

$ kubectl -n s14-issues logs deploy/report-mailer --tail=2
18:08:38 payments OK - Server name: payments-bd95bfd4-dvbmr
18:08:43 payments OK - Server name: payments-bd95bfd4-dvbmr

$ kubectl -n s14-issues exec deploy/report-mailer -- cat /etc/resolv.conf
search s14-issues.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

==============================================================
DONE
==============================================================
```
