# Shell Scripting - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Run inside the Ubuntu 22.04 lab container on 2026-09-18.

## 1. `sysinfo.sh` - the assignment task

```text
==============================================
 SYSTEM INFORMATION
==============================================
Current date : 2026-09-17 19:20:15 UTC
Hostname     : 136d08fe0388
Username     : root
Kernel       : Linux 6.12.76-linuxkit
Uptime       : 19:20:15 up 7 days, 13:03,  0 users,  load average: 6.52, 7.00, 6.93

==============================================
 STUDENT DETAILS
==============================================

My name is        : Pratyush Mohanty
My roll number is : 24BCS10238
My comment is     : DevOps homework - session 3 shell scripting

==============================================
 FILES CREATED
==============================================
created directory : sysinfo-output/
wrote             : sysinfo-output/process.log (23 lines)
wrote             : sysinfo-output/report.txt (18 lines)

--- first 5 lines of sysinfo-output/process.log ---
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 19:04 ?        00:00:00 /sbin/init
root          29       1  0 19:04 ?        00:00:00 /lib/systemd/systemd-journald
message+      43       1  0 19:04 ?        00:00:00 @dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
root          47       1  0 19:04 tty1     00:00:00 /sbin/agetty -o -p -- \u --noclear tty1 linux

--- sysinfo-output/report.txt ---
DevOps Homework - Session 3 (Shell Scripting)
=============================================
Name        : Pratyush Mohanty
Roll number : 24BCS10238
Comment     : DevOps homework - session 3 shell scripting

Generated   : 2026-09-17 19:20:15 UTC
Host        : 136d08fe0388
User        : root
Kernel      : Linux 6.12.76-linuxkit

Top 5 processes by memory:
    PID COMMAND         %MEM
     29 systemd-journal  0.0
      1 systemd          0.0
    531 nginx            0.0
    532 nginx            0.0
    533 nginx            0.0

Done.
```

## 2. `fundamentals.sh` - shell building blocks

```text

==============================================================
1. VARIABLES AND QUOTING
==============================================================
  plain          : $name        -> Pratyush
  braces         : ${name}_id   -> Pratyush_id     (needed when text follows)
  command subst  : $(date +%Y)  -> 2026
  arithmetic     : $((count*2)) -> 10

  single quotes  : no $name expansion here
  double quotes  : yes Pratyush expansion here

  ALWAYS quote variables. Unquoted $var splits on spaces and globs:
    unquoted -> 2 arguments (WRONG)
    quoted   -> 1 argument  (right)

==============================================================
2. DEFAULTS AND PARAMETER EXPANSION
==============================================================
  ${maybe:-fallback}  -> fallback   (use fallback if unset)
  ${name:?required}   -> Pratyush    (error if unset)
  ${file##*/}         -> syslog.1          (basename)
  ${file%/*}          -> /var/log           (dirname)
  ${file%.*}          -> /var/log/syslog           (strip extension)
  ${#name}            -> 8             (length)

==============================================================
3. CONDITIONALS
==============================================================
  42 is between 11 and 100

  numeric : -eq -ne -lt -le -gt -ge
  string  : =  !=  -z (empty)  -n (non-empty)
  files   : -f (file)  -d (dir)  -e (exists)  -r -w -x  -s (non-empty)

  -f "$0"           : this script is a file
  -d /etc           : /etc is a directory
  ! -e /nope        : /nope does not exist
  -z "$empty"       : empty variable detected

  case: running on Linux

==============================================================
4. LOOPS
==============================================================
  for over a list:
    service: nginx
    service: sshd
    service: cron

  for over a range:
    i=1 squared=1
    i=2 squared=4
    i=3 squared=9

  while reading a file line by line (the correct idiom):
    word=alpha  number=1
    word=beta   number=2
    word=gamma  number=3

  until:
    n=1
    n=2
    n=3

  break exits the loop, continue skips to the next iteration.

==============================================================
5. FUNCTIONS
==============================================================
  greet Pratyush -> hello, Pratyush
  greet          -> hello, world

  4 is even
  7 is odd

  A function returns an EXIT STATUS, not a value.
  To return data: echo it, and capture it with $(func).

==============================================================
6. ARGUMENTS AND EXIT CODES
==============================================================
  $0  script name   -> /work/shell-scripting/fundamentals.sh
  $#  arg count     -> 0
  $@  all args      -> <none>
  $?  last status   -> (below)

  after 'true'  -> $? = 0
  after 'false' -> $? = 1 (caught with ||)

  exit 0 = success, anything else = failure. Always exit non-zero on error,
  or the caller (make, CI, systemd) will think the script succeeded.

==============================================================
7. ERROR HANDLING - the header every script should start with
==============================================================
    set -euo pipefail

      -e           exit immediately if any command fails
      -u           error on use of an undefined variable (catches typos)
      -o pipefail  a pipeline fails if ANY stage fails, not just the last

    Without pipefail:  false | true   -> exit 0  (the failure is hidden)
    With pipefail:     false | true   -> exit 1

    trap 'echo "failed at line $LINENO"' ERR      # report where it broke
    trap 'rm -f "$tmpfile"' EXIT                  # always clean up
  demonstrating pipefail:
    without pipefail -> exit 0
    with pipefail    -> exit 1

  created temp file /tmp/tmp.m7XMySjeXF - the EXIT trap will remove it automatically

==============================================================
8. A USEFUL PATTERN: argument parsing
==============================================================
    while [ $# -gt 0 ]; do
      case "$1" in
        -v|--verbose) VERBOSE=1; shift ;;
        -f|--file)    FILE="$2"; shift 2 ;;
        -h|--help)    usage; exit 0 ;;
        *)            echo "unknown option: $1" >&2; exit 1 ;;
      esac
    done

==============================================================
DONE
==============================================================
```
