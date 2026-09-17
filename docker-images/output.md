# Docker Images - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-09-18.

```text

==============================================================
STEP 1 - Build the SAME app three ways
==============================================================
A tiny Go HTTP service, built with three different Dockerfiles.


--- 1a. naive: ship the whole Go toolchain ---
  built hellosvc:naive

--- 1b. multi-stage onto scratch: ship only the binary ---
  built hellosvc:multistage

--- 1c. multi-stage onto alpine: binary + a shell for debugging ---
  built hellosvc:alpine

==============================================================
STEP 2 - THE RESULT: image sizes
==============================================================
Two different, both-correct numbers are reported below, because this
Docker uses the containerd snapshotter:

  ON DISK   what 'docker images' reports - the UNCOMPRESSED size the
            image occupies once unpacked on a node
  DOWNLOAD  what 'docker image inspect .Size' reports - the sum of the
            COMPRESSED layers, i.e. what crosses the network on a pull

  IMAGE                       ON DISK       DOWNLOAD
  ---------------------- ------------ --------------
  hellosvc:naive                1.3GB       293.9 MB
  hellosvc:alpine              18.4MB         5.0 MB
  hellosvc:multistage          6.53MB         1.8 MB

  Comparing like with like (download size):
    naive is 159x larger than the multi-stage build
    every pull saves 292.1 MB  -  on every node, on every deploy

  The gap is the entire Go toolchain: a compiler, the standard library
  source, and build caches that the running service never touches.

==============================================================
STEP 3 - WHY: what is actually inside each image
==============================================================

--- the naive image still has the compiler ---
  go version go1.22.12 linux/arm64
  ---
  251M	/usr/local/go

  A production container does not need a compiler. It is pure attack
  surface and pure bandwidth.


--- the scratch image has NOTHING but the binary ---
  $ docker run --rm --entrypoint ls hellosvc:multistage
  -> exec: "ls"

  $ docker run --rm --entrypoint sh hellosvc:multistage
  -> exec: "sh"

  No shell, no ls, no package manager - there is no OS in there at all.
  Great for security (nothing to exploit), awkward for debugging
  (no 'kubectl exec ... sh'). That is the alpine trade-off.

==============================================================
STEP 4 - LAYERS: an image is a stack of read-only filesystem diffs
==============================================================
$ docker history hellosvc:alpine
CREATED BY                                      SIZE
ENTRYPOINT ["/usr/local/bin/hellosvc"]          0B
EXPOSE [8080/tcp]                               0B
USER appuser                                    0B
COPY /bin/hellosvc /usr/local/bin/hellosvc #…   4.61MB
RUN /bin/sh -c adduser -D -u 10001 appuser #…   41kB
CMD ["/bin/sh"]                                 0B
ADD alpine-minirootfs-3.19.9-aarch64.tar.gz …   8.42MB

Each Dockerfile instruction that changes the filesystem creates a LAYER.
Layers are content-addressed and shared between images, so pulling a
second alpine-based image only downloads the layers you do not have.

==============================================================
STEP 5 - BUILD CACHE: why instruction order matters
==============================================================
BuildKit prints each step as '#N [description]', and separately prints
'#N CACHED' for the ones it reused. Pairing those two tells us exactly
which layers were rebuilt.


--- 5a. rebuild with NO source change ---
    CACHED    [stage-1 2/3] RUN adduser -D -u 10001 appuser
    CACHED    [builder 4/4] RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /bin/h
    CACHED    [builder 2/4] WORKDIR /src
    CACHED    [builder 3/4] COPY app/ ./
    CACHED    [stage-1 3/3] COPY --from=builder /bin/hellosvc /usr/local/bin/hellosvc
    ^ everything reused; nothing had to run again.

--- 5b. append ONE comment to app/main.go, then rebuild ---
    CACHED    [builder 2/4] WORKDIR /src
    REBUILT   [builder 3/4] COPY app/ ./
    REBUILT   [builder 4/4] RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /bin/h
    CACHED    [stage-1 2/3] RUN adduser -D -u 10001 appuser
    REBUILT   [stage-1 3/3] COPY --from=builder /bin/hellosvc /usr/local/bin/hellosvc

  Compare the two lists. After editing one source file:
    - WORKDIR stays CACHED           it comes BEFORE the COPY
    - COPY app/ ./ is REBUILT        its input changed
    - RUN go build is REBUILT        it comes AFTER the changed COPY
    - RUN adduser stays CACHED       separate stage, nothing it uses changed
    - COPY --from=builder REBUILT    the binary it copies is different

  A changed layer invalidates itself AND EVERY LAYER AFTER IT,
  within its own stage.

  THE RULE:  PUT WHAT CHANGES LEAST AT THE TOP OF THE DOCKERFILE.

  In a real Node/Python app that means copying the manifest and
  installing dependencies BEFORE copying source code:
      COPY package*.json ./     <- changes rarely
      RUN npm ci                <- expensive, stays cached
      COPY . .                  <- changes every commit
  Copy everything first and npm ci reruns on every single commit.

==============================================================
STEP 6 - The images actually work
==============================================================
  hellosvc:naive         HTTP 200  hello from the multi-stage build
  hellosvc:multistage    HTTP 200  hello from the multi-stage build
  hellosvc:alpine        HTTP 200  hello from the multi-stage build

Identical behaviour. The only difference is what got shipped.

==============================================================
STEP 7 - .dockerignore and the build context
==============================================================
Every build sends a CONTEXT (the directory) to the Docker daemon first.

  excluded: .git
  excluded: *.md
  excluded: screenshots/
  excluded: output.md
  excluded: *.png

Without this, .git and screenshots would be uploaded on every build -
slower builds, and a real risk of baking secrets or junk into an image.

==============================================================
STEP 8 - Tagging and inspection
==============================================================
REPOSITORY   TAG          IMAGE ID       SIZE
hellosvc     alpine       98598e90093c   18.4MB
hellosvc     latest       b94065c77afd   6.53MB
hellosvc     multistage   b94065c77afd   6.53MB
hellosvc     v1.0.0       b94065c77afd   6.53MB
hellosvc     naive        fd016f37c4e6   1.3GB

Note v1.0.0, latest and multistage share ONE image ID - tags are just
pointers, not copies.

NEVER deploy ':latest' in production: it is mutable, so two clusters can
run different code from the same tag and you cannot tell what shipped.


--- useful inspection ---
  entrypoint: [/hellosvc]
  exposed:    map[8080/tcp:{}]
  layers:     1
  arch:       linux/arm64

==============================================================
DONE
==============================================================
```
