#!/usr/bin/env bash
# localstack.sh - start/stop a local AWS emulator for the Terraform sessions.
#
# There is no AWS account behind this homework, so Terraform and the AWS CLI are
# pointed at LocalStack running in Docker on http://localhost:4566 instead.
#
# The image is pinned to 4.14.0 on purpose. From 2026.03.0 onwards the
# localstack/localstack image refuses to start without LOCALSTACK_AUTH_TOKEN
# (exit code 55, "License activation failed"). 4.14.0 is the last Community
# release and still runs with no account at all. See terraform-iac/README.md.
#
#   ./lab/localstack.sh up        # start (or re-start) and wait until healthy
#   ./lab/localstack.sh status    # container + per-service health
#   eval "$(./lab/localstack.sh env)"   # dummy credentials for the AWS CLI
#   ./lab/localstack.sh down      # remove the container (state is in-memory)
set -euo pipefail

NAME="localstack"
IMAGE="localstack/localstack:4.14.0"
PORT=4566
URL="http://localhost:${PORT}"

usage() { echo "usage: $0 {up|status|env|down}"; exit 1; }

up() {
  if docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
    echo "localstack already running"
  elif docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
    docker start "$NAME" >/dev/null
  else
    docker run -d --name "$NAME" \
      -p "127.0.0.1:${PORT}:4566" \
      "$IMAGE" >/dev/null
  fi
  # the edge port answers before the services are ready, so poll the health API
  for _ in $(seq 1 60); do
    if curl -sf "${URL}/_localstack/health" 2>/dev/null | grep -q '"s3": "\(available\|running\)"'; then
      echo "localstack is up on ${URL} ($IMAGE)"
      return 0
    fi
    sleep 1
  done
  echo "localstack did not become healthy in 60s - check: docker logs $NAME" >&2
  exit 1
}

status() {
  docker ps -a --filter "name=^${NAME}$" --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
  curl -sf "${URL}/_localstack/health" 2>/dev/null | python3 -m json.tool 2>/dev/null \
    || echo "(health endpoint not reachable)"
}

env_lines() {
  # LocalStack accepts any credentials; the CLI and Terraform just need some set.
  cat <<EOF
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=ap-south-1
EOF
}

case "${1:-}" in
  up)     up ;;
  status) status ;;
  env)    env_lines ;;
  down)   docker rm -f "$NAME" >/dev/null 2>&1 && echo "localstack removed" || echo "no localstack running" ;;
  *)      usage ;;
esac
