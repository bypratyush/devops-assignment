#!/usr/bin/env bash
# Docker Fundamentals - images, containers, lifecycle, ports, env, limits, logs.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }

cleanup_containers() {
  docker rm -f demo-node demo-py demo-detached demo-restart demo-limits >/dev/null 2>&1 || true
}

verify() {
  cleanup_containers

  hr "1. IMAGE vs CONTAINER - the distinction everything rests on"
  echo "  IMAGE     = a read-only template (a filesystem + metadata). Like a class."
  echo "  CONTAINER = a running instance of an image, with a thin writable layer"
  echo "              on top. Like an object."
  echo
  echo "  One image -> many containers, each isolated from the others."

  hr "2. BUILD two small apps"
  docker build -q -t demo/node-app:1.0 ./node-app >/dev/null && echo "  built demo/node-app:1.0"
  docker build -q -t demo/python-app:1.0 ./python-app >/dev/null && echo "  built demo/python-app:1.0"
  echo
  docker images --filter=reference='demo/*' --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'

  hr "3. RUN a container and publish a port"
  echo "\$ docker run -d --name demo-node -p 3000:3000 demo/node-app:1.0"
  docker run -d --name demo-node -p 3000:3000 demo/node-app:1.0 >/dev/null
  sleep 2
  docker ps --filter name=demo-node --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
  echo
  echo "  -d  detached (background)    --name  a stable name instead of a random one"
  echo "  -p HOST:CONTAINER  publish a port"
  echo
  echo "  -p 3000:3000 means: traffic to localhost:3000 on the HOST is forwarded"
  echo "  to port 3000 INSIDE the container. Without -p the port is unreachable"
  echo "  from outside, even though the process is listening."
  sub "proof it works"
  curl -s --max-time 5 http://localhost:3000/hello | sed 's/^/  /'

  hr "4. ENVIRONMENT VARIABLES and a second container from the SAME image"
  # host port 5001, not 5000: on macOS the AirPlay Receiver already listens on 5000.
  echo "\$ docker run -d --name demo-py -p 5001:5000 -e APP_NAME=custom-name demo/python-app:1.0"
  echo "  (host port 5001 because macOS AirPlay Receiver already owns 5000 -"
  echo "   the HOST port must be free, the CONTAINER port does not care)"
  docker run -d --name demo-py -p 5001:5000 -e APP_NAME=custom-name demo/python-app:1.0 >/dev/null
  sleep 2
  curl -s --max-time 5 http://localhost:5001/ | sed 's/^/  /'
  echo
  echo "  APP_NAME came from -e, overriding the ENV baked into the image."
  echo "  This is how one image serves dev, staging and prod: same artifact,"
  echo "  different configuration injected at runtime."

  hr "5. THE CONTAINER LIFECYCLE"
  echo "  created -> running -> paused -> stopped -> removed"
  echo
  docker run -d --name demo-detached demo/node-app:1.0 >/dev/null
  sleep 1
  printf "  %-28s %s\n" "after run"    "$(docker inspect -f '{{.State.Status}}' demo-detached)"
  docker pause demo-detached >/dev/null
  printf "  %-28s %s\n" "after pause"  "$(docker inspect -f '{{.State.Status}}' demo-detached)"
  docker unpause demo-detached >/dev/null
  printf "  %-28s %s\n" "after unpause" "$(docker inspect -f '{{.State.Status}}' demo-detached)"
  STOP_START=$(date +%s)
  docker stop demo-detached >/dev/null
  STOP_SECS=$(( $(date +%s) - STOP_START ))
  EXITCODE=$(docker inspect -f '{{.State.ExitCode}}' demo-detached)
  printf "  %-28s %s (exit %s, took %ss)\n" "after stop" \
    "$(docker inspect -f '{{.State.Status}}' demo-detached)" "$EXITCODE" "$STOP_SECS"
  if [ "$EXITCODE" = "137" ]; then
    echo
    echo "  >>> EXIT 137 = 128 + 9 = SIGKILL, and the stop took ~${STOP_SECS}s."
    echo "      docker stop sends SIGTERM first and waits 10s. This app never"
    echo "      installs a SIGTERM handler, so it ignored it and Docker had to"
    echo "      SIGKILL it. A clean shutdown would exit 0 almost instantly."
    echo "      In production that means dropped in-flight requests on every deploy."
  fi
  docker start demo-detached >/dev/null
  sleep 1
  printf "  %-28s %s\n" "after start (restarted)" "$(docker inspect -f '{{.State.Status}}' demo-detached)"
  echo
  echo "  A STOPPED container still exists - its writable layer is on disk and"
  echo "  'docker start' brings it back. It is gone only after 'docker rm'."
  sub "docker ps -a shows stopped containers too"
  docker ps -a --filter name=demo- --format 'table {{.Names}}\t{{.Status}}' | head -6

  hr "6. LOGS"
  echo "\$ docker logs demo-node"
  docker logs demo-node 2>&1 | head -4 | sed 's/^/  /'
  curl -s -o /dev/null http://localhost:3000/logged-request
  sleep 1
  echo
  echo "  docker logs captures the container's STDOUT and STDERR."
  echo "  That is why containerised apps should log to stdout, NOT to a file:"
  echo "  a log file inside a container disappears with the container."
  echo
  echo "  docker logs -f <c>          follow live"
  echo "  docker logs --tail 50 <c>   last 50 lines"
  echo "  docker logs --since 10m <c> recent only"

  hr "7. EXEC - get a shell inside a running container"
  echo "\$ docker exec demo-node hostname"
  docker exec demo-node hostname | sed 's/^/  /'
  echo "\$ docker exec demo-node ps -o pid,comm"
  docker exec demo-node ps -o pid,comm 2>/dev/null | head -4 | sed 's/^/  /'
  echo
  echo "  NOTE: the app is PID 1 inside the container. There is no init system,"
  echo "  so PID 1 must handle SIGTERM itself or 'docker stop' will wait the full"
  echo "  10s grace period and then SIGKILL it."
  echo
  echo "\$ docker exec demo-node whoami"
  docker exec demo-node whoami | sed 's/^/  /'
  echo "  ^ not root, because the Dockerfile sets USER node."

  hr "8. INSPECT - everything Docker knows about a container"
  docker inspect demo-node --format '  image     : {{.Config.Image}}
  status    : {{.State.Status}}
  pid       : {{.State.Pid}}
  ip        : {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}
  ports     : {{json .NetworkSettings.Ports}}
  user      : {{.Config.User}}
  cmd       : {{json .Config.Cmd}}'

  hr "9. RESOURCE LIMITS - a container is NOT limited by default"
  echo "\$ docker run -d --name demo-limits --memory=64m --cpus=0.5 demo/node-app:1.0"
  docker run -d --name demo-limits --memory=64m --cpus=0.5 demo/node-app:1.0 >/dev/null
  sleep 1
  docker inspect demo-limits --format '  memory limit : {{.HostConfig.Memory}} bytes
  cpu quota    : {{.HostConfig.NanoCpus}} nano-cpus (1e9 = 1 core)'
  echo
  sub "docker stats (live resource usage, one sample)"
  docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}' \
    demo-node demo-py demo-limits 2>/dev/null
  echo
  echo "  Without --memory a container can consume ALL host RAM and take the"
  echo "  machine down. This is what Kubernetes resource limits map onto."

  hr "10. RESTART POLICIES"
  docker run -d --name demo-restart --restart=on-failure:3 demo/node-app:1.0 >/dev/null
  docker inspect demo-restart --format '  restart policy: {{.HostConfig.RestartPolicy.Name}} (max {{.HostConfig.RestartPolicy.MaximumRetryCount}} retries)'
  echo
  echo "    no              default - never restart"
  echo "    on-failure[:N]  restart only on a non-zero exit, at most N times"
  echo "    always          always restart, including on daemon start"
  echo "    unless-stopped  like always, but not if you stopped it manually"

  hr "11. CLEANING UP"
  echo "  docker stop \$(docker ps -q)      stop all running"
  echo "  docker rm -f \$(docker ps -aq)    force remove all"
  echo "  docker rmi \$(docker images -q)   remove all images"
  echo "  docker system prune -a           remove everything unused  <-- destructive"
  echo "  docker system df                 what is using disk"
  echo
  sub "docker system df"
  docker system df 2>/dev/null | head -5
  echo
  sub "removing this demo's containers"
  docker rm -f demo-node demo-py demo-detached demo-restart demo-limits 2>/dev/null | sed 's/^/  removed /'

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  cleanup_containers
  docker rmi -f demo/node-app:1.0 demo/python-app:1.0 2>/dev/null
  echo "containers and images removed"
}

case "${1:-all}" in
  all|verify) verify ;;
  cleanup) cleanup ;;
  *) echo "usage: $0 [all|cleanup]"; exit 1 ;;
esac
