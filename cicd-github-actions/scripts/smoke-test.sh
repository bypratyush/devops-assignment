#!/usr/bin/env bash
# smoke-test.sh <container> [expected-commit]
#
# Black-box checks against a running grade-calculator container. Used by the CI
# (image artifact), CD (image pulled from the registry) and deploy jobs.
#
# The container is reached on its bridge-network IP rather than a published
# port: that works the same on a GitHub-hosted runner and inside act, where the
# job itself runs in a container and a published 127.0.0.1 port is not visible.
set -euo pipefail

NAME="$1"
EXPECTED_SHA="${2:-}"
fail() { echo "::error::smoke test: $*"; exit 1; }

echo "--- waiting for the Docker HEALTHCHECK to report healthy"
for i in $(seq 1 30); do
  status=$(docker inspect "$NAME" --format '{{.State.Health.Status}}')
  [ "$status" = "healthy" ] && break
  [ "$status" = "unhealthy" ] && { docker logs "$NAME"; fail "container is unhealthy"; }
  sleep 2
done
echo "health status: $status (after ~$(( (i - 1) * 2 ))s)"
[ "$status" = "healthy" ] || { docker logs "$NAME"; fail "never became healthy"; }

IP=$(docker inspect "$NAME" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
BASE="http://${IP}:8080"
echo "container $NAME is at $BASE"

check() {  # check <description> <expected-http-code> <curl args...>
  local what="$1" want="$2"; shift 2
  local code
  code=$(curl -s -o /tmp/smoke-body -w '%{http_code}' "$@")
  printf '  %-44s HTTP %s  %s\n' "$what" "$code" "$(head -c 110 /tmp/smoke-body)"
  [ "$code" = "$want" ] || fail "$what: expected HTTP $want, got $code"
}

echo "--- endpoints"
check "GET /health"                    200 "$BASE/health"
check "GET /version"                   200 "$BASE/version"
if [ -n "$EXPECTED_SHA" ]; then
  got=$(jq -r .commit /tmp/smoke-body)
  [ "$got" = "$EXPECTED_SHA" ] || fail "image reports commit $got, expected $EXPECTED_SHA"
  echo "  image was built from the expected commit"
fi
check "GET /api/grade?score=91"        200 "$BASE/api/grade?score=91"
[ "$(jq -r .grade /tmp/smoke-body)" = "O" ] || fail "91 should be grade O"
check "GET /api/grade?score=abc (bad)" 400 "$BASE/api/grade?score=abc"
check "POST /api/sgpa"                 200 -H 'Content-Type: application/json' \
  -d '{"courses":[{"name":"DevOps","credits":4,"score":91},{"name":"DBMS","credits":3,"score":76}]}' \
  "$BASE/api/sgpa"

echo "--- container hardening"
uid=$(docker exec "$NAME" id -u)
echo "  process runs as uid $uid"
[ "$uid" != "0" ] || fail "container runs as root"

echo "--- secret-protected endpoint"
if [ -n "${ADMIN_API_KEY:-}" ]; then
  echo "  ADMIN_API_KEY secret is present (${#ADMIN_API_KEY} chars)"
  check "GET /api/admin/stats (no key)"   401 "$BASE/api/admin/stats"
  check "GET /api/admin/stats (with key)" 200 -H "X-API-Key: ${ADMIN_API_KEY}" "$BASE/api/admin/stats"
else
  echo "::warning::ADMIN_API_KEY secret is not set - admin endpoint stays disabled"
  check "GET /api/admin/stats (disabled)" 503 "$BASE/api/admin/stats"
fi

echo "smoke test passed"
