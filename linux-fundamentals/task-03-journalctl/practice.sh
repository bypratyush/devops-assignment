#!/usr/bin/env bash
# Task 3 - journalctl: viewing system and service logs.
# Run inside the Linux lab:  ./lab/lab.sh exec /work/linux-fundamentals/task-03-journalctl/practice.sh
set -u

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
# --no-pager everywhere: journalctl pipes to 'less' by default and would hang a script.
J="journalctl --no-pager"

hr "0. What journalctl is reading"
echo "systemd-journald collects logs from the kernel, initrd, services' stdout/stderr,"
echo "and syslog, and stores them in a structured, indexed BINARY format."
echo "journalctl is the query tool for that store - you cannot 'cat' it."
echo
systemctl --no-pager status systemd-journald | head -4
echo
echo "--- where the journal lives + how big it is ---"
$J --disk-usage
echo
echo "  /run/log/journal  = volatile, wiped on reboot"
echo "  /var/log/journal  = persistent (set Storage=persistent in /etc/systemd/journald.conf)"
ls -d /run/log/journal /var/log/journal 2>&1 | sed 's/^/  /'

hr "1. VIEW SYSTEM LOGS - the everyday commands"
echo "--- journalctl -n 10   (last 10 lines; default is 10) ---"
$J -n 10
echo
echo "--- journalctl -r -n 5   (-r = newest first) ---"
$J -r -n 5

hr "2. Filter by TIME"
echo "--- journalctl --since '10 minutes ago' -n 5 ---"
$J --since "10 minutes ago" -n 5
echo
echo "--- journalctl --since today -n 3 ---"
$J --since today -n 3
echo
echo "Other accepted forms: --since '2026-09-17 09:00:00' --until '2026-09-17 10:00:00'"
echo "                      --since yesterday   --until '1 hour ago'"

hr "3. Filter by PRIORITY (syslog levels 0-7)"
echo "0 emerg  1 alert  2 crit  3 err  4 warning  5 notice  6 info  7 debug"
echo
echo "--- journalctl -p err -b   (errors and worse, this boot) ---"
$J -p err -b | tail -10
echo
echo "--- journalctl -p warning -b -n 5 ---"
$J -p warning -b -n 5

hr "4. Filter by BOOT"
echo "--- journalctl -b   = current boot only (-b -1 = previous boot) ---"
$J -b -n 3
echo
echo "--- journalctl --list-boots ---"
$J --list-boots 2>&1 | tail -5
echo
echo "--- journalctl -k   (kernel ring buffer / dmesg) ---"
$J -k -n 3 2>&1 | head -3
echo "  (in this container these are the HOST kernel's messages - the kernel is"
echo "   shared. On a bare-metal host or VM, -k shows that machine's own kernel log,"
echo "   the same content as 'dmesg'.)"

hr "5. PRACTICE: logs for a SPECIFIC SERVICE  -->  journalctl -u <unit>"
echo "Using nginx as the example service."
echo
echo "--- start it ---"
systemctl start nginx
systemctl --no-pager status nginx | head -5
echo
echo "--- journalctl -u nginx   (everything nginx ever logged) ---"
$J -u nginx
echo
echo "--- restart it and watch new entries appear ---"
systemctl restart nginx
$J -u nginx --since "1 minute ago"

hr "6. PRACTICE: a service that FAILS - the real troubleshooting loop"
echo "Breaking the nginx config on purpose..."
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
echo "this_is_not_a_valid_directive;" >> /etc/nginx/nginx.conf
echo
echo "--- systemctl restart nginx (expected to fail) ---"
systemctl restart nginx 2>&1 || echo ">>> restart FAILED, exit $?"
echo
echo "--- systemctl status nginx ---"
systemctl --no-pager status nginx 2>&1 | head -12
echo
echo "--- journalctl -u nginx -n 20   <-- THIS is where the real reason is ---"
$J -u nginx -n 20
echo
echo "--- journalctl -xeu nginx   (-x adds explanatory help text, -e jumps to end) ---"
$J -xeu nginx 2>&1 | tail -15
echo
echo "Now repair the config and restart:"
mv /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf
systemctl restart nginx && echo ">>> nginx restarted cleanly"
systemctl is-active nginx
echo
echo "--- the recovery is recorded in the journal too ---"
$J -u nginx -n 5

hr "7. Other filters worth knowing"
echo "--- by unit + priority together ---"
echo "\$ journalctl -u nginx -p err -b"
$J -u nginx -p err -b | tail -5
echo
echo "--- by executable:  journalctl /usr/sbin/nginx ---"
$J /usr/sbin/nginx -n 3 2>&1 | tail -3
echo
echo "--- structured output:  journalctl -u nginx -n 1 -o json-pretty ---"
$J -u nginx -n 1 -o json-pretty 2>&1 | head -18
echo
echo "--- output formats: short (default), short-precise, verbose, json, json-pretty, cat ---"
echo "\$ journalctl -u nginx -n 3 -o cat   (message text only)"
$J -u nginx -n 3 -o cat

hr "8. FOLLOW MODE (live tail) - the one you will use most"
echo "\$ journalctl -f            # follow all new log entries"
echo "\$ journalctl -u nginx -f   # follow one service (like 'tail -f')"
echo
echo "Not run here because it blocks forever. Demonstrating the 3-second equivalent:"
timeout 3 journalctl -u nginx -f --no-pager 2>&1 | tail -5 || true
echo "(timed out after 3s, as expected)"

hr "9. MAINTENANCE - the journal is not infinite"
echo "--- journalctl --verify ---"
$J --verify 2>&1 | tail -3
echo
echo "--- current size ---"
$J --disk-usage
echo
echo "Trimming (needs persistent storage to be meaningful):"
echo "  journalctl --vacuum-time=7d     delete entries older than 7 days"
echo "  journalctl --vacuum-size=500M   shrink the journal to 500 MB"
echo "  journalctl --vacuum-files=5     keep only the newest 5 journal files"
echo
echo "Caps are configured in /etc/systemd/journald.conf:"
grep -E '^#?(Storage|SystemMaxUse|MaxRetentionSec|Compress)' /etc/systemd/journald.conf | sed 's/^/  /'

hr "DONE"
