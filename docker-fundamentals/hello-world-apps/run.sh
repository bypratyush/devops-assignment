#!/usr/bin/env bash
# Hello World apps - six stacks, six Dockerfiles, six running containers.
#
#   ./run.sh            build + run + verify (default)
#   ./run.sh build      build the six images
#   ./run.sh run        (re)start the six containers
#   ./run.sh verify     curl every app, render the React one in headless Chrome,
#                       show docker ps and image sizes
#   ./run.sh check      one-line "Hello World" check per app
#   ./run.sh shots      termshot + headless-Chrome screenshots into screenshots/
#   ./run.sh cleanup    stop and remove the containers and images
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr()  { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# folder        host port  container port  base image(s)
APPS="nodejs-app   8081  3000  node:24-alpine
python-app   8082  5000  python:3.13-slim
java-app     8083  8080  eclipse-temurin:21-jdk-alpine,eclipse-temurin:21-jre-alpine
Apache-app   8084  80    httpd:2.4-alpine
React-app    8085  80    node:24-alpine,nginx:1.30-alpine
nginx-app    8086  80    nginx:1.30-alpine"

# Headless Chrome on this Mac writes the screenshot / DOM and then sometimes
# never exits, so run it in the background, wait for the output, then kill it.
chrome() {   # chrome <out-file> <flag> <url>
  local out="$1" flag="$2" url="$3" profile pid
  profile=$(mktemp -d); rm -f "$out"
  if [ "$flag" = dom ]; then
    "$CHROME" --headless=new --disable-gpu --user-data-dir="$profile" --dump-dom "$url" >"$out" 2>/dev/null &
  else
    "$CHROME" --headless=new --disable-gpu --hide-scrollbars --user-data-dir="$profile" \
      --window-size=1000,440 --screenshot="$out" "$url" >/dev/null 2>&1 &
  fi
  pid=$!
  for _ in $(seq 1 60); do
    if [ "$flag" = dom ]; then grep -q '</html>' "$out" 2>/dev/null && break
    else [ -s "$out" ] && break; fi
    sleep 0.5
  done
  sleep 1
  kill "$pid" 2>/dev/null; pkill -f "user-data-dir=$profile" 2>/dev/null; wait "$pid" 2>/dev/null
  rm -rf "$profile"
}

lower()  { echo "$1" | tr '[:upper:]' '[:lower:]'; }
image()  { echo "hello/$(lower "$1"):1.0"; }                 # React-app -> hello/react-app:1.0
cname()  { echo "hello-$(lower "${1%-app}")"; }              # React-app -> hello-react

# Docker Hub allows anonymous clients a limited number of pulls per hour per IP;
# past that a pull fails with "429 Too Many Requests". Use the local copy when
# there is one, otherwise retry with backoff (or run `docker login` first).
ensure_image() {
  local img="$1" wait=15 err
  if docker image inspect "$img" >/dev/null 2>&1; then
    printf "  %-34s already local\n" "$img"; return 0
  fi
  for attempt in 1 2 3 4; do
    if err=$(docker pull -q "$img" 2>&1 >/dev/null); then
      printf "  %-34s pulled from Docker Hub\n" "$img"; return 0
    fi
    printf "  %-34s pull failed (%s), retrying in %ss\n" "$img" \
      "$(echo "$err" | grep -oE '429 Too Many Requests|not found|timeout' | head -1)" "$wait"
    sleep "$wait"; wait=$(( wait * 2 ))
  done
  printf "  %-34s COULD NOT PULL - try 'docker login' and rerun\n" "$img"; return 1
}

build() {
  hr "STEP 1 - Base images (pinned tags, never :latest)"
  echo "$APPS" | awk '{print $4}' | tr ',' '\n' | sort -u | while read -r img; do ensure_image "$img"; done

  hr "STEP 2 - Build one image per folder"
  echo "$APPS" | while read -r dir hport cport base; do
    local t0=$(date +%s) log
    log=$(mktemp)
    if docker build -t "$(image "$dir")" "./$dir" >"$log" 2>&1; then
      printf "  %-12s -> %-24s built in %ss\n" "$dir" "$(image "$dir")" "$(( $(date +%s) - t0 ))"
    else
      printf "  %-12s -> BUILD FAILED, last lines:\n" "$dir"; tail -15 "$log" | sed 's/^/      /'
    fi
    rm -f "$log"
  done
}

run() {
  hr "STEP 3 - Run one container per image"
  echo "$APPS" | while read -r dir hport cport base; do
    docker rm -f "$(cname "$dir")" >/dev/null 2>&1
    echo "\$ docker run -d --name $(cname "$dir") -p $hport:$cport $(image "$dir")"
    docker run -d --name "$(cname "$dir")" -p "$hport:$cport" "$(image "$dir")" | cut -c1-12 | sed 's/^/  /'
  done
}

wait_http() {   # wait until a port answers 200, up to ~20s
  for _ in $(seq 1 40); do
    [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "http://localhost:$1/")" = "200" ] && return 0
    sleep 0.5
  done
  return 1
}

verify() {
  hr "STEP 4 - Is 'Hello World' really on each page?"
  echo "$APPS" | while read -r dir hport cport base; do
    wait_http "$hport" || { printf "  %-12s :%s  NOT ANSWERING\n" "$dir" "$hport"; continue; }
    code=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$hport/")
    found=$(curl -s "http://localhost:$hport/" | grep -o 'Hello World from [A-Za-z.]*' | head -1)
    printf "  %-12s http://localhost:%s  HTTP %s  %s\n" "$dir" "$hport" "$code" "${found:-(not in the raw HTML)}"
  done

  sub "React is different: curl only gets the empty HTML shell"
  echo "\$ curl -s http://localhost:8085/ | grep -E 'root|script'"
  curl -s http://localhost:8085/ | grep -E 'id="root"|<script' | sed 's/^ */  /'
  BUNDLE=$(curl -s http://localhost:8085/ | grep -o '/assets/index-[A-Za-z0-9_-]*\.js' | head -1)
  echo
  echo "  The text lives in the JavaScript bundle ($BUNDLE):"
  echo "  $(curl -s "http://localhost:8085$BUNDLE" | grep -o 'Hello World from React' | head -1)  <- found in the bundle"
  if [ -x "$CHROME" ]; then
    echo
    echo "  ...and only appears in the page once a browser runs that JavaScript."
    echo "  Headless Chrome, DOM after rendering:"
    DOM=$(mktemp)
    chrome "$DOM" dom http://localhost:8085/
    grep -o '<h1>[^<]*</h1>' "$DOM" | sed 's/^/    /'
    rm -f "$DOM"
  fi

  hr "STEP 5 - docker ps: all six running"
  docker ps --filter name=hello- --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | sed 's/, \[::\]:[0-9]*->[0-9]*\/tcp//'

  hr "STEP 6 - Image sizes"
  echo "  (docker images = unpacked size on disk; that is what the README table uses)"
  echo
  docker images --filter=reference='hello/*' --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'

  hr "STEP 7 - Start-up line from each container's log"
  echo "$APPS" | while read -r dir hport cport base; do
    printf "  %-14s %s\n" "$(cname "$dir")" "$(docker logs "$(cname "$dir")" 2>&1 \
      | grep -E 'listening|Listening at|resuming normal operations|ready for start up' | head -1 \
      | sed -E 's/^(\[[^]]*\] ?){1,3}//' | cut -c1-105)"
  done

  hr "STEP 8 - Which user each process runs as (user:process x count)"
  echo "$APPS" | while read -r dir hport cport base; do
    c=$(cname "$dir")
    printf "  %-14s %s\n" "$c" "$(docker exec "$c" sh -c '
      for p in /proc/[0-9]*; do
        n=$(cat "$p/comm" 2>/dev/null); case "$n" in sh|cat|stat|sort|uniq|"") continue ;; esac
        echo "$(stat -c %U "$p" 2>/dev/null):$n"
      done | sort | uniq -c' | awk '{printf "%s x%s   ", $2, $1}')"
  done
  echo
  echo "  The node, python and java images run everything as a non-root user."
  echo "  httpd and nginx keep a root master process (needed to bind port 80)"
  echo "  and hand the actual requests to unprivileged workers."
}

shots() {
  local SHOT=../../lab/shot.sh
  hr "SCREENSHOTS"
  WIDTH=140 "$SHOT" screenshots/docker-ps-all-six.png \
    docker ps --filter name=hello- --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
  WIDTH=110 "$SHOT" screenshots/curl-hello-world.png ./run.sh check
  WIDTH=110 "$SHOT" screenshots/image-sizes.png \
    docker images --filter=reference='hello/*' --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'
  [ -x "$CHROME" ] || { echo "  Chrome not found, skipping browser screenshots"; return; }
  echo "$APPS" | while read -r dir hport cport base; do
    out="$PWD/screenshots/browser-$(lower "$dir").png"
    chrome "$out" png "http://localhost:$hport/"
    [ -s "$out" ] && echo "  $(basename "$out")  ($(du -h "$out" | cut -f1 | tr -d ' '))"
  done
}

check() {   # one line per app: what curl sees, and for React what the browser renders
  echo "$APPS" | while read -r dir hport cport base; do
    found=$(curl -s "http://localhost:$hport/" | grep -o 'Hello World from [A-Za-z.]*' | head -1)
    if [ -z "$found" ] && [ "$dir" = React-app ] && [ -x "$CHROME" ]; then
      DOM=$(mktemp); chrome "$DOM" dom "http://localhost:$hport/"
      found="$(grep -o 'Hello World from [A-Za-z.]*' "$DOM" | head -1)   (curl: empty <div id=\"root\">; text from headless Chrome's rendered DOM)"
      rm -f "$DOM"
    fi
    printf "%-11s localhost:%s  %s\n" "$dir" "$hport" "${found:-NOT FOUND}"
  done
}

cleanup() {
  hr "CLEANUP"
  echo "$APPS" | while read -r dir hport cport base; do
    c=$(cname "$dir")
    docker inspect "$c" >/dev/null 2>&1 || continue
    t0=$(date +%s)
    docker stop "$c" >/dev/null 2>&1
    printf "  stopped %-14s exit %-4s in %ss\n" "$c" "$(docker inspect -f '{{.State.ExitCode}}' "$c")" "$(( $(date +%s) - t0 ))"
    docker rm "$c" >/dev/null 2>&1
  done
  echo "$APPS" | while read -r dir hport cport base; do docker rmi "$(image "$dir")" >/dev/null 2>&1; done
  echo "  containers and hello/* images removed"
}

case "${1:-all}" in
  all)     build; run; verify ;;
  build)   build ;;
  run)     run ;;
  verify)  verify ;;
  shots)   shots ;;
  check)   check ;;
  cleanup) cleanup ;;
  *) echo "usage: $0 [all|build|run|verify|check|shots|cleanup]"; exit 1 ;;
esac
