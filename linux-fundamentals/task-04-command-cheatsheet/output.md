# task-04-command-cheatsheet - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./lab/lab.sh exec /work/linux-fundamentals/task-04-command-cheatsheet/practice.sh` on 2026-09-18.

```text

==============================================================
1. NAVIGATION - where am I, what is here
==============================================================

$ pwd
/root/cmd-lab

$ ls -la
total 24
drwxr-xr-x 5 root root 4096 Sep 17 19:20 .
drwx------ 1 root root 4096 Sep 17 19:20 ..
drwxr-xr-x 2 root root 4096 Sep 17 19:20 archive
drwxr-xr-x 2 root root 4096 Sep 17 19:20 conf
drwxr-xr-x 2 root root 4096 Sep 17 19:20 logs
-rw-r--r-- 1 root root   84 Sep 17 19:20 staff.csv

$ ls -lh logs/
total 4.0K
-rw-r--r-- 1 root root 203 Sep 17 19:20 app.log

$ tree -L 2
.
|-- archive
|   `-- blob.bin
|-- conf
|   `-- app.conf
|-- logs
|   `-- app.log
`-- staff.csv

3 directories, 4 files

==============================================================
2. VIEWING FILE CONTENT
==============================================================

$ cat conf/app.conf
listen_port = 8080

$ head -3 logs/app.log
2026-09-17 10:00:01 INFO  service started
2026-09-17 10:00:05 WARN  disk at 81%
2026-09-17 10:01:12 ERROR db connection refused

$ tail -2 logs/app.log
2026-09-17 10:01:13 ERROR retry failed
2026-09-17 10:02:44 INFO  recovered

$ wc -l logs/app.log staff.csv
  5 logs/app.log
  5 staff.csv
 10 total

less <file>  = page through interactively (q quits). Not run: it needs a TTY.

==============================================================
3. SEARCHING INSIDE FILES - grep
==============================================================

$ grep ERROR logs/app.log
2026-09-17 10:01:12 ERROR db connection refused
2026-09-17 10:01:13 ERROR retry failed

$ grep -c ERROR logs/app.log
2

$ grep -n 'engineering' staff.csv
1:alice,engineering,90
3:carol,engineering,85

$ grep -i -v error logs/app.log
2026-09-17 10:00:01 INFO  service started
2026-09-17 10:00:05 WARN  disk at 81%
2026-09-17 10:02:44 INFO  recovered

$ grep -rn 'listen_port' .
./conf/app.conf:1:listen_port = 8080

  -i ignore case   -v invert   -n line numbers   -r recursive   -c count   -E regex

==============================================================
4. FINDING FILES - find
==============================================================

$ find . -type f -name '*.log'
./logs/app.log

$ find . -type d
.
./logs
./archive
./conf

$ find . -type f -size +100k
./archive/blob.bin

$ find . -type f -mmin -5 | head -5
./logs/app.log
./archive/blob.bin
./conf/app.conf
./staff.csv

  find . -name '*.log' -delete          delete matches
  find . -name '*.log' -exec rm {} \;   run a command per match

==============================================================
5. TEXT PROCESSING - cut / sort / uniq / awk / sed
==============================================================

$ cut -d, -f1,2 staff.csv
alice,engineering
bob,sales
carol,engineering
dave,sales
erin,devops

$ sort -t, -k3 -n -r staff.csv
erin,devops,95
alice,engineering,90
carol,engineering,85
bob,sales,72
dave,sales,64

$ cut -d, -f2 staff.csv | sort | uniq -c | sort -rn
      2 sales
      2 engineering
      1 devops

$ awk -F, '{ sum += $3 } END { print "average score:", sum/NR }' staff.csv
average score: 81.2

$ awk -F, '$3 > 80 { print $1, "->", $3 }' staff.csv
alice -> 90
carol -> 85
erin -> 95

$ sed 's/engineering/ENG/g' staff.csv
alice,ENG,90
bob,sales,72
carol,ENG,85
dave,sales,64
erin,devops,95

  sed -i 's/old/new/g' file    edit the file IN PLACE

==============================================================
6. PIPES AND REDIRECTION - the core Unix idea
==============================================================

$ grep ERROR logs/app.log | wc -l
2

$ cut -d, -f3 staff.csv | sort -n | tail -1
95

$ echo 'written' > out.txt     (> overwrite,  >> append)
written
appended

$ command 2> err.txt           redirect stderr only
$ command > all.txt 2>&1       redirect both stdout and stderr
$ command | tee file.txt       print to screen AND write to file
stderr captured: ls: cannot access 'nonexistent': No such file or directory

==============================================================
7. FILE OPERATIONS
==============================================================

$ cp conf/app.conf conf/app.conf.bak

$ mkdir -p deep/nested/dir

$ mv conf/app.conf.bak archive/

$ ls -R archive
archive:
app.conf.bak
blob.bin

$ touch newfile.txt && ls -l newfile.txt
-rw-r--r-- 1 root root 0 Sep 17 19:20 newfile.txt

$ rm -f newfile.txt && echo removed
removed

  cp -r  recursive    mv = rename+move    rm -r recursive    rm -f force
  DANGER: 'rm -rf /' style typos are unrecoverable. Check pwd first.

==============================================================
8. PERMISSIONS - chmod / chown
==============================================================

$ ls -l staff.csv
-rw-r--r-- 1 root root 84 Sep 17 19:20 staff.csv

  rwx rwx rwx = owner group other      r=4 w=2 x=1

$ chmod 640 staff.csv && ls -l staff.csv
-rw-r----- 1 root root 84 Sep 17 19:20 staff.csv

$ chmod u+x staff.csv && ls -l staff.csv
-rwxr----- 1 root root 84 Sep 17 19:20 staff.csv

$ chmod 644 staff.csv && ls -l staff.csv
-rw-r--r-- 1 root root 84 Sep 17 19:20 staff.csv

$ chown devops-test staff.csv && ls -l staff.csv
-rw-r--r-- 1 devops-test root 84 Sep 17 19:20 staff.csv

$ chown root:root staff.csv && ls -l staff.csv
-rw-r--r-- 1 root root 84 Sep 17 19:20 staff.csv

$ umask
0022

==============================================================
9. USERS AND IDENTITY
==============================================================

$ whoami
root

$ id
uid=0(root) gid=0(root) groups=0(root)

$ getent passwd root
root:x:0:0:root:/root:/bin/bash

$ who; echo '(who = logged-in sessions; empty in a container)'
(who = logged-in sessions; empty in a container)

  su - <user>        switch user with a login shell
  sudo <cmd>         run one command as root
  sudo -i            interactive root shell

==============================================================
10. PROCESSES
==============================================================

$ ps aux | head -6
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0 165528  7092 ?        Ss   19:04   0:00 /sbin/init
root          29  0.0  0.0  31724  7640 ?        S<s  19:04   0:00 /lib/systemd/systemd-journald
message+      43  0.0  0.0   7768   520 ?        Ss   19:04   0:00 @dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
root          47  0.0  0.0   2636   208 tty1     Ss+  19:04   0:00 /sbin/agetty -o -p -- \u --noclear tty1 linux
root         530  0.0  0.0  55180  2248 ?        Ss   19:20   0:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;

$ ps -ef | grep -c .
26

$ pgrep -a nginx | head -3
530 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
531 nginx: worker process                           
532 nginx: worker process                           

  top / htop         live process view
  kill <PID>         send SIGTERM (graceful)
  kill -9 <PID>      SIGKILL (force, last resort)
  pkill <name>       kill by name

--- demonstrating a background job + kill ---
started 'sleep 120' with PID 727
    727 S    sleep 120
PID 727 terminated by kill

  cmd &     run in background     jobs   list them
  fg / bg   move between fore/background
  nohup cmd &   keep running after logout

==============================================================
11. SYSTEM INFORMATION
==============================================================

$ uname -a
Linux 136d08fe0388 6.12.76-linuxkit #1 SMP Thu Jun 18 21:12:39 UTC 2026 aarch64 aarch64 aarch64 GNU/Linux

$ hostname
136d08fe0388

$ uptime
 19:20:14 up 7 days, 13:03,  0 users,  load average: 6.52, 7.00, 6.93

$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
overlay         911G  230G  635G  27% /

$ du -sh .
248K	.

$ du -sh * | sort -h
4.0K	err.txt
4.0K	out.txt
4.0K	staff.csv
8.0K	conf
8.0K	logs
12K	deep
204K	archive

$ free -h
               total        used        free      shared  buff/cache   available
Mem:           7.7Gi       6.1Gi       169Mi        40Mi       1.5Gi       1.4Gi
Swap:          1.0Gi       1.0Gi       0.0Ki

$ nproc
15

==============================================================
12. NETWORKING
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

$ ip route
default via 172.17.0.1 dev eth0 
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.6 

$ ss -tulnp | head -6
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                                                                                                                                                                                                                                                                                                                                                                                 
tcp   LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=547,fd=6),("nginx",pid=545,fd=6),("nginx",pid=544,fd=6),("nginx",pid=543,fd=6),("nginx",pid=542,fd=6),("nginx",pid=541,fd=6),("nginx",pid=540,fd=6),("nginx",pid=539,fd=6),("nginx",pid=537,fd=6),("nginx",pid=536,fd=6),("nginx",pid=535,fd=6),("nginx",pid=534,fd=6),("nginx",pid=533,fd=6),("nginx",pid=532,fd=6),("nginx",pid=531,fd=6),("nginx",pid=530,fd=6))
tcp   LISTEN 0      511             [::]:80           [::]:*    users:(("nginx",pid=547,fd=7),("nginx",pid=545,fd=7),("nginx",pid=544,fd=7),("nginx",pid=543,fd=7),("nginx",pid=542,fd=7),("nginx",pid=541,fd=7),("nginx",pid=540,fd=7),("nginx",pid=539,fd=7),("nginx",pid=537,fd=7),("nginx",pid=536,fd=7),("nginx",pid=535,fd=7),("nginx",pid=534,fd=7),("nginx",pid=533,fd=7),("nginx",pid=532,fd=7),("nginx",pid=531,fd=7),("nginx",pid=530,fd=7))

$ curl -s -o /dev/null -w 'localhost nginx -> HTTP %{http_code}\n' http://localhost/
localhost nginx -> HTTP 200

  ping <host>        ICMP reachability
  curl -I <url>      headers only
  curl -O <url>      download to a file
  wget <url>         download
  dig / nslookup     DNS lookups

==============================================================
13. ARCHIVES AND COMPRESSION
==============================================================

$ tar -czf backup.tar.gz logs conf

$ ls -lh backup.tar.gz
-rw-r--r-- 1 root root 313 Sep 17 19:20 backup.tar.gz

$ tar -tzf backup.tar.gz
logs/
logs/app.log
conf/
conf/app.conf

$ mkdir -p restore && tar -xzf backup.tar.gz -C restore && find restore -type f
restore/logs/app.log
restore/conf/app.conf

  tar -czf out.tar.gz dir/   CREATE gzipped archive   (c=create z=gzip f=file)
  tar -xzf out.tar.gz        EXTRACT
  tar -tzf out.tar.gz        LIST contents without extracting
  gzip / gunzip, zip / unzip for single files

==============================================================
14. SERVICES - systemctl
==============================================================

$ systemctl is-active nginx
active

$ systemctl is-enabled nginx
enabled

$ systemctl --no-pager status nginx | head -5
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2026-09-17 19:20:11 UTC; 3s ago
       Docs: man:nginx(8)
    Process: 528 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)

$ systemctl list-units --type=service --state=running --no-pager | head -8
  UNIT                     LOAD   ACTIVE SUB     DESCRIPTION
  dbus.service             loaded active running D-Bus System Message Bus
  getty@tty1.service       loaded active running Getty on tty1
  nginx.service            loaded active running A high performance web server and a reverse proxy server
  systemd-journald.service loaded active running Journal Service

LOAD   = Reflects whether the unit definition was properly loaded.
ACTIVE = The high-level unit activation state, i.e. generalization of SUB.

  systemctl start|stop|restart|reload <svc>
  systemctl enable|disable <svc>     start at boot / don't
  systemctl daemon-reload            after editing a unit file
  journalctl -u <svc> -f             follow that service's logs  (see Task 3)

==============================================================
15. PACKAGES (Debian/Ubuntu)
==============================================================

$ dpkg -l | wc -l
216

$ dpkg -l nginx | tail -1
ii  nginx          1.18.0-6ubuntu14.21 arm64        small, powerful, scalable web/proxy server

$ apt list --installed 2>/dev/null | head -4
Listing...
adduser/now 3.118ubuntu5 all [installed,local]
apt/now 2.4.14 arm64 [installed,local]
base-files/now 12ubuntu4.7 arm64 [installed,local]

  apt update              refresh the package index
  apt install <pkg>       install
  apt remove <pkg>        remove (purge also deletes config)
  apt search <term>       search
  dpkg -l                 list installed
  RHEL/CentOS equivalents: yum / dnf, rpm -qa

==============================================================
16. DISK AND FILE INSPECTION
==============================================================

$ file archive/blob.bin staff.csv logs
archive/blob.bin: data
staff.csv:        CSV text
logs:             directory

$ stat staff.csv
  File: staff.csv
  Size: 84        	Blocks: 8          IO Block: 4096   regular file
Device: 46h/70d	Inode: 3829344     Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2026-09-17 19:20:14.967349009 +0000
Modify: 2026-09-17 19:20:14.489349009 +0000
Change: 2026-09-17 19:20:14.532349009 +0000
 Birth: 2026-09-17 19:20:14.489349009 +0000

$ df -hT | head -4
Filesystem           Type       Size  Used Avail Use% Mounted on
overlay              overlay    911G  230G  635G  27% /
tmpfs                tmpfs       64M     0   64M   0% /dev
shm                  tmpfs       64M     0   64M   0% /dev/shm

==============================================================
17. HISTORY AND HELP
==============================================================
$ history          previous commands    (!42 re-runs #42, !! re-runs last)
$ man <cmd>        full manual page
$ <cmd> --help     quick usage
$ which <cmd>      path to the binary
$ type <cmd>       is it a builtin, alias, or file?

$ which grep
/usr/bin/grep

$ type cd
cd is a shell builtin

$ grep --help | head -4
Usage: grep [OPTION]... PATTERNS [FILE]...
Search for PATTERNS in each FILE.
Example: grep -i 'hello world' menu.h main.c
PATTERNS can contain multiple patterns separated by newlines.

==============================================================
18. CLEANUP
==============================================================
removed /root/cmd-lab

==============================================================
DONE
==============================================================
```
