# Docker Networking

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

**Form field:** Docker Networking  ·  **Course session:** `session8-docker-networking-volume`

Run it: `./run.sh`  ·  Verified output: [output.md](output.md)

---

## 1. The three built-in network drivers

```text
bridge   the default. Containers get an IP on docker0 and reach the outside
         via NAT. NO automatic DNS between containers.
host     no isolation: the container uses the host's network stack directly.
none     no networking at all, loopback only.
```

![docker networks](screenshots/docker-networks.png)

## 2. The problem with the default bridge

Two containers on the default bridge:

```text
$ docker exec net-a ping -c1 net-b        (by NAME)
  ping: bad address 'net-b'

$ docker exec net-a ping -c1 172.17.0.13  (by IP)
  64 bytes from 172.17.0.13: seq=0 ttl=64 time=1.380 ms
```

**By IP it works. By name it fails.** The default bridge has no service
discovery, and container IPs change on every restart, so hardcoding them is not
an option either.

## 3. The fix: a user-defined bridge

```text
$ docker network create app-net
  subnet: 192.168.112.0/20  driver: bridge

$ docker exec net-a ping -c1 net-b        (by NAME, on app-net)
  64 bytes from 192.168.112.3: seq=0 ttl=64 time=0.294 ms
```

A user-defined bridge runs an **embedded DNS server at 127.0.0.11** that resolves
container names to their current IPs:

```text
$ cat /etc/resolv.conf
nameserver 127.0.0.11
```

**Always create a user-defined network for multi-container apps.** `docker
compose` does this automatically, which is exactly why compose services can reach
each other by service name.

![custom network dns](screenshots/custom-network-dns.png)

## 4. Several networks at once

```text
  net-a networks: bridge(172.17.0.11) app-net(192.168.112.2)
```

One interface per network. This is how you isolate tiers: put the web container
on `frontend` and `backend`, and the database on `backend` only, so the database
is simply unreachable from outside.

## 5. Host and none

```text
  network mode: host   ip assigned: (none)
```

With `host` there is no separate IP and `-p` is ignored, because there is nothing
to forward. Faster (no NAT) but no isolation and real port collisions.

> On macOS, Docker runs inside a Linux VM, so `host` means *the VM*, not your
> Mac. This confuses a lot of people.

```text
$ docker exec net-none ip -brief addr
  lo    UNKNOWN    127.0.0.1/8 ::1/128
```

`none` gives loopback only, for batch jobs that must not touch the network.

## 6. Publishing ports

```text
EXPOSE 8080            Dockerfile: DOCUMENTATION only, publishes nothing
-p 8080:80             publish container port 80 as host port 8080
-p 127.0.0.1:8080:80   bind to localhost only, not reachable from the LAN
-P                     publish every EXPOSEd port to random high ports
```

Containers on the same user-defined network reach each other on the **container**
port directly. `-p` is only needed for traffic from outside.

## 7. Volumes: data that outlives the container

```text
$ docker run --rm -v demo-data:/data alpine sh -c 'echo "..." > /data/note.txt'
  (that container is then REMOVED)

$ docker run --rm -v demo-data:/data alpine cat /data/note.txt
  written at 19:14:29 by container 1
```

The data survived the container that created it. A container's writable layer is
deleted with the container; anything that must persist goes in a volume.

## 8. Bind mounts

```text
$ docker run -v /tmp/xyz:/mnt alpine cat /mnt/hostfile.txt
  host file content

  writing from the container:
  host file content
  added by container
```

Changes flow **both ways**.

```text
VOLUME       docker-managed, portable, best for DATA
BIND MOUNT   a specific host path, best for SOURCE CODE in development
tmpfs        in memory only, never written to disk, for secrets
```

---

## Interview Q&A

**Q: Why can't my containers talk to each other by name?**
They are on the default bridge, which has no DNS. Create a user-defined network
(`docker network create`) and attach them; it provides an embedded DNS server
that resolves container names.

**Q: bridge vs host vs none?**
`bridge` gives the container its own network namespace and IP with NAT to the
outside. `host` shares the host's stack, so no isolation, no `-p`, but no NAT
overhead. `none` gives loopback only.

**Q: Volume vs bind mount?**
A volume is managed by Docker in its own storage area, is portable and is the
right choice for data. A bind mount maps a specific host path, which is ideal for
mounting source code during development but ties you to the host's layout.

**Q: How do you isolate a database from the internet but keep it reachable by the app?**
Put both on a `backend` network, put the web container additionally on a
`frontend` network, and publish ports only on the web container. The database has
no published port and no route from outside.

**Q: What happens to data when a container is removed?**
Everything in its writable layer is deleted. Only volumes and bind mounts survive.

**Q: Does `EXPOSE` publish a port?**
No. It is documentation in the image metadata. `-p` (or `-P`) is what actually
publishes.
