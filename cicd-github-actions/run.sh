#!/usr/bin/env bash
# Session 16 - run the real GitHub Actions workflows locally with act.
#
# Usage: ./run.sh [ci|fail-demo|cd-blocked|cd|verify|cleanup|all]   (default: all)
#
#   ci          CI workflow (lint -> test matrix -> build -> verify image artifact)
#   fail-demo   break a grading boundary, run CI, watch it go red, restore the file
#   cd-blocked  CD triggered by a FAILED CI run -> every job must be skipped
#   cd          CD triggered by a green CI run -> push, smoke test, deploy
#   verify      hit the "production" container from the Mac
#   cleanup     remove the deployed container, the local registry and built images
#
# Needs: docker, act (nektos/act). The runner image is catthehacker's
# act-latest from ghcr.io. GHCR is replaced by a local registry:2 on
# localhost:5055 (port 5000 is taken by the macOS AirPlay Receiver).
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
HERE=$(pwd)
ROOT=$(cd .. && pwd)

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

CI_WF=.github/workflows/cicd-github-actions-ci.yml
CD_WF=.github/workflows/cicd-github-actions-cd.yml
REGISTRY_NAME=s16-registry
REGISTRY_PORT=5055
RUNNER_IMAGE=ghcr.io/catthehacker/ubuntu:act-latest
case "$(uname -m)" in arm64|aarch64) ARCH=linux/arm64 ;; *) ARCH=linux/amd64 ;; esac
STATE="$HERE/.act"          # git-ignored: event payloads, artifact store
LOGS="$HERE/logs"           # full act logs of each run, kept with the repo
mkdir -p "$STATE" "$LOGS"

# act prints its own docker plumbing (cp/exec of every step, env exports). The
# filter drops only those lines and colour codes; every line a step printed stays.
tidy() {
  sed -E 's/\x1b\[[0-9;]*m//g' \
    | grep -vE '🐳  docker (cp|exec|create|run|pull|volume)|::(set-env|add-path|add-mask)::|❓  ::(end)?group::|add-matcher|⚙  ::set-output::'
}

secrets_file() {
  # A throwaway key for local runs. On GitHub the value comes from Settings -> Secrets.
  if [ ! -f .secrets ]; then
    umask 077
    echo "ADMIN_API_KEY=local-$(openssl rand -hex 12)" > .secrets
    echo "(created a random git-ignored .secrets for this machine)"
  fi
}

run_act() {  # run_act <logname> <event> <workflow> [extra act args...]
  local log="$1" event="$2" wf="$3"; shift 3
  rm -rf "$STATE/artifacts"
  echo "\$ act $event -W $wf -P ubuntu-latest=$RUNNER_IMAGE --container-architecture $ARCH \\"
  echo "      --artifact-server-path .act/artifacts --secret-file .secrets --rm --action-offline-mode $*"
  echo
  ( cd "$ROOT" && act "$event" -W "$wf" \
      -P ubuntu-latest="$RUNNER_IMAGE" \
      --container-architecture "$ARCH" \
      --artifact-server-path "$STATE/artifacts" \
      --secret-file "$HERE/.secrets" \
      --rm --pull=false --action-offline-mode "$@" 2>&1 ) \
    | sed -E 's/\x1b\[[0-9;]*m//g' | tee "$LOGS/$log.log" | tidy
  local rc=${PIPESTATUS[0]}
  echo
  echo "act exit code: $rc"
  return "$rc"
}

registry_up() {
  if ! docker inspect "$REGISTRY_NAME" >/dev/null 2>&1; then
    docker run -d --name "$REGISTRY_NAME" -p "127.0.0.1:${REGISTRY_PORT}:5000" registry:2 >/dev/null
  fi
  echo "local registry: $(docker ps --filter name=$REGISTRY_NAME --format '{{.Names}} {{.Image}} {{.Ports}}')"
}

workflow_run_event() {  # workflow_run_event <conclusion> -> path of payload
  local f="$STATE/workflow_run-$1.json"
  cat > "$f" <<EOF
{
  "action": "completed",
  "workflow_run": {
    "name": "S16 CI - grade calculator",
    "event": "push",
    "head_branch": "main",
    "head_sha": "$(git -C "$ROOT" rev-parse HEAD)",
    "conclusion": "$1"
  }
}
EOF
  echo "$f"
}

ci() {
  hr "STEP 1 - The jobs act found in the CI workflow"
  (cd "$ROOT" && act -W "$CI_WF" -l --container-architecture "$ARCH" 2>&1)
  secrets_file

  hr "STEP 2 - Run the CI workflow (push event)"
  run_act ci-green push "$CI_WF"
  local rc=$?

  hr "STEP 3 - Artifacts the CI run uploaded (act's artifact server on disk)"
  find "$STATE/artifacts" -type f | sed "s|$STATE/||" | sort
  return $rc
}

fail_demo() {
  hr "STEP 4 - Deliberately break the code: 90 is no longer an O grade"
  cp app/grading.py "$STATE/grading.py.bak"
  trap 'cp "$STATE/grading.py.bak" app/grading.py' RETURN
  sed -i.tmp 's/(90, "O", 10)/(91, "O", 10)/' app/grading.py && rm -f app/grading.py.tmp
  diff -u "$STATE/grading.py.bak" app/grading.py | sed "s|$STATE/grading.py.bak|app/grading.py (original)|"

  hr "STEP 5 - Run CI against the broken code (expected: test jobs fail, build never starts)"
  run_act ci-red push "$CI_WF"
  local rc=$?
  echo
  echo "--- job results in this run"
  grep -E 'Job (succeeded|failed)$' "$LOGS/ci-red.log" | sed -E 's/^\[[^/]*\/([^]]*)\].*Job (succeeded|failed)$/  \1: \2/' | sed -E 's/ +:/:/'
  for job in "Build image" "Verify image artifact"; do
    grep -q "/$job\]" "$LOGS/ci-red.log" && echo "  $job: RAN (unexpected)" || echo "  $job: never started"
  done
  echo
  echo "--- failing assertion, from the uploaded test report artifact"
  find "$STATE/artifacts" -name '*.zip' -path '*py3.13*' | head -1 | xargs -I{} unzip -p {} junit.xml 2>/dev/null \
    | grep -oE '<testcase [^>]*name="test_grade_band_boundaries\[90-expected1\]"|<failure message="[^"]*"' | head -2
  [ "$rc" -ne 0 ] && echo && echo "CI went red as intended (act exit code $rc)"
  hr "STEP 6 - Restore the file"
  cp "$STATE/grading.py.bak" app/grading.py
  grep -n '(90, "O", 10)' app/grading.py
  trap - RETURN
}

cd_blocked() {
  hr "STEP 7 - CD after a FAILED CI run (workflow_run, conclusion=failure)"
  local ev; ev=$(workflow_run_event failure)
  cat "$ev"
  echo
  run_act cd-blocked workflow_run "$CD_WF" -e "$ev"
  echo
  if grep -qE 'Job (succeeded|failed)' "$LOGS/cd-blocked.log"; then
    echo "a CD job ran - the gate did NOT hold"
  else
    echo "no CD job ran: publish was skipped by its if:, so smoke-test and deploy (needs: publish) never started"
  fi
}

cd_run() {
  secrets_file
  hr "STEP 8 - Start the local registry that stands in for ghcr.io"
  registry_up

  hr "STEP 9 - CD after a GREEN CI run (workflow_run, conclusion=success)"
  local ev; ev=$(workflow_run_event success)
  cat "$ev"
  echo
  run_act cd-green workflow_run "$CD_WF" -e "$ev"
}

verify() {
  hr "STEP 10 - What is in the registry now"
  curl -s "http://localhost:${REGISTRY_PORT}/v2/_catalog"; echo
  curl -s "http://localhost:${REGISTRY_PORT}/v2/bypratyush/grade-calculator/tags/list"; echo

  hr "STEP 11 - The deployed 'production' container, called from the Mac"
  docker ps --filter name=grade-calculator-production --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
  echo
  echo "\$ curl localhost:18716/version"
  curl -s localhost:18716/version; echo
  echo "\$ curl 'localhost:18716/api/grade?score=78'"
  curl -s 'localhost:18716/api/grade?score=78'; echo
}

cleanup() {
  hr "CLEANUP - deployed container, local registry, images built by the runs"
  docker rm -f grade-calculator-production "$REGISTRY_NAME" s16-ci-verify s16-cd-smoke 2>/dev/null
  docker images --format '{{.Repository}}:{{.Tag}}' \
    | grep -E '^(grade-calculator|localhost:5055/bypratyush/grade-calculator):' \
    | xargs -r docker image rm -f >/dev/null 2>&1
  docker image prune -f >/dev/null
  echo "left behind by act: $(docker ps -a --format '{{.Names}}' | grep -c '^act-') containers"
}

case "${1:-all}" in
  ci)         ci ;;
  fail-demo)  fail_demo ;;
  cd-blocked) cd_blocked ;;
  cd)         cd_run ;;
  verify)     verify ;;
  cleanup)    cleanup ;;
  all)        ci; fail_demo; cd_blocked; cd_run; verify; cleanup ;;
  *) echo "usage: $0 [ci|fail-demo|cd-blocked|cd|verify|cleanup|all]"; exit 2 ;;
esac
