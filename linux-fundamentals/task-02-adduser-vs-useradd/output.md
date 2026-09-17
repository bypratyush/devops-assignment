# task-02-adduser-vs-useradd - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./lab/lab.sh exec /work/linux-fundamentals/task-02-adduser-vs-useradd/practice.sh` on 2026-09-18.

```text

==============================================================
0. Both commands exist - but they are NOT the same kind of program
==============================================================
which useradd -> /usr/sbin/useradd
which adduser -> /usr/sbin/adduser

/usr/sbin/useradd: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, BuildID[sha1]=9ca25c8dea54feb7dcadf3675981738d91ae86f9, for GNU/Linux 3.7.0, stripped
/usr/sbin/adduser: Perl script text executable

useradd = low-level BINARY from the 'passwd' package (part of shadow-utils).
adduser = high-level PERL SCRIPT from the 'adduser' package that CALLS useradd.

--- proof that adduser calls useradd internally: ---
461:    my $useradd = &which('useradd');
463:        &systemcall($useradd, '--extrausers', '-d', $home_dir, '-g', $ingroup_name, '-s',
466:        &systemcall($useradd, '-d', $home_dir, '-g', $ingroup_name, '-s',
560:    my $useradd = &which('useradd');
562:        &systemcall($useradd, '--extrausers', '-d', $home_dir, '-g', $ingroup_name, '-s',

==============================================================
1. Create a user with BARE useradd (the low-level way)
==============================================================
exit=0

--- /etc/passwd entry: ---
test-useradd:x:1000:1000::/home/test-useradd:/bin/sh

--- does a home directory exist? ---
ls: cannot access '/home/test-useradd': No such file or directory
>>> NO HOME DIRECTORY was created

--- password status (passwd -S): ---
test-useradd L 09/17/2026 0 99999 7 -1
    L = LOCKED. The account cannot log in until you set a password.

==============================================================
2. Create a user with adduser (the recommended way on Ubuntu/Debian)
==============================================================
Adding user `test-adduser' ...
Adding new group `test-adduser' (1001) ...
Adding new user `test-adduser' (1001) with group `test-adduser' ...
Creating home directory `/home/test-adduser' ...
Copying files from `/etc/skel' ...
exit=0

==============================================================
3. Compare the two results side by side
==============================================================
--- /etc/passwd ---
test-useradd:x:1000:1000::/home/test-useradd:/bin/sh
test-adduser:x:1001:1001:,,,:/home/test-adduser:/bin/bash

field order: name:x:UID:GID:GECOS:home:shell

--- home directories ---
ls: cannot access '/home/test-useradd': No such file or directory
drwxr-x--- 2 test-adduser test-adduser 4096 Sep 17 19:20 /home/test-adduser

--- contents of the adduser home (copied from /etc/skel) ---
total 20
drwxr-x--- 2 test-adduser test-adduser 4096 Sep 17 19:20 .
drwxr-xr-x 1 root         root         4096 Sep 17 19:20 ..
-rw-r--r-- 1 test-adduser test-adduser  220 Sep 17 19:20 .bash_logout
-rw-r--r-- 1 test-adduser test-adduser 3771 Sep 17 19:20 .bashrc
-rw-r--r-- 1 test-adduser test-adduser  807 Sep 17 19:20 .profile

--- /etc/skel (the template adduser copies) ---
total 24
drwxr-xr-x 2 root root 4096 Sep  1 20:42 .
drwxr-xr-x 1 root root 4096 Sep 17 19:20 ..
-rw-r--r-- 1 root root  220 Jan  6  2022 .bash_logout
-rw-r--r-- 1 root root 3771 Jan  6  2022 .bashrc
-rw-r--r-- 1 root root  807 Jan  6  2022 .profile

--- per-user group created? ---
test-useradd:x:1000:
test-adduser:x:1001:

--- id ---
uid=1000(test-useradd) gid=1000(test-useradd) groups=1000(test-useradd)
uid=1001(test-adduser) gid=1001(test-adduser) groups=1001(test-adduser)

==============================================================
4. Making useradd behave like adduser requires explicit flags
==============================================================
devops-test:x:1002:1002:DevOps Test User:/home/devops-test:/bin/bash
drwxr-x--- 2 devops-test devops-test 4096 Sep 17 19:20 /home/devops-test

  -m  create the home directory and copy /etc/skel into it
  -s  set the login shell (default from /etc/default/useradd is /bin/sh)
  -c  GECOS / comment field (full name)

--- the defaults useradd uses when you give it nothing: ---
GROUP=100
HOME=/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/sh
SKEL=/etc/skel
CREATE_MAIL_SPOOL=no

==============================================================
5. THE ANSWER: create the test user the recommended way
==============================================================
On Ubuntu the recommended command is 'adduser'.
Already created above as 'test-adduser'. Full record:

test-adduser:x:1001:1001:,,,:/home/test-adduser:/bin/bash

test-adduser L 09/17/2026 0 99999 7 -1
    P = password set / usable account   L = locked   NP = no password

Setting a password non-interactively for the demo:
password set
test-adduser P 09/17/2026 0 99999 7 -1

==============================================================
6. Deleting users
==============================================================
userdel                -> removes the account, LEAVES the home directory
userdel -r             -> removes the account AND home directory + mail spool
deluser --remove-home  -> the adduser-family equivalent (needs the 'perl' package)

userdel -r test-useradd            -> exit 0
deluser --remove-home test-adduser -> exit 0
userdel -r devops-test             -> exit 0

--- confirm all three are gone: ---
  none left in /etc/passwd
  ls: cannot access '/home/test-useradd': No such file or directory
  ls: cannot access '/home/test-adduser': No such file or directory
  ls: cannot access '/home/devops-test': No such file or directory

==============================================================
7. TASK DELIVERABLE: create the test user with the recommended command
==============================================================
Adding user `devops-test' ...
Adding new group `devops-test' (1000) ...
Adding new user `devops-test' (1000) with group `devops-test' ...
Creating home directory `/home/devops-test' ...
Copying files from `/etc/skel' ...

--- the created account: ---
devops-test:x:1000:1000:,,,:/home/devops-test:/bin/bash
devops-test:x:1000:
total 20
drwxr-x--- 2 devops-test devops-test 4096 Sep 17 19:20 .
drwxr-xr-x 1 root        root        4096 Sep 17 19:20 ..
-rw-r--r-- 1 devops-test devops-test  220 Sep 17 19:20 .bash_logout
-rw-r--r-- 1 devops-test devops-test 3771 Sep 17 19:20 .bashrc
-rw-r--r-- 1 devops-test devops-test  807 Sep 17 19:20 .profile
devops-test L 09/17/2026 0 99999 7 -1

This user is left on the system as the deliverable for Task 2.
Remove it later with:  deluser --remove-home devops-test

==============================================================
DONE
==============================================================
```
