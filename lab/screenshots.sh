#!/usr/bin/env bash
# screenshots.sh - capture terminal screenshots for each topic.
#
# Each PNG is a real termshot capture of the command and its genuine output.
# Layout matches the convention used across this repo:
#   <topic>/screenshots/<lowercase-hyphenated-name>.png
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.."
ROOT=$(pwd)
SHOT="$ROOT/lab/shot.sh"
LAB="$ROOT/lab/lab.sh"

shot()     { WIDTH="${W:-120}" "$SHOT" "$@"; }
labshot()  { local out="$1"; shift; WIDTH="${W:-120}" "$SHOT" "$out" docker exec linux-lab bash -lc "$*"; }

echo "=== 01 linux-fundamentals ==="
"$LAB" up >/dev/null
"$LAB" exec 'rm -rf /root/shots && mkdir -p /root/shots && cd /root/shots && echo "hello from the original file" > original.txt && ln original.txt hardlink.txt && ln -s original.txt softlink.txt' >/dev/null 2>&1
W=110 labshot linux-fundamentals/screenshots/hard-vs-soft-link.png 'cd /root/shots && ls -li'
"$LAB" exec 'userdel -r shotuser 2>/dev/null; useradd shotuser; adduser --disabled-password --gecos "" shotuser2 >/dev/null 2>&1' >/dev/null 2>&1
W=120 labshot linux-fundamentals/screenshots/useradd-vs-adduser.png 'grep -E "^(shotuser|shotuser2):" /etc/passwd; ls -ld /home/shotuser /home/shotuser2 2>&1'
"$LAB" exec 'systemctl start nginx' >/dev/null 2>&1
W=130 labshot linux-fundamentals/screenshots/journalctl.png 'journalctl -u nginx --no-pager -n 8'
W=110 labshot linux-fundamentals/screenshots/basic-commands.png 'cd /root/shots && pwd && ls -lh && df -h / && free -h'
"$LAB" exec 'userdel -r shotuser 2>/dev/null; deluser --remove-home shotuser2 >/dev/null 2>&1; rm -rf /root/shots' >/dev/null 2>&1

echo "=== 02 shell-scripting ==="
W=110 labshot shell-scripting/screenshots/script-output.png 'cd /tmp && /work/shell-scripting/sysinfo.sh "Pratyush Mohanty" "24BCS10238" "DevOps homework" 2>&1 | head -24'
W=110 labshot shell-scripting/screenshots/saved-report.png 'cat /tmp/sysinfo-output/report.txt'

echo "=== 03 networking ==="
W=110 labshot networking/screenshots/subnet-calculations.png '/work/networking/subnet.sh 192.168.10.0/26'
W=120 labshot networking/screenshots/network-commands.png 'ip -brief addr; echo; ip route; echo; dig +short github.com'

echo "=== 04 git-and-github ==="
W=120 shot git-and-github/screenshots/git-workflow.png bash -c "cd \$(mktemp -d) && git init -q -b main . && git config user.name 'Pratyush Mohanty' && git config user.email p@example.com && echo a > a.txt && git add -A && git commit -qm 'Initial commit' && git switch -qc feature && echo b > b.txt && git add -A && git commit -qm 'Add feature' && git switch -q main && git merge -q --no-ff feature -m 'Merge feature' && git log --oneline --graph --all --decorate"

echo "=== 05 docker-fundamentals ==="
docker rm -f shot-node >/dev/null 2>&1
docker build -q -t demo/node-app:1.0 ./docker-fundamentals/node-app >/dev/null 2>&1
docker run -d --name shot-node -p 3000:3000 demo/node-app:1.0 >/dev/null 2>&1
sleep 2
W=130 shot docker-fundamentals/screenshots/running-container.png docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
W=110 shot docker-fundamentals/screenshots/container-inspect.png bash -c 'curl -s http://localhost:3000/hello; echo; docker logs shot-node'
docker rm -f shot-node >/dev/null 2>&1

echo "=== 06 docker-images ==="
W=110 shot docker-images/screenshots/image-sizes.png docker images --filter=reference='hellosvc' --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'
W=130 shot docker-images/screenshots/image-layers.png docker history hellosvc:alpine --format 'table {{.CreatedBy}}\t{{.Size}}'

echo "=== 07 docker-networking ==="
docker rm -f shot-a shot-b >/dev/null 2>&1; docker network rm shot-net >/dev/null 2>&1
docker network create shot-net >/dev/null 2>&1
docker run -d --name shot-a --network shot-net alpine:3.19 sleep 300 >/dev/null 2>&1
docker run -d --name shot-b --network shot-net alpine:3.19 sleep 300 >/dev/null 2>&1
sleep 2
W=110 shot docker-networking/screenshots/custom-network-dns.png docker exec shot-a ping -c2 shot-b
W=120 shot docker-networking/screenshots/docker-networks.png docker network ls
docker rm -f shot-a shot-b >/dev/null 2>&1; docker network rm shot-net >/dev/null 2>&1

echo "=== 08 kubernetes-fundamentals ==="
W=150 shot kubernetes-fundamentals/screenshots/cluster-nodes.png kubectl get nodes -o wide
W=120 shot kubernetes-fundamentals/screenshots/control-plane-pods.png kubectl get pods -n kube-system

echo "=== 09 pods-replicasets-deployments ==="
kubectl create deployment shot-demo --image=nginx:1.25-alpine --replicas=3 >/dev/null 2>&1
kubectl rollout status deployment/shot-demo --timeout=120s >/dev/null 2>&1
W=120 shot kubernetes-pods-replicasets-deployments/screenshots/deployment-hierarchy.png kubectl get deploy,rs,pods -l app=shot-demo
kubectl set image deployment/shot-demo nginx=nginx:1.27-alpine >/dev/null 2>&1
kubectl rollout status deployment/shot-demo --timeout=120s >/dev/null 2>&1
W=120 shot kubernetes-pods-replicasets-deployments/screenshots/rollout-history.png kubectl rollout history deployment/shot-demo
kubectl delete deployment shot-demo >/dev/null 2>&1
kubectl apply -f kubernetes-pods-replicasets-deployments/05-daemonset/daemonset-tolerating.yaml >/dev/null 2>&1
kubectl rollout status daemonset/node-agent-all --timeout=120s >/dev/null 2>&1
W=140 shot kubernetes-pods-replicasets-deployments/screenshots/daemonset-per-node.png kubectl get pods -l app=node-agent-all -o wide
kubectl delete -f kubernetes-pods-replicasets-deployments/05-daemonset/daemonset-tolerating.yaml >/dev/null 2>&1

echo "=== 10 kubernetes-networking-services ==="
( cd kubernetes-networking-services/01-clusterip && ./run.sh deploy >/dev/null 2>&1 )
W=130 shot kubernetes-networking-services/screenshots/clusterip-service.png kubectl get svc,endpointslices -l app=web-clusterip
W=120 shot kubernetes-networking-services/screenshots/service-dns-test.png kubectl exec curl-client -- curl -s -o /dev/null -w 'http://web-service-clusterip:8080 -> HTTP %{http_code}\n' http://web-service-clusterip:8080
( cd kubernetes-networking-services/01-clusterip && ./run.sh cleanup >/dev/null 2>&1 )

echo "=== 11 ingress-configmaps-secrets ==="
( cd kubernetes-ingress-configmaps-secrets && ./run.sh deploy >/dev/null 2>&1 )
W=130 shot kubernetes-ingress-configmaps-secrets/screenshots/ingress-rules.png kubectl get ingress,svc
W=120 shot kubernetes-ingress-configmaps-secrets/screenshots/ingress-routing.png bash -c "curl -s -H 'Host: app.local' http://localhost/ | head -4; echo; curl -s -H 'Host: second.local' http://localhost/ | head -4"
W=110 shot kubernetes-ingress-configmaps-secrets/screenshots/configmap-secret.png bash -c "kubectl get configmap app-config secret app-secret; echo; kubectl get secret app-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d; echo ' <- base64 decoded, NOT encrypted'"
( cd kubernetes-ingress-configmaps-secrets && ./run.sh cleanup >/dev/null 2>&1 )

echo "=== SCREENSHOTS COMPLETE ==="
find . -name '*.png' -path '*/screenshots/*' | sort | sed 's/^/  /'
