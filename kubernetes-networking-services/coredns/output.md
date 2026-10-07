# CoreDNS - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
SETUP - namespaces s11-coredns and s11-coredns-probe
==============================================================
namespace/s11-coredns created
namespace/s11-coredns-probe created
deployment.apps/hello created
service/hello created
pod/dns-client created
pod/dns-probe created
Waiting for deployment "hello" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "hello" rollout to finish: 1 of 2 updated replicas are available...
deployment "hello" successfully rolled out
pod/dns-client condition met
pod/dns-probe condition met

==============================================================
1. What CoreDNS is, in this cluster
==============================================================
NAME      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                                    SELECTOR
coredns   2/2     2            2           20d   coredns      registry.k8s.io/coredns/coredns:v1.14.6   k8s-app=kube-dns

NAME                       READY   STATUS    RESTARTS       AGE   IP           NODE                      NOMINATED NODE   READINESS GATES
coredns-559f6c778d-djbjl   1/1     Running   3 (4d7h ago)   20d   10.244.0.4   devops-hw-control-plane   <none>           <none>
coredns-559f6c778d-kn29k   1/1     Running   3 (4d7h ago)   20d   10.244.0.2   devops-hw-control-plane   <none>           <none>

  image     : registry.k8s.io/coredns/coredns:v1.14.6
  args      : ["-conf","/etc/coredns/Corefile"]
  dnsPolicy : Default   <- CoreDNS itself uses the NODE's resolver

NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE   SELECTOR
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   20d   k8s-app=kube-dns

NAME             ADDRESSTYPE   PORTS        ENDPOINTS               AGE
kube-dns-z4wq9   IPv4          53,53,9153   10.244.0.4,10.244.0.2   20d

  The Service is still called 'kube-dns' (the pre-CoreDNS name) so nothing that
  points at it had to change. Its ClusterIP is the nameserver of every pod.

==============================================================
2. The configuration: the Corefile (kube-system/configmap coredns)
==============================================================
.:53 {
    errors
    health {
       lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf {
       max_concurrent 1000
    }
    cache 30 {
       disable success cluster.local
       disable denial cluster.local
    }
    loop
    reload
    loadbalance
}

  saved a copy of the original (420 bytes) - it gets restored after step 6

==============================================================
3. Every pod is pointed at CoreDNS
==============================================================
$ kubectl exec dns-client -- cat /etc/resolv.conf
  search s11-coredns.svc.cluster.local svc.cluster.local cluster.local
  nameserver 10.96.0.10
  options ndots:5

  nameserver = 10.96.0.10 = the kube-dns ClusterIP = kubelet --cluster-dns

  kubernetes.default.svc.cluster.local       -> 10.96.0.1
  kube-dns.kube-system.svc.cluster.local     -> 10.96.0.10
  hello.s11-coredns.svc.cluster.local        -> 10.96.45.128

==============================================================
4. Service discovery: CoreDNS learns about Services from the API, live
==============================================================
CoreDNS's RBAC - it only ever lists and watches:
  [""] ["endpoints","services","pods","namespaces"] ["list","watch"]
  ["discovery.k8s.io"] ["endpointslices"] ["list","watch"]

$ kubectl create service clusterip late-svc --tcp=80:80   (and query it immediately)
  late-svc.s11-coredns.svc.cluster.local -> 10.96.127.44   (resolvable within ~1s, API ClusterIP 10.96.127.44)
$ kubectl delete service late-svc
  late-svc.s11-coredns.svc.cluster.local -> status NXDOMAIN

  No restart, no zone file. The kubernetes plugin keeps an in-memory view of
  Services/EndpointSlices from its watch and answers straight from it.

==============================================================
5. How a query is resolved, hop by hop
==============================================================

--- a) cluster name: answered by CoreDNS itself (flag 'aa' = authoritative) ---
  ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 20061
  ;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
  ; EDNS: version: 0, flags:; udp: 4096
  ;hello.s11-coredns.svc.cluster.local. IN	A
  hello.s11-coredns.svc.cluster.local. 30	IN A	10.96.45.128
  ;; SERVER: 10.96.0.10#53(10.96.0.10)

--- b) 10.96.0.10 is a VIP: kube-proxy DNATs it to the CoreDNS pods (iptables on devops-hw-worker) ---
  -A KUBE-SEP-WXWGHGKZOCNYRYI7 -p udp -m comment --comment "kube-system/kube-dns:dns" -m udp -j DNAT --to-destination 10.244.0.4:53
  -A KUBE-SEP-YIL6JZP7A3QYXJU2 -p udp -m comment --comment "kube-system/kube-dns:dns" -m udp -j DNAT --to-destination 10.244.0.2:53
  -A KUBE-SERVICES -d 10.96.0.10/32 -p udp -m comment --comment "kube-system/kube-dns:dns cluster IP" -m udp --dport 53 -j KUBE-SVC-TCOU7JCQXEZGVUNU
  -A KUBE-SVC-TCOU7JCQXEZGVUNU ! -s 10.244.0.0/16 -d 10.96.0.10/32 -p udp -m comment --comment "kube-system/kube-dns:dns cluster IP" -m udp --dport 53 -j KUBE-MARK-MASQ
  -A KUBE-SVC-TCOU7JCQXEZGVUNU -m comment --comment "kube-system/kube-dns:dns -> 10.244.0.2:53" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-YIL6JZP7A3QYXJU2
  -A KUBE-SVC-TCOU7JCQXEZGVUNU -m comment --comment "kube-system/kube-dns:dns -> 10.244.0.4:53" -j KUBE-SEP-WXWGHGKZOCNYRYI7

--- c) ask one CoreDNS pod directly, bypassing the VIP ---
  @10.244.0.4 -> 10.96.45.128

--- d) external name: not in cluster.local, so the forward plugin sends it upstream ---
  ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 31408
  ;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1
  ; EDNS: version: 0, flags:; udp: 4096
  example.com.		30	IN	A	172.66.147.243
  example.com.		30	IN	A	104.20.23.154
  (no 'aa' flag: CoreDNS is not authoritative, it relayed the answer)

  upstream = /etc/resolv.conf of the CoreDNS pod = the node's resolv.conf (dnsPolicy Default):
    nameserver 192.168.65.254
    options ndots:0
  192.168.65.254 is Docker Desktop's resolver, which forwards to macOS.

--- e) the search list belongs to the CLIENT, not to CoreDNS ---
  dig hello          -> status NXDOMAIN   (dig does not apply 'search' unless told to)
  dig +search hello  -> 10.96.45.128
  nslookup hello     -> 10.96.45.128   (system resolver applies 'search')

==============================================================
6. Watching real queries: temporarily enabling the 'log' plugin
==============================================================
Change (only this one line is added):
  2a3
  >     log
configmap/coredns patched
waiting for the reload plugin (checks every 30s) and the configmap volume sync...
  all 2 CoreDNS pods reloaded after ~85s

--- the client (pod IP 10.244.1.33) makes three lookups ---
  nslookup hello ; nslookup example.com ; dig payments.does-not-exist.svc.cluster.local

--- what CoreDNS logged for that pod IP (both CoreDNS pods, merged) ---
  coredns-559f6c778d-djbjl [INFO] 10.244.1.33:54479 - 11548 "A IN example.com. udp 29 false 512" NOERROR qr,rd,ra 83 0.014450166s
  coredns-559f6c778d-djbjl [INFO] 10.244.1.33:48719 - 16033 "A IN payments.does-not-exist.svc.cluster.local. udp 70 false 4096" NXDOMAIN qr,aa,rd 152 0.000692125s
  coredns-559f6c778d-kn29k [INFO] 10.244.1.33:58165 - 57772 "A IN hello.s11-coredns.svc.cluster.local. udp 53 false 512" NOERROR qr,aa,rd 104 0.000626791s
  coredns-559f6c778d-kn29k [INFO] 10.244.1.33:53238 - 62831 "A IN example.com.s11-coredns.svc.cluster.local. udp 59 false 512" NXDOMAIN qr,aa,rd 152 0.010255459s
  coredns-559f6c778d-kn29k [INFO] 10.244.1.33:35095 - 3940 "A IN example.com.svc.cluster.local. udp 47 false 512" NXDOMAIN qr,aa,rd 140 0.000729084s
  coredns-559f6c778d-kn29k [INFO] 10.244.1.33:54810 - 57094 "A IN example.com.cluster.local. udp 43 false 512" NXDOMAIN qr,aa,rd 136 0.00024825s

  Each line: client ip:port - id "TYPE CLASS NAME proto size do bufsize" RCODE flags size duration
  'hello'       -> one query, answered from the first search suffix (aa = authoritative).
  'example.com' -> 3 NXDOMAINs from the search list first (ndots:5); the real name has
                   no 'aa' and is much slower because it went upstream.
  The does-not-exist name is answered NXDOMAIN by CoreDNS itself, without going upstream.

==============================================================
7. Troubleshooting scenario 1 - DNS suddenly 'down' in one namespace
==============================================================
Someone applies a namespace-wide 'lock it down' egress policy:
networkpolicy.networking.k8s.io/default-deny-egress created

--- SYMPTOM: the app cannot reach its backend ---
  curl http://hello -> HTTP 000 (curl exit 6)

--- STEP 1 - is it DNS? (nslookup from the pod) ---
  ;; connection timed out; no servers could be reached
  
  command terminated with exit code 1

--- STEP 2 - is CoreDNS itself healthy? ---
NAME                       READY   STATUS    RESTARTS       AGE
coredns-559f6c778d-djbjl   1/1     Running   3 (4d7h ago)   20d
coredns-559f6c778d-kn29k   1/1     Running   3 (4d7h ago)   20d
NAME             ADDRESSTYPE   PORTS        ENDPOINTS               AGE
kube-dns-z4wq9   IPv4          53,53,9153   10.244.0.4,10.244.0.2   20d

--- STEP 3 - does DNS work from ANOTHER namespace? ---
  [s11-coredns-probe] Name:	hello.s11-coredns.svc.cluster.local
  [s11-coredns-probe] Address: 10.96.45.128
  -> CoreDNS is fine; the problem is local to s11-coredns.

--- STEP 4 - is the pod's resolver config right? ---
  search s11-coredns.svc.cluster.local svc.cluster.local cluster.local
  nameserver 10.96.0.10
  options ndots:5
  -> correct nameserver and search list.

--- STEP 5 - skip the VIP: ask a CoreDNS pod IP directly ---
  ;; connection timed out; no servers could be reached
  -> even the pod IP times out, so it is not kube-proxy. Packets are dropped.

--- STEP 6 - did the queries even arrive? CoreDNS log for 10.244.1.33 during this test ---
  log lines from 10.244.1.33 since the policy was applied: 0   -> nothing reached CoreDNS

--- STEP 7 - what filters traffic in this namespace? ---
NAME                  POD-SELECTOR   AGE
default-deny-egress   <none>         16s

  Spec:
    PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
    Not affecting ingress traffic
    Allowing egress traffic:
      <none> (Selected pods are isolated for egress connectivity)
    Policy Types: Egress

ROOT CAUSE: default-deny-egress selects every pod and allows no egress. DNS to
kube-system on port 53 is egress too, so every lookup is dropped at the pod.

--- FIX 1 - allow DNS to the CoreDNS pods ---
networkpolicy.networking.k8s.io/allow-dns-egress created
  Name:	hello.s11-coredns.svc.cluster.local
  Address: 10.96.45.128
  curl http://hello -> HTTP 000 (curl exit 28)
  -> DNS works now, but curl still fails (exit 28 = timeout): the deny also
     blocks the client -> hello traffic itself.

--- FIX 2 - allow the client to reach the app ---
networkpolicy.networking.k8s.io/allow-client-to-hello created
  curl http://hello -> HTTP 200 via 10.96.45.128
NAME                    POD-SELECTOR     AGE
allow-client-to-hello   app=dns-client   6s
allow-dns-egress        <none>           21s
default-deny-egress     <none>           37s

==============================================================
8. Troubleshooting scenario 2 - one pod with a hand-written resolver config
==============================================================
pod/custom-dns created

--- SYMPTOM ---
  ;; connection timed out; no servers could be reached
  
  command terminated with exit code 1

--- INVESTIGATE: resolv.conf vs the kube-dns Service ---
  search s11-coredns.svc.cluster.local
  nameserver 10.96.0.100
  options ndots:2
  kube-dns ClusterIP: 10.96.0.10
  pod dnsPolicy     : None

ROOT CAUSE: dnsPolicy None + a typo'd nameserver (10.96.0.100). Nothing listens
there. (The NetworkPolicies from scenario 1 still apply to this pod and would
allow DNS to CoreDNS - the address is simply wrong.)

--- FIX: ClusterFirst + only the option that was wanted (dnsPolicy is immutable, so recreate) ---
pod "custom-dns" deleted from s11-coredns namespace
pod/custom-dns created
  search s11-coredns.svc.cluster.local svc.cluster.local cluster.local
  nameserver 10.96.0.10
  options ndots:2
  Name:	hello.s11-coredns.svc.cluster.local
  Address: 10.96.45.128

==============================================================
9. CoreDNS metrics (prometheus plugin, :9153) - the numbers behind the logs
==============================================================
  (read through the API server's pod proxy, so no NetworkPolicy is involved)
  coredns-559f6c778d-djbjl:
    coredns_dns_responses_total{plugin="errors",rcode="NOERROR",server="dns://:53",view="",zone="."} 201448
    coredns_dns_responses_total{plugin="errors",rcode="NXDOMAIN",server="dns://:53",view="",zone="."} 1267
  coredns-559f6c778d-kn29k:
    coredns_dns_responses_total{plugin="errors",rcode="NOERROR",server="dns://:53",view="",zone="."} 200349
    coredns_dns_responses_total{plugin="errors",rcode="NXDOMAIN",server="dns://:53",view="",zone="."} 1340

  A rising SERVFAIL count points at upstream/forwarding trouble; a high NXDOMAIN
  share is usually just ndots:5 search-list noise, as seen in step 6.

==============================================================
10. Restore the original Corefile and prove it is identical
==============================================================
  restoring the original Corefile...
  all 2 CoreDNS pods reloaded after ~60s
  Corefile now identical to the saved original - 'log' removed.
  [s11-coredns-probe] Name:	kubernetes.default.svc.cluster.local
  [s11-coredns-probe] Address: 10.96.0.1

==============================================================
DONE
==============================================================
```
