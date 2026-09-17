#!/usr/bin/env bash
# Task 4 - Practise the important commands from the cheat sheet, with real output.
# Run inside the Linux lab:  ./lab/lab.sh exec /work/linux-fundamentals/task-04-command-cheatsheet/practice.sh
set -u

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
run() { echo; echo "\$ $*"; eval "$@" 2>&1 | head -15; }

LAB=/root/cmd-lab
rm -rf "$LAB"; mkdir -p "$LAB"/{logs,conf,archive}; cd "$LAB"

# seed some data to work on
printf 'alice,engineering,90\nbob,sales,72\ncarol,engineering,85\ndave,sales,64\nerin,devops,95\n' > staff.csv
printf '2026-09-17 10:00:01 INFO  service started\n2026-09-17 10:00:05 WARN  disk at 81%%\n2026-09-17 10:01:12 ERROR db connection refused\n2026-09-17 10:01:13 ERROR retry failed\n2026-09-17 10:02:44 INFO  recovered\n' > logs/app.log
echo "listen_port = 8080" > conf/app.conf
head -c 200000 /dev/urandom > archive/blob.bin

hr "1. NAVIGATION - where am I, what is here"
run pwd
run "ls -la"
run "ls -lh logs/"
run "tree -L 2"

hr "2. VIEWING FILE CONTENT"
run "cat conf/app.conf"
run "head -3 logs/app.log"
run "tail -2 logs/app.log"
run "wc -l logs/app.log staff.csv"
echo
echo "less <file>  = page through interactively (q quits). Not run: it needs a TTY."

hr "3. SEARCHING INSIDE FILES - grep"
run "grep ERROR logs/app.log"
run "grep -c ERROR logs/app.log"
run "grep -n 'engineering' staff.csv"
run "grep -i -v error logs/app.log"
run "grep -rn 'listen_port' ."
echo
echo "  -i ignore case   -v invert   -n line numbers   -r recursive   -c count   -E regex"

hr "4. FINDING FILES - find"
run "find . -type f -name '*.log'"
run "find . -type d"
run "find . -type f -size +100k"
run "find . -type f -mmin -5 | head -5"
echo
echo "  find . -name '*.log' -delete          delete matches"
echo "  find . -name '*.log' -exec rm {} \;   run a command per match"

hr "5. TEXT PROCESSING - cut / sort / uniq / awk / sed"
run "cut -d, -f1,2 staff.csv"
run "sort -t, -k3 -n -r staff.csv"
run "cut -d, -f2 staff.csv | sort | uniq -c | sort -rn"
run "awk -F, '{ sum += \$3 } END { print \"average score:\", sum/NR }' staff.csv"
run "awk -F, '\$3 > 80 { print \$1, \"->\", \$3 }' staff.csv"
run "sed 's/engineering/ENG/g' staff.csv"
echo
echo "  sed -i 's/old/new/g' file    edit the file IN PLACE"

hr "6. PIPES AND REDIRECTION - the core Unix idea"
run "grep ERROR logs/app.log | wc -l"
run "cut -d, -f3 staff.csv | sort -n | tail -1"
echo
echo "\$ echo 'written' > out.txt     (> overwrite,  >> append)"
echo "written" > out.txt; echo "appended" >> out.txt; cat out.txt
echo
echo "\$ command 2> err.txt           redirect stderr only"
echo "\$ command > all.txt 2>&1       redirect both stdout and stderr"
echo "\$ command | tee file.txt       print to screen AND write to file"
ls nonexistent 2> err.txt; echo "stderr captured: $(cat err.txt)"

hr "7. FILE OPERATIONS"
run "cp conf/app.conf conf/app.conf.bak"
run "mkdir -p deep/nested/dir"
run "mv conf/app.conf.bak archive/"
run "ls -R archive"
run "touch newfile.txt && ls -l newfile.txt"
run "rm -f newfile.txt && echo removed"
echo
echo "  cp -r  recursive    mv = rename+move    rm -r recursive    rm -f force"
echo "  DANGER: 'rm -rf /' style typos are unrecoverable. Check pwd first."

hr "8. PERMISSIONS - chmod / chown"
run "ls -l staff.csv"
echo
echo "  rwx rwx rwx = owner group other      r=4 w=2 x=1"
run "chmod 640 staff.csv && ls -l staff.csv"
run "chmod u+x staff.csv && ls -l staff.csv"
run "chmod 644 staff.csv && ls -l staff.csv"
id devops-test >/dev/null 2>&1 && { run "chown devops-test staff.csv && ls -l staff.csv"; run "chown root:root staff.csv && ls -l staff.csv"; }
run umask

hr "9. USERS AND IDENTITY"
run whoami
run id
run "getent passwd root"
run "who; echo '(who = logged-in sessions; empty in a container)'"
echo
echo "  su - <user>        switch user with a login shell"
echo "  sudo <cmd>         run one command as root"
echo "  sudo -i            interactive root shell"

hr "10. PROCESSES"
run "ps aux | head -6"
run "ps -ef | grep -c ."
run "pgrep -a nginx | head -3"
echo
echo "  top / htop         live process view"
echo "  kill <PID>         send SIGTERM (graceful)"
echo "  kill -9 <PID>      SIGKILL (force, last resort)"
echo "  pkill <name>       kill by name"
echo
echo "--- demonstrating a background job + kill ---"
sleep 120 &
BGPID=$!
echo "started 'sleep 120' with PID $BGPID"
ps -p $BGPID -o pid,stat,cmd --no-headers
kill $BGPID 2>/dev/null; sleep 0.3
ps -p $BGPID >/dev/null 2>&1 && echo "still running" || echo "PID $BGPID terminated by kill"
echo
echo "  cmd &     run in background     jobs   list them"
echo "  fg / bg   move between fore/background"
echo "  nohup cmd &   keep running after logout"

hr "11. SYSTEM INFORMATION"
run "uname -a"
run "hostname"
run "uptime"
run "df -h /"
run "du -sh ."
run "du -sh * | sort -h"
run "free -h"
run "nproc"

hr "12. NETWORKING"
run "ip -brief addr"
run "ip route"
run "ss -tulnp | head -6"
run "curl -s -o /dev/null -w 'localhost nginx -> HTTP %{http_code}\n' http://localhost/"
echo
echo "  ping <host>        ICMP reachability"
echo "  curl -I <url>      headers only"
echo "  curl -O <url>      download to a file"
echo "  wget <url>         download"
echo "  dig / nslookup     DNS lookups"

hr "13. ARCHIVES AND COMPRESSION"
run "tar -czf backup.tar.gz logs conf"
run "ls -lh backup.tar.gz"
run "tar -tzf backup.tar.gz"
run "mkdir -p restore && tar -xzf backup.tar.gz -C restore && find restore -type f"
echo
echo "  tar -czf out.tar.gz dir/   CREATE gzipped archive   (c=create z=gzip f=file)"
echo "  tar -xzf out.tar.gz        EXTRACT"
echo "  tar -tzf out.tar.gz        LIST contents without extracting"
echo "  gzip / gunzip, zip / unzip for single files"

hr "14. SERVICES - systemctl"
run "systemctl is-active nginx"
run "systemctl is-enabled nginx"
run "systemctl --no-pager status nginx | head -5"
run "systemctl list-units --type=service --state=running --no-pager | head -8"
echo
echo "  systemctl start|stop|restart|reload <svc>"
echo "  systemctl enable|disable <svc>     start at boot / don't"
echo "  systemctl daemon-reload            after editing a unit file"
echo "  journalctl -u <svc> -f             follow that service's logs  (see Task 3)"

hr "15. PACKAGES (Debian/Ubuntu)"
run "dpkg -l | wc -l"
run "dpkg -l nginx | tail -1"
run "apt list --installed 2>/dev/null | head -4"
echo
echo "  apt update              refresh the package index"
echo "  apt install <pkg>       install"
echo "  apt remove <pkg>        remove (purge also deletes config)"
echo "  apt search <term>       search"
echo "  dpkg -l                 list installed"
echo "  RHEL/CentOS equivalents: yum / dnf, rpm -qa"

hr "16. DISK AND FILE INSPECTION"
run "file archive/blob.bin staff.csv logs"
run "stat staff.csv"
run "df -hT | head -4"

hr "17. HISTORY AND HELP"
echo "\$ history          previous commands    (!42 re-runs #42, !! re-runs last)"
echo "\$ man <cmd>        full manual page"
echo "\$ <cmd> --help     quick usage"
echo "\$ which <cmd>      path to the binary"
echo "\$ type <cmd>       is it a builtin, alias, or file?"
run "which grep"
run "type cd"
run "grep --help | head -4"

hr "18. CLEANUP"
cd /; rm -rf "$LAB"; echo "removed $LAB"

hr "DONE"
