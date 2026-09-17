# Task 1 - Soft Links vs Hard Links

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Run it: `./lab/lab.sh up && ./lab/lab.sh exec /work/linux-fundamentals/task-01-links/practice.sh`
Verified output: [output.md](output.md)

---

## 1. The one idea you need first: filename ≠ file

On Linux a file is really two separate things:

| Thing | What it holds |
|---|---|
| **inode** | The actual metadata + pointers to the data blocks. Has a number, no name. |
| **directory entry** | A *name* that points at an inode number. |

A directory is just a table of `name -> inode number`. The filename is not the file.
The inode is the file. This single fact explains every difference below.

```text
        directory entry              inode 4206376            data blocks
      +------------------+        +------------------+      +---------------+
      | "original.txt"   | -----> | links: 2         | ---> | hello from... |
      +------------------+   ,--> | uid/gid, perms   |      +---------------+
      | "hardlink.txt"   | --'    | size, timestamps |
      +------------------+        +------------------+
```

---

## 2. Hard link

A **second name for the same inode**. Both names are equal - there is no
"original" and "copy" once it exists. The inode keeps a **link count**; the data
is only freed when that count reaches 0.

```bash
ln  original.txt  hardlink.txt      # ln <target> <linkname>
```

From the real run:

```text
4206376 -rw-r--r-- 2 root root 29 original.txt     <-- same inode, link count 2
4206376 -rw-r--r-- 2 root root 29 hardlink.txt     <-- same inode, link count 2
```

Delete `original.txt` and the data survives, because `hardlink.txt` still
references inode 4206376. The count just drops 2 -> 1.

## 3. Soft link (symbolic link / symlink)

A **separate, tiny file of its own** whose entire content is a *path string*.
It points at a **name**, not at an inode. Resolving it is an extra lookup.

```bash
ln -s  original.txt  softlink.txt   # ln -s <target> <linkname>
```

```text
4206377 lrwxrwxrwx 1 root root 12 softlink.txt -> original.txt
        ^type 'l'              ^size 12 = length of the string "original.txt"
```

Delete `original.txt` and the symlink becomes a **dangling/broken link** - it
still exists, but points at nothing:

```text
$ cat softlink.txt
cat: softlink.txt: No such file or directory
test -e softlink.txt  -> exit 1   (target missing)
test -L softlink.txt  -> exit 0   (the link itself is still there)
```

---

## 4. The comparison table (this is the interview answer)

| | **Hard link** | **Soft link** |
|---|---|---|
| Command | `ln target link` | `ln -s target link` |
| What it points to | The **inode** | A **pathname** (string) |
| Own inode? | No - shares the target's | Yes, its own separate inode |
| Shown by `ls -l` | `-rw-r--r--` (indistinguishable from a normal file) | `lrwxrwxrwx ... -> target` |
| Link count of target | Increases | Unchanged |
| Survives deleting the original? | **Yes**, data lives until count = 0 | **No**, becomes dangling |
| Across filesystems? | **No** - `Invalid cross-device link` | **Yes** |
| Point to a directory? | **No** - `hard link not allowed for directory` | **Yes** |
| Size | Same as the file | Length of the target path string |
| Permissions | The target's | Always `lrwxrwxrwx`; the target's perms are what get enforced |
| Relative paths | N/A | Can be relative -> breaks if you move the link |

Both failure messages above are real output from `practice.sh` steps 8 and 9.

---

## 5. Why the two restrictions exist

**No hard links across filesystems.** Inode numbers are only unique *within* one
filesystem. Inode 4206376 on `/` and on `/dev/shm` are unrelated files. A
directory entry stores only a number, so it cannot reference another filesystem.
A symlink stores a *path*, and paths are global - so it works fine.

**No hard links to directories.** You could create a loop (`a/b/c -> a`) that
makes the directory tree a cyclic graph. `find`, `rm -r` and backup tools walk
that tree assuming it is acyclic; a cycle means infinite recursion, and
unlinking could orphan whole subtrees with no way to reach them. `.` and `..`
are the only exceptions, created and managed by the kernel itself.

---

## 6. Commands to remember

```bash
ln   target link            # hard link
ln -s target link           # soft link
ln -sf target link          # force: replace an existing link
ls -li                      # -i shows the INODE number (column 1)
ls -l                       # column 3 is the LINK COUNT
stat file                   # inode, links, type, size in full
readlink link               # print the target string
readlink -f link            # fully resolve, following every hop
realpath link               # canonical absolute path
find . -type l              # find all symlinks
find . -xtype l             # find BROKEN symlinks
find . -samefile f          # find all hard links to f
find . -inum 4206376        # find every name for that inode
rm link                     # delete either kind of link
```

### Deleting links - the two traps

```bash
rm softlink.txt      # correct: removes the pointer, target untouched
rm dirlink/          # TRAP: trailing slash makes rm follow into the directory
rm -rf dirlink/      # TRAP: can delete the CONTENTS of the target directory
```
Never put a trailing slash on a symlink you are deleting. `rm dirlink` is right.

For hard links, `rm` just decrements the count. The data is only gone when the
last name is removed **and** no process still holds the file open.

---

## 7. Where each is actually used

**Symlinks** - almost everything you meet day to day:
- `/usr/bin/python3 -> python3.10`, and the whole `update-alternatives` system
- `/etc/systemd/system/multi-user.target.wants/nginx.service -> /lib/systemd/system/nginx.service` - this is literally what `systemctl enable` creates
- `/var/log/journal`-style relocations, Nginx `sites-enabled -> sites-available`
- Release directories: `current -> releases/2026-09-17`, so a deploy is one atomic `ln -sf`

**Hard links** - where you need the same data under two names with zero cost:
- Backup tools (`rsync --link-dest`, Time Machine): unchanged files are hard
  linked to the previous snapshot, so 10 snapshots cost ~1 copy of the data
- Package managers / build caches deduplicating identical files
- `/usr/bin/gzip`, `gunzip`, `zcat` historically being one binary under several names

---

## 8. Interview Q&A

**Q: Difference between a hard link and a soft link?**
A hard link is an additional directory entry pointing to the *same inode*, so
it's indistinguishable from the original and the data survives until every link
is removed. A soft link is a separate file containing the *path* of its target,
so it breaks if the target is deleted or renamed. Hard links can't cross
filesystems or point to directories; soft links can do both.

**Q: What happens to each if I delete the original file?**
The hard link keeps working - the inode's link count just drops by one. The soft
link becomes a dangling link and any read fails with `No such file or directory`.

**Q: Why can't you hard link a directory?**
It would allow cycles in the directory tree, breaking every tool that assumes
the tree is acyclic, and could orphan subtrees. Only the kernel makes the
`.`/`..` exceptions.

**Q: Why can't a hard link cross filesystems?**
A directory entry stores an inode number, and inode numbers are only unique
within a single filesystem. A symlink stores a path, which is globally
meaningful, so it can.

**Q: How do you tell them apart?**
`ls -l` - a symlink starts with `l` and shows `-> target`. A hard link looks
exactly like a regular file; use `ls -li` and compare inode numbers, or look at
the link count in column 3 (greater than 1 means other hard links exist).

**Q: How do you find all the hard links to a file?**
`find /mountpoint -samefile file` or `find /mountpoint -inum <inode>`.

**Q: What is a dangling symlink?**
One whose target no longer exists. `test -L` still succeeds (the link is there)
but `test -e` fails (the target isn't). Find them with `find . -xtype l`.

**Q: Does a symlink's permissions matter?**
No. `lrwxrwxrwx` is cosmetic - access is decided by the *target's* permissions.

**Q: What does the size of a symlink mean?**
The number of characters in the target path. `-> original.txt` is 12 bytes.
