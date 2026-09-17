#!/usr/bin/env bash
# Docker Images - Dockerfiles, layers, caching, and multi-stage builds.
# Every number below is measured on this machine.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }
size() { docker image inspect "$1" --format '{{.Size}}' 2>/dev/null; }
human() { awk -v b="$1" 'BEGIN{ split("B KB MB GB",u," "); i=1; while(b>=1024 && i<4){b/=1024;i++} printf "%.1f %s", b, u[i] }'; }

build_all() {
  hr "STEP 1 - Build the SAME app three ways"
  echo "A tiny Go HTTP service, built with three different Dockerfiles."
  echo

  sub "1a. naive: ship the whole Go toolchain"
  docker build -q -f Dockerfile.naive -t hellosvc:naive . >/dev/null 2>&1 && echo "  built hellosvc:naive"

  sub "1b. multi-stage onto scratch: ship only the binary"
  docker build -q -f Dockerfile.multistage -t hellosvc:multistage . >/dev/null 2>&1 && echo "  built hellosvc:multistage"

  sub "1c. multi-stage onto alpine: binary + a shell for debugging"
  docker build -q -f Dockerfile.alpine -t hellosvc:alpine . >/dev/null 2>&1 && echo "  built hellosvc:alpine"
}

verify() {
  hr "STEP 2 - THE RESULT: image sizes"
  echo "Two different, both-correct numbers are reported below, because this"
  echo "Docker uses the containerd snapshotter:"
  echo
  echo "  ON DISK   what 'docker images' reports - the UNCOMPRESSED size the"
  echo "            image occupies once unpacked on a node"
  echo "  DOWNLOAD  what 'docker image inspect .Size' reports - the sum of the"
  echo "            COMPRESSED layers, i.e. what crosses the network on a pull"
  echo
  printf "  %-22s %12s %14s\n" "IMAGE" "ON DISK" "DOWNLOAD"
  printf "  %-22s %12s %14s\n" "----------------------" "------------" "--------------"
  for tag in naive alpine multistage; do
    disk=$(docker images "hellosvc:$tag" --format '{{.Size}}')
    dl=$(size "hellosvc:$tag")
    printf "  %-22s %12s %14s\n" "hellosvc:$tag" "$disk" "$(human "$dl")"
  done
  echo
  N=$(size hellosvc:naive); M=$(size hellosvc:multistage)
  if [ -n "$N" ] && [ -n "$M" ] && [ "$M" -gt 0 ]; then
    echo "  Comparing like with like (download size):"
    echo "    naive is $(awk -v n="$N" -v m="$M" 'BEGIN{printf "%.0f", n/m}')x larger than the multi-stage build"
    echo "    every pull saves $(human $((N - M)))  -  on every node, on every deploy"
  fi
  echo
  echo "  The gap is the entire Go toolchain: a compiler, the standard library"
  echo "  source, and build caches that the running service never touches."

  hr "STEP 3 - WHY: what is actually inside each image"
  sub "the naive image still has the compiler"
  docker run --rm hellosvc:naive sh -c 'go version; echo "---"; du -sh /usr/local/go 2>/dev/null' 2>&1 | sed 's/^/  /'
  echo
  echo "  A production container does not need a compiler. It is pure attack"
  echo "  surface and pure bandwidth."
  echo
  sub "the scratch image has NOTHING but the binary"
  # --entrypoint is required: the image sets ENTRYPOINT ["/hellosvc"], so a bare
  # `docker run ... ls` would run `/hellosvc ls` and start the server instead.
  echo "  \$ docker run --rm --entrypoint ls hellosvc:multistage"
  docker run --rm --entrypoint ls hellosvc:multistage 2>&1 \
    | grep -oE '(executable file not found|no such file or directory|exec: [^:]*)' | head -1 | sed 's/^/  -> /'
  echo
  echo "  \$ docker run --rm --entrypoint sh hellosvc:multistage"
  docker run --rm --entrypoint sh hellosvc:multistage 2>&1 \
    | grep -oE '(executable file not found|no such file or directory|exec: [^:]*)' | head -1 | sed 's/^/  -> /'
  echo
  echo "  No shell, no ls, no package manager - there is no OS in there at all."
  echo "  Great for security (nothing to exploit), awkward for debugging"
  echo "  (no 'kubectl exec ... sh'). That is the alpine trade-off."

  hr "STEP 4 - LAYERS: an image is a stack of read-only filesystem diffs"
  echo "\$ docker history hellosvc:alpine"
  docker history hellosvc:alpine --format 'table {{.CreatedBy}}\t{{.Size}}' 2>/dev/null | head -10
  echo
  echo "Each Dockerfile instruction that changes the filesystem creates a LAYER."
  echo "Layers are content-addressed and shared between images, so pulling a"
  echo "second alpine-based image only downloads the layers you do not have."

  hr "STEP 5 - BUILD CACHE: why instruction order matters"
  echo "BuildKit prints each step as '#N [description]', and separately prints"
  echo "'#N CACHED' for the ones it reused. Pairing those two tells us exactly"
  echo "which layers were rebuilt."
  echo

  # For every real build step, report CACHED or REBUILT.
  analyse() {
    local log="$1"
    awk '
      /^#[0-9]+ CACHED/          { split($1,a,"#"); cached[a[2]]=1; next }
      /^#[0-9]+ \[(builder|stage)/ { if ($0 ~ / FROM /) next;
                                    split($1,a,"#"); n=a[2];
                                    if (!(n in seen)) { seen[n]=1; order[++c]=n;
                                      sub(/^#[0-9]+ /,""); desc[n]=$0 } }
      END { for (i=1;i<=c;i++) { n=order[i];
              printf "    %-9s %s\n", (n in cached ? "CACHED" : "REBUILT"), substr(desc[n],1,78) } }
    ' "$log"
  }

  sub "5a. rebuild with NO source change"
  docker build -f Dockerfile.alpine -t hellosvc:alpine . > /tmp/build1.log 2>&1
  analyse /tmp/build1.log
  echo "    ^ everything reused; nothing had to run again."

  sub "5b. append ONE comment to app/main.go, then rebuild"
  cp app/main.go /tmp/main.go.bak
  printf '\n// cache-busting comment %s\n' "$(date +%s)" >> app/main.go
  docker build -f Dockerfile.alpine -t hellosvc:alpine . > /tmp/build2.log 2>&1
  cp /tmp/main.go.bak app/main.go
  analyse /tmp/build2.log
  rm -f /tmp/main.go.bak /tmp/build1.log /tmp/build2.log
  echo
  echo "  Compare the two lists. After editing one source file:"
  echo "    - WORKDIR stays CACHED           it comes BEFORE the COPY"
  echo "    - COPY app/ ./ is REBUILT        its input changed"
  echo "    - RUN go build is REBUILT        it comes AFTER the changed COPY"
  echo "    - RUN adduser stays CACHED       separate stage, nothing it uses changed"
  echo "    - COPY --from=builder REBUILT    the binary it copies is different"
  echo
  echo "  A changed layer invalidates itself AND EVERY LAYER AFTER IT,"
  echo "  within its own stage."
  echo
  echo "  THE RULE:  PUT WHAT CHANGES LEAST AT THE TOP OF THE DOCKERFILE."
  echo
  echo "  In a real Node/Python app that means copying the manifest and"
  echo "  installing dependencies BEFORE copying source code:"
  echo "      COPY package*.json ./     <- changes rarely"
  echo "      RUN npm ci                <- expensive, stays cached"
  echo "      COPY . .                  <- changes every commit"
  echo "  Copy everything first and npm ci reruns on every single commit."

  hr "STEP 6 - The images actually work"
  for tag in naive multistage alpine; do
    CID=$(docker run -d -P hellosvc:$tag 2>/dev/null)
    sleep 1
    PORT=$(docker port "$CID" 8080/tcp 2>/dev/null | head -1 | sed 's/.*://')
    CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://localhost:$PORT/" 2>/dev/null)
    BODY=$(curl -s --max-time 5 "http://localhost:$PORT/" 2>/dev/null | head -1)
    printf "  %-22s HTTP %-4s %s\n" "hellosvc:$tag" "$CODE" "$BODY"
    docker rm -f "$CID" >/dev/null 2>&1
  done
  echo
  echo "Identical behaviour. The only difference is what got shipped."

  hr "STEP 7 - .dockerignore and the build context"
  echo "Every build sends a CONTEXT (the directory) to the Docker daemon first."
  echo
  cat .dockerignore | grep -v '^#' | grep -v '^$' | sed 's/^/  excluded: /'
  echo
  echo "Without this, .git and screenshots would be uploaded on every build -"
  echo "slower builds, and a real risk of baking secrets or junk into an image."

  hr "STEP 8 - Tagging and inspection"
  docker tag hellosvc:multistage hellosvc:v1.0.0
  docker tag hellosvc:multistage hellosvc:latest
  docker images hellosvc --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}'
  echo
  echo "Note v1.0.0, latest and multistage share ONE image ID - tags are just"
  echo "pointers, not copies."
  echo
  echo "NEVER deploy ':latest' in production: it is mutable, so two clusters can"
  echo "run different code from the same tag and you cannot tell what shipped."
  echo
  sub "useful inspection"
  docker image inspect hellosvc:multistage \
    --format '  entrypoint: {{.Config.Entrypoint}}{{"\n"}}  exposed:    {{.Config.ExposedPorts}}{{"\n"}}  layers:     {{len .RootFS.Layers}}{{"\n"}}  arch:       {{.Os}}/{{.Architecture}}'

  hr "DONE"
}

cleanup() {
  hr "CLEANUP"
  docker rmi -f hellosvc:naive hellosvc:multistage hellosvc:alpine hellosvc:v1.0.0 hellosvc:latest 2>/dev/null
  echo "images removed"
}

case "${1:-all}" in
  all) build_all; verify ;;
  build) build_all ;;
  verify) verify ;;
  cleanup) cleanup ;;
  *) echo "usage: $0 [all|build|verify|cleanup]"; exit 1 ;;
esac
