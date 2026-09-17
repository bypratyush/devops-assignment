# Task 2 - `adduser` vs `useradd`

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Run it: `./lab/lab.sh exec /work/linux-fundamentals/task-02-adduser-vs-useradd/practice.sh`
Verified output: [output.md](output.md)

---

## 1. They are not two versions of the same tool

```text
$ file /usr/sbin/useradd
/usr/sbin/useradd: ELF 64-bit LSB pie executable, ARM aarch64, ... stripped

$ file /usr/sbin/adduser
/usr/sbin/adduser: Perl script text executable
```

| | `useradd` | `adduser` |
|---|---|---|
| What it is | Compiled **binary** | **Perl script** |
| Package | `passwd` (shadow-utils) | `adduser` |
| Level | Low-level, raw syscall-ish | High-level **wrapper** |
| Origin | Every Linux distro | Debian/Ubuntu specific |
| Behaviour | Does *exactly* what you type | Applies Debian policy + prompts |

`adduser` literally calls `useradd` to do the work. From the real run:

```text
$ grep -n "useradd" /usr/sbin/adduser
461:    my $useradd = &which('useradd');
466:        &systemcall($useradd, '-d', $home_dir, '-g', $ingroup_name, '-s', ...
```

So: **`adduser` is a friendly front-end; `useradd` is the engine.**

---

## 2. The difference in practice

### Bare `useradd` - does the minimum and nothing else

```bash
useradd test-useradd
```
```text
/etc/passwd:  test-useradd:x:1000:1000::/home/test-useradd:/bin/sh
home dir:     ls: cannot access '/home/test-useradd': No such file or directory
password:     test-useradd L 09/17/2026 ...        <-- L = LOCKED
```

Three problems, all silent:
1. The home directory in `/etc/passwd` is declared but **was never created**.
   The user logs in and lands in a directory that doesn't exist.
2. The shell is **`/bin/sh`**, not bash - no history, no tab completion, no prompt.
3. The password is **locked**, so the account can't log in at all until you
   separately run `passwd test-useradd`.

### `adduser` - interactive and complete

```bash
adduser test-adduser
```
```text
Adding user `test-adduser' ...
Adding new group `test-adduser' (1001) ...
Adding new user `test-adduser' (1001) with group `test-adduser' ...
Creating home directory `/home/test-adduser' ...
Copying files from `/etc/skel' ...
```

It then **prompts** for a password and the GECOS fields (Full Name, Room Number,
Work Phone, Home Phone). Result:

```text
/etc/passwd:  test-adduser:x:1001:1001:,,,:/home/test-adduser:/bin/bash
home dir:     drwxr-x--- 2 test-adduser test-adduser 4096 /home/test-adduser
contents:     .bash_logout  .bashrc  .profile        <-- copied from /etc/skel
```

### Side by side

```text
test-useradd:x:1000:1000::/home/test-useradd:/bin/sh      <-- no home, sh
test-adduser:x:1001:1001:,,,:/home/test-adduser:/bin/bash <-- home + skel, bash
```

`/etc/passwd` field order: `name:x:UID:GID:GECOS:home_dir:login_shell`
(the `x` means the real password hash lives in `/etc/shadow`).

---

## 3. Making `useradd` behave properly

Everything `adduser` does for free, `useradd` needs told explicitly:

```bash
useradd -m -s /bin/bash -c "DevOps Test User" devops-test
passwd devops-test          # and you must not forget this second step
```
```text
devops-test:x:1002:1002:DevOps Test User:/home/devops-test:/bin/bash
drwxr-x--- 2 devops-test devops-test 4096 /home/devops-test
```

Why the defaults are bad - `useradd -D` shows where they come from
(`/etc/default/useradd`):

```text
GROUP=100
HOME=/home
SHELL=/bin/sh          <-- this is why you get sh, not bash
SKEL=/etc/skel
CREATE_MAIL_SPOOL=no
```

### Useful `useradd` flags

| Flag | Meaning |
|---|---|
| `-m` | Create the home directory (and copy `/etc/skel` into it) |
| `-M` | Explicitly do **not** create a home directory |
| `-s /bin/bash` | Login shell (`/usr/sbin/nologin` for service accounts) |
| `-c "Full Name"` | GECOS / comment field |
| `-d /srv/app` | Home directory path |
| `-G docker,sudo` | **Supplementary** groups (append with `-aG` on `usermod`) |
| `-g devs` | **Primary** group |
| `-u 1500` | Specific UID |
| `-r` | System account (UID below 1000, no aging) |
| `-e 2026-12-31` | Account expiry date |

---

## 4. Which one is preferred on Ubuntu, and why

### Answer: **`adduser`** for creating real human users interactively.

Ubuntu/Debian ship `adduser` precisely because bare `useradd` is easy to get
wrong. The `useradd` man page on Debian says so itself - it recommends using
`adduser` instead. Reasons:

1. **It is complete by default.** Home directory, `/etc/skel` files, a sensible
   shell, correct ownership and `0750` permissions, and the password prompt -
   all in one command. No half-created accounts.
2. **It follows Debian policy.** UID/GID allocation ranges, the per-user group
   scheme, `/etc/adduser.conf` - you inherit the distro's conventions instead of
   inventing your own.
3. **It is interactive and validating.** It rejects bad usernames and prompts
   for the password, so you can't forget step two and leave a locked account.
4. **It is harder to misuse.** The most common real-world bug - "I made a user
   but they can't log in / have no home directory" - simply doesn't happen.

### When `useradd` is the right choice

- **Scripts, Dockerfiles, Ansible, cloud-init, CI.** `useradd` is
  non-interactive, POSIX-ish, and present on *every* distro. `adduser` on
  RHEL/CentOS is just a symlink to `useradd` and takes completely different
  arguments, so any `adduser`-based script is not portable.
- **Service accounts:** `useradd -r -s /usr/sbin/nologin -M appsvc`
- Anywhere you need exact, predictable, no-surprises behaviour.

> **Rule of thumb:** interactive on an Ubuntu box -> `adduser`.
> Inside a script or a Dockerfile -> `useradd` with explicit flags.

---

## 5. Task deliverable - the test user

Created with the recommended command:

```bash
adduser devops-test        # (the run used --disabled-password --gecos "" to stay non-interactive)
```
```text
$ getent passwd devops-test
devops-test:x:1000:1000:,,,:/home/devops-test:/bin/bash

$ getent group devops-test
devops-test:x:1000:

$ ls -la /home/devops-test
drwxr-x--- 2 devops-test devops-test 4096 .
-rw-r--r-- 1 devops-test devops-test  220 .bash_logout
-rw-r--r-- 1 devops-test devops-test 3771 .bashrc
-rw-r--r-- 1 devops-test devops-test  807 .profile
```

This account is left on the lab container. Remove it with
`deluser --remove-home devops-test`.

---

## 6. Deleting users

```bash
userdel devops-test                 # account only, HOME DIRECTORY IS LEFT BEHIND
userdel -r devops-test              # account + home directory + mail spool
deluser devops-test                 # adduser-family equivalent
deluser --remove-home devops-test   # + home directory
deluser --remove-all-files devops-test   # + every file they own anywhere
```

Gotcha found during this task: `deluser --remove-home` exits **8** with
`you need to install the 'perl' package` on a minimal image. `deluser` is a Perl
script and only `perl-base` ships by default. The lab `Dockerfile` installs full
`perl` for this reason. `userdel -r` (the binary) has no such dependency.

---

## 7. Related commands

```bash
passwd user                 # set/change password
passwd -S user              # status: P=usable  L=locked  NP=no password
passwd -l / -u user         # lock / unlock
chpasswd <<< "user:pass"    # set a password non-interactively (scripts)
usermod -aG docker user     # APPEND to a group  - forgetting -a WIPES the others
usermod -s /bin/bash user   # change shell
usermod -L / -U user        # lock / unlock
id user                     # UID, GID, all groups
groups user                 # group names only
getent passwd user          # query passwd via NSS (sees LDAP/SSSD too, unlike grep)
addgroup / groupadd         # the same wrapper-vs-binary split for groups
```

Key files: `/etc/passwd` (accounts), `/etc/shadow` (hashes, `0640 root:shadow`),
`/etc/group`, `/etc/skel` (template copied into new homes),
`/etc/default/useradd` and `/etc/login.defs` (useradd defaults),
`/etc/adduser.conf` (adduser policy).

---

## 8. Interview Q&A

**Q: Difference between `adduser` and `useradd`?**
`useradd` is a low-level binary from shadow-utils available on all distros;
`adduser` is a Debian/Ubuntu Perl wrapper *around* `useradd` that adds
interactivity and distro policy. `useradd` alone doesn't create a home
directory, defaults the shell to `/bin/sh`, and leaves the account locked;
`adduser` handles all of that and prompts for a password.

**Q: Which is preferred on Ubuntu?**
`adduser` for interactive admin work - it's complete and follows Debian policy;
the Debian `useradd` man page recommends it. Use `useradd` in scripts and
Dockerfiles because it's non-interactive and portable across distros.

**Q: Can I use `adduser` on RHEL/CentOS?**
Not the same way. There `adduser` is just a symlink to `useradd`, so the Debian
syntax and interactive behaviour don't exist. That's exactly why scripts should
use `useradd`.

**Q: I ran `useradd bob` and bob can't log in. Why?**
Two reasons: the password is still locked (`passwd -S bob` shows `L`), and no
home directory was created. Fix with `passwd bob` and
`mkhomedir_helper bob` - or create it properly next time with `useradd -m -s /bin/bash`.

**Q: How do you create a service account that can't log in?**
`useradd -r -s /usr/sbin/nologin -M appsvc` - system UID, no valid shell, no home.

**Q: How do you add a user to a group without removing their existing groups?**
`usermod -aG groupname user`. Leaving out `-a` **replaces** the entire
supplementary group list - a classic way to lock yourself out of `sudo`.

**Q: `grep` vs `getent` on /etc/passwd?**
`grep` only reads the local file. `getent` goes through NSS, so it also sees
users from LDAP, SSSD, or NIS. In any directory-backed environment, use `getent`.
