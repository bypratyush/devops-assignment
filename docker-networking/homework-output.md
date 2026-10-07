# Docker Networking & Volume Homework - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `SHOTS=1 ./homework.sh` on 2026-10-07 (tasks 1-3; task 4 is research, see README.md).

```text
$ SHOTS=1 ./homework.sh

==============================================================
TASK 1 - Container networking: frontend, backend, database on 3 networks
==============================================================

--- 1.1 create three user-defined bridge networks ---
$ docker network create frontend-net
$ docker network create backend-net
$ docker network create db-net

NAME           DRIVER    SCOPE
backend-net    bridge    local
db-net         bridge    local
frontend-net   bridge    local

  frontend-net  subnet 172.21.0.0/16  gateway 172.21.0.1
  backend-net  subnet 172.22.0.0/16  gateway 172.22.0.1
  db-net  subnet 172.23.0.0/16  gateway 172.23.0.1

--- 1.2 one container per tier, each on its own network ---
$ docker run -d --name database --network db-net -e MYSQL_ROOT_PASSWORD=*** -e MYSQL_DATABASE=appdb mysql:8.4
  0f6990bf1a28
$ docker run -d --name backend  --network backend-net  -v ./homework/backend/default.conf:/etc/nginx/conf.d/default.conf:ro nginx:1.30-alpine
  75b4dc503b51
$ docker run -d --name frontend --network frontend-net -v ./homework/frontend:/usr/share/nginx/html:ro nginx:1.30-alpine
  f790d8990355

  waiting for MySQL to accept TCP connections on 3306................ ready after 45s

  frontend  frontend-net(172.21.0.2) 
  backend   backend-net(172.22.0.2) 
  database  db-net(172.23.0.2) 

--- 1.3 connectivity now: every tier is isolated ---
    from \ to  | frontend:80   backend:8080  database:3306 
    -----------+-------------------------------------------
    frontend   | -             no DNS        no DNS        
    backend    | no DNS        -             no DNS        
    database   | no DNS        no DNS        -             

  'no DNS' means the name does not even resolve: Docker's embedded DNS
  (127.0.0.11) only answers for containers that share a network with you.

--- 1.4 attach the backend to a SECOND network (db-net) ---
$ docker network connect db-net backend
  backend   backend-net(172.22.0.2) db-net(172.23.0.3) 

$ docker exec backend ip -o -f inet addr show      (one interface per network)
  lo    127.0.0.1/8
  eth0  172.22.0.2/16
  eth1  172.23.0.3/16

    from \ to  | frontend:80   backend:8080  database:3306 
    -----------+-------------------------------------------
    frontend   | -             no DNS        no DNS        
    backend    | no DNS        -             OK            
    database   | no DNS        OK            -             

  backend <-> database works in both directions now; frontend is still alone.

--- 1.5 let the frontend call the API: join it to backend-net ---
$ docker network connect backend-net frontend

  frontend  backend-net(172.22.0.3) frontend-net(172.21.0.2) 
  backend   backend-net(172.22.0.2) db-net(172.23.0.3) 
  database  db-net(172.23.0.2) 

    from \ to  | frontend:80   backend:8080  database:3306 
    -----------+-------------------------------------------
    frontend   | -             OK            no DNS        
    backend    | OK            -             OK            
    database   | no DNS        OK            -             

  Final picture: frontend -> backend -> database, and NO path from the
  frontend to the database. The backend sits on 2 networks (backend-net
  and db-net) and is the only way into the data tier.

--- 1.6 the same results with real tools ---
$ docker exec frontend ping -c 2 backend
  PING backend (172.22.0.2): 56 data bytes
  64 bytes from 172.22.0.2: seq=0 ttl=64 time=0.144 ms
  64 bytes from 172.22.0.2: seq=1 ttl=64 time=0.272 ms
  
  --- backend ping statistics ---
  2 packets transmitted, 2 packets received, 0% packet loss
  round-trip min/avg/max = 0.144/0.208/0.272 ms

$ docker exec frontend wget -qO- http://backend:8080/
  {"service":"backend","db_host":"database:3306","status":"ok"}

$ docker exec frontend ping -c 2 database
  ping: bad address 'database'

$ docker exec backend ping -c 2 database
  PING database (172.23.0.2): 56 data bytes
  64 bytes from 172.23.0.2: seq=0 ttl=64 time=0.335 ms
  64 bytes from 172.23.0.2: seq=1 ttl=64 time=0.132 ms
  
  --- database ping statistics ---
  2 packets transmitted, 2 packets received, 0% packet loss
  round-trip min/avg/max = 0.132/0.233/0.335 ms

$ docker exec backend sh -c 'nc -w 2 database 3306 | head -c 100'   (MySQL's greeting packet, printable parts)
tr: Illegal byte sequence
  8.4.11

  The backend image has no MySQL client, so borrow one: a throwaway mysql:8.4
  container started with --network container:<name> shares that container's
  network namespace, i.e. it sees exactly what the backend (or frontend) sees.

$ docker run --rm --network container:backend mysql:8.4 mysqladmin -h database -uroot -p*** ping
  mysqld is alive
$ docker run --rm --network container:backend mysql:8.4 mysql -h database -uroot -p*** -e 'SELECT @@hostname, @@version, DATABASE()' appdb
  @@hostname	@@version	DATABASE()
  0f6990bf1a28	8.4.11	appdb
  (@@hostname is the database container's ID: 0f6990bf1a28)

$ docker run --rm --network container:frontend mysql:8.4 mysqladmin -h database -uroot -p*** ping
  mysqladmin: connect to server at 'database' failed
  error: 'Unknown MySQL server host 'database' (-2)'
  Check that mysqld is running on database and that the port is 3306.
  You can check this by doing 'telnet database 3306'

--- 1.7 it is not just DNS: even the database's IP is unreachable from the frontend ---
$ docker exec frontend nc -z -w 3 172.23.0.2 3306
  failed - exit 1, no route between the two bridges
$ docker exec backend  nc -z -w 3 172.23.0.2 3306
  connected

  Docker installs firewall rules that drop traffic between different
  bridge networks, so knowing the IP does not help.

--- 1.8 docker network inspect - who is on which network ---
  frontend-net (172.21.0.0/16):  frontend=172.21.0.2/16
  backend-net (172.22.0.0/16):  backend=172.22.0.2/16  frontend=172.22.0.3/16
  db-net (172.23.0.0/16):  database=172.23.0.2/16  backend=172.23.0.3/16

$ docker network inspect db-net    (trimmed to the interesting part)
  {
    "Name": "db-net",
    "Driver": "bridge",
    "Internal": false,
    "IPAM": [
      {
        "Subnet": "172.23.0.0/16",
        "Gateway": "172.23.0.1"
      }
    ],
    "Containers": {
      "database": {
        "IPv4Address": "172.23.0.2/16",
        "MacAddress": "ae:9d:5d:b5:56:4f"
      },
      "backend": {
        "IPv4Address": "172.23.0.3/16",
        "MacAddress": "7a:67:85:0f:57:06"
      }
    }
  }

--- screenshots ---
  hw-connectivity-matrix.png  (388K)
  hw-network-inspect.png  (132K)
  hw-ping-and-mysql.png  (324K)

--- 1.9 cleanup ---
  containers frontend, backend, database and the three networks removed

==============================================================
TASK 2 - Apache2 (httpd) on the HOST network, port 80
==============================================================

--- 2.1 straight attempt on Docker Desktop ---
$ docker run -d --name apache-host --network host httpd:2.4-alpine
  3ce2539dc46c

$ docker ps -a --filter name=apache-host
NAMES         STATUS                     PORTS
apache-host   Exited (1) 2 seconds ago   

$ docker logs apache-host
  AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 192.168.65.3. Set the 'ServerName' directive globally to suppress this message
  (98)Address in use: AH00072: make_sock: could not bind to address [::]:80
  (98)Address in use: AH00072: make_sock: could not bind to address 0.0.0.0:80
  no listening sockets available, shutting down
  AH00015: Unable to open logs

  It exited: port 80 is already taken. 'host' here is not the Mac but the
  Linux VM Docker Desktop runs, and in that VM port 80 is held by the
  port mapping of the kind cluster used for the Kubernetes homework:

$ docker ps --filter publish=80
NAMES                     PORTS
devops-hw-control-plane   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:30080->30080/tcp, 127.0.0.1:54986-

$ docker run --rm --network host alpine:3.19 netstat -tln | grep ':80 '   (listeners in the VM)
  tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      

--- 2.2 a clean host with a free port 80: Docker-in-Docker ---
  docker:dind is a container running its own Docker daemon. For containers
  started BY that inner daemon, the dind container's network namespace is
  the host, and its port 80 is free. The kind cluster is left untouched.

$ docker run -d --privileged --name dind-host -e DOCKER_TLS_CERTDIR= -p 8088:80 docker:29-dind
  26958a71d71d
  inner daemon up: Docker 29.8.2

$ docker save httpd:2.4-alpine | docker exec -i dind-host docker load   (no second pull from Docker Hub)
  Loaded image: httpd:2.4-alpine

--- 2.3 the Apache2 container on the host network, inside that host ---
$ docker exec dind-host docker run -d --name apache2 --network host httpd:2.4-alpine
  cff7e3749c0a

$ docker exec dind-host docker ps
NAMES     IMAGE              STATUS         PORTS
apache2   httpd:2.4-alpine   Up 5 seconds   

$ docker exec dind-host docker inspect apache2 -f 'mode={{.HostConfig.NetworkMode}} ip={{...IPAddress}}'
  mode=host  ip=invalid IP(none of its own)

$ docker exec dind-host netstat -tlnp | grep ':80 '   (httpd is listening in the HOST's namespace)
  tcp        0      0 :::80                   :::*                    LISTEN      642/httpd

$ docker exec dind-host wget -qO- http://localhost:80/
  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
  <html>
  <head>
  <title>It works! Apache httpd</title>
  </head>
  <body>
  <p>It works!</p>
  </body>
  </html>

$ docker exec dind-host wget -qO- http://172.17.0.3:80/   (the host's own IP, port 80 directly)
  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
  <html>
  <head>
  <title>It works! Apache httpd</title>
  </head>
  <body>
  <p>It works!</p>
  </body>
  </html>

  No -p was given to the inner 'docker run' and no port mapping exists for
  apache2: it simply IS on the host's port 80.

--- 2.4 and from the Mac ---
$ curl -s http://localhost:8088/
  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
  <html>
  <head>
  <title>It works! Apache httpd</title>
  </head>
  <body>
  <p>It works!</p>
  </body>
  </html>

  Mac :8088 -> dind-host :80 (the one -p mapping) -> apache2, which listens
  on that host's port 80 itself because it shares the host network stack.

--- screenshots ---
  hw-host-network-port80-taken.png  (88K)
  hw-host-network-apache.png  (200K)
  hw-host-network-browser.png  (4.0K)

--- 2.5 cleanup ---
  dind-host (and the apache2 container inside it) removed

==============================================================
TASK 3 - Bind mount a host folder into nginx, edit it live
==============================================================

--- 3.1 create the folder and index.html on the Mac ---
$ mkdir -p bind-mount-site && echo '<h1>Hello students</h1>' > bind-mount-site/index.html
  drwxr-xr-x@ 3 pratyushmohanty  staff   96 Oct  7 23:56 .
  drwxr-xr-x@ 9 pratyushmohanty  staff  288 Oct  7 23:56 ..
  -rw-r--r--@ 1 pratyushmohanty  staff   24 Oct  7 23:56 index.html

--- 3.2 bind mount it over nginx's document root ---
$ docker run -d --name bind-nginx -p 8090:80 -v "$PWD/bind-mount-site:/usr/share/nginx/html:ro" nginx:1.30-alpine
  36edd6bbd65b
  mount: bind  /Users/pratyushmohanty/Devops-assignment/docker-networking/bind-mount-site -> /usr/share/nginx/html  rw=false

--- 3.3 access it ---
$ curl -s http://localhost:8090/
  <h1>Hello students</h1>
  container StartedAt: 2026-10-07T18:26:54.094522592Z
  hw-bind-mount-before.png  (8.0K)

--- 3.4 modify index.html ON THE HOST (not in the container) ---
$ echo '<h1>Hello students - edited on the Mac at 23:57:03, no restart</h1>' > bind-mount-site/index.html

--- 3.5 access it again ---
$ curl -s http://localhost:8090/
  <h1>Hello students - edited on the Mac at 23:57:03, no restart</h1>
$ docker exec bind-nginx cat /usr/share/nginx/html/index.html
  <h1>Hello students - edited on the Mac at 23:57:03, no restart</h1>
  hw-bind-mount-after.png  (12K)

  StartedAt before the edit : 2026-10-07T18:26:54.094522592Z
  StartedAt after the edit  : 2026-10-07T18:26:54.094522592Z
  RestartCount              : 0
  >>> same start time: the change was picked up with NO restart

--- 3.6 the mount is read-only from the container's side (:ro) ---
$ docker exec bind-nginx sh -c 'echo hacked > /usr/share/nginx/html/index.html'
  sh: can't create /usr/share/nginx/html/index.html: Read-only file system
  The host can change the site; the web server cannot.

--- screenshots ---
  hw-bind-mount-curl.png  (84K)

--- 3.7 cleanup ---
  bind-nginx removed, bind-mount-site/index.html put back to the original text

==============================================================
DONE
==============================================================
```

## Task 1 again, after fixing the `tr` locale issue

The Task 1 screenshots (`screenshots/hw-*matrix*`, `hw-network-inspect`, `hw-ping-and-mysql`) were taken during this second run, so its IPs differ from the run above.

```text
$ SHOTS=1 ./homework.sh task1

==============================================================
TASK 1 - Container networking: frontend, backend, database on 3 networks
==============================================================

--- 1.1 create three user-defined bridge networks ---
$ docker network create frontend-net
$ docker network create backend-net
$ docker network create db-net

NAME           DRIVER    SCOPE
backend-net    bridge    local
db-net         bridge    local
frontend-net   bridge    local

  frontend-net  subnet 172.18.0.0/16  gateway 172.18.0.1
  backend-net  subnet 172.19.0.0/16  gateway 172.19.0.1
  db-net  subnet 172.21.0.0/16  gateway 172.21.0.1

--- 1.2 one container per tier, each on its own network ---
$ docker run -d --name database --network db-net -e MYSQL_ROOT_PASSWORD=*** -e MYSQL_DATABASE=appdb mysql:8.4
  90868a6783b0
$ docker run -d --name backend  --network backend-net  -v ./homework/backend/default.conf:/etc/nginx/conf.d/default.conf:ro nginx:1.30-alpine
  de12dcdc51f0
$ docker run -d --name frontend --network frontend-net -v ./homework/frontend:/usr/share/nginx/html:ro nginx:1.30-alpine
  67b45ed1f660

  waiting for MySQL to accept TCP connections on 3306..... ready after 10s

  frontend  frontend-net(172.18.0.2) 
  backend   backend-net(172.19.0.2) 
  database  db-net(172.21.0.2) 

--- 1.3 connectivity now: every tier is isolated ---
    from \ to  | frontend:80   backend:8080  database:3306 
    -----------+-------------------------------------------
    frontend   | -             no DNS        no DNS        
    backend    | no DNS        -             no DNS        
    database   | no DNS        no DNS        -             

  'no DNS' means the name does not even resolve: Docker's embedded DNS
  (127.0.0.11) only answers for containers that share a network with you.

--- 1.4 attach the backend to a SECOND network (db-net) ---
$ docker network connect db-net backend
  backend   backend-net(172.19.0.2) db-net(172.21.0.3) 

$ docker exec backend ip -o -f inet addr show      (one interface per network)
  lo    127.0.0.1/8
  eth0  172.19.0.2/16
  eth1  172.21.0.3/16

    from \ to  | frontend:80   backend:8080  database:3306 
    -----------+-------------------------------------------
    frontend   | -             no DNS        no DNS        
    backend    | no DNS        -             OK            
    database   | no DNS        OK            -             

  backend <-> database works in both directions now; frontend is still alone.

--- 1.5 let the frontend call the API: join it to backend-net ---
$ docker network connect backend-net frontend

  frontend  backend-net(172.19.0.3) frontend-net(172.18.0.2) 
  backend   backend-net(172.19.0.2) db-net(172.21.0.3) 
  database  db-net(172.21.0.2) 

    from \ to  | frontend:80   backend:8080  database:3306 
    -----------+-------------------------------------------
    frontend   | -             OK            no DNS        
    backend    | OK            -             OK            
    database   | no DNS        OK            -             

  Final picture: frontend -> backend -> database, and NO path from the
  frontend to the database. The backend sits on 2 networks (backend-net
  and db-net) and is the only way into the data tier.

--- 1.6 the same results with real tools ---
$ docker exec frontend ping -c 2 backend
  PING backend (172.19.0.2): 56 data bytes
  64 bytes from 172.19.0.2: seq=0 ttl=64 time=0.075 ms
  64 bytes from 172.19.0.2: seq=1 ttl=64 time=0.070 ms
  
  --- backend ping statistics ---
  2 packets transmitted, 2 packets received, 0% packet loss
  round-trip min/avg/max = 0.070/0.072/0.075 ms

$ docker exec frontend wget -qO- http://backend:8080/
  {"service":"backend","db_host":"database:3306","status":"ok"}

$ docker exec frontend ping -c 2 database
  ping: bad address 'database'

$ docker exec backend ping -c 2 database
  PING database (172.21.0.2): 56 data bytes
  64 bytes from 172.21.0.2: seq=0 ttl=64 time=0.108 ms
  64 bytes from 172.21.0.2: seq=1 ttl=64 time=0.095 ms
  
  --- database ping statistics ---
  2 packets transmitted, 2 packets received, 0% packet loss
  round-trip min/avg/max = 0.095/0.101/0.108 ms

$ docker exec backend sh -c 'nc -w 2 database 3306 | head -c 100'   (MySQL's greeting packet, printable parts)
  8.4.11
  caching_sha2_password

  The backend image has no MySQL client, so borrow one: a throwaway mysql:8.4
  container started with --network container:<name> shares that container's
  network namespace, i.e. it sees exactly what the backend (or frontend) sees.

$ docker run --rm --network container:backend mysql:8.4 mysqladmin -h database -uroot -p*** ping
  mysqld is alive
$ docker run --rm --network container:backend mysql:8.4 mysql -h database -uroot -p*** -e 'SELECT @@hostname, @@version, DATABASE()' appdb
  @@hostname	@@version	DATABASE()
  90868a6783b0	8.4.11	appdb
  (@@hostname is the database container's ID: 90868a6783b0)

$ docker run --rm --network container:frontend mysql:8.4 mysqladmin -h database -uroot -p*** ping
  mysqladmin: connect to server at 'database' failed
  error: 'Unknown MySQL server host 'database' (-2)'
  Check that mysqld is running on database and that the port is 3306.
  You can check this by doing 'telnet database 3306'

--- 1.7 it is not just DNS: even the database's IP is unreachable from the frontend ---
$ docker exec frontend nc -z -w 3 172.21.0.2 3306
  failed - exit 1, no route between the two bridges
$ docker exec backend  nc -z -w 3 172.21.0.2 3306
  connected

  Docker installs firewall rules that drop traffic between different
  bridge networks, so knowing the IP does not help.

--- 1.8 docker network inspect - who is on which network ---
  frontend-net (172.18.0.0/16):  frontend=172.18.0.2/16
  backend-net (172.19.0.0/16):  frontend=172.19.0.3/16  backend=172.19.0.2/16
  db-net (172.21.0.0/16):  database=172.21.0.2/16  backend=172.21.0.3/16

$ docker network inspect db-net    (trimmed to the interesting part)
  {
    "Name": "db-net",
    "Driver": "bridge",
    "Internal": false,
    "IPAM": [
      {
        "Subnet": "172.21.0.0/16",
        "Gateway": "172.21.0.1"
      }
    ],
    "Containers": {
      "database": {
        "IPv4Address": "172.21.0.2/16",
        "MacAddress": "42:e7:b4:df:d1:41"
      },
      "backend": {
        "IPv4Address": "172.21.0.3/16",
        "MacAddress": "d6:3e:43:c9:ab:07"
      }
    }
  }

--- screenshots ---
  hw-connectivity-matrix.png  (132K)
  hw-network-inspect.png  (132K)
  hw-ping-and-mysql.png  (324K)

--- 1.9 cleanup ---
  containers frontend, backend, database and the three networks removed
```
