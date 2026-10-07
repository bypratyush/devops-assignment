#!/usr/bin/env bash
# lib.sh - small helpers shared by every run.sh in kubernetes-troubleshooting/.
# Sourced, not executed:   . "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"
#
# Written for the macOS system bash (3.2), so no associative arrays etc.

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$LIB_DIR/.." && pwd)"

hr()  { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }

# Print a command, then run it (stdout+stderr). For simple commands only;
# anything with a pipe is echoed by hand in the scripts.
run() { echo "\$ $*"; "$@" 2>&1; }

# Create a namespace if it is missing (idempotent, quiet).
ensure_ns() { kubectl get ns "$1" >/dev/null 2>&1 || kubectl create ns "$1"; }

# watch_for SECONDS cmd...
# Runs a watch command (kubectl get -w) for a fixed time and prefixes every line
# with the wall-clock time it arrived, so a state transition is visible as a
# timeline. macOS has no `timeout`, hence the background-and-kill.
watch_for() {
  local secs=$1; shift
  local tmp; tmp=$(mktemp)
  "$@" > >(while IFS= read -r l; do printf '%s  %s\n' "$(date +%H:%M:%S)" "$l"; done > "$tmp") 2>&1 &
  local pid=$!
  sleep "$secs"
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  sleep 0.5
  cat "$tmp"; rm -f "$tmp"
}

# shot <out.png> cmd...   - real terminal screenshot via lab/shot.sh.
# Only when SHOTS=1, and silent, so it never changes the captured output.md.
shot() {
  [ "${SHOTS:-0}" = 1 ] || return 0
  local out="$1"; shift
  WIDTH="${W:-130}" "$REPO_ROOT/lab/shot.sh" "$out" "$@" >/dev/null 2>&1 || true
}

# http_code_retry <ns> <client-pod> <url> [tries]
# A pod being Ready does not mean its Service endpoint is programmed on every
# node yet, so give a known-good path a few attempts before calling it failed.
http_code_retry() {
  local ns=$1 pod=$2 url=$3 tries=${4:-10} code=000
  for _ in $(seq 1 "$tries"); do
    code=$(kubectl -n "$ns" exec "$pod" -- curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$url" 2>/dev/null)
    [ "$code" = "200" ] && break
    sleep 1
  done
  echo "$code"
}

# wait_gone <ns> <label-selector>
# `kubectl delete` returns once the Deployment is gone, but its pods can sit in
# Terminating for the 30s grace period. Wait for them, so a re-run's watch
# timeline is not polluted with the previous run's pods.
wait_gone() { kubectl -n "$1" wait --for=delete pod -l "$2" --timeout=120s >/dev/null 2>&1 || true; }
