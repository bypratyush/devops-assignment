# Task 4 - Linux Command Cheat Sheet

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Run it: `./lab/lab.sh exec /work/linux-fundamentals/task-04-command-cheatsheet/practice.sh`
Verified output: [output.md](output.md) - every command below was executed with real output.

---

## 1. Navigation

| Command | Purpose |
|---|---|
| `pwd` | Print working directory |
| `ls` | List. `-l` long, `-a` hidden, `-h` human sizes, `-t` by time, `-R` recursive |
| `ls -lh` | The one you'll type most |
| `cd dir` / `cd ..` / `cd -` | Change dir / up one / **back to previous** |
| `cd` or `cd ~` | Home directory |
| `tree -L 2` | Directory tree, 2 levels deep |
| `find` | Search the filesystem (below) |
| `which cmd` | Path to the binary |
| `type cmd` | Is it a builtin, alias, function, or file? |

---

## 2. Viewing file content

| Command | Purpose |
|---|---|
| `cat file` | Dump whole file (small files only) |
| `less file` | **Page through it** - `/` search, `n` next, `G` end, `q` quit |
| `head -20 file` | First 20 lines |
| `tail -20 file` | Last 20 lines |
| `tail -f file` | **Follow a growing log live** |
| `wc -l file` | Count lines (`-w` words, `-c` bytes) |
| `file x` | What *kind* of file is it really |
| `stat x` | inode, links, perms, size, timestamps |
| `diff a b` | Line differences (`diff -u` unified) |

---

## 3. grep - search inside files

```bash
grep ERROR app.log              # lines containing ERROR
grep -i error app.log           # case-insensitive
grep -v INFO app.log            # INVERT: lines NOT matching
grep -n pattern file            # show line numbers
grep -c ERROR app.log           # count matching lines
grep -r "listen_port" .         # recursive through a directory
grep -rn "TODO" --include='*.py' .
grep -E "ERROR|WARN" app.log    # extended regex (alternation)
grep -A3 -B3 ERROR app.log      # 3 lines After / Before for context
```

---

## 4. find - search for files

```bash
find . -type f -name '*.log'        # files by name (-iname = case-insensitive)
find . -type d -name 'conf*'        # directories
find . -type f -size +100M          # bigger than 100 MB
find . -type f -mtime -7            # modified in the last 7 days
find . -type f -mmin -5             # modified in the last 5 minutes
find . -type f -perm 0777           # by permission
find . -user devops-test            # by owner
find . -type l                      # symlinks;  -xtype l = BROKEN symlinks
find . -name '*.tmp' -delete        # delete every match
find . -name '*.log' -exec gzip {} \;   # run a command per match
find /var/log -type f -size +1G -exec ls -lh {} \;   # the classic "what filled my disk"
```

---

## 5. Text processing - cut / sort / uniq / awk / sed

Given `staff.csv` = `name,department,score`:

```bash
cut -d, -f1,2 staff.csv            # columns 1 and 2, comma delimited
sort -t, -k3 -n -r staff.csv       # sort by field 3, numeric, reversed
cut -d, -f2 staff.csv | sort | uniq -c | sort -rn   # COUNT BY CATEGORY
```
```text
      2 sales
      2 engineering
      1 devops
```
> `uniq` only collapses **adjacent** duplicates - you must `sort` first. The
> `sort | uniq -c | sort -rn` idiom is the standard "top N by frequency".

```bash
awk -F, '{ sum += $3 } END { print "average:", sum/NR }' staff.csv   # -> 81.2
awk -F, '$3 > 80 { print $1, "->", $3 }' staff.csv                   # filter by column
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head       # top IPs in a log

sed 's/engineering/ENG/g' staff.csv    # substitute (g = every match per line)
sed -i 's/old/new/g' file              # edit the file IN PLACE
sed -n '10,20p' file                   # print only lines 10-20
sed '/^#/d' config                     # delete comment lines
```

`tr`, `paste`, `join`, `column -t`, `xargs` round out the toolkit.

---

## 6. Pipes and redirection - the core Unix idea

```bash
cmd1 | cmd2            # stdout of cmd1 becomes stdin of cmd2
cmd > file             # stdout to file (OVERWRITE)
cmd >> file            # stdout to file (APPEND)
cmd 2> errors.txt      # stderr only
cmd > all.txt 2>&1     # both stdout and stderr to one file
cmd &> all.txt         # bash shorthand for the same
cmd 2>/dev/null        # discard errors
cmd | tee file.txt     # print to screen AND write to file
cmd | tee -a file.txt  # ...appending
```

File descriptors: **0** stdin, **1** stdout, **2** stderr. `2>&1` means
"send fd 2 wherever fd 1 currently goes" - so order matters:
`> f 2>&1` works, `2>&1 > f` does not.

---

## 7. File operations

```bash
cp src dst              # copy      -r recursive, -p preserve attrs, -a archive
mv src dst              # move AND rename - same command
rm file                 # delete    -r recursive, -f force
mkdir -p a/b/c          # create nested dirs, no error if they exist
rmdir dir               # only removes EMPTY dirs
touch file              # create empty file / update timestamp
ln -s target link       # symlink (see Task 1)
rsync -av src/ dst/     # smarter copy: resumable, delta transfer, over SSH
```

> `rm -rf` has no undo and no confirmation. Run `pwd` first. Beware unquoted
> variables: if `$DIR` is empty, `rm -rf $DIR/*` becomes `rm -rf /*`.

---

## 8. Permissions and ownership

```text
-rwxr-xr--   1 root root  ...
 │└┬┘└┬┘└┬┘
 │ │  │  └── other:  r--  = 4
 │ │  └───── group:  r-x  = 5
 │ └──────── owner:  rwx  = 7      -> chmod 754
 └────────── type: - file, d dir, l symlink
```

`r`=4 `w`=2 `x`=1. On a **directory**: `r` = list it, `w` = create/delete files
in it, `x` = enter/traverse it.

```bash
chmod 644 file          # rw-r--r--   normal file
chmod 600 ~/.ssh/id_rsa # rw-------   private key (SSH REFUSES anything looser)
chmod 755 script.sh     # rwxr-xr-x   executable / directory
chmod +x script.sh      # add execute for everyone
chmod u+x,go-w file     # symbolic: u user, g group, o other, a all
chmod -R 755 dir/       # recursive
chown user:group file   # change owner and group
chown -R www-data:www-data /var/www
umask                   # -> 0022, the permission bits masked OFF for new files
```

---

## 9. Users and identity

```bash
whoami                  # current username
id                      # uid, gid, and all groups
id username             # for another user
groups                  # my group names
who / w                 # who is logged in (w adds what they're doing)
last                    # login history
su - username           # switch user, with a login shell
sudo cmd                # run one command as root
sudo -i                 # interactive root shell
getent passwd user      # query via NSS (sees LDAP/SSSD, unlike grep)
```
See [Task 2](../task-02-adduser-vs-useradd/README.md) for user creation.

---

## 10. Processes

```bash
ps aux                  # every process, BSD syntax
ps -ef                  # every process, System V syntax
ps aux | grep nginx     # find a process
pgrep -a nginx          # cleaner: PIDs + command line
top                     # live view   (htop is nicer if installed)
kill PID                # SIGTERM - polite, lets it clean up
kill -9 PID             # SIGKILL - unblockable, LAST RESORT (no cleanup)
pkill nginx             # kill by name
killall nginx           # kill all by exact name
```

Job control:
```bash
cmd &                   # run in background
jobs                    # list background jobs
fg %1 / bg %1           # bring to foreground / resume in background
Ctrl+Z                  # suspend the foreground job
Ctrl+C                  # SIGINT - interrupt it
nohup cmd &             # keep running after logout
```

---

## 11. System information

```bash
uname -a                # kernel, arch, hostname
hostname                # or hostnamectl
uptime                  # load averages + how long it's been up
df -h                   # DISK SPACE per filesystem      <-- "disk full?"
df -i                   # INODE usage - the other way a disk "fills up"
du -sh dir/             # total size of a directory
du -sh * | sort -h      # what's big in here             <-- "what filled it?"
free -h                 # RAM and swap
nproc / lscpu           # CPU count / details
lsblk                   # block devices
```

---

## 12. Networking

```bash
ip addr / ip -brief addr    # interfaces and IPs      (modern; ifconfig is legacy)
ip route                    # routing table           (legacy: route -n)
ss -tulnp                   # LISTENING SOCKETS       (legacy: netstat -tulnp)
ss -tn state established    # active connections
ping -c4 host               # reachability
curl -s url                 # HTTP request
curl -I url                 # headers only
curl -o out.html url        # save to file
curl -s -o /dev/null -w '%{http_code}\n' url   # just the status code
wget url                    # download
dig name / nslookup name    # DNS lookup
traceroute host             # path to a host
telnet host 443 / nc -zv host 443   # is that port open?
```

`ss -tulnp` decoded: `-t` TCP, `-u` UDP, `-l` listening, `-n` numeric ports,
`-p` show the process. This is the "what is using port 8080" command.

---

## 13. Archives and compression

```bash
tar -czf backup.tar.gz dir/     # CREATE gzipped archive
tar -xzf backup.tar.gz          # EXTRACT
tar -xzf backup.tar.gz -C /dst  # extract somewhere specific
tar -tzf backup.tar.gz          # LIST contents without extracting
```
Flags: `c` create, `x` extract, `t` list, `z` gzip, `j` bzip2, `J` xz,
`f` file (must come last), `v` verbose.

> Always `-t` before `-x` on an archive you didn't make - check it doesn't
> explode 400 files into your current directory.

```bash
gzip file / gunzip file.gz      # compress/decompress in place
zip -r out.zip dir/ ; unzip out.zip
```

---

## 14. Services (systemd)

```bash
systemctl status nginx          # state + recent log lines
systemctl start|stop|restart nginx
systemctl reload nginx          # re-read config WITHOUT dropping connections
systemctl enable nginx          # start at boot
systemctl disable nginx
systemctl enable --now nginx    # enable AND start
systemctl is-active nginx       # -> active   (script friendly)
systemctl is-enabled nginx
systemctl daemon-reload         # REQUIRED after editing a unit file
systemctl list-units --type=service --state=running
systemctl --failed              # everything that's broken
```
Logs: `journalctl -u nginx -f` - see [Task 3](../task-03-journalctl/README.md).

---

## 15. Packages

**Debian / Ubuntu:**
```bash
apt update                  # refresh the index (NOT an upgrade)
apt upgrade                 # install available upgrades
apt install nginx
apt remove nginx            # apt purge also deletes config files
apt search term / apt show nginx
dpkg -l                     # list installed
dpkg -l nginx               # is this one installed, and what version
dpkg -S /usr/sbin/nginx     # which package owns this file
```

**RHEL / CentOS / Fedora:** `dnf`/`yum install`, `rpm -qa`, `rpm -qf <file>`.

---

## 16. History and help

```bash
history                 # previous commands
!42                     # re-run command 42
!!                      # re-run the last command      (sudo !! is the classic)
Ctrl+R                  # SEARCH history interactively  <-- learn this one
man ls                  # full manual
ls --help               # quick usage
apropos keyword         # find commands by topic
```

---

## 17. The ones worth committing to muscle memory

| Command | Why |
|---|---|
| `Ctrl+R` | Search shell history - saves more typing than anything else |
| `cd -` | Jump back to the previous directory |
| `df -h` / `du -sh * \| sort -h` | Disk full -> where |
| `ss -tulnp` | What's listening on that port |
| `ps aux \| grep x` / `pgrep -a x` | Is it running |
| `journalctl -xeu svc` | Why did the service fail |
| `systemctl status svc` | Is the service up |
| `grep -rn "text" .` | Find that string anywhere |
| `find . -name '*.log' -mtime +30 -delete` | Clean up old files |
| `sort \| uniq -c \| sort -rn` | Top-N by frequency in any log |
| `tail -f` / `journalctl -f` | Watch it happen live |
| `chmod 600 ~/.ssh/id_rsa` | The permission SSH insists on |

---

## 18. Interview-worthy details

- **`kill` vs `kill -9`** - `kill` sends SIGTERM, which a process can trap to
  flush buffers and shut down cleanly. `kill -9` sends SIGKILL, which the kernel
  enforces and the process cannot catch - no cleanup, possible data loss. Always
  try SIGTERM first.
- **Disk full but `df` shows space free** - you've exhausted **inodes**, not
  bytes. Check `df -i`. Usually millions of tiny files in one directory.
- **Deleted a big log but space didn't come back** - a process still holds the
  file open. The inode isn't freed until the last descriptor closes. Find it
  with `lsof | grep deleted`, then restart that service. (Same link-count rule
  as [Task 1](../task-01-links/README.md).)
- **`apt update` vs `apt upgrade`** - `update` only refreshes the package index;
  `upgrade` actually installs the new versions.
- **`systemctl reload` vs `restart`** - `reload` re-reads config without
  dropping connections; `restart` stops and starts, breaking active requests.
- **`>` vs `>>`** - `>` truncates the file first. Redirecting into a file you're
  also reading in the same pipeline empties it before the read.
