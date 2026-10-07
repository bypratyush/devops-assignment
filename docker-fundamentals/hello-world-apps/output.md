# Hello World Apps - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07, then `./run.sh cleanup` once the screenshots were taken.

```text
$ ./run.sh

==============================================================
STEP 1 - Base images (pinned tags, never :latest)
==============================================================
  eclipse-temurin:21-jdk-alpine      already local
  eclipse-temurin:21-jre-alpine      already local
  httpd:2.4-alpine                   already local
  nginx:1.30-alpine                  already local
  node:24-alpine                     already local
  python:3.13-slim                   already local

==============================================================
STEP 2 - Build one image per folder
==============================================================
  nodejs-app   -> hello/nodejs-app:1.0     built in 1s
  python-app   -> hello/python-app:1.0     built in 1s
  java-app     -> hello/java-app:1.0       built in 1s
  Apache-app   -> hello/apache-app:1.0     built in 1s
  React-app    -> hello/react-app:1.0      built in 1s
  nginx-app    -> hello/nginx-app:1.0      built in 1s

==============================================================
STEP 3 - Run one container per image
==============================================================
$ docker run -d --name hello-nodejs -p 8081:3000 hello/nodejs-app:1.0
  4fee156a8bad
$ docker run -d --name hello-python -p 8082:5000 hello/python-app:1.0
  8d033d9e0db7
$ docker run -d --name hello-java -p 8083:8080 hello/java-app:1.0
  32b2c7979eab
$ docker run -d --name hello-apache -p 8084:80 hello/apache-app:1.0
  347a376153e0
$ docker run -d --name hello-react -p 8085:80 hello/react-app:1.0
  53e7b877bded
$ docker run -d --name hello-nginx -p 8086:80 hello/nginx-app:1.0
  35192b258015

==============================================================
STEP 4 - Is 'Hello World' really on each page?
==============================================================
  nodejs-app   http://localhost:8081  HTTP 200  Hello World from Node.js
  python-app   http://localhost:8082  HTTP 200  Hello World from Python
  java-app     http://localhost:8083  HTTP 200  Hello World from Java
  Apache-app   http://localhost:8084  HTTP 200  Hello World from Apache
  React-app    http://localhost:8085  HTTP 200  (not in the raw HTML)
  nginx-app    http://localhost:8086  HTTP 200  Hello World from Nginx

--- React is different: curl only gets the empty HTML shell ---
$ curl -s http://localhost:8085/ | grep -E 'root|script'
  <script type="module" crossorigin src="/assets/index-CQH-phKj.js"></script>
  <div id="root"></div>

  The text lives in the JavaScript bundle (/assets/index-CQH-phKj.js):
  Hello World from React  <- found in the bundle

  ...and only appears in the page once a browser runs that JavaScript.
  Headless Chrome, DOM after rendering:
    <h1>Hello World from React</h1>

==============================================================
STEP 5 - docker ps: all six running
==============================================================
NAMES          IMAGE                  STATUS          PORTS
hello-nginx    hello/nginx-app:1.0    Up 4 seconds    0.0.0.0:8086->80/tcp
hello-react    hello/react-app:1.0    Up 5 seconds    0.0.0.0:8085->80/tcp
hello-apache   hello/apache-app:1.0   Up 6 seconds    0.0.0.0:8084->80/tcp
hello-java     hello/java-app:1.0     Up 7 seconds    0.0.0.0:8083->8080/tcp
hello-python   hello/python-app:1.0   Up 9 seconds    0.0.0.0:8082->5000/tcp
hello-nodejs   hello/nodejs-app:1.0   Up 10 seconds   0.0.0.0:8081->3000/tcp

==============================================================
STEP 6 - Image sizes
==============================================================
  (docker images = unpacked size on disk; that is what the README table uses)

REPOSITORY         TAG       SIZE
hello/nginx-app    1.0       92.1MB
hello/react-app    1.0       92.4MB
hello/apache-app   1.0       115MB
hello/java-app     1.0       286MB
hello/python-app   1.0       212MB
hello/nodejs-app   1.0       246MB

==============================================================
STEP 7 - Start-up line from each container's log
==============================================================
  hello-nodejs   nodejs-app listening on :3000
  hello-python   Listening at: http://0.0.0.0:5000 (1)
  hello-java     java-app listening on :8080
  hello-apache   AH00489: Apache/2.4.69 (Unix) configured -- resuming normal operations
  hello-react    /docker-entrypoint.sh: Configuration complete; ready for start up
  hello-nginx    /docker-entrypoint.sh: Configuration complete; ready for start up

==============================================================
STEP 8 - Which user each process runs as (user:process x count)
==============================================================
  hello-nodejs   node:MainThread x1   
  hello-python   appuser:gunicorn x3   
  hello-java     app:java x1   
  hello-apache   root:httpd x1   www-data:httpd x3   
  hello-react    nginx:nginx x15   root:nginx x1   
  hello-nginx    nginx:nginx x15   root:nginx x1   

  The node, python and java images run everything as a non-root user.
  httpd and nginx keep a root master process (needed to bind port 80)
  and hand the actual requests to unprivileged workers.

$ ./run.sh cleanup

==============================================================
CLEANUP
==============================================================
  stopped hello-nodejs   exit 0    in 2s
  stopped hello-python   exit 137  in 1s
  stopped hello-java     exit 143  in 1s
  stopped hello-apache   exit 137  in 2s
  stopped hello-react    exit 0    in 1s
  stopped hello-nginx    exit 0    in 1s
  containers and hello/* images removed
```
