# Monitoring - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07.

```text

==============================================================
STEP 1 - Validate config BEFORE starting anything (promtool / amtool)
==============================================================
Checking /etc/prometheus/prometheus.yml
  SUCCESS: 1 rule files found
 SUCCESS: /etc/prometheus/prometheus.yml is valid prometheus config file syntax

Checking /etc/prometheus/alert-rules.yml
  SUCCESS: 8 rules found


--- unit tests for the alert rules (fake series in, expected alerts out) ---
  SUCCESS

--- Alertmanager routing config ---
Checking '/a/alertmanager.yml'  SUCCESS
Found:
 - global config
 - route
 - 1 inhibit rules
 - 1 receivers
 - 0 templates

  promtool-checks.png  (96K)

==============================================================
STEP 2 - Start the stack (app, Prometheus, Alertmanager, Grafana, exporters, Loki, Alloy)
==============================================================
 Container monitoring-demo-alertmanager-1 Started 
 Container monitoring-demo-node-exporter-1 Started 
 Container monitoring-demo-app-1 Started 
 Container monitoring-demo-alert-receiver-1 Starting 
 Container monitoring-demo-cadvisor-1 Started 
 Container monitoring-demo-prometheus-1 Started 
 Container monitoring-demo-loki-1 Started 
 Container monitoring-demo-grafana-1 Starting 
 Container monitoring-demo-alloy-1 Starting 
 Container monitoring-demo-alert-receiver-1 Started 
 Container monitoring-demo-alloy-1 Started 
 Container monitoring-demo-grafana-1 Started 

waiting for every Prometheus target to be UP ...

==============================================================
STEP 3 - What is running
==============================================================
SERVICE             IMAGE                                          STATUS                            PORTS
alert-receiver      s20-orders-api:1.0                             Up 4 seconds                      8000/tcp
alertmanager        quay.io/prometheus/alertmanager:v0.34.1        Up 4 seconds                      19193->9093/tcp
alloy               grafana/alloy:v1.20.1                          Up 3 seconds                      
app                 s20-orders-api:1.0                             Up 4 seconds (health: starting)   18010->8000/tcp
blackbox-exporter   quay.io/prometheus/blackbox-exporter:v0.29.0   Up 4 seconds                      9115/tcp
cadvisor            gcr.io/cadvisor/cadvisor:v0.55.1               Up 4 seconds (health: starting)   8080/tcp
grafana             grafana/grafana:13.2.3                         Up 3 seconds                      13030->3000/tcp
loki                grafana/loki:3.7.8                             Up 4 seconds                      13100->3100/tcp
node-exporter       quay.io/prometheus/node-exporter:v1.12.1       Up 4 seconds                      9100/tcp
prometheus          quay.io/prometheus/prometheus:v3.15.0          Up 4 seconds                      19190->9090/tcp

--- Prometheus scrape targets (GET /api/v1/targets) ---

==============================================================
STEP 4 - The application: health, a normal request, and its /metrics
==============================================================
$ curl http://localhost:18010/health
{"held_memory_mb":0,"service":"orders-api","status":"ok","uptime_s":3,"version":"1.0.0"}

$ curl http://localhost:18010/api/orders
{"orders":[{"id":5809,"status":"shipped"}]}


--- a few lines of http://localhost:18010/metrics (Prometheus text format) ---
process_resident_memory_bytes 4.124672e+07
process_cpu_seconds_total 0.62
app_requests_total{endpoint="/health",method="GET",status="200"} 1.0
app_requests_total{endpoint="/api/orders",method="GET",status="200"} 2.0
# HELP app_request_duration_seconds Time spent serving a request
# TYPE app_request_duration_seconds histogram
app_request_duration_seconds_bucket{endpoint="/api/orders",le="0.05"} 1.0
app_request_duration_seconds_bucket{endpoint="/api/orders",le="0.1"} 1.0
app_request_duration_seconds_bucket{endpoint="/api/orders",le="0.25"} 2.0

==============================================================
STEP 5 - METRICS under load: request rate, p95 latency, error ratio
==============================================================
18:17:39 background load started (~10 req/s, 2% of /api/orders fail by design)

request rate (req/s), by endpoint:
  /health      0.309
  /api/orders  9.108
  /            2.273
p50 latency /api/orders:  0.067s
p95 latency /api/orders:  0.413s
error ratio (5xx / all):  0.012
app process CPU (cores):  0.057
app process RSS (MiB):    39.461
host CPU used (%):        62.478
host memory used (%):     61.257
  promql-under-load.png  (220K)

==============================================================
STEP 6 - CPU UTILISATION: spin one core -> HighCPU goes pending -> firing
==============================================================
before: app CPU = 0.057 cores
$ curl 'http://localhost:18010/stress/cpu?seconds=110'
{"burning_for_s":110}

rule: rate(process_cpu_seconds_total[1m]) > 0.8  for 30s
  18:18:56 UTC  t+  0s  HighCPU            inactive  value=-
  18:19:54 UTC  t+ 58s  HighCPU            pending   value=0.848
  18:20:18 UTC  t+ 82s  HighCPU            inactive  value=-
  gave up after 180s

per-container CPU from cAdvisor (cores):
  monitoring-demo-grafana-1            0.182
  monitoring-demo-loki-1               0.12
  monitoring-demo-alloy-1              0.08
  monitoring-demo-alertmanager-1       0.033
  monitoring-demo-cadvisor-1           0.096
  monitoring-demo-node-exporter-1      0.068
  monitoring-demo-blackbox-exporter-1  0.032
  monitoring-demo-prometheus-1         0.113
  monitoring-demo-app-1                0.151

Alertmanager now holds:
  prometheus-alerts-api-highcpu.png  (48K)

==============================================================
STEP 7 - MEMORY UTILISATION + APPLICATION HEALTH: hold 350 MB
==============================================================
before: RSS = 19.461 MiB
$ curl 'http://localhost:18010/stress/memory?mb=350'
{"held_mb":350}

after:  RSS = 369.461 MiB

the process is still UP, but /health now reports it is not healthy:
$ curl -i http://localhost:18010/health
HTTP/1.1 503 SERVICE UNAVAILABLE
{"held_memory_mb":350,"reason":"holding 350 MB > limit 300 MB","service":"orders-api","status":"degraded","uptime_s":269,"version":"1.0.0"}

  18:22:06 UTC  t+  0s  HighMemory         pending   value=387407872
  18:22:39 UTC  t+ 33s  HighMemory         firing    value=385048576
  18:22:39 UTC  t+  0s  HealthCheckFailing firing    value=0
cAdvisor sees the same thing from the cgroup: container working set = 368.98 MiB
up{job="demo-app"} = 1   probe_success{job="app-health"} = 0

18:22:39 releasing the memory
{"held_mb":0}

  18:22:39 UTC  t+  0s  HighMemory         firing    value=385048576
  18:22:49 UTC  t+ 10s  HighMemory         inactive  value=-
  18:22:49 UTC  t+  0s  HealthCheckFailing inactive  value=-

==============================================================
STEP 8 - ERRORS: raise the failure rate to 30% -> HighErrorRate
==============================================================
{"error_rate":0.3}

  18:22:49 UTC  t+  0s  HighErrorRate      inactive  value=-
  18:23:04 UTC  t+ 15s  HighErrorRate      pending   value=0.066
  18:23:34 UTC  t+ 45s  HighErrorRate      firing    value=0.188
{"error_rate":0.02}

(error rate back to 2%; the alert resolves once the 1m window has rolled past)

==============================================================
STEP 9 - ALERTING END TO END: stop the app -> AppDown pending -> firing -> resolved
==============================================================
18:23:34 $ docker compose stop app
 Container monitoring-demo-app-1 Stopped 
  18:23:37 UTC  t+  0s  AppDown            inactive  value=-
  18:23:44 UTC  t+  7s  AppDown            pending   value=0
  18:24:14 UTC  t+ 37s  AppDown            firing    value=0

Prometheus says (GET /api/v1/alerts):
  AppDown             firing  activeAt=18:23:38
  HealthCheckFailing  firing  activeAt=18:23:38
  HighErrorRate       firing  activeAt=18:22:58

Alertmanager says (GET /api/v2/alerts) - note HealthCheckFailing is SUPPRESSED by the inhibit rule:
  HighErrorRate       severity=critical  state=active      inhibitedBy=0  startsAt=18:23:28
  AppDown             severity=critical  state=active      inhibitedBy=0  startsAt=18:24:08
  HealthCheckFailing  severity=warning   state=suppressed  inhibitedBy=1  startsAt=18:24:08
  alertmanager-api-appdown.png  (116K)
  prometheus-alerts-firing.png (headless Chrome)
  alertmanager-ui-firing.png (headless Chrome)

18:24:43 $ docker compose start app
 Container monitoring-demo-app-1 Started 
  18:24:46 UTC  t+  0s  AppDown            firing    value=0
  18:24:58 UTC  t+ 12s  AppDown            inactive  value=-

--- every notification Alertmanager delivered to the webhook receiver ---
  firing    HealthCheckFailing  warning   started 18:22:33
  firing    HighMemory          warning   started 18:22:33
  resolved  HighMemory          warning   started 18:22:33  ended 18:22:43
  resolved  HealthCheckFailing  warning   started 18:22:33  ended 18:22:43
  firing    HighErrorRate       critical  started 18:23:28
  firing    AppDown             critical  started 18:24:08
  resolved  HighErrorRate       critical  started 18:23:28  ended 18:24:28
  resolved  AppDown             critical  started 18:24:08  ended 18:24:53
  alert-receiver-notifications.png  (452K)

==============================================================
STEP 10 - LOGS: structured JSON on stdout, shipped to Loki by Alloy
==============================================================
$ docker compose logs app --tail 6
{"ts": "2026-10-07T18:25:21.550Z", "level": "INFO", "service": "orders-api", "msg": "request", "method": "GET", "path": "/api/orders", "status": 200, "duration_ms": 95.3, "client": "loadgen"}
{"ts": "2026-10-07T18:25:21.698Z", "level": "INFO", "service": "orders-api", "msg": "request", "method": "GET", "path": "/api/orders", "status": 200, "duration_ms": 250.9, "client": "loadgen"}
{"ts": "2026-10-07T18:25:21.706Z", "level": "INFO", "service": "orders-api", "msg": "request", "method": "GET", "path": "/api/orders", "status": 200, "duration_ms": 250.9, "client": "loadgen"}
{"ts": "2026-10-07T18:25:21.988Z", "level": "INFO", "service": "orders-api", "msg": "request", "method": "GET", "path": "/", "status": 200, "duration_ms": 0.2, "client": "loadgen"}
{"ts": "2026-10-07T18:25:22.010Z", "level": "INFO", "service": "orders-api", "msg": "request", "method": "GET", "path": "/api/orders", "status": 200, "duration_ms": 22.9, "client": "loadgen"}
{"ts": "2026-10-07T18:25:22.042Z", "level": "INFO", "service": "orders-api", "msg": "request", "method": "GET", "path": "/api/orders", "status": 200, "duration_ms": 82.4, "client": "loadgen"}

LogQL: errors in the last 10 minutes, parsed from the JSON body
  sum by (level) (count_over_time({service="app"} | json | status >= 500 [10m]))
  level=ERROR  count=218

LogQL: the WARNING lines (what the stress endpoints and admin calls logged)
  {"ts": "2026-10-07T18:18:56.374Z", "level": "WARNING", "service": "orders-api", "msg": "cpu burn started", "seconds": 110}
  {"ts": "2026-10-07T18:21:59.909Z", "level": "WARNING", "service": "orders-api", "msg": "memory allocated", "added_mb": 350, "held_mb": 350}
  {"ts": "2026-10-07T18:22:49.619Z", "level": "WARNING", "service": "orders-api", "msg": "error rate changed", "error_rate": 0.3}
  {"ts": "2026-10-07T18:23:34.704Z", "level": "WARNING", "service": "orders-api", "msg": "error rate changed", "error_rate": 0.02}

LogQL: p95 and max of duration_ms for /api/orders, computed from the log lines alone
  (json path, duration_ms extracts only those two fields - extracting everything would
   turn every unique ts into its own series)
  p95 duration_ms from logs (exact):       254.64499999999998
  max duration_ms from logs:               2227.6
  p95 from the Prometheus histogram (s):   0.413   (estimated inside the 0.25-0.5 bucket)
  loki-logql.png  (388K)
  app-json-logs.png  (452K)

==============================================================
STEP 11 - Grafana dashboards (provisioned from files) and the Prometheus targets page
==============================================================
Grafana: http://localhost:13030 (anonymous Viewer enabled for this demo; admin/admin)
  dashboard: orders-api - logs (Loki)  uid=orders-api-logs  folder=Session 20
  dashboard: orders-api - service overview  uid=orders-api  folder=Session 20
  datasource Prometheus: OK - Successfully queried the Prometheus API.
  datasource Loki:       OK - Data source successfully connected.
  grafana-dashboard.png (headless Chrome)
  prometheus-targets.png (headless Chrome)
  grafana-logs-dashboard.png (headless Chrome)

==============================================================
STEP 12 - Kubernetes side: kubectl top (Metrics API, served by metrics-server)
==============================================================
$ kubectl top nodes
NAME                      CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
devops-hw-control-plane   2827m        18%      1713Mi          21%         
devops-hw-worker          1871m        12%      954Mi           12%         
devops-hw-worker2         2184m        14%      797Mi           10%         

$ kubectl top pods -n kube-system --sort-by=memory
NAME                                              CPU(cores)   MEMORY(bytes)   
kube-apiserver-devops-hw-control-plane            1322m        869Mi           
kube-controller-manager-devops-hw-control-plane   113m         100Mi           
etcd-devops-hw-control-plane                      199m         85Mi            
kube-scheduler-devops-hw-control-plane            77m          46Mi            
coredns-559f6c778d-djbjl                          36m          36Mi            
metrics-server-84c99cb944-vqmln                   70m          32Mi            
kube-proxy-g5p89                                  43m          30Mi            
  kubectl-top.png  (224K)

==============================================================
CLEANUP - docker compose down -v
==============================================================
 Volume monitoring-demo_prometheus-data Removed 
 Volume monitoring-demo_loki-data Removed 
 Network monitoring-demo_default Removed 
```
