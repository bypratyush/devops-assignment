#!/usr/bin/env bash
# Task 2 - adduser vs useradd on Ubuntu.
# Run inside the Linux lab:  ./lab/lab.sh exec /work/linux-fundamentals/task-02-adduser-vs-useradd/practice.sh
set -u

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

# clean slate in case the script is re-run
for u in test-useradd test-adduser devops-test; do
  userdel -r "$u" 2>/dev/null
done

hr "0. Both commands exist - but they are NOT the same kind of program"
echo "which useradd -> $(which useradd)"
echo "which adduser -> $(which adduser)"
echo
file /usr/sbin/useradd /usr/sbin/adduser
echo
echo "useradd = low-level BINARY from the 'passwd' package (part of shadow-utils)."
echo "adduser = high-level PERL SCRIPT from the 'adduser' package that CALLS useradd."
echo
echo "--- proof that adduser calls useradd internally: ---"
grep -n "useradd" /usr/sbin/adduser | head -5

hr "1. Create a user with BARE useradd (the low-level way)"
useradd test-useradd
echo "exit=$?"
echo
echo "--- /etc/passwd entry: ---"
grep '^test-useradd:' /etc/passwd
echo
echo "--- does a home directory exist? ---"
ls -ld /home/test-useradd 2>&1 || echo ">>> NO HOME DIRECTORY was created"
echo
echo "--- password status (passwd -S): ---"
passwd -S test-useradd
echo "    L = LOCKED. The account cannot log in until you set a password."

hr "2. Create a user with adduser (the recommended way on Ubuntu/Debian)"
# --disabled-password + --gecos '' make it non-interactive for this demo.
# Run plain 'adduser devops-test' by hand and it will PROMPT for all of this.
adduser --disabled-password --gecos "" test-adduser
echo "exit=$?"

hr "3. Compare the two results side by side"
echo "--- /etc/passwd ---"
grep -E '^(test-useradd|test-adduser):' /etc/passwd
echo
echo "field order: name:x:UID:GID:GECOS:home:shell"
echo
echo "--- home directories ---"
ls -ld /home/test-useradd /home/test-adduser 2>&1
echo
echo "--- contents of the adduser home (copied from /etc/skel) ---"
ls -la /home/test-adduser
echo
echo "--- /etc/skel (the template adduser copies) ---"
ls -la /etc/skel
echo
echo "--- per-user group created? ---"
grep -E '^(test-useradd|test-adduser):' /etc/group
echo
echo "--- id ---"
id test-useradd
id test-adduser

hr "4. Making useradd behave like adduser requires explicit flags"
useradd -m -s /bin/bash -c "DevOps Test User" devops-test
grep '^devops-test:' /etc/passwd
ls -ld /home/devops-test
echo
echo "  -m  create the home directory and copy /etc/skel into it"
echo "  -s  set the login shell (default from /etc/default/useradd is /bin/sh)"
echo "  -c  GECOS / comment field (full name)"
echo
echo "--- the defaults useradd uses when you give it nothing: ---"
useradd -D

hr "5. THE ANSWER: create the test user the recommended way"
echo "On Ubuntu the recommended command is 'adduser'."
echo "Already created above as 'test-adduser'. Full record:"
echo
getent passwd test-adduser
echo
passwd -S test-adduser
echo "    P = password set / usable account   L = locked   NP = no password"
echo
echo "Setting a password non-interactively for the demo:"
echo "test-adduser:SuperSecret123" | chpasswd && echo "password set"
passwd -S test-adduser

hr "6. Deleting users"
echo "userdel                -> removes the account, LEAVES the home directory"
echo "userdel -r             -> removes the account AND home directory + mail spool"
echo "deluser --remove-home  -> the adduser-family equivalent (needs the 'perl' package)"
echo
userdel -r test-useradd 2>/dev/null; echo "userdel -r test-useradd            -> exit $?"
deluser --remove-home test-adduser >/dev/null 2>&1; echo "deluser --remove-home test-adduser -> exit $?"
userdel -r devops-test 2>/dev/null; echo "userdel -r devops-test             -> exit $?"
echo
echo "--- confirm all three are gone: ---"
grep -E '^(test-useradd|test-adduser|devops-test):' /etc/passwd || echo "  none left in /etc/passwd"
ls -ld /home/test-useradd /home/test-adduser /home/devops-test 2>&1 | sed 's/^/  /'

hr "7. TASK DELIVERABLE: create the test user with the recommended command"
adduser --disabled-password --gecos "" devops-test
echo
echo "--- the created account: ---"
getent passwd devops-test
getent group devops-test
ls -la /home/devops-test
passwd -S devops-test
echo
echo "This user is left on the system as the deliverable for Task 2."
echo "Remove it later with:  deluser --remove-home devops-test"

hr "DONE"
