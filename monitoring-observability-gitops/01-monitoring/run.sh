#!/usr/bin/env bash
# Task 1 - Monitoring: metrics, logs, alerts, CPU, memory and application health.
#
# Usage: ./run.sh [check|up|demo|down|all]     (default: all)
#   check  validate the Prometheus config, alert rules (+ unit tests) and Alertmanager config
#   up     build the app and start the whole stack, wait until every target is UP
#   demo   load, CPU spike, memory spike, error burst, app outage - each alert is
#          watched going inactive -> pending -> firing -> resolved
#   down   docker compose down -v
# SHOTS=0 skips the screenshots.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
now() { date -u '+%H:%M:%S'; }      # UTC, same clock as the Prometheus/Alertmanager APIs

APP=http://localhost:18010
PROM=http://localhost:19190
AM=http://localhost:19193
GRAFANA=http://localhost:13030
LOKI=http://localhost:13100
PROMIMG=quay.io/prometheus/prometheus:v3.15.0
AMIMG=quay.io/prometheus/alertmanager:v0.34.1
SHOT=../../lab/shot.sh
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SHOTS=${SHOTS:-1}

# instant PromQL query -> "value" (first series) or every series with a label
q()  { curl -s -G "$PROM/api/v1/query" --data-urlencode "query=$1" | jq -r '.data.result[0].value[1] // "no data" | tonumber? // . | if type == "number" then (. * 1000 | round / 1000) else . end'; }
qby(){ curl -s -G "$PROM/api/v1/query" --data-urlencode "query=$1" | jq -r --arg l "$2" '.data.result[] | "  \(.metric[$l] // "-")\t\(.value[1] | tonumber * 1000 | round / 1000)"' | column -t -s $'\t'; }

# poll Prometheus' own view of an alert and print every state change until it
# reaches the wanted state (inactive -> pending -> firing, or back to inactive)
watch_alert() {   # name  wanted-state  timeout-s
  local name=$1 want=$2 timeout=${3:-240} start=$SECONDS last="" st val
  while :; do
    read -r st val < <(curl -s "$PROM/api/v1/alerts" | jq -r --arg n "$name" \
      '[.data.alerts[] | select(.labels.alertname==$n) | "\(.state) \(.value | tonumber | . * 1000 | round / 1000)"] | first // "inactive -"')
    if [ "$st" != "$last" ]; then
      printf '  %s UTC  t+%3ss  %-18s %-9s value=%s\n' "$(now)" $((SECONDS - start)) "$name" "$st" "$val"; last=$st
    fi
    [ "$st" = "$want" ] && return 0
    if [ $((SECONDS - start)) -ge "$timeout" ]; then echo "  gave up after ${timeout}s"; return 1; fi
    sleep 1
  done
}

lq() { curl -s -G "$LOKI/loki/api/v1/query" --data-urlencode "query=$1" | jq -r '.data.result[0].value[1] // "no data"'; }

am_alerts() {
  curl -s "$AM/api/v2/alerts" | jq -r '.[] | "  \(.labels.alertname)\tseverity=\(.labels.severity)\tstate=\(.status.state)\tinhibitedBy=\(.status.inhibitedBy | length)\tstartsAt=\(.startsAt[11:19])"' | column -t -s $'\t'
}

termshot() { [ "$SHOTS" = 1 ] && WIDTH="${W:-130}" "$SHOT" "screenshots/$1" "${@:2}"; }
webshot() {   # file url [width height budget-ms]
  [ "$SHOTS" = 1 ] || return 0
  local prof out="$PWD/screenshots/$1" pid
  prof=$(mktemp -d); rm -f "$out"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --user-data-dir="$prof" \
    --window-size="${3:-1400},${4:-900}" --virtual-time-budget="${5:-12000}" \
    --screenshot="$out" "$2" >/dev/null 2>&1 &
  pid=$!
  # Chrome writes the PNG but sometimes never exits on these single-page apps,
  # so wait for the file (max 90s) and then stop it ourselves
  for _ in $(seq 1 90); do [ -s "$out" ] && break; kill -0 $pid 2>/dev/null || break; sleep 1; done
  sleep 1; kill $pid 2>/dev/null; wait $pid 2>/dev/null
  rm -rf "$prof"; echo "  $1 (headless Chrome)"
}

# background traffic: ~10 req/s, mostly /api/orders
LOADPID=""
load_start() {
  ( while :; do
      for _ in 1 2 3 4; do curl -s -o /dev/null -A loadgen "$APP/api/orders" & done
      curl -s -o /dev/null -A loadgen "$APP/" &
      wait; sleep 0.2
    done ) >/dev/null 2>&1 &
  LOADPID=$!
}
load_stop() { [ -n "$LOADPID" ] && kill "$LOADPID" 2>/dev/null; wait "$LOADPID" 2>/dev/null; LOADPID=""; }
trap load_stop EXIT

check() {
  hr "STEP 1 - Validate config BEFORE starting anything (promtool / amtool)"
  docker run --rm -v "$PWD/prometheus:/etc/prometheus:ro" --entrypoint promtool $PROMIMG \
    check config /etc/prometheus/prometheus.yml
  echo
  echo "--- unit tests for the alert rules (fake series in, expected alerts out) ---"
  docker run --rm -v "$PWD/prometheus:/p:ro" -w /p --entrypoint promtool $PROMIMG \
    test rules alert-rules.test.yml
  echo "--- Alertmanager routing config ---"
  docker run --rm -v "$PWD/alertmanager:/a:ro" --entrypoint amtool $AMIMG check-config /a/alertmanager.yml
  termshot promtool-checks.png bash -c "docker run --rm -v \$PWD/prometheus:/p:ro -w /p --entrypoint promtool $PROMIMG check rules alert-rules.yml && docker run --rm -v \$PWD/prometheus:/p:ro -w /p --entrypoint promtool $PROMIMG test rules alert-rules.test.yml"
}

up() {
  hr "STEP 2 - Start the stack (app, Prometheus, Alertmanager, Grafana, exporters, Loki, Alloy)"
  docker compose up -d --build --quiet-pull 2>&1 | grep -vE '^ *#|Building|Built|exporting|naming|writing|resolve|load|transferring|DONE|CACHED' | tail -12
  echo
  echo "waiting for every Prometheus target to be UP ..."
  for _ in $(seq 1 40); do
    # count only once Prometheus has loaded its targets (an empty list is not "all up")
    down=$(curl -s "$PROM/api/v1/targets" 2>/dev/null | jq '.data.activeTargets as $t | if ($t | length) == 0 then -1 else [$t[] | select(.health!="up")] | length end' 2>/dev/null)
    [ "$down" = "0" ] && break; sleep 3
  done

  hr "STEP 3 - What is running"
  docker compose ps --format 'table {{.Service}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | sed 's/0.0.0.0://g; s/, \[::\]:[0-9]*->[0-9]*\/tcp//g'
  echo
  echo "--- Prometheus scrape targets (GET /api/v1/targets) ---"
  curl -s "$PROM/api/v1/targets" | jq -r '.data.activeTargets[] | "  \(.labels.job)\t\(.scrapeUrl)\t\(.health)\t\(.lastScrapeDuration*1000|floor)ms"' | column -t -s $'\t'
}

demo() {
  hr "STEP 4 - The application: health, a normal request, and its /metrics"
  echo "\$ curl $APP/health"; curl -s "$APP/health"; echo
  echo "\$ curl $APP/api/orders"; curl -s "$APP/api/orders"; echo
  echo
  echo "--- a few lines of $APP/metrics (Prometheus text format) ---"
  curl -s "$APP/api/orders" >/dev/null
  curl -s "$APP/metrics" | grep -E '^(# (HELP|TYPE) app_request_duration_seconds |app_request_duration_seconds_bucket\{endpoint="/api/orders",le="0\.(05|1|25)"\}|app_requests_total\{|process_cpu_seconds_total|process_resident_memory_bytes)' | head -12

  hr "STEP 5 - METRICS under load: request rate, p95 latency, error ratio"
  load_start
  echo "$(now) background load started (~10 req/s, 2% of /api/orders fail by design)"
  sleep 75
  echo
  echo "request rate (req/s), by endpoint:"
  qby 'sum by (endpoint) (rate(app_requests_total{job="demo-app"}[1m]))' endpoint
  printf 'p50 latency /api/orders:  %ss\n' "$(q 'histogram_quantile(0.50, sum by (le) (rate(app_request_duration_seconds_bucket{endpoint="/api/orders"}[1m])))')"
  printf 'p95 latency /api/orders:  %ss\n' "$(q 'histogram_quantile(0.95, sum by (le) (rate(app_request_duration_seconds_bucket{endpoint="/api/orders"}[1m])))')"
  printf 'error ratio (5xx / all):  %s\n' "$(q 'sum(rate(app_requests_total{status=~"5.."}[1m])) / sum(rate(app_requests_total[1m]))')"
  printf 'app process CPU (cores):  %s\n' "$(q 'rate(process_cpu_seconds_total{job="demo-app"}[1m])')"
  printf 'app process RSS (MiB):    %s\n' "$(q 'process_resident_memory_bytes{job="demo-app"} / 1048576')"
  printf 'host CPU used (%%):        %s\n' "$(q '100 * (1 - avg(rate(node_cpu_seconds_total{mode="idle"}[1m])))')"
  printf 'host memory used (%%):     %s\n' "$(q '100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)')"
  termshot promql-under-load.png bash -c "for e in 'sum(rate(app_requests_total[1m]))' 'histogram_quantile(0.95, sum by (le) (rate(app_request_duration_seconds_bucket{endpoint=\"/api/orders\"}[1m])))' 'sum(rate(app_requests_total{status=~\"5..\"}[1m])) / sum(rate(app_requests_total[1m]))' 'rate(process_cpu_seconds_total{job=\"demo-app\"}[1m])' 'process_resident_memory_bytes{job=\"demo-app\"}'; do printf '%-118s = ' \"\$e\"; curl -s -G $PROM/api/v1/query --data-urlencode \"query=\$e\" | jq -r '.data.result[0].value[1]'; done"

  hr "STEP 6 - CPU UTILISATION: spin one core -> HighCPU goes pending -> firing"
  printf 'before: app CPU = %s cores\n' "$(q 'rate(process_cpu_seconds_total{job="demo-app"}[1m])')"
  echo "\$ curl '$APP/stress/cpu?seconds=110'"; curl -s "$APP/stress/cpu?seconds=110"; echo
  echo "rule: rate(process_cpu_seconds_total[1m]) > 0.8  for 30s"
  watch_alert HighCPU firing 180
  echo
  echo "per-container CPU from cAdvisor (cores):"
  qby 'sum by (name) (rate(container_cpu_usage_seconds_total{name=~"monitoring-demo-.*"}[1m])) > 0.01' name
  echo
  echo "Alertmanager now holds:"; am_alerts
  termshot prometheus-alerts-api-highcpu.png bash -c "curl -s $PROM/api/v1/alerts | jq '.data.alerts[] | {alertname: .labels.alertname, state, activeAt, value, summary: .annotations.summary}'"

  hr "STEP 7 - MEMORY UTILISATION + APPLICATION HEALTH: hold 350 MB"
  printf 'before: RSS = %s MiB\n' "$(q 'process_resident_memory_bytes{job="demo-app"} / 1048576')"
  echo "\$ curl '$APP/stress/memory?mb=350'"; curl -s "$APP/stress/memory?mb=350"; echo
  sleep 6
  printf 'after:  RSS = %s MiB\n' "$(q 'process_resident_memory_bytes{job="demo-app"} / 1048576')"
  echo
  echo "the process is still UP, but /health now reports it is not healthy:"
  echo "\$ curl -i $APP/health"; curl -s -i "$APP/health" | grep -E '^HTTP|^\{'
  echo
  watch_alert HighMemory firing 90
  watch_alert HealthCheckFailing firing 60
  printf 'cAdvisor sees the same thing from the cgroup: container working set = %s MiB\n' \
    "$(q 'container_memory_working_set_bytes{name="monitoring-demo-app-1"} / 1048576')"
  printf 'up{job="demo-app"} = %s   probe_success{job="app-health"} = %s\n' "$(q 'up{job="demo-app"}')" "$(q 'probe_success{job="app-health"}')"
  echo
  echo "$(now) releasing the memory"
  curl -s "$APP/stress/release"; echo
  watch_alert HighMemory inactive 60
  watch_alert HealthCheckFailing inactive 60

  hr "STEP 8 - ERRORS: raise the failure rate to 30% -> HighErrorRate"
  curl -s "$APP/admin/error-rate?value=0.3"; echo
  watch_alert HighErrorRate firing 120
  curl -s "$APP/admin/error-rate?value=0.02"; echo
  echo "(error rate back to 2%; the alert resolves once the 1m window has rolled past)"

  hr "STEP 9 - ALERTING END TO END: stop the app -> AppDown pending -> firing -> resolved"
  echo "$(now) \$ docker compose stop app"
  docker compose stop app 2>&1 | tail -1
  watch_alert AppDown firing 90
  sleep 8
  echo
  echo "Prometheus says (GET /api/v1/alerts):"
  curl -s "$PROM/api/v1/alerts" | jq -r '.data.alerts[] | "  \(.labels.alertname)\t\(.state)\tactiveAt=\(.activeAt[11:19])"' | column -t -s $'\t'
  echo
  echo "Alertmanager says (GET /api/v2/alerts) - note HealthCheckFailing is SUPPRESSED by the inhibit rule:"
  am_alerts
  termshot alertmanager-api-appdown.png bash -c "curl -s $AM/api/v2/alerts | jq -r '.[] | [.labels.alertname, .labels.severity, .status.state, (.status.inhibitedBy|length|tostring)+\" inhibitors\", .startsAt] | @tsv' | column -t"
  webshot prometheus-alerts-firing.png "$PROM/alerts" 1400 1000
  webshot alertmanager-ui-firing.png "$AM/#/alerts?silenced=false&inhibited=true&muted=false&active=true" 1400 800
  echo
  echo "$(now) \$ docker compose start app"
  docker compose start app 2>&1 | tail -1
  watch_alert AppDown inactive 60
  sleep 20      # let Alertmanager's group_interval pass so the resolved webhook goes out
  echo
  echo "--- every notification Alertmanager delivered to the webhook receiver ---"
  docker compose logs --no-log-prefix alert-receiver | jq -rR 'fromjson? | select(.notification) | "  \(.notification)\t\(.alertname)\t\(.severity)\tstarted \(.startsAt[11:19])\(if .endsAt then "\tended " + .endsAt[11:19] else "" end)"' | column -t -s $'\t'
  termshot alert-receiver-notifications.png bash -c "docker compose logs --no-log-prefix alert-receiver | tail -n 14"

  hr "STEP 10 - LOGS: structured JSON on stdout, shipped to Loki by Alloy"
  echo "\$ docker compose logs app --tail 6"
  docker compose logs --no-log-prefix app --tail 6
  sleep 5
  echo
  echo "LogQL: errors in the last 10 minutes, parsed from the JSON body"
  echo "  sum by (level) (count_over_time({service=\"app\"} | json | status >= 500 [10m]))"
  curl -s -G "$LOKI/loki/api/v1/query" --data-urlencode 'query=sum by (level) (count_over_time({service="app"} | json | status >= 500 [10m]))' | jq -r '.data.result[] | "  level=\(.metric.level)  count=\(.value[1])"'
  echo
  echo "LogQL: the WARNING lines (what the stress endpoints and admin calls logged)"
  curl -s -G "$LOKI/loki/api/v1/query_range" --data-urlencode 'query={service="app", level="WARNING"}' \
    --data-urlencode "start=$(( $(date +%s) - 900 ))000000000" --data-urlencode limit=10 --data-urlencode direction=forward \
    | jq -r '.data.result[].values[][1]' | sort | sed 's/^/  /'
  echo
  echo "LogQL: p95 and max of duration_ms for /api/orders, computed from the log lines alone"
  echo "  (json path, duration_ms extracts only those two fields - extracting everything would"
  echo "   turn every unique ts into its own series)"
  printf '  p95 duration_ms from logs (exact):       %s\n' "$(lq 'max by (path) (quantile_over_time(0.95, {service="app"} | json path, duration_ms | path="/api/orders" | unwrap duration_ms [10m]))')"
  printf '  max duration_ms from logs:               %s\n' "$(lq 'max by (path) (max_over_time({service="app"} | json path, duration_ms | path="/api/orders" | unwrap duration_ms [10m]))')"
  printf '  p95 from the Prometheus histogram (s):   %s   (estimated inside the 0.25-0.5 bucket)\n' "$(q 'histogram_quantile(0.95, sum by (le) (rate(app_request_duration_seconds_bucket{endpoint="/api/orders"}[10m])))')"
  termshot loki-logql.png bash -c "curl -s -G $LOKI/loki/api/v1/query_range --data-urlencode 'query={service=\"app\"} | json | status >= 500' --data-urlencode limit=8 | jq -r '.data.result[].values[][1]'"
  termshot app-json-logs.png docker compose logs --no-log-prefix app --tail 10

  hr "STEP 11 - Grafana dashboards (provisioned from files) and the Prometheus targets page"
  load_stop
  echo "Grafana: $GRAFANA (anonymous Viewer enabled for this demo; admin/admin)"
  curl -s "$GRAFANA/api/search?type=dash-db" | jq -r '.[] | "  dashboard: \(.title)  uid=\(.uid)  folder=\(.folderTitle)"'
  curl -s "$GRAFANA/api/datasources/uid/prometheus/health" -u admin:admin | jq -r '"  datasource Prometheus: \(.status) - \(.message)"'
  curl -s "$GRAFANA/api/datasources/uid/loki/health" -u admin:admin | jq -r '"  datasource Loki:       \(.status) - \(.message)"'
  webshot grafana-dashboard.png "$GRAFANA/d/orders-api/orders-api-service-overview?orgId=1&from=now-15m&to=now&kiosk" 1600 1500 25000
  webshot prometheus-targets.png "$PROM/targets" 1400 900
  webshot grafana-logs-dashboard.png "$GRAFANA/d/orders-api-logs/orders-api-logs-loki?orgId=1&from=now-15m&to=now&kiosk" 1500 760 20000

  hr "STEP 12 - Kubernetes side: kubectl top (Metrics API, served by metrics-server)"
  if kubectl top nodes >/dev/null 2>&1; then
    echo "\$ kubectl top nodes"
    kubectl top nodes
    echo
    echo "\$ kubectl top pods -n kube-system --sort-by=memory"
    kubectl top pods -n kube-system --sort-by=memory | head -8
    termshot kubectl-top.png bash -c "kubectl top nodes; echo; kubectl top pods -n kube-system --sort-by=memory | head -8"
  else
    echo "metrics-server is not installed on the cluster - skipping (kubectl top needs the Metrics API)"
  fi
}

down() {
  hr "CLEANUP - docker compose down -v"
  load_stop
  docker compose down -v 2>&1 | tail -3
}

case "${1:-all}" in
  check) check ;;
  up)    up ;;
  demo)  demo ;;
  down)  down ;;
  all)   check; up; demo; down ;;
  *) echo "usage: $0 [check|up|demo|down|all]"; exit 1 ;;
esac
