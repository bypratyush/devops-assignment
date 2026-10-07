#!/bin/sh
# Run DB migrations, then start the API. Postgres may still be starting when
# the container comes up (compose, or the first Helm install), so retry.
set -e

if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  n=0
  until alembic upgrade head; do
    n=$((n + 1))
    if [ "$n" -ge 15 ]; then
      echo "migrations failed after $n attempts, giving up" >&2
      exit 1
    fi
    echo "migration attempt $n failed (database not up yet?), retrying in 2s" >&2
    sleep 2
  done
fi

exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers "${WEB_WORKERS:-1}" --no-access-log
