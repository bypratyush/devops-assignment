# task-03-journalctl - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./lab/lab.sh exec /work/linux-fundamentals/task-03-journalctl/practice.sh` on 2026-09-18.

```text

==============================================================
0. What journalctl is reading
==============================================================
systemd-journald collects logs from the kernel, initrd, services' stdout/stderr,
and syslog, and stores them in a structured, indexed BINARY format.
journalctl is the query tool for that store - you cannot 'cat' it.

● systemd-journald.service - Journal Service
     Loaded: loaded (/lib/systemd/system/systemd-journald.service; static)
     Active: active (running) since Thu 2026-09-17 19:04:32 UTC; 15min ago
TriggeredBy: ● systemd-journald.socket

--- where the journal lives + how big it is ---
Archived and active journals take up 8.0M in the file system.

  /run/log/journal  = volatile, wiped on reboot
  /var/log/journal  = persistent (set Storage=persistent in /etc/systemd/journald.conf)
  /run/log/journal
  /var/log/journal

==============================================================
1. VIEW SYSTEM LOGS - the everyday commands
==============================================================
--- journalctl -n 10   (last 10 lines; default is 10) ---
Sep 17 19:20:11 136d08fe0388 userdel[413]: removed shadow group 'test-adduser' owned by 'test-adduser'
Sep 17 19:20:11 136d08fe0388 userdel[421]: delete user 'devops-test'
Sep 17 19:20:11 136d08fe0388 userdel[421]: removed group 'devops-test' owned by 'devops-test'
Sep 17 19:20:11 136d08fe0388 userdel[421]: removed shadow group 'devops-test' owned by 'devops-test'
Sep 17 19:20:11 136d08fe0388 groupadd[433]: group added to /etc/group: name=devops-test, GID=1000
Sep 17 19:20:11 136d08fe0388 groupadd[433]: group added to /etc/gshadow: name=devops-test
Sep 17 19:20:11 136d08fe0388 groupadd[433]: new group: name=devops-test, GID=1000
Sep 17 19:20:11 136d08fe0388 useradd[439]: new user: name=devops-test, UID=1000, GID=1000, home=/home/devops-test, shell=/bin/bash, from=none
Sep 17 19:20:11 136d08fe0388 usermod[450]: change user 'devops-test' password
Sep 17 19:20:11 136d08fe0388 chfn[457]: changed user 'devops-test' information

--- journalctl -r -n 5   (-r = newest first) ---
Sep 17 19:20:11 136d08fe0388 chfn[457]: changed user 'devops-test' information
Sep 17 19:20:11 136d08fe0388 usermod[450]: change user 'devops-test' password
Sep 17 19:20:11 136d08fe0388 useradd[439]: new user: name=devops-test, UID=1000, GID=1000, home=/home/devops-test, shell=/bin/bash, from=none
Sep 17 19:20:11 136d08fe0388 groupadd[433]: new group: name=devops-test, GID=1000
Sep 17 19:20:11 136d08fe0388 groupadd[433]: group added to /etc/gshadow: name=devops-test

==============================================================
2. Filter by TIME
==============================================================
--- journalctl --since '10 minutes ago' -n 5 ---
Sep 17 19:10:39 136d08fe0388 kernel: docker0: port 9(veth2f0dc03) entered disabled state
Sep 17 19:10:39 136d08fe0388 kernel: veth8c280fa: renamed from eth0
Sep 17 19:10:39 136d08fe0388 kernel: docker0: port 18(vethb2e7d89) entered disabled state
Sep 17 19:10:39 136d08fe0388 kernel: vethd9c938c: renamed from eth0
Sep 17 19:10:39 136d08fe0388 kernel: veth945720e: renamed from eth0

--- journalctl --since today -n 3 ---
Sep 17 19:04:32 136d08fe0388 systemd-journald[29]: Missed 138767 kernel messages
Sep 17 19:04:32 136d08fe0388 kernel: vethadfe8aa (unregistering): left promiscuous mode
Sep 17 19:04:32 136d08fe0388 kernel: docker0: port 5(vethadfe8aa) entered disabled state

Other accepted forms: --since '2026-09-17 09:00:00' --until '2026-09-17 10:00:00'
                      --since yesterday   --until '1 hour ago'

==============================================================
3. Filter by PRIORITY (syslog levels 0-7)
==============================================================
0 emerg  1 alert  2 crit  3 err  4 warning  5 notice  6 info  7 debug

--- journalctl -p err -b   (errors and worse, this boot) ---
-- No entries --

--- journalctl -p warning -b -n 5 ---
Sep 17 19:04:32 136d08fe0388 kernel: ICMPv6: NA: 2a:46:63:5e:3b:7a advertised our address fc00:f853:ccd:e793::3 on eth0!
Sep 17 19:04:32 136d08fe0388 kernel: ICMPv6: NA: 76:2e:c4:11:d0:70 advertised our address fc00:f853:ccd:e793::4 on eth0!
Sep 17 19:04:32 136d08fe0388 kernel: ICMPv6: NA: e2:de:70:14:b5:df advertised our address fc00:f853:ccd:e793::2 on eth0!
Sep 17 19:04:32 136d08fe0388 kernel: ICMPv6: NA: 2a:46:63:5e:3b:7a advertised our address fc00:f853:ccd:e793::3 on eth0!
Sep 17 19:04:32 136d08fe0388 kernel: ICMPv6: NA: 76:2e:c4:11:d0:70 advertised our address fc00:f853:ccd:e793::4 on eth0!

==============================================================
4. Filter by BOOT
==============================================================
--- journalctl -b   = current boot only (-b -1 = previous boot) ---
Sep 17 19:20:11 136d08fe0388 useradd[439]: new user: name=devops-test, UID=1000, GID=1000, home=/home/devops-test, shell=/bin/bash, from=none
Sep 17 19:20:11 136d08fe0388 usermod[450]: change user 'devops-test' password
Sep 17 19:20:11 136d08fe0388 chfn[457]: changed user 'devops-test' information

--- journalctl --list-boots ---
 0 7a7e4a2fd81a499090b46fdb36016fc1 Thu 2026-09-17 19:04:32 UTC—Thu 2026-09-17 19:20:11 UTC

--- journalctl -k   (kernel ring buffer / dmesg) ---
Sep 17 19:14:33 136d08fe0388 kernel: veth828ac70 (unregistering): left allmulticast mode
Sep 17 19:14:33 136d08fe0388 kernel: veth828ac70 (unregistering): left promiscuous mode
Sep 17 19:14:33 136d08fe0388 kernel: docker0: port 8(veth828ac70) entered disabled state
  (in this container these are the HOST kernel's messages - the kernel is
   shared. On a bare-metal host or VM, -k shows that machine's own kernel log,
   the same content as 'dmesg'.)

==============================================================
5. PRACTICE: logs for a SPECIFIC SERVICE  -->  journalctl -u <unit>
==============================================================
Using nginx as the example service.

--- start it ---
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2026-09-17 19:04:32 UTC; 15min ago
       Docs: man:nginx(8)
    Process: 45 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)

--- journalctl -u nginx   (everything nginx ever logged) ---
Sep 17 19:04:32 136d08fe0388 systemd[1]: Starting A high performance web server and a reverse proxy server...
Sep 17 19:04:32 136d08fe0388 systemd[1]: Started A high performance web server and a reverse proxy server.

--- restart it and watch new entries appear ---
Sep 17 19:20:11 136d08fe0388 systemd[1]: Stopping A high performance web server and a reverse proxy server...
Sep 17 19:20:11 136d08fe0388 systemd[1]: nginx.service: Deactivated successfully.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Stopped A high performance web server and a reverse proxy server.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Starting A high performance web server and a reverse proxy server...
Sep 17 19:20:11 136d08fe0388 systemd[1]: Started A high performance web server and a reverse proxy server.

==============================================================
6. PRACTICE: a service that FAILS - the real troubleshooting loop
==============================================================
Breaking the nginx config on purpose...

--- systemctl restart nginx (expected to fail) ---
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
>>> restart FAILED, exit 1

--- systemctl status nginx ---
× nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: failed (Result: exit-code) since Thu 2026-09-17 19:20:11 UTC; 2ms ago
       Docs: man:nginx(8)
    Process: 520 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=1/FAILURE)
        CPU: 4ms

Sep 17 19:20:11 136d08fe0388 systemd[1]: Starting A high performance web server and a reverse proxy server...
Sep 17 19:20:11 136d08fe0388 nginx[520]: nginx: [emerg] unknown directive "this_is_not_a_valid_directive" in /etc/nginx/nginx.conf:84
Sep 17 19:20:11 136d08fe0388 nginx[520]: nginx: configuration file /etc/nginx/nginx.conf test failed
Sep 17 19:20:11 136d08fe0388 systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Sep 17 19:20:11 136d08fe0388 systemd[1]: nginx.service: Failed with result 'exit-code'.

--- journalctl -u nginx -n 20   <-- THIS is where the real reason is ---
Sep 17 19:04:32 136d08fe0388 systemd[1]: Starting A high performance web server and a reverse proxy server...
Sep 17 19:04:32 136d08fe0388 systemd[1]: Started A high performance web server and a reverse proxy server.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Stopping A high performance web server and a reverse proxy server...
Sep 17 19:20:11 136d08fe0388 systemd[1]: nginx.service: Deactivated successfully.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Stopped A high performance web server and a reverse proxy server.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Starting A high performance web server and a reverse proxy server...
Sep 17 19:20:11 136d08fe0388 systemd[1]: Started A high performance web server and a reverse proxy server.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Stopping A high performance web server and a reverse proxy server...
Sep 17 19:20:11 136d08fe0388 systemd[1]: nginx.service: Deactivated successfully.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Stopped A high performance web server and a reverse proxy server.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Starting A high performance web server and a reverse proxy server...
Sep 17 19:20:11 136d08fe0388 nginx[520]: nginx: [emerg] unknown directive "this_is_not_a_valid_directive" in /etc/nginx/nginx.conf:84
Sep 17 19:20:11 136d08fe0388 nginx[520]: nginx: configuration file /etc/nginx/nginx.conf test failed
Sep 17 19:20:11 136d08fe0388 systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Sep 17 19:20:11 136d08fe0388 systemd[1]: nginx.service: Failed with result 'exit-code'.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Failed to start A high performance web server and a reverse proxy server.

--- journalctl -xeu nginx   (-x adds explanatory help text, -e jumps to end) ---
░░ The process' exit code is 'exited' and its exit status is 1.
Sep 17 19:20:11 136d08fe0388 systemd[1]: nginx.service: Failed with result 'exit-code'.
░░ Subject: Unit failed
░░ Defined-By: systemd
░░ Support: http://www.ubuntu.com/support
░░ 
░░ The unit nginx.service has entered the 'failed' state with result 'exit-code'.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Failed to start A high performance web server and a reverse proxy server.
░░ Subject: A start job for unit nginx.service has failed
░░ Defined-By: systemd
░░ Support: http://www.ubuntu.com/support
░░ 
░░ A start job for unit nginx.service has finished with a failure.
░░ 
░░ The job identifier is 293 and the job result is failed.

Now repair the config and restart:
>>> nginx restarted cleanly
active

--- the recovery is recorded in the journal too ---
Sep 17 19:20:11 136d08fe0388 systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Sep 17 19:20:11 136d08fe0388 systemd[1]: nginx.service: Failed with result 'exit-code'.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Failed to start A high performance web server and a reverse proxy server.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Starting A high performance web server and a reverse proxy server...
Sep 17 19:20:11 136d08fe0388 systemd[1]: Started A high performance web server and a reverse proxy server.

==============================================================
7. Other filters worth knowing
==============================================================
--- by unit + priority together ---
$ journalctl -u nginx -p err -b
Sep 17 19:20:11 136d08fe0388 systemd[1]: Failed to start A high performance web server and a reverse proxy server.

--- by executable:  journalctl /usr/sbin/nginx ---
Sep 17 19:20:11 136d08fe0388 nginx[520]: nginx: [emerg] unknown directive "this_is_not_a_valid_directive" in /etc/nginx/nginx.conf:84
Sep 17 19:20:11 136d08fe0388 nginx[520]: nginx: configuration file /etc/nginx/nginx.conf test failed

--- structured output:  journalctl -u nginx -n 1 -o json-pretty ---
{
	"_SYSTEMD_SLICE" : "-.slice",
	"SYSLOG_FACILITY" : "3",
	"_HOSTNAME" : "136d08fe0388",
	"JOB_ID" : "336",
	"_BOOT_ID" : "7a7e4a2fd81a499090b46fdb36016fc1",
	"CODE_LINE" : "713",
	"SYSLOG_IDENTIFIER" : "systemd",
	"MESSAGE_ID" : "39f53479d3a045ac8e11786248231fbf",
	"_SYSTEMD_UNIT" : "init.scope",
	"_TRANSPORT" : "journal",
	"UNIT" : "nginx.service",
	"JOB_TYPE" : "start",
	"_GID" : "0",
	"__MONOTONIC_TIMESTAMP" : "651784488652",
	"CODE_FUNC" : "job_emit_done_message",
	"_CMDLINE" : "/sbin/init",
	"_CAP_EFFECTIVE" : "1ffffffffff",

--- output formats: short (default), short-precise, verbose, json, json-pretty, cat ---
$ journalctl -u nginx -n 3 -o cat   (message text only)
Failed to start A high performance web server and a reverse proxy server.
Starting A high performance web server and a reverse proxy server...
Started A high performance web server and a reverse proxy server.

==============================================================
8. FOLLOW MODE (live tail) - the one you will use most
==============================================================
$ journalctl -f            # follow all new log entries
$ journalctl -u nginx -f   # follow one service (like 'tail -f')

Not run here because it blocks forever. Demonstrating the 3-second equivalent:
Sep 17 19:20:11 136d08fe0388 systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Sep 17 19:20:11 136d08fe0388 systemd[1]: nginx.service: Failed with result 'exit-code'.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Failed to start A high performance web server and a reverse proxy server.
Sep 17 19:20:11 136d08fe0388 systemd[1]: Starting A high performance web server and a reverse proxy server...
Sep 17 19:20:11 136d08fe0388 systemd[1]: Started A high performance web server and a reverse proxy server.
(timed out after 3s, as expected)

==============================================================
9. MAINTENANCE - the journal is not infinite
==============================================================
--- journalctl --verify ---
PASS: /var/log/journal/dfef33d1cae34bebbd36918506efbd20/system.journal

--- current size ---
Archived and active journals take up 8.0M in the file system.

Trimming (needs persistent storage to be meaningful):
  journalctl --vacuum-time=7d     delete entries older than 7 days
  journalctl --vacuum-size=500M   shrink the journal to 500 MB
  journalctl --vacuum-files=5     keep only the newest 5 journal files

Caps are configured in /etc/systemd/journald.conf:
  #Storage=auto
  #Compress=yes
  #SystemMaxUse=
  #MaxRetentionSec=

==============================================================
DONE
==============================================================
```
