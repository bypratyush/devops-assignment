# Networking - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Run inside the Ubuntu 22.04 lab container on 2026-09-18.

## 1. `subnet.sh` - IP addressing and subnetting

```text
==============================================================
 SUBNET CALCULATIONS
==============================================================

  input                  120.27.1.0/8
  class                  A
  scope                  PUBLIC
  subnet mask            255.0.0.0
  bits                   8 network / 24 host
  network address        120.0.0.0
  broadcast address      120.255.255.255
  usable host range      120.0.0.1 - 120.255.255.254
  total addresses        2^24 = 16777216
  usable hosts           2^24 - 2 = 16777214   (network + broadcast are reserved)

  input                  197.23.45.10/24
  class                  C
  scope                  PUBLIC
  subnet mask            255.255.255.0
  bits                   24 network / 8 host
  network address        197.23.45.0
  broadcast address      197.23.45.255
  usable host range      197.23.45.1 - 197.23.45.254
  total addresses        2^8 = 256
  usable hosts           2^8 - 2 = 254   (network + broadcast are reserved)

  input                  192.168.10.0/26
  class                  C
  scope                  PRIVATE (192.168.0.0/16)
  subnet mask            255.255.255.192
  bits                   26 network / 6 host
  network address        192.168.10.0
  broadcast address      192.168.10.63
  usable host range      192.168.10.1 - 192.168.10.62
  total addresses        2^6 = 64
  usable hosts           2^6 - 2 = 62   (network + broadcast are reserved)

  input                  10.244.0.0/16
  class                  A
  scope                  PRIVATE (10.0.0.0/8)
  subnet mask            255.255.0.0
  bits                   16 network / 16 host
  network address        10.244.0.0
  broadcast address      10.244.255.255
  usable host range      10.244.0.1 - 10.244.255.254
  total addresses        2^16 = 65536
  usable hosts           2^16 - 2 = 65534   (network + broadcast are reserved)

  input                  172.16.5.0/20
  class                  B
  scope                  PRIVATE (172.16.0.0/12)
  subnet mask            255.255.240.0
  bits                   20 network / 12 host
  network address        172.16.0.0
  broadcast address      172.16.15.255
  usable host range      172.16.0.1 - 172.16.15.254
  total addresses        2^12 = 4096
  usable hosts           2^12 - 2 = 4094   (network + broadcast are reserved)

  input                  192.168.1.1/32
  class                  C
  scope                  PRIVATE (192.168.0.0/16)
  subnet mask            255.255.255.255
  bits                   32 network / 0 host
  network address        192.168.1.1
  broadcast address      192.168.1.1
  usable host range      none (too small)
  total addresses        2^0 = 1
  usable hosts           2^0 - 2 = 0   (network + broadcast are reserved)

```

## 2. `netcmds.sh` - the networking commands

```text

==============================================================
1. INTERFACES AND ADDRESSES
==============================================================

$ ip -brief addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
tunl0@NONE       DOWN           
gre0@NONE        DOWN           
gretap0@NONE     DOWN           
erspan0@NONE     DOWN           
ip_vti0@NONE     DOWN           
ip6_vti0@NONE    DOWN           
sit0@NONE        DOWN           
ip6tnl0@NONE     DOWN           
ip6gre0@NONE     DOWN           
eth0@if3988      UP             172.17.0.6/16 

$ ip addr show eth0
11: eth0@if3988: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 65535 qdisc noqueue state UP group default 
    link/ether 52:fb:a1:49:18:3a brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.6/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever

  ip is the modern tool. ifconfig is deprecated (net-tools) and may not
  even be installed on a current distro.

$ ip -brief link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
tunl0@NONE       DOWN           0.0.0.0 <NOARP> 
gre0@NONE        DOWN           0.0.0.0 <NOARP> 
gretap0@NONE     DOWN           00:00:00:00:00:00 <BROADCAST,MULTICAST> 
erspan0@NONE     DOWN           00:00:00:00:00:00 <BROADCAST,MULTICAST> 
ip_vti0@NONE     DOWN           0.0.0.0 <NOARP> 
ip6_vti0@NONE    DOWN           :: <NOARP> 
sit0@NONE        DOWN           0.0.0.0 <NOARP> 
ip6tnl0@NONE     DOWN           :: <NOARP> 
ip6gre0@NONE     DOWN           :: <NOARP> 
eth0@if3988      UP             52:fb:a1:49:18:3a <BROADCAST,MULTICAST,UP,LOWER_UP> 

==============================================================
2. ROUTING - how a packet decides where to go
==============================================================

$ ip route
default via 172.17.0.1 dev eth0 
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.6 

  'default via X dev eth0' is the DEFAULT GATEWAY: anything not matching a
  more specific route is sent there. This is how a host reaches the internet.

$ ip route get 8.8.8.8
8.8.8.8 via 172.17.0.1 dev eth0 src 172.17.0.6 uid 0 
    cache 
  ^ asks the kernel which route and source IP it WOULD use, without sending.

==============================================================
3. DNS RESOLUTION
==============================================================
--- the resolver config ---
  
  nameserver 192.168.65.7
  


$ getent hosts github.com
20.207.73.82    github.com

$ dig +short github.com
20.207.73.82

$ dig github.com A +noall +answer
github.com.		15	IN	A	20.207.73.82

  A record    = name -> IPv4        AAAA = name -> IPv6
  CNAME       = name -> another NAME (an alias)
  MX          = mail servers        NS = authoritative nameservers

$ dig +short MX github.com
0 github-com.mail.protection.outlook.com.

$ nslookup github.com
Server:		192.168.65.7
Address:	192.168.65.7#53

Non-authoritative answer:
Name:	github.com
Address: 20.207.73.82


--- /etc/hosts is checked BEFORE DNS ---
  127.0.0.1	localhost
  ::1	localhost ip6-localhost ip6-loopback
  fe00::	ip6-localnet
  ff00::	ip6-mcastprefix
  ff02::1	ip6-allnodes
  ff02::2	ip6-allrouters
  172.17.0.6	136d08fe0388
  Order is set by /etc/nsswitch.conf:
  hosts:          files dns

==============================================================
4. CONNECTIVITY
==============================================================

$ ping -c 3 1.1.1.1
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=63 time=60.1 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=63 time=95.1 ms
64 bytes from 1.1.1.1: icmp_seq=3 ttl=63 time=147 ms

--- 1.1.1.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 60.118/100.774/147.058/35.715 ms

  ping uses ICMP, not TCP. A host can be perfectly healthy and still not
  answer ping - plenty of firewalls drop ICMP. 'ping fails' does NOT mean
  'the service is down'.

$ traceroute -m 6 -w 1 1.1.1.1
traceroute to 1.1.1.1 (1.1.1.1), 6 hops max, 60 byte packets
 1  172.17.0.1 (172.17.0.1)  0.312 ms  0.007 ms  0.004 ms
 2  * * *
 3  * * *
 4  * * *
 5  * * *
 6  * * *
  ^ each line is one hop. '* * *' means that hop did not reply to the probe,
    which again is common and not necessarily a fault.

==============================================================
5. PORTS AND SOCKETS
==============================================================
Starting nginx so there is something listening...

$ ss -tulnp
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                                                                                                                                                                                                                                                                                                                                                                                 
tcp   LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=547,fd=6),("nginx",pid=545,fd=6),("nginx",pid=544,fd=6),("nginx",pid=543,fd=6),("nginx",pid=542,fd=6),("nginx",pid=541,fd=6),("nginx",pid=540,fd=6),("nginx",pid=539,fd=6),("nginx",pid=537,fd=6),("nginx",pid=536,fd=6),("nginx",pid=535,fd=6),("nginx",pid=534,fd=6),("nginx",pid=533,fd=6),("nginx",pid=532,fd=6),("nginx",pid=531,fd=6),("nginx",pid=530,fd=6))
tcp   LISTEN 0      511             [::]:80           [::]:*    users:(("nginx",pid=547,fd=7),("nginx",pid=545,fd=7),("nginx",pid=544,fd=7),("nginx",pid=543,fd=7),("nginx",pid=542,fd=7),("nginx",pid=541,fd=7),("nginx",pid=540,fd=7),("nginx",pid=539,fd=7),("nginx",pid=537,fd=7),("nginx",pid=536,fd=7),("nginx",pid=535,fd=7),("nginx",pid=534,fd=7),("nginx",pid=533,fd=7),("nginx",pid=532,fd=7),("nginx",pid=531,fd=7),("nginx",pid=530,fd=7))

  -t TCP  -u UDP  -l listening  -n numeric ports  -p owning process
  This is THE command for 'what is using port 8080?'

$ ss -tn state established
Recv-Q Send-Q Local Address:Port Peer Address:PortProcess

$ netstat -tulnp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      530/nginx: master p 
tcp6       0      0 :::80                   :::*                    LISTEN      530/nginx: master p 
  ^ netstat is the legacy equivalent; ss is faster and is the modern tool.

==============================================================
6. TESTING A PORT
==============================================================

$ nc -zv localhost 80
Connection to localhost (::1) 80 port [tcp/http] succeeded!

$ nc -zv localhost 9999
nc: connect to localhost (::1) port 9999 (tcp) failed: Connection refused
nc: connect to localhost (127.0.0.1) port 9999 (tcp) failed: Connection refused

  -z scan without sending data, -v verbose. This distinguishes
  'port closed' from 'host unreachable' from 'firewalled (hangs)'.

==============================================================
7. HTTP WITH CURL
==============================================================

$ curl -s -o /dev/null -w 'http_code=%{http_code}\ntime_total=%{time_total}s\n' http://localhost/
http_code=200
time_total=0.000344s

$ curl -sI http://localhost/
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Thu, 17 Sep 2026 19:20:19 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Thu, 17 Sep 2026 19:04:21 GMT
Connection: keep-alive
ETag: "6aac39b5-264"
Accept-Ranges: bytes


--- timing breakdown: where the time actually goes ---
  dns_lookup   : 0.002768s
  tcp_connect  : 0.033702s
  tls_handshake: 0.092823s
  first_byte   : 0.122492s
  total        : 0.262793s

  This one command tells you WHICH phase is slow: name resolution, the TCP
  handshake, the TLS handshake, or the server thinking (first byte).

--- inspecting the TLS certificate itself ---
$ openssl s_client -connect github.com:443 -servername github.com </dev/null
  subject=CN = github.com
  issuer=C = GB, O = Sectigo Limited, CN = Sectigo Public Server Authentication CA DV E36
  notBefore=Sep  1 00:00:00 2026 GMT
  notAfter=Nov 29 23:59:59 2026 GMT

  -servername sends SNI, which is how one IP can host many HTTPS sites.
  This is the tool for 'is the cert expired, wrong host, or wrong chain?'

$ curl -s -o /dev/null -w '%{http_code}\n' -X POST -d 'a=1' http://localhost/
405

==============================================================
8. PUTTING IT TOGETHER - what one HTTP request actually does
==============================================================
    curl https://github.com/

    1. DNS       resolve github.com -> an IP        (/etc/hosts, then resolv.conf)
    2. ROUTE     kernel picks an interface + gateway  (ip route get)
    3. ARP       find the gateway's MAC on the LAN    (ip neigh)
    4. TCP       3-way handshake  SYN -> SYN/ACK -> ACK
    5. TLS       ClientHello / certificate / key exchange
    6. HTTP      GET / HTTP/1.1 + Host: github.com
    7. RESPONSE  status line, headers, body
    8. CLOSE     FIN/ACK, or the connection is kept alive for reuse

    Each layer has its own debugging tool:
      1 dig / nslookup     2 ip route get      3 ip neigh / arp
      4 nc -zv / ss        5 openssl s_client  6-7 curl -v

$ ip neigh
172.17.0.1 dev eth0 lladdr 7a:40:3d:5e:e5:b7 DELAY

==============================================================
9. PORTS WORTH KNOWING
==============================================================
    20/21  FTP        22   SSH         23  Telnet      25  SMTP
    53     DNS        67/68 DHCP       80  HTTP       110  POP3
    143    IMAP       443  HTTPS       465 SMTPS      587  SMTP submission
    3306   MySQL      5432 PostgreSQL  6379 Redis     27017 MongoDB
    8080   HTTP-alt   9090 Prometheus  6443 k8s API   2379/2380 etcd

    0-1023      well-known  (need root to bind)
    1024-49151  registered
    49152-65535 ephemeral   (the source port your client picks)

==============================================================
DONE
==============================================================
```
