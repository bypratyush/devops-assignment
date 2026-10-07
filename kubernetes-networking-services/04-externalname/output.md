# externalname - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Deploy the ExternalName service and a test client
==============================================================
service/external-database-service created
pod/dns-test-client created
pod/dns-test-client condition met

==============================================================
STEP 2 - What this Service does and does NOT have
==============================================================
NAME                        TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
external-database-service   ExternalName   <none>       example.com   <none>    1s

>>> CLUSTER-IP is <none>.  EXTERNAL-IP is the DNS name.

    externalName: example.com
    type: ExternalName

Compare with every other service type:
  no clusterIP   -> nothing to route to, no virtual IP allocated
  no selector    -> it selects no pods at all
  no ports       -> it does not proxy, so ports are meaningless

==============================================================
STEP 3 - Therefore it has NO endpoints
==============================================================
  No resources found in default namespace.

An empty endpoint list is NORMAL here. For any other service type it
would mean the selector is broken.

==============================================================
STEP 4 - What it actually is: a CNAME served by CoreDNS
==============================================================
$ nslookup external-database-service.default.svc.cluster.local
  Server:		10.96.0.10
  Address:	10.96.0.10:53
  
  external-database-service.default.svc.cluster.local	canonical name = example.com
  
  external-database-service.default.svc.cluster.local	canonical name = example.com
  Name:	example.com
  Address: 104.20.23.154
  Name:	example.com
  Address: 172.66.147.243
  

CoreDNS answers the in-cluster name with a CNAME pointing at the
external hostname, and the resolver then follows it to the real A record.

==============================================================
STEP 5 - Using it, and the Host-header trap you WILL hit
==============================================================
$ curl http://external-database-service/
  HTTP 403

>>> 403, not 200. The DNS worked perfectly - we really did reach the
    external host. What failed is HTTP virtual hosting:

    ExternalName rewrites DNS ONLY. curl still sends
        Host: external-database-service
    because that is the name in the URL. The origin has no vhost by that
    name, so it refuses the request.

Proof - same URL, correct Host header:
$ curl -H 'Host: example.com' http://external-database-service/
  HTTP 200

--- what came back ---
  <!doctype html><html lang=en><head><meta charset=utf-8><link rel=icon href=data:,><meta name=viewport content="width=device-width,initial-scale=1"><title>Example Domain</title><style>html{color-scheme:light dark;background:light-dark(#eee,#222)}body{font:16px/1.6 system-ui,sans-serif;max-width:26em;margin:auto;padding:25vh 2em 2em;text-align:center}</style></head><body><p>This domain is for use in documentation examples without needing permission. This is not a service; avoid relying on it for testing and monitoring purposes.</p><script src=/s.js></script></body></html>

The pod addressed an internal Kubernetes name and the traffic went
straight to the external host - it never passed through kube-proxy or
any virtual IP. ExternalName is DNS, and nothing but DNS.

==============================================================
STEP 6 - Why this is useful: swap the backend without touching the app
==============================================================
The application hardcodes 'external-database-service'. To repoint it from
a managed dev database to a prod one, you edit only the Service:

$ kubectl patch svc external-database-service -p '{"spec":{"externalName":"iana.org"}}'
NAME                        TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
external-database-service   ExternalName   <none>       iana.org      <none>    7s

  external-database-service.default.svc.cluster.local	canonical name = iana.org
  external-database-service.default.svc.cluster.local	canonical name = iana.org
  Name:	iana.org

Same in-cluster name, different external target, zero application changes.
Restoring the original target...
  external-database-service   ExternalName   <none>   example.com   <none>   8s

==============================================================
STEP 7 - The gotchas
==============================================================
1. HTTPS/TLS: the external host serves a certificate for ITS name
   (example.com), not for 'external-database-service'. Verification fails unless the client
   sends the right SNI/Host. This is the #1 ExternalName surprise.
     curl https://external-database-service/ -> exit 000
  command terminated with exit code 35

2. No health checking, no load balancing, no retries - it is only DNS.
3. It cannot point at an IP address, only at a DNS NAME.
   (To front a fixed external IP, use a selector-less Service with a
    manually-created EndpointSlice instead.)
4. Some clients cache DNS forever, so a change may not be picked up.

==============================================================
DONE
==============================================================
```
