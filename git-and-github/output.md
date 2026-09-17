# Git and GitHub - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./git-demo.sh` on 2026-09-18.

```text

==============================================================
0. Sandbox
==============================================================
  working in: /var/folders/gk/f_l1kjks5bq7lbb62mnpv16w0000gn/T//git-demo.HMZYRc  (deleted automatically on exit)
  git version 2.39.5 (Apple Git-154)

==============================================================
1. CREATE A REPOSITORY AND MAKE COMMITS
==============================================================
  git init -b main   (main as the initial branch)

--- git status - untracked files ---
  ?? README.md
  ?? app.py

--- git status - staged (the INDEX) ---
  A  README.md
  A  app.py
  'A' = added to the index. Staging is a separate step from committing:
  working tree  ->  git add  ->  index/staging  ->  git commit  ->  history

--- git log ---
  * f88f907 (HEAD -> main) Add LICENSE
  * fc30e61 Add config, bump app to v2
  * 5d1cdac Initial commit: README and app

==============================================================
2. BRANCHING
==============================================================
  created and committed on feature/login

--- branches ---
  * feature/login 02340e5 Add logout
    main          f88f907 Add LICENSE

--- history - the branch has diverged ---
  * 02340e5 (HEAD -> feature/login) Add logout
  * e8551fe Add login module
  * f88f907 (main) Add LICENSE
  * fc30e61 Add config, bump app to v2
  * 5d1cdac Initial commit: README and app

==============================================================
3. FAST-FORWARD MERGE
==============================================================
  merging feature/login into main (main has not moved, so it fast-forwards)
  Updating f88f907..02340e5
  Fast-forward
   login.py | 2 ++
   1 file changed, 2 insertions(+)
   create mode 100644 login.py
  * 02340e5 (HEAD -> main, feature/login) Add logout
  * e8551fe Add login module
  * f88f907 Add LICENSE
  * fc30e61 Add config, bump app to v2
  * 5d1cdac Initial commit: README and app

  A fast-forward just moves the branch pointer - no merge commit is created,
  because main had no commits of its own since the branch point.

==============================================================
4. A REAL MERGE CONFLICT, AND RESOLVING IT
==============================================================
  Both branches changed version.py differently. Merging now:

--- git merge feature/banner ---
  Auto-merging version.py
  CONFLICT (add/add): Merge conflict in version.py
  Automatic merge failed; fix conflicts and then commit the result.


--- the conflicted file as Git leaves it ---
  <<<<<<< HEAD
  VERSION = "2.0-hotfix"
  =======
  VERSION = "2.0-banner"
  >>>>>>> feature/banner

  <<<<<<< HEAD          your side (main)
  =======               the divider
  >>>>>>> branch        their side (feature/banner)

--- git status during a conflict ---
  AA version.py
  The two-letter code says how the conflict arose:
    AA = both sides ADDED the same new file   (this case)
    UU = both sides MODIFIED an existing file (the more common case)
    DU / UD = one side deleted it, the other modified it


--- resolving: edit the file, then git add, then commit ---
  VERSION = "2.0"
  *   4f13d80 (HEAD -> main) Merge feature/banner: reconcile version to 2.0
  |\  
  | * f870730 (feature/banner) Set version 2.0-banner
  * | a48b08a Set version 2.0-hotfix
  |/  
  * 02340e5 (feature/login) Add logout
  * e8551fe Add login module
  * f88f907 Add LICENSE

  Note the merge commit with TWO parents - that is what a real merge looks
  like. 'git merge --abort' at any point would have thrown it all away.

==============================================================
5. CHERRY-PICK - take ONE commit from another branch
==============================================================
  feature/experimental has two commits; we want only 2eed420

--- git cherry-pick 2eed420 ---
  [main 2eed420] Add helper function (WANTED)
   Date: Fri Sep 18 00:50:20 2026 +0530
   1 file changed, 1 insertion(+)
   create mode 100644 helper.py

  files on main now:
    LICENSE
    README.md
    app.py
    config.py
    helper.py
    login.py
    version.py

  helper.py came across; broken.py did NOT.


--- proof it is a DIFFERENT commit object ---
  original on feature/experimental : 2eed420
  new commit on main               : 2eed420
  (identical here only because the tree, message, author and timestamp
   all matched - git deduplicated it)

  Typical use: a hotfix that must also go onto a release branch.

==============================================================
6. UNDOING THINGS - reset vs revert
==============================================================

--- git reset --soft HEAD~1   (undo the commit, KEEP changes staged) ---
  A  helper.py
  the file is still staged - only the commit was removed

--- the three resets ---
    git reset --soft  HEAD~1   undo commit, keep changes STAGED
    git reset --mixed HEAD~1   undo commit, keep changes in WORKING TREE (default)
    git reset --hard  HEAD~1   undo commit AND DISCARD the changes  <-- destructive

--- git revert - the safe undo for shared history ---
  [main fa30f88] Revert "Add helper function (re-committed)"
   Date: Fri Sep 18 00:50:21 2026 +0530
  * fa30f88 (HEAD -> main) Revert "Add helper function (re-committed)"
  * 04d61dd Add helper function (re-committed)
  | * 6da35a0 (feature/experimental) Half-finished experiment (NOT wanted)
  | * 2eed420 Add helper function (WANTED)
  |/  
  *   4f13d80 Merge feature/banner: reconcile version to 2.0

  revert creates a NEW commit that undoes an old one. History is preserved,
  so it is safe on a branch other people have pulled.

  RULE: reset rewrites history - only on your own unpushed commits.
        revert adds history   - the correct tool for anything already pushed.

==============================================================
7. STASH - park work in progress
==============================================================

--- dirty working tree ---
   M app.py

--- after git stash - tree is clean ---
  (clean)
  stash@{0}: On main: WIP on app.py

--- git stash pop - bring it back ---
  
  no changes added to commit (use "git add" and/or "git commit -a")
  Dropped refs/stash@{0} (4d914d8952b01abfad60005a2d528dc419a0669f)

==============================================================
8. TAGS
==============================================================
  v1.0.0          First release
  v1.0.1          Revert "Add helper function (re-committed)"

  -a makes an ANNOTATED tag: its own object with author, date and message.
  A bare 'git tag x' is lightweight - just a pointer. Use annotated for releases.
  Tags are NOT pushed by default: git push origin v1.0.0  (or --tags)

==============================================================
9. .gitignore
==============================================================

--- git status - the ignored files do not appear ---
  ?? .gitignore

  debug.log, .env and __pycache__/ exist on disk but Git ignores them.
  .gitignore only affects UNTRACKED files. A file already committed stays
  tracked forever until you run: git rm --cached <file>

==============================================================
10. REMOTES - how local history reaches GitHub
==============================================================

--- git remote -v ---
  origin	/var/folders/gk/f_l1kjks5bq7lbb62mnpv16w0000gn/T//git-demo.HMZYRc/origin.git (fetch)
  origin	/var/folders/gk/f_l1kjks5bq7lbb62mnpv16w0000gn/T//git-demo.HMZYRc/origin.git (push)

--- git push -u origin main ---
  To /var/folders/gk/f_l1kjks5bq7lbb62mnpv16w0000gn/T//git-demo.HMZYRc/origin.git
   * [new branch]      main -> main
  branch 'main' set up to track 'origin/main'.

--- the bare remote now has the history ---
  3d54bbb Add .gitignore
  fa30f88 Revert "Add helper function (re-committed)"
  04d61dd Add helper function (re-committed)
  4f13d80 Merge feature/banner: reconcile version to 2.0
  a48b08a Set version 2.0-hotfix

    git fetch    download remote commits, do NOT touch your working tree
    git pull     = fetch + merge   (git pull --rebase = fetch + rebase)
    git push     upload your commits
    git clone    copy a repo and set 'origin' automatically

    On GitHub the flow is:
      fork/branch -> commit -> push -> open a Pull Request -> review -> merge

==============================================================
11. INSPECTION
==============================================================

--- git log --oneline --graph --all ---
  * 3d54bbb (HEAD -> main, origin/main) Add .gitignore
  * fa30f88 (tag: v1.0.1, tag: v1.0.0) Revert "Add helper function (re-committed)"
  * 04d61dd Add helper function (re-committed)
  | * 6da35a0 (feature/experimental) Half-finished experiment (NOT wanted)
  | * 2eed420 Add helper function (WANTED)
  |/  
  *   4f13d80 Merge feature/banner: reconcile version to 2.0
  |\  
  | * f870730 (feature/banner) Set version 2.0-banner
  * | a48b08a Set version 2.0-hotfix

--- git show --stat HEAD ---
  commit 3d54bbb3ab3ca2e1e3765c9e9c4eaf6e2f76fac2
  Author: Pratyush Mohanty <pratyush@example.com>
  Date:   Fri Sep 18 00:50:21 2026 +0530
  
      Add .gitignore
  
   .gitignore                                 |   4 +
   origin.git/HEAD                            |   1 +

--- git diff HEAD~1 --stat ---
   .gitignore                                 |   4 +
   origin.git/HEAD                            |   1 +
   origin.git/config                          |   6 +
   origin.git/description                     |   1 +
   origin.git/hooks/applypatch-msg.sample     |  15 +++
   origin.git/hooks/commit-msg.sample         |  24 ++++
   origin.git/hooks/fsmonitor-watchman.sample | 174 +++++++++++++++++++++++++++++
   origin.git/hooks/post-update.sample        |   8 ++
   origin.git/hooks/pre-applypatch.sample     |  14 +++
   origin.git/hooks/pre-commit.sample         |  49 ++++++++
   origin.git/hooks/pre-merge-commit.sample   |  13 +++
   origin.git/hooks/pre-push.sample           |  53 +++++++++
   origin.git/hooks/pre-rebase.sample         | 169 ++++++++++++++++++++++++++++
   origin.git/hooks/pre-receive.sample        |  24 ++++
   origin.git/hooks/prepare-commit-msg.sample |  42 +++++++
   origin.git/hooks/push-to-checkout.sample   |  78 +++++++++++++
   origin.git/hooks/sendemail-validate.sample |  77 +++++++++++++
   origin.git/hooks/update.sample             | 128 +++++++++++++++++++++
   origin.git/info/exclude                    |   6 +
   19 files changed, 886 insertions(+)

--- git blame version.py ---
  4f13d80c (Pratyush Mohanty 2026-09-18 00:50:20 +0530 1) VERSION = "2.0"

==============================================================
DONE
==============================================================
  sandbox /var/folders/gk/f_l1kjks5bq7lbb62mnpv16w0000gn/T//git-demo.HMZYRc will now be removed.
```
