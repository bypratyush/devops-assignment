# Monitoring - Prometheus and Grafana in the cluster

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

| File | What it is |
|---|---|
| [kube-prometheus-stack-values.yaml](kube-prometheus-stack-values.yaml) | Helm values for `prometheus-community/kube-prometheus-stack` 92.1.0, trimmed for a laptop |
| [lostfound-alerts.yaml](lostfound-alerts.yaml) | `PrometheusRule`: backend down / database down / 5xx ratio / slow p95 |
| [lostfound-dashboard.yaml](lostfound-dashboard.yaml) | Grafana dashboard as a ConfigMap (the sidecar loads anything labelled `grafana_dashboard`) |
| [lostfound-dashboard.json](lostfound-dashboard.json) | The same dashboard as plain JSON, for importing by hand |
| [../helm/lostfound/templates/servicemonitor.yaml](../helm/lostfound/templates/servicemonitor.yaml) | Ships with the app: tells Prometheus to scrape the backend's `/metrics` |

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack --version 92.1.0 \
  -n monitoring --create-namespace -f kube-prometheus-stack-values.yaml --wait
kubectl apply -f lostfound-alerts.yaml -f lostfound-dashboard.yaml
kubectl -n monitoring port-forward svc/monitoring-grafana 13000:80                      # Grafana
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 19090:9090 # Prometheus
```

```text
NAME                                                   READY   STATUS    RESTARTS   AGE
monitoring-grafana-5bd569fdc7-hwpjv                    3/3     Running   0          2m7s
monitoring-kube-prometheus-operator-7896b4bf77-9p8wb   1/1     Running   0          2m7s
monitoring-kube-state-metrics-5dfd8797f7-7cvfj         1/1     Running   0          2m7s
prometheus-monitoring-kube-prometheus-prometheus-0     2/2     Running   0          119s
```

Trimmed on purpose: Alertmanager, node-exporter and the etcd / scheduler /
controller-manager / kube-proxy scrapes are off. On kind those control-plane
components listen on 127.0.0.1 inside the node container, so their targets would
only ever be DOWN. Alert rules still evaluate and show on Prometheus' `/alerts`.

## How the app gets scraped

The backend exposes Prometheus metrics at `/metrics` (see
[application/backend/app/observability.py](../application/backend/app/observability.py)):

| Metric | Type | Labels |
|---|---|---|
| `lostfound_http_requests_total` | counter | method, route, status |
| `lostfound_http_request_duration_seconds` | histogram | method, route |
| `lostfound_items_reported_total` | counter | kind |
| `lostfound_db_up` | gauge | - |

`route` is the route **template** (`/api/items/{item_id}`), not the raw path,
otherwise every item id would become a new time series.

The chain is: the chart's `ServiceMonitor` (label `release: monitoring`) ->
the Prometheus Operator, whose `serviceMonitorSelector` is
`{"matchLabels":{"release":"monitoring"}}` -> a scrape job per backend pod:

```text
$ curl -s 'http://localhost:19090/api/v1/targets?state=active' | ...
  serviceMonitor/lostfound/lostfound-backend/0            up
  serviceMonitor/lostfound/lostfound-backend/0            up
```

![Prometheus targets](../screenshots/prometheus-targets.png)

## The dashboard

Six headline numbers (pods up, database, request rate, 5xx ratio, p95 latency,
items reported) over requests by route/status, latency p50/p95 by route, CPU and
memory per pod (kubelet cAdvisor), and HPA current/desired/available replicas
(kube-state-metrics). Captured while [scripts/traffic.sh](../scripts/traffic.sh)
ran 4 workers through the Ingress:

![Grafana dashboard](../screenshots/grafana-lostfound-dashboard.png)

What it shows: ~75 req/s, p95 under 10 ms, and the HPA panel jumping from 2 to 6
backend replicas under that load (the CPU target is 60% of a 100m request). The
"Backend pods UP = 9" is a real artefact, not a typo: the screenshot was taken
mid-rollout, and the terminated pods' `up` series were still inside Prometheus'
lookback window.

## Alerts

| Alert | Expression (short) | for |
|---|---|---|
| LostFoundBackendDown | `sum(up{...}) == 0 or absent(up{...})` | 1m |
| LostFoundDatabaseDown | `max(lostfound_db_up) == 0` | 30s |
| LostFoundHighErrorRate | 5xx / all > 5% | 1m |
| LostFoundSlowRequests | p95 > 500 ms | 2m |

`LostFoundBackendDown` fired for real during fault 2 of the
[troubleshooting challenge](../troubleshooting/README.md), and fault 3 is about
what it takes to notice that Prometheus has stopped scraping something.

## Notes from running this

- A stat panel built from `sum(rate(x{status=~"5.."}[2m])) / ...` shows **No data**
  when there have been no 5xx at all, because the numerator is an empty vector,
  not zero. `(... or vector(0))` fixes it.
- Grafana's anonymous Viewer role is enabled in the values so dashboards can be
  rendered by headless Chrome for screenshots. Fine on a laptop, not on a shared
  cluster.
- `absent()` only helps once the old series have actually gone. See fault 3.
