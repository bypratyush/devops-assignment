#!/usr/bin/env bash
# gitops.sh - how to reach Argo CD and the in-cluster Git server (Gitea).
#
# Both were installed on the kind cluster `devops-hw` by
# monitoring-observability-gitops/03-gitops/run.sh and are left running so later
# sessions (the final project) can reuse them. Nothing here is exposed outside
# the cluster; everything is reached through kubectl port-forward.
#
#   ./lab/gitops.sh info       URLs and the demo credentials
#   ./lab/gitops.sh status     pods, services and Applications
#   ./lab/gitops.sh password   Argo CD admin password
#   ./lab/gitops.sh ui         Argo CD UI  -> https://localhost:18443   (Ctrl-C stops it)
#   ./lab/gitops.sh git        Gitea       -> http://localhost:13300    (Ctrl-C stops it)
#   ./lab/gitops.sh both       both port-forwards at once               (Ctrl-C stops them)
#   ./lab/gitops.sh login      argocd CLI login (needs `ui` or `both` running in another tab)
#
# The credentials below are demo-only, for a throwaway local cluster.
set -u

ARGO_PORT=18443
GITEA_PORT=13300
GIT_USER=gitops
GIT_PASS=gitops-demo-pass

password() { kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo; }

info() {
  cat <<EOF
Argo CD (namespace argocd, v3.5.4)
  UI / API      https://localhost:$ARGO_PORT   (after: ./lab/gitops.sh ui)   self-signed cert
  user          admin
  password      ./lab/gitops.sh password      (secret argocd-initial-admin-secret)
  webhook       https://argocd-server.argocd.svc.cluster.local/api/webhook
                secret key webhook.gogs.secret in argocd-secret (demo value: gitops-demo-webhook-secret)

Gitea (namespace git-server, 28.1.0, SQLite on a 1Gi local-path PVC)
  from the Mac  http://localhost:$GITEA_PORT   (after: ./lab/gitops.sh git)
  in-cluster    http://gitea.git-server.svc.cluster.local:3000/<owner>/<repo>.git   <- use this as repoURL in Argo CD
  user          $GIT_USER / $GIT_PASS   (site admin of this Gitea only)
  push example  git remote add origin http://$GIT_USER:$GIT_PASS@localhost:$GITEA_PORT/$GIT_USER/<repo>.git
  new repo      curl -u $GIT_USER:$GIT_PASS -H 'Content-Type: application/json' \\
                  -X POST http://localhost:$GITEA_PORT/api/v1/user/repos -d '{"name":"<repo>","default_branch":"main"}'
EOF
}

status() {
  kubectl -n argocd get pods
  echo
  kubectl -n git-server get pods,svc,pvc
  echo
  kubectl -n argocd get applications 2>&1
}

pf_argo()  { kubectl -n argocd     port-forward svc/argocd-server "$ARGO_PORT:443"; }
pf_gitea() { kubectl -n git-server port-forward svc/gitea         "$GITEA_PORT:3000"; }

case "${1:-info}" in
  info)     info ;;
  status)   status ;;
  password) password ;;
  ui)       echo "Argo CD -> https://localhost:$ARGO_PORT  (admin / $(password))"; pf_argo ;;
  git)      echo "Gitea   -> http://localhost:$GITEA_PORT  ($GIT_USER / $GIT_PASS)"; pf_gitea ;;
  both)     pf_gitea & trap 'kill $! 2>/dev/null' EXIT
            echo "Gitea -> http://localhost:$GITEA_PORT   Argo CD -> https://localhost:$ARGO_PORT"; pf_argo ;;
  login)    argocd login "localhost:$ARGO_PORT" --username admin --password "$(password)" --insecure --grpc-web ;;
  *)        sed -n '2,20p' "$0"; exit 1 ;;
esac
