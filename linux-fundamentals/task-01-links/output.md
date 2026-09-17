# task-01-links - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./lab/lab.sh exec /work/linux-fundamentals/task-01-links/practice.sh` on 2026-09-18.

```text

==============================================================
0. Create the original file
==============================================================
3826902 -rw-r--r-- 1 root root 29 Sep 17 19:20 original.txt

==============================================================
1. Create a HARD link  ->  ln <target> <linkname>
==============================================================
created hardlink.txt

==============================================================
2. Create a SOFT (symbolic) link  ->  ln -s <target> <linkname>
==============================================================
created softlink.txt

==============================================================
3. Compare them: inode number (col 1) and link count (col 3)
==============================================================
3826902 -rw-r--r-- 2 root root 29 Sep 17 19:20 hardlink.txt
3826902 -rw-r--r-- 2 root root 29 Sep 17 19:20 original.txt
3826903 lrwxrwxrwx 1 root root 12 Sep 17 19:20 softlink.txt -> original.txt

NOTE: original.txt and hardlink.txt share the SAME inode and both show link count 2.
      softlink.txt has its OWN inode, link count 1, and is type 'l' (lrwxrwxrwx).

==============================================================
4. stat confirms the same thing
==============================================================
name=original.txt  inode=3826902  links=2  type=regular file  size=29
name=hardlink.txt  inode=3826902  links=2  type=regular file  size=29
name=softlink.txt  inode=3826903  links=1  type=symbolic link  size=12

==============================================================
5. All three read the same content right now
==============================================================
original.txt   -> hello from the original file
hardlink.txt   -> hello from the original file
softlink.txt   -> hello from the original file

==============================================================
6. Writing through one hard link changes the shared data
==============================================================
--- original.txt now contains: ---
hello from the original file
second line added via hardlink

==============================================================
7. THE KEY TEST: delete the original file
==============================================================
total 4
3826902 -rw-r--r-- 1 root root 60 Sep 17 19:20 hardlink.txt
3826903 lrwxrwxrwx 1 root root 12 Sep 17 19:20 softlink.txt -> original.txt

--- hardlink.txt (still works, link count dropped 2 -> 1): ---
hello from the original file
second line added via hardlink

--- softlink.txt (now a DANGLING/broken link): ---
cat: softlink.txt: No such file or directory
test -e softlink.txt  -> exit 1   (1 = target missing)
test -L softlink.txt  -> exit 0   (0 = the link itself exists)

==============================================================
8. Symlinks can point at directories; hard links cannot
==============================================================
lrwxrwxrwx 1 root root    7 Sep 17 19:20 dirlink -> realdir
drwxr-xr-x 2 root root 4096 Sep 17 19:20 realdir

--- attempting a hard link to a directory: ---
ln: realdir: hard link not allowed for directory

==============================================================
9. Symlinks can cross filesystems; hard links cannot
==============================================================
soft link across filesystems: OK
ln: failed to create hard link 'xfs-hard.txt' => '/dev/shm/other-fs.txt': Invalid cross-device link

==============================================================
10. readlink / realpath resolve a symlink's target
==============================================================
hardlink.txt
/root/link-lab/hardlink.txt

==============================================================
11. DELETING links - always use rm, never rm -r on a dir symlink
==============================================================
dirlink
good-soft.txt
hardlink.txt
realdir
softlink.txt
xfs-soft.txt
--- after deleting the links: ---
total 4
drwxr-xr-x 2 root root 4096 Sep 17 19:20 realdir

Deleting a symlink removes only the pointer.
Deleting a hard link only decrements the link count; data dies at count 0.

==============================================================
DONE
==============================================================
```
