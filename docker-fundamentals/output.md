# Docker Fundamentals - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-09-18.

```text

==============================================================
1. IMAGE vs CONTAINER - the distinction everything rests on
==============================================================
  IMAGE     = a read-only template (a filesystem + metadata). Like a class.
  CONTAINER = a running instance of an image, with a thin writable layer
              on top. Like an object.

  One image -> many containers, each isolated from the others.

==============================================================
2. BUILD two small apps
==============================================================
  built demo/node-app:1.0
  built demo/python-app:1.0

REPOSITORY        TAG       SIZE
demo/python-app   1.0       87.8MB
demo/node-app     1.0       194MB

==============================================================
3. RUN a container and publish a port
==============================================================
$ docker run -d --name demo-node -p 3000:3000 demo/node-app:1.0
NAMES       IMAGE               STATUS         PORTS
demo-node   demo/node-app:1.0   Up 2 seconds   0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp

  -d  detached (background)    --name  a stable name instead of a random one
  -p HOST:CONTAINER  publish a port

  -p 3000:3000 means: traffic to localhost:3000 on the HOST is forwarded
  to port 3000 INSIDE the container. Without -p the port is unreachable
  from outside, even though the process is listening.

--- proof it works ---
  {
    "app": "node-app",
    "hostname": "1c02bb742b95",
    "platform": "linux/arm64",
    "node": "v20.20.2",
    "uptime_s": 2,
    "path": "/hello"
  }
==============================================================
4. ENVIRONMENT VARIABLES and a second container from the SAME image
==============================================================
$ docker run -d --name demo-py -p 5001:5000 -e APP_NAME=custom-name demo/python-app:1.0
  (host port 5001 because macOS AirPlay Receiver already owns 5000 -
   the HOST port must be free, the CONTAINER port does not care)
  {
    "app": "custom-name",
    "hostname": "12c6092287bd",
    "platform": "Linux/aarch64",
    "python": "3.12.14",
    "path": "/"
  }
  APP_NAME came from -e, overriding the ENV baked into the image.
  This is how one image serves dev, staging and prod: same artifact,
  different configuration injected at runtime.

==============================================================
5. THE CONTAINER LIFECYCLE
==============================================================
  created -> running -> paused -> stopped -> removed

  after run                    running
  after pause                  paused
  after unpause                running
  after stop                   exited (exit 137, took 1s)

  >>> EXIT 137 = 128 + 9 = SIGKILL, and the stop took ~1s.
      docker stop sends SIGTERM first and waits 10s. This app never
      installs a SIGTERM handler, so it ignored it and Docker had to
      SIGKILL it. A clean shutdown would exit 0 almost instantly.
      In production that means dropped in-flight requests on every deploy.
  after start (restarted)      running

  A STOPPED container still exists - its writable layer is on disk and
  'docker start' brings it back. It is gone only after 'docker rm'.

--- docker ps -a shows stopped containers too ---
NAMES           STATUS
demo-detached   Up 1 second
demo-py         Up 5 seconds
demo-node       Up 8 seconds

==============================================================
6. LOGS
==============================================================
$ docker logs demo-node
  node-app listening on :3000

  docker logs captures the container's STDOUT and STDERR.
  That is why containerised apps should log to stdout, NOT to a file:
  a log file inside a container disappears with the container.

  docker logs -f <c>          follow live
  docker logs --tail 50 <c>   last 50 lines
  docker logs --since 10m <c> recent only

==============================================================
7. EXEC - get a shell inside a running container
==============================================================
$ docker exec demo-node hostname
  1c02bb742b95
$ docker exec demo-node ps -o pid,comm
  PID   COMMAND
      1 node
     20 ps

  NOTE: the app is PID 1 inside the container. There is no init system,
  so PID 1 must handle SIGTERM itself or 'docker stop' will wait the full
  10s grace period and then SIGKILL it.

$ docker exec demo-node whoami
  node
  ^ not root, because the Dockerfile sets USER node.

==============================================================
8. INSPECT - everything Docker knows about a container
==============================================================
  image     : demo/node-app:1.0
  status    : running
  pid       : 238800
  ip        : 172.17.0.9
  ports     : {"3000/tcp":[{"HostIp":"0.0.0.0","HostPort":"3000"},{"HostIp":"::","HostPort":"3000"}]}
  user      : node
  cmd       : ["node","server.js"]

==============================================================
9. RESOURCE LIMITS - a container is NOT limited by default
==============================================================
$ docker run -d --name demo-limits --memory=64m --cpus=0.5 demo/node-app:1.0
  memory limit : 67108864 bytes
  cpu quota    : 500000000 nano-cpus (1e9 = 1 core)


--- docker stats (live resource usage, one sample) ---
NAME          CPU %     MEM USAGE / LIMIT     MEM %
demo-node     0.00%     50.17MiB / 7.749GiB   0.63%
demo-py       0.01%     22.76MiB / 7.749GiB   0.29%
demo-limits   0.00%     7.738MiB / 64MiB      12.09%

  Without --memory a container can consume ALL host RAM and take the
  machine down. This is what Kubernetes resource limits map onto.

==============================================================
10. RESTART POLICIES
==============================================================
  restart policy: on-failure (max 3 retries)

    no              default - never restart
    on-failure[:N]  restart only on a non-zero exit, at most N times
    always          always restart, including on daemon start
    unless-stopped  like always, but not if you stopped it manually

==============================================================
11. CLEANING UP
==============================================================
  docker stop $(docker ps -q)      stop all running
  docker rm -f $(docker ps -aq)    force remove all
  docker rmi $(docker images -q)   remove all images
  docker system prune -a           remove everything unused  <-- destructive
  docker system df                 what is using disk


--- docker system df ---
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          252       57        89.08GB   48.58GB (54%)
Containers      74        22        1.595GB   948.6MB (59%)
Local Volumes   195       23        97.26GB   905.9MB (0%)
Build Cache     1250      43        70.96GB   18.14GB


--- removing this demo's containers ---
  removed demo-node
  removed demo-py
  removed demo-detached
  removed demo-restart
  removed demo-limits

==============================================================
DONE
==============================================================
```
