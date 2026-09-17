#!/usr/bin/env bash
# regen.sh - re-run every task script and rewrite its output.md.
# Guarantees each output.md is the genuine output of the script beside it.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.."
ROOT=$(pwd)
ATTR="> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238"
DATE=$(date '+%Y-%m-%d')

save() { # $1=title  $2=dest  $3=how  $4=tmpfile
  { echo "# $1 - Captured Output"; echo; echo "$ATTR"; echo
    echo "Produced by \`$3\` on $DATE."; echo
    echo '```text'; cat "$4"; echo '```'; } > "$2"
  printf "  %-62s %s lines\n" "$2" "$(wc -l < "$2" | tr -d ' ')"
}

lab() { "$ROOT/lab/lab.sh" exec "$1" ; }

echo "=== LAB (Ubuntu 22.04 container) ==="
"$ROOT/lab/lab.sh" up >/dev/null
for t in task-01-links task-02-adduser-vs-useradd task-03-journalctl task-04-command-cheatsheet; do
  lab "/work/linux-fundamentals/$t/practice.sh" > /tmp/r.txt 2>&1
  save "$t" "linux-fundamentals/$t/output.md" "./lab/lab.sh exec /work/linux-fundamentals/$t/practice.sh" /tmp/r.txt
done

lab '/work/shell-scripting/fundamentals.sh' > /tmp/shf.txt 2>&1
lab 'cd /tmp && /work/shell-scripting/sysinfo.sh "Pratyush Mohanty" "24BCS10238" "DevOps homework - session 3 shell scripting"' > /tmp/shs.txt 2>&1
{ echo "# Shell Scripting - Captured Output"; echo; echo "$ATTR"; echo
  echo "Run inside the Ubuntu 22.04 lab container on $DATE."; echo
  echo "## 1. \`sysinfo.sh\` - the assignment task"; echo; echo '```text'; cat /tmp/shs.txt; echo '```'; echo
  echo "## 2. \`fundamentals.sh\` - shell building blocks"; echo; echo '```text'; cat /tmp/shf.txt; echo '```'; } > shell-scripting/output.md
printf "  %-62s %s lines\n" "shell-scripting/output.md" "$(wc -l < shell-scripting/output.md | tr -d ' ')"

lab '/work/networking/subnet.sh'  > /tmp/sub.txt 2>&1
lab '/work/networking/netcmds.sh' > /tmp/net.txt 2>&1
{ echo "# Networking - Captured Output"; echo; echo "$ATTR"; echo
  echo "Run inside the Ubuntu 22.04 lab container on $DATE."; echo
  echo "## 1. \`subnet.sh\` - IP addressing and subnetting"; echo; echo '```text'; cat /tmp/sub.txt; echo '```'; echo
  echo "## 2. \`netcmds.sh\` - the networking commands"; echo; echo '```text'; cat /tmp/net.txt; echo '```'; } > networking/output.md
printf "  %-62s %s lines\n" "networking/output.md" "$(wc -l < networking/output.md | tr -d ' ')"

echo "=== LOCAL ==="
./git-and-github/git-demo.sh > /tmp/r.txt 2>&1
save "Git and GitHub" "git-and-github/output.md" "./git-demo.sh" /tmp/r.txt

echo "=== DOCKER ==="
./docker-fundamentals/run.sh all > /tmp/r.txt 2>&1
save "Docker Fundamentals" "docker-fundamentals/output.md" "./run.sh" /tmp/r.txt
./docker-images/run.sh all > /tmp/r.txt 2>&1
save "Docker Images" "docker-images/output.md" "./run.sh" /tmp/r.txt
./docker-networking/run.sh all > /tmp/r.txt 2>&1
save "Docker Networking" "docker-networking/output.md" "./run.sh" /tmp/r.txt

echo "=== KUBERNETES ==="
./kubernetes-fundamentals/run.sh all > /tmp/r.txt 2>&1
save "Kubernetes Fundamentals" "kubernetes-fundamentals/output.md" "./run.sh" /tmp/r.txt

for d in 01-pods 02-replicasets 03-deployments 04-deployment-strategies 05-daemonset; do
  B="kubernetes-pods-replicasets-deployments/$d"
  "$ROOT/$B/run.sh" cleanup >/dev/null 2>&1
  "$ROOT/$B/run.sh" all > /tmp/r.txt 2>&1
  save "${d#*-}" "$B/output.md" "./run.sh" /tmp/r.txt
  "$ROOT/$B/run.sh" cleanup >/dev/null 2>&1
done

for d in 01-clusterip 02-nodeport 03-loadbalancer 04-externalname 05-headless; do
  B="kubernetes-networking-services/$d"
  "$ROOT/$B/run.sh" cleanup >/dev/null 2>&1
  "$ROOT/$B/run.sh" all > /tmp/r.txt 2>&1
  save "${d#*-}" "$B/output.md" "./run.sh" /tmp/r.txt
  "$ROOT/$B/run.sh" cleanup >/dev/null 2>&1
done

./kubernetes-ingress-configmaps-secrets/run.sh cleanup >/dev/null 2>&1
./kubernetes-ingress-configmaps-secrets/run.sh all > /tmp/r.txt 2>&1
save "Ingress, ConfigMaps and Secrets" "kubernetes-ingress-configmaps-secrets/output.md" "./run.sh" /tmp/r.txt

echo "=== REGEN COMPLETE ==="
