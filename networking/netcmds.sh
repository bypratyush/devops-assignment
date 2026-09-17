#!/usr/bin/env bash
# netcmds.sh - the networking commands, run for real.
set -u
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
run() { echo; echo "\$ $*"; eval "$@" 2>&1 | head -14; }

hr "1. INTERFACES AND ADDRESSES"
run "ip -brief addr"
run "ip addr show eth0"
echo
echo "  ip is the modern tool. ifconfig is deprecated (net-tools) and may not"
echo "  even be installed on a current distro."
run "ip -brief link"

hr "2. ROUTING - how a packet decides where to go"
run "ip route"
echo
echo "  'default via X dev eth0' is the DEFAULT GATEWAY: anything not matching a"
echo "  more specific route is sent there. This is how a host reaches the internet."
run "ip route get 8.8.8.8"
echo "  ^ asks the kernel which route and source IP it WOULD use, without sending."

hr "3. DNS RESOLUTION"
echo "--- the resolver config ---"
cat /etc/resolv.conf | grep -v '^#' | sed 's/^/  /'
echo
run "getent hosts github.com"
run "dig +short github.com"
run "dig github.com A +noall +answer"
echo
echo "  A record    = name -> IPv4        AAAA = name -> IPv6"
echo "  CNAME       = name -> another NAME (an alias)"
echo "  MX          = mail servers        NS = authoritative nameservers"
run "dig +short MX github.com"
run "nslookup github.com"
echo
echo "--- /etc/hosts is checked BEFORE DNS ---"
grep -v '^#' /etc/hosts | grep -v '^$' | sed 's/^/  /'
echo "  Order is set by /etc/nsswitch.conf:"
grep '^hosts' /etc/nsswitch.conf | sed 's/^/  /'

hr "4. CONNECTIVITY"
run "ping -c 3 1.1.1.1"
echo
echo "  ping uses ICMP, not TCP. A host can be perfectly healthy and still not"
echo "  answer ping - plenty of firewalls drop ICMP. 'ping fails' does NOT mean"
echo "  'the service is down'."
run "traceroute -m 6 -w 1 1.1.1.1"
echo "  ^ each line is one hop. '* * *' means that hop did not reply to the probe,"
echo "    which again is common and not necessarily a fault."

hr "5. PORTS AND SOCKETS"
echo "Starting nginx so there is something listening..."
systemctl start nginx 2>/dev/null || service nginx start >/dev/null 2>&1
sleep 1
run "ss -tulnp"
echo
echo "  -t TCP  -u UDP  -l listening  -n numeric ports  -p owning process"
echo "  This is THE command for 'what is using port 8080?'"
run "ss -tn state established"
run "netstat -tulnp"
echo "  ^ netstat is the legacy equivalent; ss is faster and is the modern tool."

hr "6. TESTING A PORT"
run "nc -zv localhost 80"
run "nc -zv localhost 9999"
echo
echo "  -z scan without sending data, -v verbose. This distinguishes"
echo "  'port closed' from 'host unreachable' from 'firewalled (hangs)'."

hr "7. HTTP WITH CURL"
run "curl -s -o /dev/null -w 'http_code=%{http_code}\\ntime_total=%{time_total}s\\n' http://localhost/"
run "curl -sI http://localhost/"
echo
echo "--- timing breakdown: where the time actually goes ---"
curl -s -o /dev/null -w '  dns_lookup   : %{time_namelookup}s\n  tcp_connect  : %{time_connect}s\n  tls_handshake: %{time_appconnect}s\n  first_byte   : %{time_starttransfer}s\n  total        : %{time_total}s\n' https://github.com 2>/dev/null
echo
echo "  This one command tells you WHICH phase is slow: name resolution, the TCP"
echo "  handshake, the TLS handshake, or the server thinking (first byte)."

echo
echo "--- inspecting the TLS certificate itself ---"
echo "\$ openssl s_client -connect github.com:443 -servername github.com </dev/null"
echo | openssl s_client -connect github.com:443 -servername github.com 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates 2>/dev/null | sed 's/^/  /'
echo
echo "  -servername sends SNI, which is how one IP can host many HTTPS sites."
echo "  This is the tool for 'is the cert expired, wrong host, or wrong chain?'"
run "curl -s -o /dev/null -w '%{http_code}\\n' -X POST -d 'a=1' http://localhost/"

hr "8. PUTTING IT TOGETHER - what one HTTP request actually does"
cat <<'FLOW'
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
FLOW
run "ip neigh"

hr "9. PORTS WORTH KNOWING"
cat <<'PORTS'
    20/21  FTP        22   SSH         23  Telnet      25  SMTP
    53     DNS        67/68 DHCP       80  HTTP       110  POP3
    143    IMAP       443  HTTPS       465 SMTPS      587  SMTP submission
    3306   MySQL      5432 PostgreSQL  6379 Redis     27017 MongoDB
    8080   HTTP-alt   9090 Prometheus  6443 k8s API   2379/2380 etcd

    0-1023      well-known  (need root to bind)
    1024-49151  registered
    49152-65535 ephemeral   (the source port your client picks)
PORTS

hr "DONE"
