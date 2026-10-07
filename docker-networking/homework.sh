#!/usr/bin/env bash
# Docker Networking & Volume homework - the four tasks from the course form.
#
#   ./homework.sh                 all four tasks (default)
#   ./homework.sh task1|task2|task3
#   SHOTS=1 ./homework.sh         also take the screenshots while things are running
#   ./homework.sh cleanup         remove everything this script creates
#
# Task 1  frontend / backend / database on three user-defined networks
# Task 2  Apache2 (httpd) on the host network, port 80
# Task 3  bind-mount a host folder into nginx and edit it live
# Task 4  overlay networks - research only, see README.md
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
HERE=$PWD
hr()  { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }

SHOTS=${SHOTS:-0}
SHOT=../lab/shot.sh
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
NGINX=nginx:1.30-alpine
MYSQL=mysql:8.4
HTTPD=httpd:2.4-alpine
DIND=docker:29-dind
ALPINE=alpine:3.19
DB_PASS=hw-root-pass          # throwaway demo password, the container is deleted at the end

shot() { [ "$SHOTS" = 1 ] && WIDTH="${W:-120}" "$SHOT" "$@"; return 0; }
browser_shot() {   # browser_shot <url> <out.png> - headless Chrome, killed once the file exists
  [ "$SHOTS" = 1 ] && [ -x "$CHROME" ] || return 0
  local url="$1" out="$HERE/$2" profile pid
  profile=$(mktemp -d); rm -f "$out"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --user-data-dir="$profile" \
    --window-size=900,300 --screenshot="$out" "$url" >/dev/null 2>&1 &
  pid=$!
  for _ in $(seq 1 60); do [ -s "$out" ] && break; sleep 0.5; done
  sleep 1; kill "$pid" 2>/dev/null; pkill -f "user-data-dir=$profile" 2>/dev/null; wait "$pid" 2>/dev/null
  rm -rf "$profile"
  [ -s "$out" ] && echo "  $(basename "$out")  ($(du -h "$out" | cut -f1 | tr -d ' '))"
}

# ---------------------------------------------------------------- task 1 ---
T1_CONTAINERS="frontend backend database"
T1_NETWORKS="frontend-net backend-net db-net"

t1_wipe() {
  docker rm -f $T1_CONTAINERS >/dev/null 2>&1
  for n in $T1_NETWORKS; do docker network rm "$n" >/dev/null 2>&1; done
}

port_of() { case "$1" in frontend) echo 80 ;; backend) echo 8080 ;; database) echo 3306 ;; esac; }

# Can <src> reach <dst>'s service port by name? Two checks: does the name
# resolve (Docker's embedded DNS only answers for containers on a shared
# network), and does a TCP connection to the service port succeed.
probe() {
  local src="$1" dst="$2" port ip
  port=$(port_of "$dst")
  ip=$(docker exec "$src" getent hosts "$dst" 2>/dev/null | awk '{print $1; exit}')
  [ -z "$ip" ] && { echo "no DNS"; return; }
  # the mysql image has no nc, so fall back to bash's /dev/tcp there
  if docker exec "$src" sh -c "command -v nc >/dev/null" 2>/dev/null; then
    docker exec "$src" nc -z -w 2 "$dst" "$port" >/dev/null 2>&1 && echo "OK" || echo "no TCP"
  else
    docker exec "$src" timeout 3 bash -c "</dev/tcp/$dst/$port" >/dev/null 2>&1 && echo "OK" || echo "no TCP"
  fi
}

matrix() {
  printf "    %-10s | %-14s%-14s%-14s\n" "from \\ to" frontend:80 backend:8080 database:3306
  printf "    %s-+-%s\n" "----------" "------------------------------------------"
  for s in frontend backend database; do
    row=""
    for d in frontend backend database; do
      if [ "$s" = "$d" ]; then cell="-"; else cell=$(probe "$s" "$d"); fi
      row="$row$(printf '%-14s' "$cell")"
    done
    printf "    %-10s | %s\n" "$s" "$row"
  done
}

nets_of() { docker inspect "$1" -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}({{$v.IPAddress}}) {{end}}'; }

task1() {
  t1_wipe
  hr "TASK 1 - Container networking: frontend, backend, database on 3 networks"

  sub "1.1 create three user-defined bridge networks"
  for n in $T1_NETWORKS; do
    echo "\$ docker network create $n"
    docker network create "$n" >/dev/null
  done
  echo
  docker network ls --filter name=-net --format 'table {{.Name}}\t{{.Driver}}\t{{.Scope}}'
  echo
  for n in $T1_NETWORKS; do
    docker network inspect "$n" -f '  {{.Name}}  subnet {{range .IPAM.Config}}{{.Subnet}}  gateway {{.Gateway}}{{end}}'
  done

  sub "1.2 one container per tier, each on its own network"
  echo "\$ docker run -d --name database --network db-net -e MYSQL_ROOT_PASSWORD=*** -e MYSQL_DATABASE=appdb $MYSQL"
  docker run -d --name database --network db-net -e MYSQL_ROOT_PASSWORD="$DB_PASS" -e MYSQL_DATABASE=appdb "$MYSQL" | cut -c1-12 | sed 's/^/  /'
  echo "\$ docker run -d --name backend  --network backend-net  -v ./homework/backend/default.conf:/etc/nginx/conf.d/default.conf:ro $NGINX"
  docker run -d --name backend --network backend-net \
    -v "$HERE/homework/backend/default.conf:/etc/nginx/conf.d/default.conf:ro" "$NGINX" | cut -c1-12 | sed 's/^/  /'
  echo "\$ docker run -d --name frontend --network frontend-net -v ./homework/frontend:/usr/share/nginx/html:ro $NGINX"
  docker run -d --name frontend --network frontend-net \
    -v "$HERE/homework/frontend:/usr/share/nginx/html:ro" "$NGINX" | cut -c1-12 | sed 's/^/  /'

  # Wait over TCP, not the local socket: on first start the image runs a
  # temporary server with networking switched off while it creates appdb,
  # and that one already answers a socket ping.
  printf "\n  waiting for MySQL to accept TCP connections on 3306"
  T0=$(date +%s)
  for _ in $(seq 1 90); do
    docker exec database mysqladmin -h 127.0.0.1 --protocol=TCP -uroot -p"$DB_PASS" ping >/dev/null 2>&1 && break
    printf "."; sleep 2
  done
  echo " ready after $(( $(date +%s) - T0 ))s"
  echo
  for c in $T1_CONTAINERS; do printf "  %-9s %s\n" "$c" "$(nets_of "$c")"; done

  sub "1.3 connectivity now: every tier is isolated"
  matrix
  echo
  echo "  'no DNS' means the name does not even resolve: Docker's embedded DNS"
  echo "  (127.0.0.11) only answers for containers that share a network with you."

  sub "1.4 attach the backend to a SECOND network (db-net)"
  echo "\$ docker network connect db-net backend"
  docker network connect db-net backend
  printf "  %-9s %s\n" backend "$(nets_of backend)"
  echo
  echo "\$ docker exec backend ip -o -f inet addr show      (one interface per network)"
  docker exec backend ip -o -f inet addr show | awk '{printf "  %-5s %s\n", $2, $4}'
  echo
  matrix
  echo
  echo "  backend <-> database works in both directions now; frontend is still alone."

  sub "1.5 let the frontend call the API: join it to backend-net"
  echo "\$ docker network connect backend-net frontend"
  docker network connect backend-net frontend
  echo
  for c in $T1_CONTAINERS; do printf "  %-9s %s\n" "$c" "$(nets_of "$c")"; done
  echo
  matrix
  echo
  echo "  Final picture: frontend -> backend -> database, and NO path from the"
  echo "  frontend to the database. The backend sits on 2 networks (backend-net"
  echo "  and db-net) and is the only way into the data tier."

  sub "1.6 the same results with real tools"
  echo "\$ docker exec frontend ping -c 2 backend"
  docker exec frontend ping -c 2 -W 2 backend 2>&1 | sed 's/^/  /'
  echo
  echo "\$ docker exec frontend wget -qO- http://backend:8080/"
  docker exec frontend wget -qO- http://backend:8080/ 2>&1 | sed 's/^/  /'
  echo
  echo "\$ docker exec frontend ping -c 2 database"
  docker exec frontend ping -c 2 -W 2 database 2>&1 | sed 's/^/  /'
  echo
  echo "\$ docker exec backend ping -c 2 database"
  docker exec backend ping -c 2 -W 2 database 2>&1 | sed 's/^/  /'
  echo
  echo "\$ docker exec backend sh -c 'nc -w 2 database 3306 | head -c 100'   (MySQL's greeting packet, printable parts)"
  docker exec backend sh -c 'nc -w 2 database 3306 2>/dev/null | head -c 100' \
    | LC_ALL=C tr -c 'a-zA-Z0-9._' ' ' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+|caching_sha2_password' | sed 's/^/  /'
  echo
  echo "  The backend image has no MySQL client, so borrow one: a throwaway mysql:8.4"
  echo "  container started with --network container:<name> shares that container's"
  echo "  network namespace, i.e. it sees exactly what the backend (or frontend) sees."
  echo
  echo "\$ docker run --rm --network container:backend $MYSQL mysqladmin -h database -uroot -p*** ping"
  docker run --rm --network container:backend "$MYSQL" mysqladmin -h database -uroot -p"$DB_PASS" ping 2>&1 \
    | grep -v 'Using a password' | sed 's/^/  /'
  echo "\$ docker run --rm --network container:backend $MYSQL mysql -h database -uroot -p*** -e 'SELECT @@hostname, @@version, DATABASE()' appdb"
  docker run --rm --network container:backend "$MYSQL" mysql -h database -uroot -p"$DB_PASS" \
    -e 'SELECT @@hostname, @@version, DATABASE()' appdb 2>&1 | grep -v 'Using a password' | sed 's/^/  /'
  echo "  (@@hostname is the database container's ID: $(docker inspect database -f '{{.Id}}' | cut -c1-12))"
  echo
  echo "\$ docker run --rm --network container:frontend $MYSQL mysqladmin -h database -uroot -p*** ping"
  docker run --rm --network container:frontend "$MYSQL" mysqladmin -h database -uroot -p"$DB_PASS" --connect-timeout=3 ping 2>&1 \
    | grep -v 'Using a password' | sed 's/^/  /'

  sub "1.7 it is not just DNS: even the database's IP is unreachable from the frontend"
  DBIP=$(docker inspect database -f '{{(index .NetworkSettings.Networks "db-net").IPAddress}}')
  echo "\$ docker exec frontend nc -z -w 3 $DBIP 3306"
  if docker exec frontend nc -z -w 3 "$DBIP" 3306 >/dev/null 2>&1; then echo "  connected (unexpected)"; else echo "  failed - exit $?, no route between the two bridges"; fi
  echo "\$ docker exec backend  nc -z -w 3 $DBIP 3306"
  if docker exec backend nc -z -w 3 "$DBIP" 3306 >/dev/null 2>&1; then echo "  connected"; else echo "  failed"; fi
  echo
  echo "  Docker installs firewall rules that drop traffic between different"
  echo "  bridge networks, so knowing the IP does not help."

  sub "1.8 docker network inspect - who is on which network"
  for n in $T1_NETWORKS; do
    docker network inspect "$n" -f '  {{.Name}} ({{range .IPAM.Config}}{{.Subnet}}{{end}}):{{range .Containers}}  {{.Name}}={{.IPv4Address}}{{end}}'
  done
  echo
  echo "\$ docker network inspect db-net    (trimmed to the interesting part)"
  docker network inspect db-net | python3 -c '
import json,sys
n=json.load(sys.stdin)[0]
keep={"Name":n["Name"],"Driver":n["Driver"],"Internal":n["Internal"],"IPAM":n["IPAM"]["Config"],
      "Containers":{v["Name"]:{"IPv4Address":v["IPv4Address"],"MacAddress":v["MacAddress"]} for v in n["Containers"].values()}}
print(json.dumps(keep,indent=2))' | sed 's/^/  /'

  if [ "$SHOTS" = 1 ]; then
    sub "screenshots"
    W=110 shot screenshots/hw-connectivity-matrix.png ./homework.sh matrix
    W=120 shot screenshots/hw-network-inspect.png bash -c 'for n in frontend-net backend-net db-net; do docker network inspect $n -f "{{.Name}} ({{range .IPAM.Config}}{{.Subnet}}{{end}}):{{range .Containers}}  {{.Name}}={{.IPv4Address}}{{end}}"; done; echo; docker inspect backend -f "backend is on: {{range \$k,\$v := .NetworkSettings.Networks}}{{\$k}} {{end}}"'
    W=120 shot screenshots/hw-ping-and-mysql.png bash -c "docker exec frontend ping -c1 -W2 backend; echo; docker exec frontend ping -c1 -W2 database; echo; echo '\$ mysqladmin ping from the backend namespace'; docker run --rm --network container:backend $MYSQL mysqladmin -h database -uroot -p$DB_PASS ping 2>&1 | grep -v 'Using a password'; echo '\$ mysqladmin ping from the frontend namespace'; docker run --rm --network container:frontend $MYSQL mysqladmin -h database -uroot -p$DB_PASS --connect-timeout=3 ping 2>&1 | grep -v 'Using a password'"
  fi

  sub "1.9 cleanup"
  t1_wipe
  echo "  containers frontend, backend, database and the three networks removed"
}

# ---------------------------------------------------------------- task 2 ---
t2_wipe() { docker rm -f apache-host >/dev/null 2>&1; docker rm -fv dind-host >/dev/null 2>&1; }

wait_dind() {   # wait until the docker daemon inside a dind container answers
  for _ in $(seq 1 60); do docker exec "$1" docker info >/dev/null 2>&1 && return 0; sleep 1; done
  echo "  daemon in $1 did not come up"; return 1
}

task2() {
  t2_wipe
  hr "TASK 2 - Apache2 (httpd) on the HOST network, port 80"

  sub "2.1 straight attempt on Docker Desktop"
  echo "\$ docker run -d --name apache-host --network host $HTTPD"
  docker run -d --name apache-host --network host "$HTTPD" | cut -c1-12 | sed 's/^/  /'
  sleep 3
  echo
  echo "\$ docker ps -a --filter name=apache-host"
  docker ps -a --filter name=apache-host --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  echo
  echo "\$ docker logs apache-host"
  docker logs apache-host 2>&1 | sed 's/^/  /'
  echo
  echo "  It exited: port 80 is already taken. 'host' here is not the Mac but the"
  echo "  Linux VM Docker Desktop runs, and in that VM port 80 is held by the"
  echo "  port mapping of the kind cluster used for the Kubernetes homework:"
  echo
  echo "\$ docker ps --filter publish=80"
  docker ps --filter publish=80 --format 'table {{.Names}}\t{{.Ports}}' | cut -c1-110
  echo
  echo "\$ docker run --rm --network host $ALPINE netstat -tln | grep ':80 '   (listeners in the VM)"
  docker run --rm --network host "$ALPINE" netstat -tln 2>/dev/null | grep -E ':80 ' | sed 's/^/  /'
  docker rm -f apache-host >/dev/null 2>&1

  sub "2.2 a clean host with a free port 80: Docker-in-Docker"
  echo "  docker:dind is a container running its own Docker daemon. For containers"
  echo "  started BY that inner daemon, the dind container's network namespace is"
  echo "  the host, and its port 80 is free. The kind cluster is left untouched."
  echo
  echo "\$ docker run -d --privileged --name dind-host -e DOCKER_TLS_CERTDIR= -p 8088:80 $DIND"
  docker run -d --privileged --name dind-host -e DOCKER_TLS_CERTDIR= -p 8088:80 "$DIND" | cut -c1-12 | sed 's/^/  /'
  wait_dind dind-host && docker exec dind-host docker version --format '  inner daemon up: Docker {{.Server.Version}}'
  echo
  echo "\$ docker save $HTTPD | docker exec -i dind-host docker load   (no second pull from Docker Hub)"
  docker save --platform linux/arm64 "$HTTPD" | docker exec -i dind-host docker load 2>&1 | sed 's/^/  /'

  sub "2.3 the Apache2 container on the host network, inside that host"
  echo "\$ docker exec dind-host docker run -d --name apache2 --network host $HTTPD"
  docker exec dind-host docker run -d --name apache2 --network host "$HTTPD" | cut -c1-12 | sed 's/^/  /'
  sleep 2
  echo
  echo "\$ docker exec dind-host docker ps"
  docker exec dind-host docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
  echo
  echo "\$ docker exec dind-host docker inspect apache2 -f 'mode={{.HostConfig.NetworkMode}} ip={{...IPAddress}}'"
  docker exec dind-host docker inspect apache2 -f '  mode={{.HostConfig.NetworkMode}}  ip={{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}(none of its own)'
  echo
  echo "\$ docker exec dind-host netstat -tlnp | grep ':80 '   (httpd is listening in the HOST's namespace)"
  docker exec dind-host netstat -tlnp 2>/dev/null | grep -E ':80 ' | sed 's/^/  /'
  echo
  echo "\$ docker exec dind-host wget -qO- http://localhost:80/"
  docker exec dind-host wget -qO- http://localhost:80/ 2>&1 | sed 's/^/  /'
  echo
  HOSTIP=$(docker exec dind-host ip -4 -o addr show eth0 | awk '{print $4}' | cut -d/ -f1)
  echo "\$ docker exec dind-host wget -qO- http://$HOSTIP:80/   (the host's own IP, port 80 directly)"
  docker exec dind-host wget -qO- "http://$HOSTIP:80/" 2>&1 | sed 's/^/  /'
  echo
  echo "  No -p was given to the inner 'docker run' and no port mapping exists for"
  echo "  apache2: it simply IS on the host's port 80."

  sub "2.4 and from the Mac"
  echo "\$ curl -s http://localhost:8088/"
  for _ in $(seq 1 10); do curl -s -o /dev/null --max-time 2 http://localhost:8088/ && break; sleep 1; done
  curl -s --max-time 5 http://localhost:8088/ | sed 's/^/  /'
  echo
  echo "  Mac :8088 -> dind-host :80 (the one -p mapping) -> apache2, which listens"
  echo "  on that host's port 80 itself because it shares the host network stack."

  if [ "$SHOTS" = 1 ]; then
    sub "screenshots"
    W=120 shot screenshots/hw-host-network-port80-taken.png bash -c "docker run --name apache-host-shot --network host $HTTPD 2>&1 | tail -3; docker rm -f apache-host-shot >/dev/null 2>&1"
    W=120 shot screenshots/hw-host-network-apache.png bash -c "docker exec dind-host docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'; echo; docker exec dind-host docker inspect apache2 -f 'network mode: {{.HostConfig.NetworkMode}}'; echo; docker exec dind-host netstat -tlnp | grep ':80 '; echo; docker exec dind-host wget -qO- http://localhost:80/"
    browser_shot http://localhost:8088/ screenshots/hw-host-network-browser.png
  fi

  sub "2.5 cleanup"
  t2_wipe
  echo "  dind-host (and the apache2 container inside it) removed"
}

# ---------------------------------------------------------------- task 3 ---
SITE=bind-mount-site
ORIGINAL='<h1>Hello students</h1>'

t3_wipe() { docker rm -f bind-nginx >/dev/null 2>&1; }

task3() {
  t3_wipe
  hr "TASK 3 - Bind mount a host folder into nginx, edit it live"

  sub "3.1 create the folder and index.html on the Mac"
  echo "\$ mkdir -p $SITE && echo '$ORIGINAL' > $SITE/index.html"
  mkdir -p "$SITE" && echo "$ORIGINAL" > "$SITE/index.html"
  ls -la "$SITE" | tail -n +2 | sed 's/^/  /'

  sub "3.2 bind mount it over nginx's document root"
  echo "\$ docker run -d --name bind-nginx -p 8090:80 -v \"\$PWD/$SITE:/usr/share/nginx/html:ro\" $NGINX"
  docker run -d --name bind-nginx -p 8090:80 -v "$HERE/$SITE:/usr/share/nginx/html:ro" "$NGINX" | cut -c1-12 | sed 's/^/  /'
  for _ in $(seq 1 20); do curl -s -o /dev/null --max-time 2 http://localhost:8090/ && break; sleep 0.5; done
  docker inspect bind-nginx -f '  mount: {{range .Mounts}}{{.Type}}  {{.Source}} -> {{.Destination}}  rw={{.RW}}{{end}}'

  sub "3.3 access it"
  echo "\$ curl -s http://localhost:8090/"
  curl -s http://localhost:8090/ | sed 's/^/  /'
  STARTED1=$(docker inspect bind-nginx -f '{{.State.StartedAt}}')
  echo "  container StartedAt: $STARTED1"
  browser_shot http://localhost:8090/ screenshots/hw-bind-mount-before.png

  sub "3.4 modify index.html ON THE HOST (not in the container)"
  NEW="<h1>Hello students - edited on the Mac at $(date +%H:%M:%S), no restart</h1>"
  echo "\$ echo '$NEW' > $SITE/index.html"
  echo "$NEW" > "$SITE/index.html"
  sleep 1

  sub "3.5 access it again"
  echo "\$ curl -s http://localhost:8090/"
  curl -s http://localhost:8090/ | sed 's/^/  /'
  echo "\$ docker exec bind-nginx cat /usr/share/nginx/html/index.html"
  docker exec bind-nginx cat /usr/share/nginx/html/index.html | sed 's/^/  /'
  browser_shot http://localhost:8090/ screenshots/hw-bind-mount-after.png
  STARTED2=$(docker inspect bind-nginx -f '{{.State.StartedAt}}')
  echo
  echo "  StartedAt before the edit : $STARTED1"
  echo "  StartedAt after the edit  : $STARTED2"
  echo "  RestartCount              : $(docker inspect bind-nginx -f '{{.RestartCount}}')"
  [ "$STARTED1" = "$STARTED2" ] && echo "  >>> same start time: the change was picked up with NO restart"

  sub "3.6 the mount is read-only from the container's side (:ro)"
  echo "\$ docker exec bind-nginx sh -c 'echo hacked > /usr/share/nginx/html/index.html'"
  docker exec bind-nginx sh -c 'echo hacked > /usr/share/nginx/html/index.html' 2>&1 | sed 's/^/  /'
  echo "  The host can change the site; the web server cannot."

  if [ "$SHOTS" = 1 ]; then
    sub "screenshots"
    W=120 shot screenshots/hw-bind-mount-curl.png bash -c "curl -s http://localhost:8090/; docker inspect bind-nginx -f 'StartedAt={{.State.StartedAt}}  RestartCount={{.RestartCount}}'"
  fi

  sub "3.7 cleanup"
  t3_wipe
  echo "$ORIGINAL" > "$SITE/index.html"
  echo "  bind-nginx removed, $SITE/index.html put back to the original text"
}

cleanup() {
  t1_wipe; t2_wipe; t3_wipe
  [ -d "$SITE" ] && echo "$ORIGINAL" > "$SITE/index.html"
  echo "cleaned"
}

case "${1:-all}" in
  all)     task1; task2; task3; hr "DONE" ;;
  task1)   task1 ;;
  matrix)  matrix ;;       # connectivity matrix of whatever is running now
  task2)   task2 ;;
  task3)   task3 ;;
  cleanup) cleanup ;;
  *) echo "usage: $0 [all|task1|task2|task3|cleanup]"; exit 1 ;;
esac
