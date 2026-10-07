#!/usr/bin/env bash
# traffic.sh [SECONDS] [WORKERS] - realistic-ish traffic through the Ingress so
# the Grafana panels have something to show: mostly reads, some searches and
# reports, and a few lookups of items that do not exist (404s).
set -u
DUR="${1:-180}"; WORKERS="${2:-4}"
BASE="${BASE:-http://localhost}"; HOST="${HOST_HEADER:-lostfound.local}"
end=$((SECONDS + DUR))
worker() {
  while [ $SECONDS -lt $end ]; do
    curl -s -o /dev/null -H "Host: $HOST" "$BASE/api/items"
    curl -s -o /dev/null -H "Host: $HOST" "$BASE/api/items?kind=found&status=open"
    curl -s -o /dev/null -H "Host: $HOST" "$BASE/api/items?q=library"
    curl -s -o /dev/null -H "Host: $HOST" "$BASE/api/stats"
    curl -s -o /dev/null -H "Host: $HOST" "$BASE/api/items/$((RANDOM % 12 + 1))"   # ids > 6 are 404s
    if [ $((RANDOM % 10)) -eq 0 ]; then
      curl -s -o /dev/null -H "Host: $HOST" -H 'content-type: application/json' -X POST "$BASE/api/items" \
        -d "{\"kind\":\"found\",\"title\":\"Umbrella #$RANDOM\",\"category\":\"other\",\"location\":\"Bus stop\",\"contact\":\"helpdesk@campus.test\"}"
    fi
  done
}
echo "sending traffic to $BASE (Host: $HOST) for ${DUR}s with $WORKERS workers"
for _ in $(seq 1 "$WORKERS"); do worker & done
wait
echo "done"
