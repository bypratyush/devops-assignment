#!/usr/bin/env bash
# Task 2 - Observability: follow ONE request through metrics, logs and traces.
#
# Usage: ./run.sh [up|demo|k8s|down|all]     (default: all)
#   up    build the two services, start Jaeger + Prometheus
#   demo  one slow checkout and one failing checkout, each followed by trace_id
#         through the logs, the Jaeger trace and the Prometheus exemplar
#   k8s   where the same signals come from on Kubernetes (read-only, kind cluster)
#   down  docker compose down -v
# SHOTS=0 skips the screenshots.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

SHOP=http://localhost:18020
JAEGER=http://localhost:26686
PROM=http://localhost:29190
SHOT=../../lab/shot.sh
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SHOTS=${SHOTS:-1}

termshot() { [ "$SHOTS" = 1 ] && WIDTH="${W:-130}" "$SHOT" "screenshots/$1" "${@:2}"; }
webshot() {   # file url [width height budget-ms]
  [ "$SHOTS" = 1 ] || return 0
  local prof out="$PWD/screenshots/$1" pid
  prof=$(mktemp -d); rm -f "$out"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --user-data-dir="$prof" \
    --window-size="${3:-1400},${4:-900}" --virtual-time-budget="${5:-12000}" \
    --screenshot="$out" "$2" >/dev/null 2>&1 &
  pid=$!
  for _ in $(seq 1 90); do [ -s "$out" ] && break; kill -0 $pid 2>/dev/null || break; sleep 1; done
  sleep 1; kill $pid 2>/dev/null; wait $pid 2>/dev/null
  rm -rf "$prof"; echo "  $1 (headless Chrome)"
}

# print the spans of a trace from Jaeger's HTTP API as an indented tree
trace_tree() {
  curl -s "$JAEGER/api/traces/$1" | jq -r '
    .data[0] as $t
    | ($t.spans | map({key: .spanID, value: .}) | from_entries) as $byid
    | ($t.spans | map(.startTime) | min) as $t0
    | def depth(s): if (s.references | length) == 0 then 0 else 1 + depth($byid[s.references[0].spanID]) end;
      $t.spans | sort_by(.startTime) | .[]
    | (depth(.)) as $d
    | ([.tags[] | select(.key == "otel.status_code" or .key == "error" or .key == "http.response.status_code" or .key == "db.statement") | "\(.key)=\(.value)"] | join(" ")) as $tags
    | "  \("  " * $d)\($t.processes[.processID].serviceName): \(.operationName)  [+\((.startTime - $t0) / 1000 | floor)ms, \(.duration / 1000 | floor)ms]  \($tags)"'
}

follow() {   # item  - make one request and chase its trace_id through every signal
  local item=$1 body tid
  echo "\$ curl '$SHOP/checkout?item=$item'"
  body=$(curl -s -w '  (HTTP %{http_code}, %{time_total}s)' "$SHOP/checkout?item=$item"); echo "$body"
  tid=$(echo "$body" | sed 's/  (HTTP.*//' | jq -r .trace_id)
  TID=$tid
  sleep 4      # spans are batched and flushed every second; give the scrape a moment too
  echo
  echo "--- LOGS: every line from both services that carries trace_id=$tid ---"
  docker compose logs --no-log-prefix shop inventory 2>/dev/null | grep "$tid" \
    | jq -c '{service, level, msg, trace_id, span_id} + (del(.ts, .service, .level, .msg, .trace_id, .span_id))'
  echo
  echo "--- TRACE: GET $JAEGER/api/traces/$tid  (span tree, [start offset, duration]) ---"
  trace_tree "$tid"
  echo
  echo "--- METRICS: Prometheus exemplars that point at this trace ---"
  curl -s -G "$PROM/api/v1/query_exemplars" --data-urlencode 'query=demo_request_duration_seconds_bucket' \
    --data-urlencode "start=$(( $(date +%s) - 300 ))" --data-urlencode "end=$(date +%s)" \
    | jq -r --arg t "$tid" '.data[] | .seriesLabels as $s | .exemplars[] | select(.labels.trace_id == $t)
        | "  demo_request_duration_seconds_bucket{service=\"\($s.service)\", route=\"\($s.route)\", status=\"\($s.status)\", le=\"\($s.le)\"}  exemplar value=\(.value)s  trace_id=\(.labels.trace_id)"'
}

up() {
  hr "STEP 1 - Start shop + inventory (OpenTelemetry), Jaeger and Prometheus"
  docker compose up -d --build --quiet-pull 2>&1 | grep -E 'Started|Created|Error|error' | tail -8
  for _ in $(seq 1 30); do curl -sf "$SHOP/checkout?item=book" >/dev/null && break; sleep 2; done
  for _ in $(seq 1 30); do curl -sf "$JAEGER/" >/dev/null && break; sleep 2; done
  echo
  docker compose ps --format 'table {{.Service}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | sed 's/0.0.0.0://g; s/, \[::\]:[0-9]*->[0-9]*\/tcp//g'
  sleep 6
  echo
  echo "services Jaeger has received spans from:"
  curl -s "$JAEGER/api/v3/services" | jq -r '.services[] | "  \(.)"'
}

demo() {
  hr "STEP 2 - A SLOW request: GET /checkout?item=gpu"
  echo "The client only sees that the call was slow. Monitoring would tell us latency went up."
  echo "Observability has to tell us WHERE the time went - follow the trace_id."
  echo
  follow gpu
  SLOW=$TID
  echo
  echo "--- the raw OpenMetrics text the shop exposes (exemplar after the '#') ---"
  curl -s -H 'Accept: application/openmetrics-text; version=1.0.0' "$SHOP/metrics" | grep "$SLOW" | head -2
  W=140 termshot logs-with-trace-id.png bash -c "docker compose logs --no-log-prefix shop inventory | grep $SLOW | jq -c '{service, level, msg, trace_id, span_id}'"
  W=140 termshot jaeger-api-trace.png bash -c "curl -s $JAEGER/api/traces/$SLOW | jq -r '.data[0] as \$t | \$t.spans | sort_by(.startTime) | .[] | [\$t.processes[.processID].serviceName, .operationName, (.duration/1000|floor|tostring)+\"ms\", .traceID] | @tsv' | column -t"
  W=140 termshot prometheus-exemplar.png bash -c "curl -s -G $PROM/api/v1/query_exemplars --data-urlencode query=demo_request_duration_seconds_bucket --data-urlencode start=\$(( \$(date +%s) - 300 )) | jq -c '.data[] | {series: (.seriesLabels | {service, route, le}), exemplars: [.exemplars[] | select(.labels.trace_id == \"$SLOW\") | {trace_id: .labels.trace_id, value}]} | select(.exemplars | length > 0)'"
  webshot jaeger-trace-slow.png "$JAEGER/trace/$SLOW" 1400 520

  hr "STEP 3 - A FAILING request: GET /checkout?item=unicorn"
  follow unicorn
  FAIL=$TID
  echo
  echo "--- Jaeger search (API v3): traces of service 'shop' with error=true in the last 15 minutes ---"
  curl -s -G "$JAEGER/api/v3/traces" --data-urlencode query.service_name=shop --data-urlencode 'query.attributes={"error":"true"}' \
    --data-urlencode "query.start_time_min=$(date -u -v-15M +%Y-%m-%dT%H:%M:%SZ)" --data-urlencode "query.start_time_max=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    | jq -r '[.result.resourceSpans[].scopeSpans[].spans[] | select((.parentSpanId // "") == "")] | unique_by(.traceId) | .[]
             | "  trace_id=\(.traceId)  root span=\(.name)  status=\(.status.message // "ERROR")"'
  webshot jaeger-trace-error.png "$JAEGER/trace/$FAIL" 1400 520

  hr "STEP 4 - Some normal traffic, then the metric view of the same story"
  for i in $(seq 1 30); do curl -s -o /dev/null "$SHOP/checkout?item=book"; curl -s -o /dev/null "$SHOP/checkout?item=lamp"; done
  for i in 1 2 3; do curl -s -o /dev/null "$SHOP/checkout?item=gpu"; done
  sleep 8
  echo "request count by service/status (from the histogram's _count):"
  curl -s -G "$PROM/api/v1/query" --data-urlencode 'query=sum by (service, route, status) (demo_request_duration_seconds_count)' \
    | jq -r '.data.result[] | "  \(.metric.service)\t\(.metric.route)\t\(.metric.status)\t\(.value[1])"' | column -t -s $'\t'
  echo
  echo "p95 latency per service over the last 2 minutes:"
  curl -s -G "$PROM/api/v1/query" --data-urlencode 'query=histogram_quantile(0.95, sum by (service, le) (rate(demo_request_duration_seconds_bucket[2m])))' \
    | jq -r '.data.result[] | "  \(.metric.service)\t\(.value[1] | tonumber * 1000 | round)ms"' | column -t -s $'\t'
  echo
  echo "The metric says p95 is high. It cannot say why - but the exemplar on the slow"
  echo "bucket hands us a trace_id, and the trace shows db.query on 'gpu' taking ~600ms."
  echo
  echo "--- SUMMARY: one trace_id, three signals ---"
  printf '  slow request    trace_id=%s\n' "$SLOW"
  printf '    in logs:      %s lines\n' "$(docker compose logs --no-log-prefix shop inventory 2>/dev/null | grep -c "$SLOW")"
  printf '    in Jaeger:    %s spans\n' "$(curl -s "$JAEGER/api/traces/$SLOW" | jq '.data[0].spans | length')"
  printf '    in metrics:   %s exemplars\n' "$(curl -s -G "$PROM/api/v1/query_exemplars" --data-urlencode 'query=demo_request_duration_seconds_bucket' --data-urlencode "start=$(( $(date +%s) - 600 ))" | jq --arg t "$SLOW" '[.data[].exemplars[] | select(.labels.trace_id == $t)] | length')"
  printf '  failed request  trace_id=%s\n' "$FAIL"
  printf '    in logs:      %s lines (%s at ERROR)\n' "$(docker compose logs --no-log-prefix shop inventory 2>/dev/null | grep -c "$FAIL")" "$(docker compose logs --no-log-prefix shop inventory 2>/dev/null | grep "$FAIL" | grep -c '"ERROR"')"
  printf '    in Jaeger:    %s spans, error=%s\n' "$(curl -s "$JAEGER/api/traces/$FAIL" | jq '.data[0].spans | length')" "$(curl -s "$JAEGER/api/traces/$FAIL" | jq '[.data[0].spans[].tags[] | select(.key == "error")] | length > 0')"
}

k8s() {
  hr "STEP 5 - The same signals on Kubernetes (read-only look at the kind cluster)"
  local node=devops-hw-worker
  echo "cAdvisor is built into every kubelet - per-container CPU/memory, the raw source of most k8s metrics:"
  echo "\$ kubectl get --raw /api/v1/nodes/$node/proxy/metrics/cadvisor | grep container_memory_working_set_bytes | head -3"
  kubectl get --raw "/api/v1/nodes/$node/proxy/metrics/cadvisor" | grep '^container_memory_working_set_bytes' | grep 'namespace="kube-system"' | head -3 | cut -c1-230
  echo
  echo "The kubelet's summarised resource endpoint - this is what metrics-server scrapes:"
  echo "\$ kubectl get --raw /api/v1/nodes/$node/proxy/metrics/resource | grep ^node_"
  kubectl get --raw "/api/v1/nodes/$node/proxy/metrics/resource" | grep -E '^node_(cpu|memory)'
  echo
  echo "metrics-server aggregates that into the Metrics API (what kubectl top and the HPA read):"
  if kubectl top nodes >/dev/null 2>&1; then
    kubectl top nodes
    echo
    kubectl get apiservice v1beta1.metrics.k8s.io --no-headers 2>/dev/null | awk '{print "  apiservice " $1 "  service=" $2 "  available=" $3}'
  else
    echo "  (metrics-server not installed)"
  fi
  echo
  echo "Container logs live as files on each node; a DaemonSet log agent tails exactly these paths:"
  kubectl get --raw "/api/v1/nodes/$node/proxy/logs/pods/" 2>/dev/null | sed -n 's/.*href="\([^"]*\)".*/  \/var\/log\/pods\/\1/p' | grep kube-system | head -3
  W=140 termshot k8s-metrics-sources.png bash -c "kubectl get --raw /api/v1/nodes/$node/proxy/metrics/resource | grep -E '^node_(cpu|memory)'; echo; kubectl top nodes"
}

down() {
  hr "CLEANUP - docker compose down -v"
  docker compose down -v 2>&1 | tail -3
}

case "${1:-all}" in
  up)   up ;;
  demo) demo ;;
  k8s)  k8s ;;
  down) down ;;
  all)  up; demo; k8s; down ;;
  *) echo "usage: $0 [up|demo|k8s|down|all]"; exit 1 ;;
esac
