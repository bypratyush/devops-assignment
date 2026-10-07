#!/usr/bin/env bash
# Session 21 - run .github/workflows/final-project.yml locally with act
# (push event on main), with a local registry:2 standing in for ghcr.io.
#
# Usage: ./security/run-pipeline.sh [run|cleanup|all]   (default: all)
#
#   run      start the registry on 127.0.0.1:5057, run the whole pipeline,
#            show job results, artifacts and what landed in the registry
#   cleanup  remove the registry and the images the run built/pushed
#
# The deploy-gitops job is skipped under act: the event file below sets
# {"act": true} and the job has `if: ... && !github.event.act`.
# Set ACT_OFFLINE=1 to reuse act's cached copies of the actions.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.."
HERE=$(pwd)
ROOT=$(cd .. && pwd)

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

WF=.github/workflows/final-project.yml
REGISTRY_NAME=s21-registry
REGISTRY=127.0.0.1:5057
RUNNER_IMAGE=ghcr.io/catthehacker/ubuntu:act-latest
case "$(uname -m)" in arm64|aarch64) ARCH=linux/arm64 ;; *) ARCH=linux/amd64 ;; esac
STATE="$HERE/.act"
LOGS="$STATE/logs"   # full act logs (git-ignored)
mkdir -p "$STATE" "$LOGS"
OFFLINE=""; [ "${ACT_OFFLINE:-0}" = 1 ] && OFFLINE="--action-offline-mode"

# drop act's container plumbing lines; keep every step's real output
tidy() {
  grep -vE '🐳  docker (cp|exec|create|run|pull|volume)|::(set-env|add-path|add-mask)::|❓  ::(end)?group::|add-matcher|⚙  ::set-output::|DeprecationWarning|trace-deprecation'
}

run() {
  hr "STEP 1 - tools and the local registry that stands in for ghcr.io"
  act --version
  docker version --format 'docker {{.Server.Version}}'
  docker inspect "$REGISTRY_NAME" >/dev/null 2>&1 \
    || docker run -d --name "$REGISTRY_NAME" -p "$REGISTRY:5000" registry:2 >/dev/null
  echo "registry: $(docker ps --filter name=$REGISTRY_NAME --format '{{.Names}} {{.Image}} {{.Ports}}')"
  echo '{"act": true}' > "$STATE/event-push.json"
  echo "event file: $(cat "$STATE/event-push.json")"
  echo "commit under test: $(git -C "$ROOT" rev-parse --short HEAD) on $(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"

  hr "STEP 2 - act push (the whole pipeline)"
  rm -rf "$STATE/artifacts"
  echo "\$ act push -W $WF -e final-devops-project/.act/event-push.json \\"
  echo "      -P ubuntu-latest=$RUNNER_IMAGE --container-architecture $ARCH \\"
  echo "      --artifact-server-path final-devops-project/.act/artifacts --artifact-server-port 34570 --rm --pull=false $OFFLINE"
  echo
  ( cd "$ROOT" && act push -W "$WF" -e "$STATE/event-push.json" \
      -P ubuntu-latest="$RUNNER_IMAGE" \
      --container-architecture "$ARCH" \
      --artifact-server-path "$STATE/artifacts" --artifact-server-port 34570 \
      --rm --pull=false $OFFLINE 2>&1 ) \
    | sed -E 's/\x1b\[[0-9;]*m//g' | tee "$LOGS/act-push.log" | tidy
  local rc=${PIPESTATUS[0]}
  echo
  echo "act exit code: $rc"

  hr "STEP 3 - job results"
  grep -E 'Job (succeeded|failed)$' "$LOGS/act-push.log" \
    | sed -E 's/^\[[^/]*\/([^]]*)\].*Job (succeeded|failed)$/  \1: \2/' | sed -E 's/ +:/:/'
  grep -q 'Deploy (GitOps' "$LOGS/act-push.log" || echo "  Deploy (GitOps - bump image.tag for Argo CD): skipped (github.event.act is true)"

  hr "STEP 4 - artifacts kept by act's artifact server"
  ( cd "$STATE" && find artifacts -type f | sort )

  hr "STEP 5 - what reached the registry (tagged with the short SHA, no :latest)"
  curl -s "http://$REGISTRY/v2/_catalog"; echo
  for img in lostfound-backend lostfound-frontend; do
    curl -s "http://$REGISTRY/v2/bypratyush/$img/tags/list"; echo
  done
  echo "act containers left: $(docker ps -a --format '{{.Names}}' | grep -c '^act-')"
  return "$rc"
}

cleanup() {
  hr "CLEANUP"
  docker rm -f "$REGISTRY_NAME" >/dev/null 2>&1 && echo "removed $REGISTRY_NAME"
  docker images --format '{{.Repository}}:{{.Tag}}' \
    | grep -E "^(lostfound-(backend|frontend)|$REGISTRY/bypratyush/lostfound-(backend|frontend)):[0-9a-f]{7}$" \
    | xargs -r docker image rm -f >/dev/null 2>&1
  echo "act containers left: $(docker ps -a --format '{{.Names}}' | grep -c '^act-')"
  echo "registry containers left: $(docker ps -a --format '{{.Names}}' | grep -c "^$REGISTRY_NAME$")"
}

case "${1:-all}" in
  run)     run ;;
  cleanup) cleanup ;;
  all)     run; rc=$?; cleanup; exit $rc ;;
  *) echo "usage: $0 [run|cleanup|all]"; exit 2 ;;
esac
