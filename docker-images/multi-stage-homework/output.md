# Multi-Stage Build Homework - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07, then `./run.sh cleanup` once the screenshots were taken.

```text
$ ./run.sh

==============================================================
STEP 1 - Clone the repository that contains the multi-stage Dockerfile
==============================================================
$ git clone --depth 1 https://github.com/Nency-Ravaliya/devops-heros.git
  cloned commit 8376590 (2026-10-05) replicas from 2 to 5

$ ls session6-7-docker/multi-stage-dockerfile
  Dockerfile
  package.json
  server.js

--- the Dockerfile ---
  # -------------------------
  # Stage 1: Build
  # -------------------------
  FROM node:24-alpine AS builder
  WORKDIR /app
  COPY package*.json ./
  RUN npm install
  COPY . .
  
  # -------------------------
  # Stage 2: Production
  # -------------------------
  FROM node:24-alpine AS production
  WORKDIR /app
  COPY --from=builder /app/package*.json ./
  RUN npm install --omit=dev
  COPY --from=builder /app/server.js ./
  EXPOSE 3000
  CMD ["npm", "start"]

--- server.js ---
  const express = require("express");
  
  const app = express();
  const PORT = 3000;
  
  app.get("/", (req, res) => {
    res.send("<h1>Hello World from Docker Multi-Stage Build!</h1>");
  });
  
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });

==============================================================
STEP 2 - Build the image with the multi-stage Dockerfile
==============================================================
$ docker build -t multi-stage-hello:1.0 .
  build OK. Steps BuildKit ran, per stage:
    [builder 1/5] FROM docker.io/library/node:24-alpine@sha256:ebfe2f90462722a7a4de65e9199
    [builder 2/5] WORKDIR /app
    [builder 3/5] COPY package*.json ./
    [builder 4/5] RUN npm install
    [builder 5/5] COPY . .
    [production 3/5] COPY --from=builder /app/package*.json ./
    [production 4/5] RUN npm install --omit=dev
    [production 5/5] COPY --from=builder /app/server.js ./

==============================================================
STEP 3 - Run a container from it, host port 8080 -> container port 3000
==============================================================
$ docker run -d --name multi-stage-app -p 8080:3000 multi-stage-hello:1.0
  c410520b9af2

$ docker logs multi-stage-app
  
  > docker-hello-world@1.0.0 start
  > node server.js
  
  Server running on port 3000

==============================================================
STEP 4 - Access the application
==============================================================
$ curl -i http://localhost:8080/
  HTTP/1.1 200 OK
  X-Powered-By: Express
  Content-Type: text/html; charset=utf-8
  Content-Length: 51
  
  <h1>Hello World from Docker Multi-Stage Build!</h1>


  >>> PASS: the page says 'Hello World from Docker Multi-Stage Build!'

==============================================================
STEP 5 - Verify with docker ps, and confirm port 8080
==============================================================
$ docker ps --filter name=multi-stage-app
CONTAINER ID   IMAGE                   STATUS         PORTS                                         NAMES
c410520b9af2   multi-stage-hello:1.0   Up 3 seconds   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp   multi-stage-app

$ docker port multi-stage-app
  3000/tcp -> 0.0.0.0:8080
  3000/tcp -> [::]:8080

$ lsof -nP -iTCP:8080 -sTCP:LISTEN     (on the Mac itself)
  COMMAND    TYPE  NODE  NAME
  com.docke  IPv6  TCP   *:8080  (LISTEN)

  The app listens on 3000 INSIDE the container; Docker publishes it on
  port 8080 of the host, which is the port the browser and curl use.

==============================================================
STEP 6 - Same app, single-stage build, for comparison
==============================================================
$ docker build -f Dockerfile.single-stage -t multi-stage-hello:single <clone>/session6-7-docker/multi-stage-dockerfile
  built multi-stage-hello:single

  IMAGE                         ON DISK     DOWNLOAD  LAYERS
  multi-stage-hello:single        255MB       64.9MB       8
  multi-stage-hello:1.0           249MB       64.0MB       8

--- what is in /app in each image ---
  multi-stage-hello:single   Dockerfile node_modules package-lock.json package.json server.js 
                             node_modules: 65 packages, 4.3M
  multi-stage-hello:1.0      node_modules package-lock.json package.json server.js 
                             node_modules: 65 packages, 4.3M

--- npm's download cache (/root/.npm) left behind in each image ---
  multi-stage-hello:single   7.5M   (66 package tarballs, 65 registry metadata documents)
  multi-stage-hello:1.0      2.1M   (66 package tarballs, 0 registry metadata documents)

  The single-stage build ran 'npm install' with only package.json, so npm
  had to download every package's metadata to resolve versions. The
  production stage got package-lock.json from the builder (COPY package*.json),
  so it fetched the exact tarballs and no metadata.

--- layers of the multi-stage image (only the final stage is in it) ---
CREATED BY                                      SIZE
CMD ["npm" "start"]                             0B
EXPOSE [3000/tcp]                               0B
COPY /app/server.js ./ # buildkit               12.3kB
RUN /bin/sh -c npm install --omit=dev # buil…   9.44MB
COPY /app/package*.json ./ # buildkit           45.1kB
WORKDIR /app                                    8.19kB
CMD ["node"]                                    0B

  clone removed from /var/folders/gk/f_l1kjks5bq7lbb62mnpv16w0000gn/T/tmp.8abmX5GvQf

==============================================================
STEP 7 - Task 3: deploy three different types of application
==============================================================
  The Node.js, Python and Java apps live in docker-fundamentals/hello-world-apps/.

$ docker run -d --name hello-nodejs -p 8081:3000 hello/nodejs-app:1.0
  43a738febecf
$ docker run -d --name hello-python -p 8082:5000 hello/python-app:1.0
  5a26eff1496d
$ docker run -d --name hello-java -p 8083:8080 hello/java-app:1.0
  1c1033bf61ad

  curl localhost:8081  ->  Hello World from Node.js
  curl localhost:8082  ->  Hello World from Python
  curl localhost:8083  ->  Hello World from Java

--- docker ps - the multi-stage app plus three different stacks ---
NAMES             IMAGE                   STATUS          PORTS
hello-java        hello/java-app:1.0      Up 2 seconds    0.0.0.0:8083->8080/tcp
hello-python      hello/python-app:1.0    Up 6 seconds    0.0.0.0:8082->5000/tcp
hello-nodejs      hello/nodejs-app:1.0    Up 9 seconds    0.0.0.0:8081->3000/tcp
multi-stage-app   multi-stage-hello:1.0   Up 27 seconds   0.0.0.0:8080->3000/tcp

$ ./run.sh cleanup

==============================================================
CLEANUP
==============================================================
  removed multi-stage-app, hello-nodejs, hello-python, hello-java and the multi-stage-hello images
  (hello/* images are left for docker-fundamentals/hello-world-apps/run.sh cleanup)
```
