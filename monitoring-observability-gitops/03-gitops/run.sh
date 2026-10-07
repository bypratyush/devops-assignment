#!/usr/bin/env bash
# Session 20 - Task 3: GitOps with Argo CD, using a Git server inside the cluster
# as the source of truth.
#
# Usage: ./run.sh [install|repo|app|demo|history|ui-shots|cleanup|uninstall|all]
#   install   Argo CD v3.5.4 (namespace argocd) + Gitea (namespace git-server)
#   repo      create the Git repo in Gitea and push gitops-repo/app as the first commit
#   app       apply application.yaml and wait for the first sync
#   demo      Git change by polling, Git change by webhook, drift + self-heal,
#             bad commit + git revert, prune
#   history   argocd app history / app get / git log
#   ui-shots  headless-Chrome screenshots of the Argo CD and Gitea UIs
#   cleanup   delete the demo Application and its namespace (Argo CD + Gitea stay)
#   uninstall remove Argo CD and Gitea completely (not run in the demo)
#   all       install + repo + app + demo + history   (default)
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
HERE=$(pwd)

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

# --- demo-only settings (nothing here is a real secret) ---------------------
GIT_USER=gitops
GIT_PASS=gitops-demo-pass
GIT_EMAIL=gitops@example.local
REPO=gitops-demo
GITEA_PORT=13300                       # localhost -> svc/gitea:3000
ARGO_PORT=18443                        # localhost -> svc/argocd-server:443
GITEA_API="http://localhost:$GITEA_PORT/api/v1"
PUSH_URL="http://$GIT_USER:$GIT_PASS@localhost:$GITEA_PORT/$GIT_USER/$REPO.git"
WEBHOOK_URL="https://argocd-server.argocd.svc.cluster.local/api/webhook"
WEBHOOK_SECRET=gitops-demo-webhook-secret
APP=gitops-demo                        # Argo CD Application name
NS=gitops-demo                         # where the app is deployed
CLONE="${TMPDIR:-/tmp}/gitops-demo-clone"
PF_PIDS=""

stop_port_forwards() { for p in $PF_PIDS; do kill "$p" 2>/dev/null; done; PF_PIDS=""; }
trap stop_port_forwards EXIT

# port_forward <namespace> <service> <local:remote> <url-to-probe>
port_forward() {
  kubectl -n "$1" port-forward "svc/$2" "$3" >/dev/null 2>&1 &
  PF_PIDS="$PF_PIDS $!"
  for _ in $(seq 1 30); do curl -sk -o /dev/null "$4" && return 0; sleep 1; done
  echo "port-forward to $1/$2 did not come up"; return 1
}
gitea_pf() { curl -s -o /dev/null "http://localhost:$GITEA_PORT/api/healthz" || port_forward git-server gitea "$GITEA_PORT:3000" "http://localhost:$GITEA_PORT/api/healthz"; }
argo_pf()  { curl -sk -o /dev/null "https://localhost:$ARGO_PORT/healthz"  || port_forward argocd argocd-server "$ARGO_PORT:443" "https://localhost:$ARGO_PORT/healthz"; }

argo_login() {
  argo_pf || return 1
  local pw
  pw=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
  argocd login "localhost:$ARGO_PORT" --username admin --password "$pw" --insecure --grpc-web
}

# --- small helpers for measuring how long reconciliation takes --------------
# wait_until <max-seconds> <command...>: polls once a second, sets ELAPSED
wait_until() {
  local max=$1; shift
  local start; start=$(date +%s)
  until "$@" >/dev/null 2>&1; do
    if [ $(( $(date +%s) - start )) -ge "$max" ]; then ELAPSED="TIMEOUT(${max}s)"; return 1; fi
    sleep 1
  done
  ELAPSED=$(( $(date +%s) - start ))
}
app_field()      { kubectl -n argocd get application "$APP" -o jsonpath="$1" 2>/dev/null; }
synced_to()      { [ "$(app_field '{.status.sync.revision}')" = "$1" ] && [ "$(app_field '{.status.sync.status}')" = "Synced" ]; }
health_is()      { [ "$(app_field '{.status.health.status}')" = "$1" ]; }
replicas_are()   { [ "$(kubectl -n $NS get deploy web -o jsonpath='{.spec.replicas}')" = "$1" ]; }
page_has()       { kubectl -n $NS get configmap web-content -o jsonpath='{.data.index\.html}' | grep -q "$1"; }
svc_exists()     { kubectl -n $NS get svc web; }
cm_exists()      { kubectl -n $NS get configmap "$1"; }
cm_gone()        { ! kubectl -n $NS get configmap "$1"; }
rolled_out()     { kubectl -n $NS rollout status deploy/web --timeout=2s; }
pod_count_is()   { [ "$(kubectl -n $NS get pods -l app.kubernetes.io/name=web --no-headers | wc -l | tr -d ' ')" = "$1" ]; }

app_status() {
  kubectl -n argocd get application "$APP" \
    -o custom-columns='APP:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision'
}
page() { kubectl -n $NS exec deploy/web -c nginx -- wget -qO- http://localhost/ 2>/dev/null; }

# Screenshots taken mid-demo, only when SHOTS=1 (silent so output.md stays clean)
snap() { # <out.png> <command...>  - termshot of a real command
  [ "${SHOTS:-0}" = 1 ] || return 0
  local out=$1; shift
  WIDTH="${W:-130}" ../../lab/shot.sh "$HERE/screenshots/$out" "$@" >/dev/null 2>&1
}
argo_token() {
  local pw; pw=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)
  curl -sk -H 'Content-Type: application/json' -X POST "https://localhost:$ARGO_PORT/api/v1/session" \
    -d "{\"username\":\"admin\",\"password\":\"$pw\"}" | jq -r .token
}
ui_one() { # <out.png> <argocd-path> [width] [height]  - headless Chrome over CDP
  [ "${SHOTS:-0}" = 1 ] || [ "${FORCE_UI:-0}" = 1 ] || return 0
  node ui-shot.mjs "https://localhost:$ARGO_PORT/$2" "$HERE/screenshots/$1" "${3:-1750}" "${4:-760}" 8000 \
    "argocd.token=$(argo_token)" >/dev/null 2>&1
}

# commit_and_push "<message>": commits whatever changed in the clone and pushes
commit_and_push() {
  git -C "$CLONE" add -A
  git -C "$CLONE" commit -q -m "$1"
  git -C "$CLONE" push -q origin main 2>&1 | grep -v '^remote: *$'
  PUSHED_AT=$(date +%s)
  SHA=$(git -C "$CLONE" rev-parse HEAD)
  echo "pushed $(git -C "$CLONE" log -1 --format='%h  %s')"
}

# ============================================================================
install() {
  hr "STEP 1 - Install Argo CD v3.5.4 (pinned manifest + kustomize patch) in namespace argocd"
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply --server-side --force-conflicts -k argocd/ > "${TMPDIR:-/tmp}/argocd-apply.txt" 2>&1
  echo "objects applied: $(wc -l < "${TMPDIR:-/tmp}/argocd-apply.txt" | tr -d ' ')"
  grep -E 'customresourcedefinition|configmap/argocd-cm ' "${TMPDIR:-/tmp}/argocd-apply.txt"
  for d in argocd-redis argocd-repo-server argocd-server argocd-dex-server argocd-applicationset-controller argocd-notifications-controller; do
    kubectl -n argocd rollout status deploy/$d --timeout=300s
  done
  kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s
  echo
  kubectl -n argocd get pods
  echo
  echo "--- argocd-cm (reconciliation settings from the kustomize patch) ---"
  kubectl -n argocd get configmap argocd-cm -o jsonpath='timeout.reconciliation={.data.timeout\.reconciliation}  timeout.reconciliation.jitter={.data.timeout\.reconciliation\.jitter}{"\n"}'
  echo "--- image actually running ---"
  kubectl -n argocd get deploy argocd-server -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

  hr "STEP 2 - Install the Git server (Gitea, SQLite) in namespace git-server"
  kubectl apply -f git-server/gitea.yaml
  kubectl -n git-server rollout status deploy/gitea --timeout=300s
  kubectl -n git-server get pods,svc,pvc
  echo
  echo "--- create the demo Git user (admin of this Gitea only) ---"
  kubectl -n git-server exec deploy/gitea -- gitea admin user create \
    --username "$GIT_USER" --password "$GIT_PASS" --email "$GIT_EMAIL" \
    --admin --must-change-password=false 2>&1 | grep -v '^$' | tail -2
  kubectl -n git-server exec deploy/gitea -- gitea --version
}

# ============================================================================
repo() {
  gitea_pf || return 1
  hr "STEP 3 - Create the GitOps repo in Gitea (the source of truth)"
  curl -s -o /dev/null -u "$GIT_USER:$GIT_PASS" -X DELETE "$GITEA_API/repos/$GIT_USER/$REPO"   # start from a clean repo
  curl -s -u "$GIT_USER:$GIT_PASS" -H 'Content-Type: application/json' -X POST "$GITEA_API/user/repos" \
    -d "{\"name\":\"$REPO\",\"private\":false,\"default_branch\":\"main\",\"description\":\"GitOps source of truth for the session 20 demo\"}" \
    | jq '{full_name, private, default_branch, clone_url}'

  hr "STEP 4 - Push the manifests (gitops-repo/app) as the first commit"
  rm -rf "$CLONE"; mkdir -p "$CLONE"
  cp -R gitops-repo/app "$CLONE/app"
  git -C "$CLONE" init -q -b main
  git -C "$CLONE" config user.name "Pratyush Mohanty"
  git -C "$CLONE" config user.email "$GIT_EMAIL"
  git -C "$CLONE" remote add origin "$PUSH_URL"
  commit_and_push "Initial commit: web v1, 2 replicas, nginx 1.28.0"
  echo
  (cd "$CLONE" && find app -type f | sort)
  echo
  echo "--- what Gitea now holds ---"
  git -C "$CLONE" ls-remote origin
  sleep 2
  curl -s "$GITEA_API/repos/$GIT_USER/$REPO/contents/app?ref=main" | jq -r '.[] | "  \(.path)  \(.size) bytes"'
}

# ============================================================================
app() {
  argo_login || return 1
  hr "STEP 5 - Create the Argo CD Application (automated sync + prune + selfHeal)"
  gitea_pf || return 1
  local sha; sha=$(git ls-remote "$PUSH_URL" refs/heads/main | cut -f1)
  kubectl apply -f application.yaml
  local t0; t0=$(date +%s)
  wait_until 180 synced_to "$sha"; echo "synced to Git HEAD ${sha:0:7} after ${ELAPSED}s"
  wait_until 180 health_is Healthy; echo "Healthy after $(( $(date +%s) - t0 ))s total"
  echo
  app_status
  echo
  argocd app get "$APP"
  echo
  echo "--- what Argo CD created (nobody ran kubectl apply on these) ---"
  kubectl -n $NS get deploy,rs,pods,svc,configmap -l app.kubernetes.io/name=web -o wide
  echo
  echo "page served: $(page)"
}

# ============================================================================
demo() {
  argo_login >/dev/null || return 1
  gitea_pf || return 1

  hr "STEP 6 - Git change #1 (replicas 2 -> 3), NO webhook: Argo CD finds it by polling"
  echo "timeout.reconciliation = $(kubectl -n argocd get cm argocd-cm -o jsonpath='{.data.timeout\.reconciliation}'), so the controller re-reads Git at most this often"
  sed -i '' 's/^  replicas: 2$/  replicas: 3/' "$CLONE/app/deployment.yaml"
  git -C "$CLONE" diff --stat
  commit_and_push "Scale web to 3 replicas"
  wait_until 240 synced_to "$SHA"; echo "Argo CD synced ${SHA:0:7}  ${ELAPSED}s after git push   (polling)"
  wait_until 120 rolled_out;       echo "rollout complete            $(( $(date +%s) - PUSHED_AT ))s after git push"
  kubectl -n $NS get deploy web
  echo
  echo "--- application-controller log: the periodic refresh that picked it up ---"
  kubectl -n argocd logs statefulset/argocd-application-controller --since=5m 2>/dev/null \
    | grep 'comparison expired' | tail -1 | jq -r '"\(.time)  \(.msg)"'

  hr "STEP 7 - Add a Gitea push webhook -> Argo CD, so Git tells Argo CD immediately"
  kubectl -n argocd patch secret argocd-secret --type merge \
    -p "{\"stringData\":{\"webhook.gogs.secret\":\"$WEBHOOK_SECRET\"}}"
  curl -s -u "$GIT_USER:$GIT_PASS" -H 'Content-Type: application/json' -X POST "$GITEA_API/repos/$GIT_USER/$REPO/hooks" \
    -d "{\"type\":\"gitea\",\"active\":true,\"events\":[\"push\"],\"branch_filter\":\"main\",\"config\":{\"url\":\"$WEBHOOK_URL\",\"content_type\":\"json\",\"secret\":\"$WEBHOOK_SECRET\"}}" \
    | jq '{id, type, active, events, url: .config.url}'

  hr "STEP 8 - Git change #2 (new image + new page content), WITH webhook"
  sed -i '' 's/nginx:1.28.0-alpine/nginx:1.29.0-alpine/' "$CLONE/app/deployment.yaml"
  sed -i '' 's/gitops-demo\/config-version: "v1"/gitops-demo\/config-version: "v2"/' "$CLONE/app/deployment.yaml"
  sed -i '' 's/version=v1 message="hello from git"/version=v2 message="changed by a git commit"/' "$CLONE/app/configmap.yaml"
  git -C "$CLONE" --no-pager diff -U0 | grep -E '^[-+][^-+]'
  commit_and_push "Upgrade nginx to 1.29.0 and publish page v2"
  wait_until 240 synced_to "$SHA"; echo "Argo CD synced ${SHA:0:7}  ${ELAPSED}s after git push   (webhook)"
  wait_until 180 rolled_out;       echo "rollout complete            $(( $(date +%s) - PUSHED_AT ))s after git push"
  wait_until 60 pod_count_is 3
  kubectl -n $NS get pods -l app.kubernetes.io/name=web \
    -o custom-columns='POD:.metadata.name,IMAGE:.spec.containers[0].image,READY:.status.containerStatuses[0].ready'
  echo "page served: $(page)"
  echo
  echo "--- argocd-server log: the webhook arriving ---"
  kubectl -n argocd logs deploy/argocd-server --since=5m 2>/dev/null | grep -iE 'push event|refresh' | tail -3 | cut -c1-220

  hr "STEP 9 - Drift #1: someone runs 'kubectl scale' by hand (Git says 3)"
  kubectl -n $NS scale deploy web --replicas=6
  echo "spec.replicas right after the manual change: $(kubectl -n $NS get deploy web -o jsonpath='{.spec.replicas}')"
  wait_until 120 replicas_are 3; echo "self-heal put it back to 3 after ${ELAPSED}s"
  kubectl -n $NS get deploy web
  echo
  echo "--- Deployment events: scaled to 6 by hand, back to 3 by Argo CD ---"
  kubectl -n $NS get events --field-selector involvedObject.kind=Deployment,reason=ScalingReplicaSet \
    --sort-by=.lastTimestamp -o custom-columns='REASON:.reason,MESSAGE:.message' | tail -2

  hr "STEP 10 - Drift #2: someone edits the live ConfigMap by hand"
  kubectl -n $NS patch configmap web-content --type merge -p '{"data":{"index.html":"hot-fixed by hand in production\n"}}'
  echo "live ConfigMap now: $(kubectl -n $NS get cm web-content -o jsonpath='{.data.index\.html}')"
  wait_until 120 page_has 'version=v2'; echo "self-heal restored the Git version after ${ELAPSED}s"
  echo "live ConfigMap now: $(kubectl -n $NS get cm web-content -o jsonpath='{.data.index\.html}')"

  hr "STEP 11 - Drift #3: someone deletes the Service"
  echo "Service UID before: $(kubectl -n $NS get svc web -o jsonpath='{.metadata.uid}')"
  kubectl -n $NS delete svc web
  wait_until 120 svc_exists; echo "Service re-created by Argo CD after ${ELAPSED}s"
  echo "Service UID after:  $(kubectl -n $NS get svc web -o jsonpath='{.metadata.uid}')   <- a new object"
  echo
  echo "--- Argo CD events: every self-heal is a normal sync it started itself ---"
  kubectl -n argocd get events --field-selector involvedObject.name=$APP --sort-by=.lastTimestamp \
    -o custom-columns='REASON:.reason,MESSAGE:.message' | grep -E '^REASON|^Operation' | tail -7 | cut -c1-150

  hr "STEP 12 - A bad commit: typo in the image tag"
  sed -i '' 's/nginx:1.29.0-alpine/nginx:1.29.0-alpne/' "$CLONE/app/deployment.yaml"
  git -C "$CLONE" --no-pager diff -U0 | grep -E '^[-+][^-+]'
  commit_and_push "Bump nginx image (typo)"
  wait_until 120 synced_to "$SHA"; echo "Argo CD synced the bad commit ${SHA:0:7} after ${ELAPSED}s - Git is the truth, even when wrong"
  echo "waiting for the Deployment's progressDeadlineSeconds (60s) to expire ..."
  wait_until 180 health_is Degraded; echo "app health is Degraded $(( $(date +%s) - PUSHED_AT ))s after the push"
  app_status
  echo
  kubectl -n $NS get pods -l app.kubernetes.io/name=web \
    -o custom-columns='POD:.metadata.name,IMAGE:.spec.containers[0].image,READY:.status.containerStatuses[0].ready,WAITING:.status.containerStatuses[0].state.waiting.reason'
  echo
  echo "old pods are still serving (rolling update never removed them): $(page)"
  snap bad-commit-degraded.png kubectl -n $NS get pods -l app.kubernetes.io/name=web \
    -o custom-columns='POD:.metadata.name,IMAGE:.spec.containers[0].image,READY:.status.containerStatuses[0].ready,WAITING:.status.containerStatuses[0].state.waiting.reason'
  ui_one argocd-app-degraded.png "applications/argocd/$APP?view=tree"

  hr "STEP 13 - Roll back the GitOps way: git revert, not kubectl"
  git -C "$CLONE" revert --no-edit HEAD >/dev/null
  git -C "$CLONE" push -q origin main 2>&1 | grep -v '^remote: *$'
  PUSHED_AT=$(date +%s); SHA=$(git -C "$CLONE" rev-parse HEAD)
  echo "pushed $(git -C "$CLONE" log -1 --format='%h  %s')"
  wait_until 120 synced_to "$SHA";   echo "Argo CD synced the revert ${SHA:0:7} after ${ELAPSED}s"
  wait_until 180 health_is Healthy;  echo "app Healthy again $(( $(date +%s) - PUSHED_AT ))s after the push"
  app_status
  kubectl -n $NS get pods -l app.kubernetes.io/name=web \
    -o custom-columns='POD:.metadata.name,IMAGE:.spec.containers[0].image,READY:.status.containerStatuses[0].ready'

  hr "STEP 14 - Prune: a resource removed from Git is removed from the cluster"
  cat > "$CLONE/app/feature-flags.yaml" <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
  labels:
    app.kubernetes.io/name: web
data:
  new-checkout: "false"
EOF
  commit_and_push "Add feature-flags ConfigMap"
  wait_until 120 cm_exists feature-flags; echo "feature-flags created $(( $(date +%s) - PUSHED_AT ))s after the push"
  git -C "$CLONE" rm -q app/feature-flags.yaml
  commit_and_push "Remove feature-flags ConfigMap (no longer used)"
  wait_until 120 cm_gone feature-flags;   echo "feature-flags pruned  $(( $(date +%s) - PUSHED_AT ))s after the push"
  kubectl -n $NS get configmap
}

# ============================================================================
show_history() {
  argo_login >/dev/null || return 1
  hr "STEP 15 - History: Git log vs what Argo CD deployed"
  echo "--- git log (the source of truth) ---"
  git -C "$CLONE" --no-pager log --format='%h  %s'
  echo
  echo "--- argocd app history (every revision Argo CD synced) ---"
  argocd app history "$APP"
  echo
  echo "--- argocd app get ---"
  argocd app get "$APP"
  echo
  echo "--- rollback through Argo CD is refused while auto-sync is on ---"
  argocd app rollback "$APP" 1 2>&1 | tail -1 | cut -c1-200
}

# ============================================================================
ui_shots() {
  argo_pf || return 1; gitea_pf || return 1
  hr "UI screenshots (headless Chrome over CDP, logged in with an Argo CD session cookie)"
  FORCE_UI=1
  ui_one argocd-app-tree.png    "applications/argocd/$APP?view=tree";            echo "  screenshots/argocd-app-tree.png"
  ui_one argocd-app-list.png    "applications" 1300 560;                         echo "  screenshots/argocd-app-list.png"
  ui_one argocd-app-history.png "applications/argocd/$APP?view=tree&rollback=0" 1500 800; echo "  screenshots/argocd-app-history.png"
  node ui-shot.mjs "http://localhost:$GITEA_PORT/$GIT_USER/$REPO/commits/branch/main" "$HERE/screenshots/gitea-commits.png" 1200 740 4000
}

# ============================================================================
delete_demo_app() {
  kubectl -n argocd delete application "$APP" --ignore-not-found --wait=true --timeout=120s
  echo "left in $NS after deleting only the Application: $(kubectl -n $NS get deploy,svc,configmap -l app.kubernetes.io/name=web --no-headers 2>/dev/null | wc -l | tr -d ' ') objects"
  # CreateNamespace=true namespaces are not tracked, so Argo CD leaves them behind
  kubectl delete namespace "$NS" --ignore-not-found --wait=true --timeout=120s
  rm -rf "$CLONE"
}

cleanup() {
  hr "CLEANUP - delete the demo Application (its finalizer deletes what it created)"
  echo "--- before: resources owned by the Application ---"
  kubectl -n $NS get deploy,svc,configmap -l app.kubernetes.io/name=web 2>&1
  echo
  delete_demo_app
  echo
  echo "namespace $NS: $(kubectl get ns $NS 2>&1 | tail -1)"
  echo
  echo "--- still installed for later sessions ---"
  kubectl -n argocd get pods
  echo
  kubectl -n git-server get pods
  echo
  kubectl -n argocd get applications 2>&1
}

uninstall() {
  hr "UNINSTALL - remove Argo CD and Gitea completely"
  delete_demo_app
  kubectl delete -k argocd/ --ignore-not-found >/dev/null
  kubectl delete namespace argocd --ignore-not-found
  kubectl delete -f git-server/gitea.yaml --ignore-not-found
}

case "${1:-all}" in
  install)   install ;;
  repo)      repo ;;
  app)       app ;;
  demo)      demo ;;
  history)   show_history ;;
  ui-shots)  ui_shots ;;
  cleanup)   cleanup ;;
  uninstall) uninstall ;;
  all)       install; repo; app; demo; show_history ;;
  *) echo "usage: $0 [install|repo|app|demo|history|ui-shots|cleanup|uninstall|all]"; exit 1 ;;
esac
