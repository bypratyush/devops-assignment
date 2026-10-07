#!/usr/bin/env bash
# Docker Multi-Stage Build homework.
#   Task 1: clone the course repo, build its multi-stage Dockerfile, run it on
#           host port 8080, check the page and docker ps.
#   + measure the same app built single-stage, for comparison.
#   Task 3: deploy three different kinds of app (Node.js, Python, Java).
#
#   ./run.sh            everything above (default)
#   ./run.sh shots      screenshots of the running containers into screenshots/
#   ./run.sh cleanup    remove the containers and images this script made
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
HERE=$PWD
hr()  { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }

REPO=https://github.com/Nency-Ravaliya/devops-heros.git
APPDIR=session6-7-docker/multi-stage-dockerfile
IMAGE=multi-stage-hello:1.0
SINGLE=multi-stage-hello:single
NAME=multi-stage-app
HELLO=../../docker-fundamentals/hello-world-apps
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Task 3 apps: folder, container, host port, container port
TASK3="nodejs-app hello-nodejs 8081 3000
python-app hello-python 8082 5000
java-app   hello-java   8083 8080"

wait_http() { for _ in $(seq 1 40); do curl -s -o /dev/null --max-time 2 "http://localhost:$1/" && return 0; sleep 0.5; done; return 1; }

# BuildKit prints every step as "#N [stage step/total] INSTRUCTION". Keep one line per step.
steps() { grep -E '^#[0-9]+ \[(builder|production|stage-|[0-9])' "$1" | grep -v 'internal' | awk '!seen[$0]++' | sed 's/^#[0-9]* /    /' | cut -c1-90; }

task1() {
  WORK=$(mktemp -d)
  trap 'rm -rf "$WORK"' EXIT

  hr "STEP 1 - Clone the repository that contains the multi-stage Dockerfile"
  echo "\$ git clone --depth 1 $REPO"
  git clone -q --depth 1 "$REPO" "$WORK/devops-heros" 2>&1 | sed 's/^/  /'
  git -C "$WORK/devops-heros" log -1 --format='  cloned commit %h (%cs) %s'
  SRC="$WORK/devops-heros/$APPDIR"
  echo
  echo "\$ ls $APPDIR"
  ls -1 "$SRC" | sed 's/^/  /'
  sub "the Dockerfile"
  sed 's/^/  /' "$SRC/Dockerfile"; echo
  sub "server.js"
  sed 's/^/  /' "$SRC/server.js"; echo

  hr "STEP 2 - Build the image with the multi-stage Dockerfile"
  echo "\$ docker build -t $IMAGE ."
  LOG=$(mktemp)
  if (cd "$SRC" && docker build --progress=plain -t "$IMAGE" .) >"$LOG" 2>&1; then
    echo "  build OK. Steps BuildKit ran, per stage:"
    steps "$LOG"
  else
    echo "  BUILD FAILED:"; tail -20 "$LOG" | sed 's/^/  /'
  fi
  rm -f "$LOG"

  hr "STEP 3 - Run a container from it, host port 8080 -> container port 3000"
  docker rm -f "$NAME" >/dev/null 2>&1
  echo "\$ docker run -d --name $NAME -p 8080:3000 $IMAGE"
  docker run -d --name "$NAME" -p 8080:3000 "$IMAGE" | cut -c1-12 | sed 's/^/  /'
  wait_http 8080 || echo "  (not answering on 8080 yet)"
  echo
  echo "\$ docker logs $NAME"
  docker logs "$NAME" 2>&1 | sed 's/^/  /'

  hr "STEP 4 - Access the application"
  echo "\$ curl -i http://localhost:8080/"
  curl -s -i http://localhost:8080/ | tr -d '\r' | grep -vE '^(Date|ETag|Connection|Keep-Alive):' | sed 's/^/  /'
  echo
  echo
  if curl -s http://localhost:8080/ | grep -q 'Hello World from Docker Multi-Stage Build!'; then
    echo "  >>> PASS: the page says 'Hello World from Docker Multi-Stage Build!'"
  else
    echo "  >>> FAIL: expected text not found"
  fi

  hr "STEP 5 - Verify with docker ps, and confirm port 8080"
  echo "\$ docker ps --filter name=$NAME"
  docker ps --filter name="$NAME" --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}'
  echo
  echo "\$ docker port $NAME"
  docker port "$NAME" | sed 's/^/  /'
  echo
  echo "\$ lsof -nP -iTCP:8080 -sTCP:LISTEN     (on the Mac itself)"
  lsof -nP -iTCP:8080 -sTCP:LISTEN 2>/dev/null | awk '{print "  "$1, $5, $8, $9, $10}' | column -t | sed 's/^/  /'
  echo
  echo "  The app listens on 3000 INSIDE the container; Docker publishes it on"
  echo "  port 8080 of the host, which is the port the browser and curl use."

  hr "STEP 6 - Same app, single-stage build, for comparison"
  echo "\$ docker build -f Dockerfile.single-stage -t $SINGLE <clone>/$APPDIR"
  if docker build -q -f "$HERE/Dockerfile.single-stage" -t "$SINGLE" "$SRC" >/dev/null 2>&1; then
    echo "  built $SINGLE"
  else
    echo "  single-stage build FAILED"
  fi
  echo
  printf "  %-26s %10s %12s %7s\n" "IMAGE" "ON DISK" "DOWNLOAD" "LAYERS"
  for img in "$SINGLE" "$IMAGE"; do
    printf "  %-26s %10s %10.1fMB %7s\n" "$img" \
      "$(docker images "$img" --format '{{.Size}}')" \
      "$(docker image inspect "$img" --format '{{.Size}}' | awk '{print $1/1000000}')" \
      "$(docker image inspect "$img" --format '{{len .RootFS.Layers}}')"
  done
  sub "what is in /app in each image"
  for img in "$SINGLE" "$IMAGE"; do
    printf "  %-26s %s\n" "$img" "$(docker run --rm --entrypoint sh "$img" -c 'ls -A /app | tr "\n" " "')"
    printf "  %-26s %s\n" "" "$(docker run --rm --entrypoint sh "$img" -c 'echo "node_modules: $(ls /app/node_modules | wc -l) packages, $(du -sh /app/node_modules | cut -f1)"')"
  done
  sub "npm's download cache (/root/.npm) left behind in each image"
  for img in "$SINGLE" "$IMAGE"; do
    printf "  %-26s %s\n" "$img" "$(docker run --rm --entrypoint sh "$img" -c '
      c=/root/.npm/_cacache/index-v5
      t=$(grep -rhoE "request-cache:https://registry.npmjs.org/[^\"]*\.tgz" $c | sort -u | wc -l)
      m=$(grep -rhoE "request-cache:https://registry.npmjs.org/[^\"]*" $c | grep -v "\.tgz" | sort -u | wc -l)
      echo "$(du -sh /root/.npm | cut -f1)   ($t package tarballs, $m registry metadata documents)"')"
  done
  echo
  echo "  The single-stage build ran 'npm install' with only package.json, so npm"
  echo "  had to download every package's metadata to resolve versions. The"
  echo "  production stage got package-lock.json from the builder (COPY package*.json),"
  echo "  so it fetched the exact tarballs and no metadata."
  sub "layers of the multi-stage image (only the final stage is in it)"
  docker history "$IMAGE" --format 'table {{.CreatedBy}}\t{{.Size}}' | head -8 | cut -c1-100

  rm -rf "$WORK"; trap - EXIT
  echo
  echo "  clone removed from $WORK"
}

task3() {
  hr "STEP 7 - Task 3: deploy three different types of application"
  echo "  The Node.js, Python and Java apps live in docker-fundamentals/hello-world-apps/."
  echo
  echo "$TASK3" | while read -r dir c hport cport; do
    docker rm -f "$c" >/dev/null 2>&1
    img="hello/$dir:1.0"
    if docker build -q -t "$img" "$HELLO/$dir" >/dev/null 2>&1; then
      echo "\$ docker run -d --name $c -p $hport:$cport $img"
      docker run -d --name "$c" -p "$hport:$cport" "$img" | cut -c1-12 | sed 's/^/  /'
    else
      echo "  build of $dir FAILED"
    fi
  done
  echo
  echo "$TASK3" | while read -r dir c hport cport; do
    wait_http "$hport"
    printf "  curl localhost:%s  ->  %s\n" "$hport" \
      "$(curl -s "http://localhost:$hport/" | grep -o 'Hello World from [A-Za-z.]*' | head -1)"
  done
  sub "docker ps - the multi-stage app plus three different stacks"
  docker ps --filter name="$NAME" --filter name=hello-nodejs --filter name=hello-python --filter name=hello-java \
    --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | sed 's/, \[::\]:[0-9]*->[0-9]*\/tcp//'
}

# Headless Chrome writes the screenshot and then sometimes never exits on this
# Mac, so run it in the background, wait for the file, then kill it.
browser_shot() {
  local url="$1" out="$2" profile pid
  profile=$(mktemp -d); rm -f "$out"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --user-data-dir="$profile" \
    --window-size=1000,400 --screenshot="$out" "$url" >/dev/null 2>&1 &
  pid=$!
  for _ in $(seq 1 60); do [ -s "$out" ] && break; sleep 0.5; done
  sleep 1; kill "$pid" 2>/dev/null; pkill -f "user-data-dir=$profile" 2>/dev/null; wait "$pid" 2>/dev/null
  rm -rf "$profile"
  [ -s "$out" ] && echo "  $(basename "$out")  ($(du -h "$out" | cut -f1 | tr -d ' '))"
}

shots() {
  local SHOT=../../lab/shot.sh
  hr "SCREENSHOTS"
  WIDTH=110 "$SHOT" screenshots/curl-app.png curl -s -i http://localhost:8080/
  WIDTH=140 "$SHOT" screenshots/docker-ps-port-8080.png \
    docker ps --filter name="$NAME" --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}'
  WIDTH=110 "$SHOT" screenshots/image-size-comparison.png \
    docker images --filter=reference='multi-stage-hello' --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}'
  WIDTH=130 "$SHOT" screenshots/task3-three-apps.png \
    docker ps --filter name="$NAME" --filter name=hello-nodejs --filter name=hello-python --filter name=hello-java \
    --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
  [ -x "$CHROME" ] && browser_shot http://localhost:8080/ "$PWD/screenshots/browser-port-8080.png"
}

cleanup() {
  hr "CLEANUP"
  docker rm -f "$NAME" hello-nodejs hello-python hello-java >/dev/null 2>&1
  docker rmi "$IMAGE" "$SINGLE" >/dev/null 2>&1
  echo "  removed $NAME, hello-nodejs, hello-python, hello-java and the multi-stage-hello images"
  echo "  (hello/* images are left for docker-fundamentals/hello-world-apps/run.sh cleanup)"
}

case "${1:-all}" in
  all)     task1; task3 ;;
  task1)   task1 ;;
  task3)   task3 ;;
  shots)   shots ;;
  cleanup) cleanup ;;
  *) echo "usage: $0 [all|task1|task3|shots|cleanup]"; exit 1 ;;
esac
