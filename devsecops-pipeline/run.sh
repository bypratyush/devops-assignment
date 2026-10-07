#!/usr/bin/env bash
# Session 17 - run the DevSecOps workflow locally with act.
#
# Usage: ./run.sh [red|green|cleanup|all]   (default: all)
#
#   red      inject an insecure code pattern, a vulnerable dependency and a fake
#            token, run the pipeline, show the Security Gate stopping it, restore
#   green    run the clean pipeline end to end, including the kind deploy
#   cleanup  remove the local registry, the kind cluster (if left) and images
#
# GHCR is replaced by a local registry:2 on localhost:5056 under act.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
HERE=$(pwd)
ROOT=$(cd .. && pwd)

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

WF=.github/workflows/devsecops.yml
REGISTRY_NAME=s17-registry
RUNNER_IMAGE=ghcr.io/catthehacker/ubuntu:act-latest
case "$(uname -m)" in arm64|aarch64) ARCH=linux/arm64 ;; *) ARCH=linux/amd64 ;; esac
STATE="$HERE/.act"
LOGS="$HERE/logs"
mkdir -p "$STATE" "$LOGS"

tidy() {
  grep -vE '🐳  docker (cp|exec|create|run|pull|volume)|::(set-env|add-path|add-mask)::|❓  ::(end)?group::|add-matcher|⚙  ::set-output::|DeprecationWarning|trace-deprecation'
}

run_act() {  # run_act <logname>
  rm -rf "$STATE/artifacts"
  echo "\$ act push -W $WF -P ubuntu-latest=$RUNNER_IMAGE --container-architecture $ARCH \\"
  echo "      --artifact-server-path .act/artifacts --artifact-server-port 34568 --rm --action-offline-mode"
  echo
  ( cd "$ROOT" && act push -W "$WF" \
      -P ubuntu-latest="$RUNNER_IMAGE" \
      --container-architecture "$ARCH" \
      --artifact-server-path "$STATE/artifacts" --artifact-server-port 34568 \
      --rm --pull=false --action-offline-mode 2>&1 ) \
    | sed -E 's/\x1b\[[0-9;]*m//g; s/ghp_[A-Za-z0-9]{36}/ghp_<redacted by run.sh>/g' | tee "$LOGS/$1.log" | tidy
  local rc=${PIPESTATUS[0]}
  echo
  echo "act exit code: $rc"
  echo "--- job results"
  grep -E 'Job (succeeded|failed)$' "$LOGS/$1.log" | sed -E 's/^\[[^/]*\/([^]]*)\].*Job (succeeded|failed)$/  \1: \2/' | sed -E 's/ +:/:/'
  for job in "10 Push Image" "11 Deploy to Kubernetes"; do
    grep -q "/$job" "$LOGS/$1.log" || echo "  $job: never started"
  done
  return "$rc"
}

registry_up() {
  docker inspect "$REGISTRY_NAME" >/dev/null 2>&1 \
    || docker run -d --name "$REGISTRY_NAME" -p 127.0.0.1:5056:5000 registry:2 >/dev/null
  echo "local registry: $(docker ps --filter name=$REGISTRY_NAME --format '{{.Names}} {{.Image}} {{.Ports}}')"
}

red() {
  hr "RED RUN - STEP 1: inject three problems into the code"
  cp src/passguard/strength.py "$STATE/strength.py.bak"
  cp requirements.txt "$STATE/requirements.txt.bak"
  trap 'cp "$STATE/strength.py.bak" src/passguard/strength.py; cp "$STATE/requirements.txt.bak" requirements.txt; rm -f src/passguard/config.py' RETURN

  # 1. insecure code: MD5 over a password (Bandit B324)
  perl -0pi -e 's/^import math$/import hashlib\nimport math/m' src/passguard/strength.py
  printf '\n\ndef fingerprint(password):\n    """Short id used to cache results."""\n    return hashlib.md5(password.encode()).hexdigest()[:12]\n' >> src/passguard/strength.py
  # 2. vulnerable dependency: an old gunicorn
  sed -i.tmp 's/^gunicorn==.*/gunicorn==21.2.0/' requirements.txt && rm -f requirements.txt.tmp
  # 3. hard-coded credential: an obviously fake GitHub token (built from two parts
  #    so this script itself never contains a scannable token)
  prefix="ghp_"; body="FAKE0demo0token0for0gitleaks0test012"
  printf '# upstream API used for breach lookups\nUPSTREAM_TOKEN = "%s%s"\n' "$prefix" "$body" > src/passguard/config.py

  echo "--- strength.py"; diff "$STATE/strength.py.bak" src/passguard/strength.py
  echo "--- requirements.txt"; diff "$STATE/requirements.txt.bak" requirements.txt
  echo "--- new file config.py (token masked here)"; sed -E 's/ghp_[A-Za-z0-9]+/ghp_<36 fake characters>/' src/passguard/config.py

  hr "RED RUN - STEP 2: run the pipeline"
  run_act red
  local rc=$?
  if [ "$rc" -ne 0 ] && grep -q '9 Security Gate\].*Job failed' "$LOGS/red.log"; then
    echo; echo "pipeline stopped at the Security Gate as intended (act exit code $rc)"
  fi

  hr "RED RUN - STEP 3: restore the clean code"
  cp "$STATE/strength.py.bak" src/passguard/strength.py
  cp "$STATE/requirements.txt.bak" requirements.txt
  rm -f src/passguard/config.py
  grep -c md5 src/passguard/strength.py; grep '^gunicorn' requirements.txt; ls src/passguard/
  trap - RETURN
}

green() {
  hr "GREEN RUN - STEP 1: start the local registry that stands in for ghcr.io"
  registry_up
  hr "GREEN RUN - STEP 2: run the clean pipeline"
  run_act green
  local rc=$?
  hr "GREEN RUN - STEP 3: registry contents and leftovers"
  curl -s localhost:5056/v2/_catalog; echo
  curl -s localhost:5056/v2/bypratyush/passguard/tags/list; echo
  echo "kind clusters still present: $(kind get clusters 2>/dev/null | grep -c devsecops-ci)"
  return $rc
}

cleanup() {
  hr "CLEANUP"
  kind delete cluster --name devsecops-ci 2>/dev/null
  docker rm -f "$REGISTRY_NAME" 2>/dev/null
  docker images --format '{{.Repository}}:{{.Tag}}' \
    | grep -E '^(passguard|localhost:5056/bypratyush/passguard):' \
    | xargs -r docker image rm -f >/dev/null 2>&1
  echo "act containers left: $(docker ps -a --format '{{.Names}}' | grep -c '^act-')"
  echo "kind clusters: $(kind get clusters 2>/dev/null | tr '\n' ' ')"
}

report() {  # report <red|green> - the key lines of a saved run
  grep -E 'Job (succeeded|failed)$|\| (CONTROL|SAST |SCA |Secrets |Image |  \[|SECURITY GATE)|pushed |deployment.apps/passguard (created|successfully)|passguard-[a-z0-9]+-[a-z0-9]+ +1/1|"commit"|"label"|GET / ->|violates PodSecurity|Deleting cluster' "$LOGS/$1.log" \
    | sed -E 's/^\[S17 DevSecOps - PassGuard\//[/; s/ +\]/]/' | cut -c1-150
}

case "${1:-all}" in
  report)  report "${2:-green}" ;;
  red)     red ;;
  green)   green ;;
  cleanup) cleanup ;;
  all)     red; green; cleanup ;;
  *) echo "usage: $0 [red|green|cleanup|all]"; exit 2 ;;
esac
