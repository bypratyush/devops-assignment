#!/usr/bin/env bash
# Task 1 - Soft links vs hard links, demonstrated end to end.
# Run inside the Linux lab:  ./lab/lab.sh exec /work/linux-fundamentals/task-01-links/practice.sh
set -u

LAB=/root/link-lab
rm -rf "$LAB"; mkdir -p "$LAB"; cd "$LAB"

hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

hr "0. Create the original file"
echo "hello from the original file" > original.txt
ls -li original.txt

hr "1. Create a HARD link  ->  ln <target> <linkname>"
ln original.txt hardlink.txt
echo "created hardlink.txt"

hr "2. Create a SOFT (symbolic) link  ->  ln -s <target> <linkname>"
ln -s original.txt softlink.txt
echo "created softlink.txt"

hr "3. Compare them: inode number (col 1) and link count (col 3)"
ls -li original.txt hardlink.txt softlink.txt
echo
echo "NOTE: original.txt and hardlink.txt share the SAME inode and both show link count 2."
echo "      softlink.txt has its OWN inode, link count 1, and is type 'l' (lrwxrwxrwx)."

hr "4. stat confirms the same thing"
stat -c 'name=%n  inode=%i  links=%h  type=%F  size=%s' original.txt hardlink.txt softlink.txt

hr "5. All three read the same content right now"
for f in original.txt hardlink.txt softlink.txt; do printf '%-14s -> %s\n' "$f" "$(cat $f)"; done

hr "6. Writing through one hard link changes the shared data"
echo "second line added via hardlink" >> hardlink.txt
echo "--- original.txt now contains: ---"; cat original.txt

hr "7. THE KEY TEST: delete the original file"
rm original.txt
ls -li
echo
echo "--- hardlink.txt (still works, link count dropped 2 -> 1): ---"
cat hardlink.txt
echo
echo "--- softlink.txt (now a DANGLING/broken link): ---"
cat softlink.txt 2>&1 || true
echo "test -e softlink.txt  -> exit $( test -e softlink.txt; echo $? )   (1 = target missing)"
echo "test -L softlink.txt  -> exit $( test -L softlink.txt; echo $? )   (0 = the link itself exists)"

hr "8. Symlinks can point at directories; hard links cannot"
mkdir realdir
ln -s realdir dirlink
ls -ld realdir dirlink
echo
echo "--- attempting a hard link to a directory: ---"
ln realdir dirhard 2>&1 || true

hr "9. Symlinks can cross filesystems; hard links cannot"
echo "target on tmpfs" > /dev/shm/other-fs.txt
ln -s /dev/shm/other-fs.txt xfs-soft.txt && echo "soft link across filesystems: OK"
ln /dev/shm/other-fs.txt xfs-hard.txt 2>&1 || true

hr "10. readlink / realpath resolve a symlink's target"
ln -s hardlink.txt good-soft.txt
readlink good-soft.txt
realpath good-soft.txt

hr "11. DELETING links - always use rm, never rm -r on a dir symlink"
ls
rm hardlink.txt softlink.txt dirlink xfs-soft.txt good-soft.txt
rm -f /dev/shm/other-fs.txt
echo "--- after deleting the links: ---"
ls -l
echo
echo "Deleting a symlink removes only the pointer."
echo "Deleting a hard link only decrements the link count; data dies at count 0."

hr "DONE"
