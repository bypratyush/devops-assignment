# FQDN and Service DNS - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
SETUP - namespaces s11-dns and s11-dns-other
==============================================================
namespace/s11-dns created
namespace/s11-dns-other created
deployment.apps/backend created
service/backend created
service/peer created
statefulset.apps/peer created
deployment.apps/payments created
service/payments created
pod/dns-client created
Waiting for deployment "backend" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "backend" rollout to finish: 1 of 2 updated replicas are available...
deployment "backend" successfully rolled out
Waiting for 2 pods to be ready...
Waiting for 1 pods to be ready...
Waiting for 1 pods to be ready...
partitioned roll out complete: 2 new pods have been updated...
deployment "payments" successfully rolled out
pod/dns-client condition met

==============================================================
1. The cluster domain and the DNS server every pod is given
==============================================================
kubelet config (kube-system/kubelet-config):
  clusterDNS:
  - 10.96.0.10
  clusterDomain: cluster.local

NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   20d

  Every FQDN in this cluster ends in .cluster.local, and every pod is told to
  ask 10.96.0.10 - the ClusterIP of the kube-dns Service (CoreDNS pods behind it).

==============================================================
2. Inside the pod: /etc/resolv.conf
==============================================================
  search s11-dns.svc.cluster.local svc.cluster.local cluster.local
  nameserver 10.96.0.10
  options ndots:5

  search  : suffixes tried, in order, for names that are not 'qualified enough'
  ndots:5 : a name with FEWER than 5 dots goes through the search list FIRST

==============================================================
3. Service DNS: the same Service, five spellings
==============================================================
  backend ClusterIP (from the API) = 10.96.74.37

  backend                                  -> 10.96.74.37 
  backend.s11-dns                          -> 10.96.74.37 
  backend.s11-dns.svc                      -> 10.96.74.37 
  backend.s11-dns.svc.cluster.local        -> 10.96.74.37 
  backend.s11-dns.svc.cluster.local.       -> 10.96.74.37 

  All five reach the same A record. Pattern: <service>.<namespace>.svc.<cluster-domain>

==============================================================
4. What the resolver ACTUALLY sends for each spelling (search list + ndots:5)
==============================================================

--- backend ---
    backend.s11-dns.svc.cluster.local.                             NOERROR

--- backend.s11-dns ---
    backend.s11-dns.s11-dns.svc.cluster.local.                     NXDOMAIN
    backend.s11-dns.svc.cluster.local.                             NOERROR

--- backend.s11-dns.svc.cluster.local ---
    backend.s11-dns.svc.cluster.local.s11-dns.svc.cluster.local.   NXDOMAIN
    backend.s11-dns.svc.cluster.local.svc.cluster.local.           NXDOMAIN
    backend.s11-dns.svc.cluster.local.cluster.local.               NXDOMAIN
    backend.s11-dns.svc.cluster.local.                             NOERROR

--- backend.s11-dns.svc.cluster.local. ---
    backend.s11-dns.svc.cluster.local.                             NOERROR

  'backend' matched on the FIRST search suffix: one query.
  The full name WITHOUT the trailing dot has only 4 dots, so it is still treated
  as relative: three NXDOMAIN round-trips before the absolute name is tried.
  WITH the trailing dot it is absolute: exactly one query.

==============================================================
5. The ndots cost for EXTERNAL names
==============================================================

--- example.com   (1 dot < 5) ---
    example.com.s11-dns.svc.cluster.local.                         NXDOMAIN
    example.com.svc.cluster.local.                                 NXDOMAIN
    example.com.cluster.local.                                     NXDOMAIN
    example.com.                                                   NOERROR

--- example.com.  (trailing dot) ---
    example.com.                                                   NOERROR

  Every external hostname an app calls costs 3 wasted queries to CoreDNS first.
  Fixes: a trailing dot in config, or dnsConfig.options ndots: "2" on the pod.

==============================================================
6. Namespace-based DNS: crossing namespaces
==============================================================
  payments lives in namespace s11-dns-other (ClusterIP 10.96.17.253); the client is in s11-dns.

  payments                                 -> <NXDOMAIN - no answer>
  payments.s11-dns-other                   -> 10.96.17.253 
  payments.s11-dns-other.svc.cluster.local -> 10.96.17.253 
  backend.default.svc.cluster.local        -> <NXDOMAIN - no answer>

--- the search list explains it ---
    payments.s11-dns.svc.cluster.local.                            NXDOMAIN
    payments.svc.cluster.local.                                    NXDOMAIN
    payments.cluster.local.                                        NXDOMAIN
    payments.                                                      NXDOMAIN

  The short name only ever expands inside the CLIENT's own namespace. Across
  namespaces you need at least <service>.<namespace>.

==============================================================
7. Pod-to-Service communication (curl container, same pod)
==============================================================
  http://backend                                -> HTTP 200 via 10.96.74.37
  http://backend.s11-dns                        -> HTTP 200 via 10.96.74.37
  http://backend.s11-dns.svc.cluster.local      -> HTTP 200 via 10.96.74.37
  http://10.96.74.37                            -> HTTP 200 via 10.96.74.37
  http://payments                               -> HTTP 000 via (curl exit 6)
  http://payments.s11-dns-other                 -> HTTP 200 via 10.96.17.253

  'http://payments' fails at the DNS step (curl exit 6, HTTP 000): the name is
  looked up as payments.s11-dns.svc.cluster.local, which does not exist.

==============================================================
8. Headless Service: one A record per pod, plus per-pod names
==============================================================
  peer-0   10.244.1.206
  peer-1   10.244.2.241

  peer.s11-dns.svc.cluster.local           -> 10.244.1.206 10.244.2.241 
  peer-0.peer.s11-dns.svc.cluster.local    -> 10.244.1.206
  peer-1.peer.s11-dns.svc.cluster.local    -> 10.244.2.241

  Pattern: <pod>.<headless-service>.<namespace>.svc.cluster.local

==============================================================
9. SRV records: the PORT is in DNS too (named ports only)
==============================================================
$ dig +short SRV _http._tcp.backend.s11-dns.svc.cluster.local
  0 100 80 backend.s11-dns.svc.cluster.local.
$ dig +short SRV _http._tcp.peer.s11-dns.svc.cluster.local
  0 50 80 peer-0.peer.s11-dns.svc.cluster.local.
  0 50 80 peer-1.peer.s11-dns.svc.cluster.local.

  Format: priority weight PORT target. For the headless Service there is one
  SRV per pod, pointing at its per-pod name.

==============================================================
10. Pod A records and reverse lookups
==============================================================
  10-244-1-205.s11-dns.pod.cluster.local        -> 10.244.1.205
  dig -x 10.96.74.37 (the ClusterIP)            -> backend.s11-dns.svc.cluster.local.
  dig -x 10.244.1.205 (a backend pod)           -> 10-244-1-205.backend.s11-dns.svc.cluster.local. 

  <ip-with-dashes>.<namespace>.pod.cluster.local exists for every pod ('pods
  insecure' in the Corefile answers it for any IP). Reverse lookups map the
  ClusterIP back to the Service name, and a pod that backs a Service back to
  <ip-with-dashes>.<service>.<namespace>.svc.cluster.local.

==============================================================
DONE
==============================================================
```
