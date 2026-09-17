#!/usr/bin/env bash
# lab.sh - start/stop/enter a real Linux (Ubuntu 22.04 + systemd) container.
#
# macOS has no useradd/adduser/journalctl, so Tasks 1-4 are practised inside a
# systemd-enabled Ubuntu container. systemd runs as PID 1 so journalctl works.
set -euo pipefail

NAME="linux-lab"
IMAGE="devops-hw-lab:22.04"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() { echo "usage: $0 {up|shell|exec <cmd>|status|down}"; exit 1; }

up() {
  if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
    docker start "$NAME" >/dev/null
  else
    docker run -d --name "$NAME" \
      --privileged \
      --cgroupns=host \
      -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
      -v "$REPO_DIR":/work \
      "$IMAGE" >/dev/null
  fi
  # wait for systemd to finish booting so journald is up
  for _ in $(seq 1 30); do
    if docker exec "$NAME" systemctl is-system-running 2>/dev/null | grep -Eq 'running|degraded'; then
      break
    fi
    sleep 1
  done
  echo "lab '$NAME' is up (repo mounted at /work)"
}

case "${1:-}" in
  up)     up ;;
  shell)  docker exec -it "$NAME" bash ;;
  exec)   shift; docker exec "$NAME" bash -lc "$*" ;;
  status) docker ps -a --filter "name=$NAME" ;;
  down)   docker rm -f "$NAME" >/dev/null 2>&1 && echo "lab removed" || echo "no lab running" ;;
  *)      usage ;;
esac
