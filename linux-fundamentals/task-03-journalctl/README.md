# Task 3 - `journalctl`

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Run it: `./lab/lab.sh exec /work/linux-fundamentals/task-03-journalctl/practice.sh`
Verified output: [output.md](output.md)

---

## 1. What journalctl is for

`systemd-journald` is the logging daemon in systemd. It collects, in one place:

- kernel messages (what `dmesg` shows)
- everything from early boot and the initrd
- **stdout and stderr of every systemd service** - a service doesn't need to
  implement logging at all; whatever it prints is captured
- anything sent to syslog
- structured messages from applications via the native journal API

It stores them in an **indexed binary format**, not plain text. That's the whole
point and also why you need a tool: you can't `cat` or `tail` the journal.

**`journalctl` is the query interface to that store.**

```text
$ journalctl --disk-usage
Archived and active journals take up 8.0M in the file system.
```

### Why binary instead of /var/log/*.log?

Each entry carries **structured fields** - `_SYSTEMD_UNIT`, `_PID`, `_UID`,
`PRIORITY`, `_HOSTNAME`, `_EXE`, `_BOOT_ID` and more - so you can filter on any
of them instead of writing fragile `grep`/`awk` against free text. You get:

- indexed filtering by unit, time, priority, boot, PID, or executable
- automatic rotation and size caps
- interleaving of kernel + service + syslog logs on one timeline
- tamper-evident sequencing (`journalctl --verify`)

The trade-off: you need `journalctl` to read it, and plain-text tooling
(`grep`, `tail`, log shippers) needs `-o cat`/`-o json` to consume it.

### Where it is stored

| Path | Meaning |
|---|---|
| `/run/log/journal/` | **Volatile** - RAM only, wiped on every reboot |
| `/var/log/journal/` | **Persistent** - survives reboots |

Controlled by `Storage=` in `/etc/systemd/journald.conf`:

```text
#Storage=auto        auto = persistent IF /var/log/journal exists, else volatile
#Compress=yes
#SystemMaxUse=
#MaxRetentionSec=
```

To make logs persistent on a box where they aren't:
`sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald`

> If you ever ran `journalctl -b -1` and got "Specified boot ID not found",
> it's almost always because storage is volatile - previous boots were never saved.

---

## 2. Viewing system logs

```bash
journalctl                       # everything, oldest first, in a pager
journalctl -n 20                 # last 20 entries (default 10)
journalctl -r                    # reverse: newest first
journalctl -e                    # jump to the end of the pager
journalctl --no-pager            # don't pipe through less (ESSENTIAL in scripts)
journalctl -f                    # FOLLOW live, like tail -f
```

> `journalctl` pipes to `less` by default. In any script or non-interactive
> shell always add `--no-pager`, or it will appear to hang.

### Filter by time

```bash
journalctl --since "10 minutes ago"
journalctl --since today
journalctl --since yesterday --until "1 hour ago"
journalctl --since "2026-09-17 09:00:00" --until "2026-09-17 10:00:00"
```

### Filter by priority (syslog levels 0-7)

| n | name | n | name |
|---|---|---|---|
| 0 | emerg | 4 | warning |
| 1 | alert | 5 | notice |
| 2 | crit | 6 | info |
| 3 | **err** | 7 | debug |

```bash
journalctl -p err -b        # errors and ANYTHING WORSE, this boot
journalctl -p warning -n 20
journalctl -p 3..4          # a range
```
`-p err` means "err **and above in severity**" (0-3), not "err only".

### Filter by boot

```bash
journalctl -b               # current boot
journalctl -b -1            # previous boot  <-- what you want after a crash
journalctl --list-boots     # all recorded boots
journalctl -k               # kernel messages only (= dmesg)
```
```text
$ journalctl --list-boots
 0 7a7e4a2fd81a499090b46fdb36016fc1 Thu 2026-09-17 16:58:43 UTC-...
```

---

## 3. Logs for a specific service - the main event

```bash
journalctl -u nginx              # everything nginx has ever logged
journalctl -u nginx -f           # follow it live
journalctl -u nginx -n 50        # last 50 lines
journalctl -u nginx --since today
journalctl -u nginx -p err -b    # only its errors this boot
journalctl -xeu nginx            # the one systemd itself tells you to run
```

`-xeu` = `-x` (add explanatory text) + `-e` (jump to end) + `-u` (unit).

You can pass `-u` more than once to correlate two services on one timeline:
`journalctl -u nginx -u php8.1-fpm --since "1 hour ago"`

### The real troubleshooting loop (captured from the run)

The practice script deliberately appends an invalid directive to
`nginx.conf` and restarts. Here is what each tool tells you:

**Step 1 - the restart fails, but says nothing useful:**
```text
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
```

**Step 2 - `systemctl status nginx` gives state + the last few log lines:**
```text
× nginx.service - A high performance web server and a reverse proxy server
     Active: failed (Result: exit-code) since Thu 2026-09-17 16:59:36 UTC
    Process: 286 ExecStartPre=/usr/sbin/nginx -t -q ... (code=exited, status=1/FAILURE)
```

**Step 3 - `journalctl -u nginx` has the actual reason:**
```text
nginx[286]: nginx: [emerg] unknown directive "this_is_not_a_valid_directive" in /etc/nginx/nginx.conf:84
nginx[286]: nginx: configuration file /etc/nginx/nginx.conf test failed
systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
systemd[1]: nginx.service: Failed with result 'exit-code'.
```

**File and line number.** `systemctl status` told you it broke; `journalctl`
told you *why*. That's the division of labour, and it's the habit to build:

> `systemctl status <svc>` -> is it up? -> `journalctl -xeu <svc>` -> why not?

**Step 4 -** fixing the config and restarting is recorded on the same timeline,
so the journal shows the full failure-and-recovery story.

---

## 4. Other filters

```bash
journalctl /usr/sbin/nginx         # by executable path
journalctl _PID=1234               # by PID
journalctl _UID=1000               # by user
journalctl -t sshd                 # by syslog identifier
journalctl -g "connection refused" # grep the message text (regex)
journalctl --user -u myapp         # the calling user's own services
journalctl -F _SYSTEMD_UNIT        # list all values a field takes
```

### Output formats

```bash
journalctl -u nginx -o short          # default: syslog-like
journalctl -u nginx -o short-precise  # microsecond timestamps
journalctl -u nginx -o cat            # message text ONLY - pipe this to grep/awk
journalctl -u nginx -o verbose        # every structured field
journalctl -u nginx -o json-pretty    # machine readable
```

`-o json-pretty` shows what's really stored per entry:
```json
{
  "PRIORITY" : "6",
  "_SYSTEMD_UNIT" : "init.scope",
  "UNIT" : "nginx.service",
  "_PID" : "1",
  "_HOSTNAME" : "357944b38e37",
  "_EXE" : "/usr/lib/systemd/systemd",
  "MESSAGE" : "..."
}
```
Every one of those keys is filterable: `journalctl _EXE=/usr/sbin/nginx`.

---

## 5. Maintenance - the journal is not infinite

```bash
journalctl --disk-usage        # how big is it
journalctl --verify            # integrity check
journalctl --vacuum-time=7d    # delete entries older than 7 days
journalctl --vacuum-size=500M  # shrink to 500 MB
journalctl --vacuum-files=5    # keep only the newest 5 journal files
journalctl --rotate            # force rotation now
```

Caps belong in `/etc/systemd/journald.conf` (`SystemMaxUse=`,
`MaxRetentionSec=`, `SystemMaxFileSize=`), then
`systemctl restart systemd-journald`. Vacuuming is the one-off fix; the config
is the permanent one. By default journald already caps itself at 10% of the
filesystem, but on a small root volume that can still be a lot.

---

## 6. Cheat sheet

| Command | Purpose |
|---|---|
| `journalctl -u nginx -f` | **Follow one service** - the everyday command |
| `journalctl -xeu nginx` | **Why did this service fail** |
| `journalctl -p err -b` | All errors this boot |
| `journalctl -b -1 -p err` | Errors from the boot before a crash |
| `journalctl --since "1 hour ago"` | Recent activity |
| `journalctl -u nginx --since today -o cat` | Plain text for grep/awk |
| `journalctl -k` | Kernel log (dmesg) |
| `journalctl --disk-usage` | Size on disk |
| `journalctl --vacuum-time=7d` | Trim old logs |
| `journalctl --list-boots` | Boot history |
| `journalctl --no-pager` | **Always, in scripts** |

---

## 7. Interview Q&A

**Q: What is journalctl?**
The query tool for `systemd-journald`, which collects kernel, boot, syslog and
service stdout/stderr into one indexed binary store with structured metadata.
Because it's binary, `journalctl` is how you read it.

**Q: journalctl vs tail -f /var/log/syslog?**
The journal is structured and indexed, so you can filter by unit, priority,
boot or PID natively instead of grepping free text, and kernel + service logs
share one timeline. `tail` only works on plain-text files, which systemd
services don't need to write at all. `journalctl -f` is the equivalent of `tail -f`.

**Q: How do you see logs for one service?**
`journalctl -u <service>`, plus `-f` to follow, `-n` to limit, `--since` for
time, `-p err` for severity. When it has failed, `journalctl -xeu <service>`.

**Q: A service won't start. Walk me through it.**
`systemctl status <svc>` for state and the failing `ExecStart`/`ExecStartPre`
line, then `journalctl -xeu <svc>` for the actual error message. For nginx-type
services also run the config test (`nginx -t`). Fix, `systemctl daemon-reload`
if the unit file changed, restart, then confirm with `systemctl is-active`.

**Q: Logs disappear after reboot. Why?**
Storage is volatile - the journal is in `/run/log/journal`, which is RAM.
Create `/var/log/journal` (or set `Storage=persistent`) and restart
`systemd-journald`.

**Q: What does `-p err` actually match?**
Priority `err` *and more severe* - levels 0 through 3. Not err only.

**Q: Your journal has filled the disk. What now?**
`journalctl --disk-usage` to confirm, `journalctl --vacuum-size=500M` or
`--vacuum-time=7d` for immediate relief, then set `SystemMaxUse=` in
`/etc/systemd/journald.conf` and restart journald so it can't recur.

**Q: How do you get journal logs into ELK/Splunk/Loki?**
`journalctl -o json --follow` and ship that, or use a collector with a native
journald input (Fluent Bit, Vector, Promtail all have one) so the structured
fields survive instead of being flattened to text.
