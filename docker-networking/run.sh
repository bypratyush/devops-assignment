#!/usr/bin/env bash
# Docker Networking and Volumes - bridge, custom networks, host, none, DNS, volumes.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }

NAMES="net-a net-b net-default net-host net-none vol-writer vol-reader bind-demo"
wipe() {
  for c in $NAMES; do docker rm -f "$c" >/dev/null 2>&1 || true; done
  docker network rm app-net >/dev/null 2>&1 || true
  docker volume rm demo-data >/dev/null 2>&1 || true
}

verify() {
  wipe
  hr "1. THE DEFAULT BRIDGE NETWORK"
  docker network ls
  echo
  echo "  bridge  the default. Containers get an IP on docker0 and reach the"
  echo "          outside via NAT. NO automatic DNS between containers."
  echo "  host    no isolation at all: the container uses the host's stack."
  echo "  none    no networking whatsoever."
  echo
  docker run -d --name net-default alpine:3.19 sleep 600 >/dev/null
  sleep 1
  docker inspect net-default -f '  net-default ip: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}  gateway: {{range .NetworkSettings.Networks}}{{.Gateway}}{{end}}'

  hr "2. THE PROBLEM WITH THE DEFAULT BRIDGE: no DNS"
  docker run -d --name net-a --network bridge alpine:3.19 sleep 600 >/dev/null
  docker run -d --name net-b --network bridge alpine:3.19 sleep 600 >/dev/null
  sleep 1
  IP_B=$(docker inspect net-b -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
  echo "  net-b has IP $IP_B"
  echo
  echo "\$ docker exec net-a ping -c1 net-b     (by NAME)"
  docker exec net-a ping -c1 -W2 net-b 2>&1 | head -2 | sed 's/^/  /'
  echo
  echo "\$ docker exec net-a ping -c1 $IP_B   (by IP)"
  docker exec net-a ping -c1 -W2 "$IP_B" 2>&1 | head -2 | sed 's/^/  /'
  echo
  echo "  >>> By IP it works. By NAME it fails. The default bridge has no"
  echo "      service discovery, and container IPs change on every restart,"
  echo "      so you cannot hardcode them either."

  hr "3. THE FIX: a USER-DEFINED bridge network"
  docker network create app-net >/dev/null
  echo "\$ docker network create app-net"
  docker network inspect app-net -f '  subnet: {{range .IPAM.Config}}{{.Subnet}}{{end}}  driver: {{.Driver}}'
  echo
  docker network connect app-net net-a
  docker network connect app-net net-b
  echo "  connected net-a and net-b to app-net"
  echo
  echo "\$ docker exec net-a ping -c1 net-b     (by NAME, on the custom network)"
  docker exec net-a ping -c1 -W2 net-b 2>&1 | head -2 | sed 's/^/  /'
  echo
  echo "  >>> Now it resolves. A user-defined bridge runs an embedded DNS server"
  echo "      at 127.0.0.11 that resolves CONTAINER NAMES to current IPs."
  sub "the container's resolver"
  docker exec net-a cat /etc/resolv.conf | sed 's/^/  /'
  echo
  echo "  ALWAYS create a user-defined network for multi-container apps."
  echo "  docker compose does this for you, which is why compose services can"
  echo "  talk to each other by service name."

  hr "4. A container can be on SEVERAL networks at once"
  docker inspect net-a -f '  net-a networks: {{range $k,$v := .NetworkSettings.Networks}}{{$k}}({{$v.IPAddress}}) {{end}}'
  echo
  echo "  One interface per network. This is how you isolate tiers: put the web"
  echo "  container on frontend+backend, and the database on backend only, so"
  echo "  the database is unreachable from outside."

  hr "5. HOST NETWORKING"
  docker run -d --name net-host --network host alpine:3.19 sleep 600 >/dev/null 2>&1
  sleep 1
  docker inspect net-host -f '  network mode: {{.HostConfig.NetworkMode}}   ip assigned: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}(none)'
  echo
  echo "  No separate IP: the container shares the host's network namespace."
  echo "  -p is ignored because there is nothing to forward. Faster (no NAT),"
  echo "  but no isolation and port collisions with the host are possible."
  echo
  echo "  NOTE on macOS: Docker runs inside a Linux VM, so 'host' means the VM,"
  echo "  not your Mac. This is a common source of confusion."

  hr "6. NONE - fully isolated"
  docker run -d --name net-none --network none alpine:3.19 sleep 600 >/dev/null
  sleep 1
  echo "\$ docker exec net-none ip -brief addr"
  docker exec net-none ip -brief addr 2>&1 | sed 's/^/  /'
  echo
  echo "  Only loopback. Used for batch jobs that must not touch the network."

  hr "7. PORT PUBLISHING vs EXPOSE"
  cat <<'PORTS'
    EXPOSE 8080        in a Dockerfile: DOCUMENTATION only. Publishes nothing.
    -p 8080:80         publish container port 80 as host port 8080
    -p 127.0.0.1:8080:80   bind to localhost only (not reachable from the LAN)
    -P                 publish every EXPOSEd port to random high host ports

    Containers on the same user-defined network reach each other on the
    CONTAINER port directly. You only need -p for traffic from OUTSIDE.
PORTS

  hr "8. VOLUMES - data that outlives the container"
  echo "  A container's writable layer is deleted with the container."
  echo "  Anything that must survive goes in a volume."
  echo
  docker volume create demo-data >/dev/null
  echo "\$ docker volume create demo-data"
  docker volume inspect demo-data -f '  name: {{.Name}}  driver: {{.Driver}}  mountpoint: {{.Mountpoint}}'
  echo
  sub "write from one container"
  docker run --rm -v demo-data:/data alpine:3.19 sh -c 'echo "written at $(date -u +%H:%M:%S) by container 1" > /data/note.txt'
  echo "  wrote /data/note.txt, then that container was REMOVED (--rm)"
  sub "read from a completely different container"
  docker run --rm -v demo-data:/data alpine:3.19 cat /data/note.txt | sed 's/^/  /'
  echo
  echo "  >>> The data survived the container that created it."

  hr "9. BIND MOUNTS - map a host directory into a container"
  TMPD=$(mktemp -d)
  echo "host file content" > "$TMPD/hostfile.txt"
  echo "\$ docker run -v $TMPD:/mnt alpine cat /mnt/hostfile.txt"
  docker run --rm -v "$TMPD:/mnt" alpine:3.19 cat /mnt/hostfile.txt | sed 's/^/  /'
  echo
  echo "  changes go BOTH ways - writing from the container:"
  docker run --rm -v "$TMPD:/mnt" alpine:3.19 sh -c 'echo "added by container" >> /mnt/hostfile.txt'
  cat "$TMPD/hostfile.txt" | sed 's/^/  /'
  rm -rf "$TMPD"
  echo
  cat <<'MOUNTS'
    VOLUME       docker-managed, portable, backed up by docker, best for DATA
    BIND MOUNT   a specific host path, best for SOURCE CODE in development
                 (edit on the host, the running container sees it immediately)
    tmpfs        in memory only, never written to disk - for secrets
MOUNTS

  hr "10. INSPECTING A NETWORK"
  docker network inspect app-net -f '  containers on app-net:{{range .Containers}} {{.Name}}({{.IPv4Address}}){{end}}'
  echo
  echo "  docker network ls / inspect / create / connect / disconnect / rm"
  echo "  docker volume  ls / inspect / create / rm / prune"

  hr "CLEANUP"
  wipe
  echo "  demo containers, network and volume removed"

  hr "DONE"
}

case "${1:-all}" in
  all|verify) verify ;;
  cleanup) wipe; echo "cleaned" ;;
  *) echo "usage: $0 [all|cleanup]"; exit 1 ;;
esac
