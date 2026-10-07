# Observability - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Start shop + inventory (OpenTelemetry), Jaeger and Prometheus
==============================================================
 Container observability-demo-jaeger-1 Created 
 Container observability-demo-prometheus-1 Created 
 Container observability-demo-inventory-1 Created 
 Container observability-demo-shop-1 Created 
 Container observability-demo-prometheus-1 Started 
 Container observability-demo-jaeger-1 Started 
 Container observability-demo-inventory-1 Started 
 Container observability-demo-shop-1 Started 

SERVICE      IMAGE                                   STATUS          PORTS
inventory    s20-otel-demo:1.0                       Up 16 seconds   8000/tcp
jaeger       jaegertracing/jaeger:2.22.0             Up 18 seconds   26686->16686/tcp
prometheus   quay.io/prometheus/prometheus:v3.15.0   Up 18 seconds   29190->9090/tcp
shop         s20-otel-demo:1.0                       Up 11 seconds   18020->8000/tcp

services Jaeger has received spans from:
  inventory
  shop
  jaeger

==============================================================
STEP 2 - A SLOW request: GET /checkout?item=gpu
==============================================================
The client only sees that the call was slow. Monitoring would tell us latency went up.
Observability has to tell us WHERE the time went - follow the trace_id.

$ curl 'http://localhost:18020/checkout?item=gpu'
{"item":"gpu","price":54999,"reservation":"R-69771","trace_id":"431e91f8a54724561ee91a1fb624e39c"}
  (HTTP 200, 1.045267s)

--- LOGS: every line from both services that carries trace_id=431e91f8a54724561ee91a1fb624e39c ---
{"service":"inventory","level":"INFO","msg":"reserve requested","trace_id":"431e91f8a54724561ee91a1fb624e39c","span_id":"71058bf67ca9bbf5","item":"gpu","traceparent":"00-431e91f8a54724561ee91a1fb624e39c-5a89656192852011-03"}
{"service":"inventory","level":"INFO","msg":"reserved","trace_id":"431e91f8a54724561ee91a1fb624e39c","span_id":"71058bf67ca9bbf5","item":"gpu","remaining":1}
{"service":"shop","level":"INFO","msg":"checkout started","trace_id":"431e91f8a54724561ee91a1fb624e39c","span_id":"8f7af089c4f39302","item":"gpu"}
{"service":"shop","level":"INFO","msg":"checkout complete","trace_id":"431e91f8a54724561ee91a1fb624e39c","span_id":"8f7af089c4f39302","item":"gpu","price":54999}

--- TRACE: GET http://localhost:26686/api/traces/431e91f8a54724561ee91a1fb624e39c  (span tree, [start offset, duration]) ---
  shop: GET /checkout  [+0ms, 997ms]  
    shop: price.calculate  [+38ms, 16ms]  
    shop: GET  [+97ms, 877ms]  
      inventory: GET /reserve/<item>  [+145ms, 795ms]  
        inventory: db.query  [+191ms, 626ms]  db.statement=SELECT qty FROM stock WHERE sku = $1 FOR UPDATE

--- METRICS: Prometheus exemplars that point at this trace ---
  demo_request_duration_seconds_bucket{service="inventory", route="/reserve", status="200", le="1.0"}  exemplar value=0.6592474170029163s  trace_id=431e91f8a54724561ee91a1fb624e39c
  demo_request_duration_seconds_bucket{service="shop", route="/checkout", status="200", le="1.0"}  exemplar value=0.9614459580043331s  trace_id=431e91f8a54724561ee91a1fb624e39c

--- the raw OpenMetrics text the shop exposes (exemplar after the '#') ---
demo_request_duration_seconds_bucket{le="1.0",route="/checkout",service="shop",status="200"} 2.0 # {trace_id="431e91f8a54724561ee91a1fb624e39c"} 0.9614459580043331 1791397563.805896
  logs-with-trace-id.png  (188K)
  jaeger-api-trace.png  (164K)
  prometheus-exemplar.png  (172K)
  jaeger-trace-slow.png (headless Chrome)

==============================================================
STEP 3 - A FAILING request: GET /checkout?item=unicorn
==============================================================
$ curl 'http://localhost:18020/checkout?item=unicorn'
{"error":"could not reserve item","item":"unicorn","trace_id":"8036c53e6da949ed8ef3f7fd568d39da"}
  (HTTP 502, 0.456834s)

--- LOGS: every line from both services that carries trace_id=8036c53e6da949ed8ef3f7fd568d39da ---
{"service":"inventory","level":"INFO","msg":"reserve requested","trace_id":"8036c53e6da949ed8ef3f7fd568d39da","span_id":"d4504a723c4e37e4","item":"unicorn","traceparent":"00-8036c53e6da949ed8ef3f7fd568d39da-87b2a6e59d751d65-03"}
{"service":"inventory","level":"ERROR","msg":"out of stock","trace_id":"8036c53e6da949ed8ef3f7fd568d39da","span_id":"d4504a723c4e37e4","item":"unicorn"}
{"service":"shop","level":"INFO","msg":"checkout started","trace_id":"8036c53e6da949ed8ef3f7fd568d39da","span_id":"f7108c97335ae2a0","item":"unicorn"}
{"service":"shop","level":"ERROR","msg":"checkout failed","trace_id":"8036c53e6da949ed8ef3f7fd568d39da","span_id":"f7108c97335ae2a0","item":"unicorn","inventory_status":409,"reason":"out of stock"}

--- TRACE: GET http://localhost:26686/api/traces/8036c53e6da949ed8ef3f7fd568d39da  (span tree, [start offset, duration]) ---
  shop: GET /checkout  [+0ms, 372ms]  otel.status_code=ERROR error=true
    shop: price.calculate  [+96ms, 16ms]  
    shop: GET  [+143ms, 213ms]  otel.status_code=ERROR error=true
      inventory: GET /reserve/<item>  [+249ms, 100ms]  otel.status_code=ERROR error=true
        inventory: db.query  [+320ms, 17ms]  db.statement=SELECT qty FROM stock WHERE sku = $1 FOR UPDATE

--- METRICS: Prometheus exemplars that point at this trace ---
  demo_request_duration_seconds_bucket{service="inventory", route="/reserve", status="409", le="0.05"}  exemplar value=0.0326781669864431s  trace_id=8036c53e6da949ed8ef3f7fd568d39da
  demo_request_duration_seconds_bucket{service="shop", route="/checkout", status="502", le="0.5"}  exemplar value=0.28220766701269895s  trace_id=8036c53e6da949ed8ef3f7fd568d39da

--- Jaeger search (API v3): traces of service 'shop' with error=true in the last 15 minutes ---
  trace_id=8036c53e6da949ed8ef3f7fd568d39da  root span=GET /checkout  status=ERROR
  jaeger-trace-error.png (headless Chrome)

==============================================================
STEP 4 - Some normal traffic, then the metric view of the same story
==============================================================
request count by service/status (from the histogram's _count):
  inventory  /reserve   200  65
  shop       /checkout  200  65
  inventory  /reserve   409  1
  shop       /checkout  502  1

p95 latency per service over the last 2 minutes:
  shop       675ms
  inventory  594ms

The metric says p95 is high. It cannot say why - but the exemplar on the slow
bucket hands us a trace_id, and the trace shows db.query on 'gpu' taking ~600ms.

--- SUMMARY: one trace_id, three signals ---
  slow request    trace_id=431e91f8a54724561ee91a1fb624e39c
    in logs:      4 lines
    in Jaeger:    5 spans
    in metrics:   2 exemplars
  failed request  trace_id=8036c53e6da949ed8ef3f7fd568d39da
    in logs:      4 lines (2 at ERROR)
    in Jaeger:    5 spans, error=true

==============================================================
STEP 5 - The same signals on Kubernetes (read-only look at the kind cluster)
==============================================================
cAdvisor is built into every kubelet - per-container CPU/memory, the raw source of most k8s metrics:
$ kubectl get --raw /api/v1/nodes/devops-hw-worker/proxy/metrics/cadvisor | grep container_memory_working_set_bytes | head -3
container_memory_working_set_bytes{container="",id="/kubelet.slice/kubelet-kubepods.slice/kubelet-kubepods-besteffort.slice/kubelet-kubepods-besteffort-pod965450cb_a307_418f_9349_5a715e85cdd3.slice",image="",name="",namespace="kub
container_memory_working_set_bytes{container="",id="/kubelet.slice/kubelet-kubepods.slice/kubelet-kubepods-besteffort.slice/kubelet-kubepods-besteffort-pod965450cb_a307_418f_9349_5a715e85cdd3.slice/cri-containerd-89840abab34d053f9
container_memory_working_set_bytes{container="",id="/kubelet.slice/kubelet-kubepods.slice/kubelet-kubepods-burstable.slice/kubelet-kubepods-burstable-podb15d8c96_12da_479d_8b9f_b569fbda4d2d.slice",image="",name="",namespace="kube-

The kubelet's summarised resource endpoint - this is what metrics-server scrapes:
$ kubectl get --raw /api/v1/nodes/devops-hw-worker/proxy/metrics/resource | grep ^node_
node_cpu_usage_seconds_total 11904.988821 1791397605798
node_memory_working_set_bytes 1.005961216e+09 1791397605798

metrics-server aggregates that into the Metrics API (what kubectl top and the HPA read):
NAME                      CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
devops-hw-control-plane   3525m        23%      1710Mi          21%         
devops-hw-worker          1493m        9%       959Mi           12%         
devops-hw-worker2         1794m        11%      832Mi           10%         

  apiservice v1beta1.metrics.k8s.io  service=kube-system/metrics-server  available=True

Container logs live as files on each node; a DaemonSet log agent tails exactly these paths:
  /var/log/pods/kube-system_kindnet-xd667_b15d8c96-12da-479d-8b9f-b569fbda4d2d/
  /var/log/pods/kube-system_kube-proxy-tqnkd_965450cb-a307-418f-9349-5a715e85cdd3/
  /var/log/pods/kube-system_metrics-server-84c99cb944-vqmln_eee2e162-68d5-4acd-a11c-72c2322cf1c0/
  k8s-metrics-sources.png  (148K)

==============================================================
CLEANUP - docker compose down -v
==============================================================
 Container observability-demo-jaeger-1 Removed 
 Network observability-demo_default Removing 
 Network observability-demo_default Removed 
```
