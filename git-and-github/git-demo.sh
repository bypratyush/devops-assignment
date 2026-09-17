#!/usr/bin/env bash
# git-demo.sh - Git workflows demonstrated in a disposable sandbox repository.
#
# Everything happens in a temp directory, so this NEVER touches the repo you
# are reading it from.
set -u
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
sub() { echo; echo "--- $* ---"; }
lg()  { git log --oneline --graph --all --decorate | head -"${1:-12}" | sed 's/^/  /'; }

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/git-demo.XXXXXX")
trap 'rm -rf "$SANDBOX"' EXIT
cd "$SANDBOX"

export GIT_AUTHOR_NAME="Pratyush Mohanty"
export GIT_AUTHOR_EMAIL="pratyush@example.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

hr "0. Sandbox"
echo "  working in: $SANDBOX  (deleted automatically on exit)"
git --version | sed 's/^/  /'

hr "1. CREATE A REPOSITORY AND MAKE COMMITS"
git init -q -b main
git config user.name "$GIT_AUTHOR_NAME"
git config user.email "$GIT_AUTHOR_EMAIL"
echo "  git init -b main   (main as the initial branch)"

echo "# Notes App" > README.md
echo "print('v1')" > app.py
sub "git status - untracked files"
git status --short | sed 's/^/  /'

git add README.md app.py
sub "git status - staged (the INDEX)"
git status --short | sed 's/^/  /'
echo "  'A' = added to the index. Staging is a separate step from committing:"
echo "  working tree  ->  git add  ->  index/staging  ->  git commit  ->  history"

git commit -qm "Initial commit: README and app"
echo "print('v2')" > app.py
echo "config = {}" > config.py
git add -A && git commit -qm "Add config, bump app to v2"
echo "MIT" > LICENSE
git add -A && git commit -qm "Add LICENSE"

sub "git log"
lg

hr "2. BRANCHING"
git switch -qc feature/login
echo "def login(): pass" > login.py
git add -A && git commit -qm "Add login module"
echo "def logout(): pass" >> login.py
git add -A && git commit -qm "Add logout"
echo "  created and committed on feature/login"
sub "branches"
git branch -v | sed 's/^/  /'
sub "history - the branch has diverged"
lg

hr "3. FAST-FORWARD MERGE"
git switch -q main
echo "  merging feature/login into main (main has not moved, so it fast-forwards)"
git merge --ff-only feature/login 2>&1 | sed 's/^/  /'
lg 8
echo
echo "  A fast-forward just moves the branch pointer - no merge commit is created,"
echo "  because main had no commits of its own since the branch point."

hr "4. A REAL MERGE CONFLICT, AND RESOLVING IT"
git switch -qc feature/banner
printf 'VERSION = "2.0-banner"\n' > version.py
git add -A && git commit -qm "Set version 2.0-banner"

git switch -q main
printf 'VERSION = "2.0-hotfix"\n' > version.py
git add -A && git commit -qm "Set version 2.0-hotfix"

echo "  Both branches changed version.py differently. Merging now:"
sub "git merge feature/banner"
git merge feature/banner 2>&1 | sed 's/^/  /' || true
echo
sub "the conflicted file as Git leaves it"
cat version.py | sed 's/^/  /'
echo
echo "  <<<<<<< HEAD          your side (main)"
echo "  =======               the divider"
echo "  >>>>>>> branch        their side (feature/banner)"
sub "git status during a conflict"
git status --short | sed 's/^/  /'
echo "  The two-letter code says how the conflict arose:"
echo "    AA = both sides ADDED the same new file   (this case)"
echo "    UU = both sides MODIFIED an existing file (the more common case)"
echo "    DU / UD = one side deleted it, the other modified it"
echo
sub "resolving: edit the file, then git add, then commit"
printf 'VERSION = "2.0"\n' > version.py
git add version.py
git commit -qm "Merge feature/banner: reconcile version to 2.0"
cat version.py | sed 's/^/  /'
lg 8
echo
echo "  Note the merge commit with TWO parents - that is what a real merge looks"
echo "  like. 'git merge --abort' at any point would have thrown it all away."

hr "5. CHERRY-PICK - take ONE commit from another branch"
git switch -qc feature/experimental
echo "def helper(): return 42" > helper.py
git add -A && git commit -qm "Add helper function (WANTED)"
echo "BROKEN = True" > broken.py
git add -A && git commit -qm "Half-finished experiment (NOT wanted)"
WANTED=$(git log --oneline --all --grep="WANTED" --format=%h | head -1)
echo "  feature/experimental has two commits; we want only $WANTED"
git switch -q main
sub "git cherry-pick $WANTED"
git cherry-pick "$WANTED" 2>&1 | sed 's/^/  /'
NEWHASH=$(git rev-parse --short HEAD)
echo
echo "  files on main now:"
ls | sed 's/^/    /'
echo
echo "  helper.py came across; broken.py did NOT."
echo
sub "proof it is a DIFFERENT commit object"
printf "  original on feature/experimental : %s\n" "$WANTED"
printf "  new commit on main               : %s\n" "$NEWHASH"
if [ "$WANTED" = "$NEWHASH" ]; then
  echo "  (identical here only because the tree, message, author and timestamp"
  echo "   all matched - git deduplicated it)"
else
  echo "  Different hashes, same change. A commit hash covers its PARENT too,"
  echo "  so the same diff on a different base is always a different commit."
fi
echo
echo "  Typical use: a hotfix that must also go onto a release branch."

hr "6. UNDOING THINGS - reset vs revert"
sub "git reset --soft HEAD~1   (undo the commit, KEEP changes staged)"
git reset --soft HEAD~1
git status --short | sed 's/^/  /'
echo "  the file is still staged - only the commit was removed"
git commit -qm "Add helper function (re-committed)"

sub "the three resets"
cat <<'RESETS'
    git reset --soft  HEAD~1   undo commit, keep changes STAGED
    git reset --mixed HEAD~1   undo commit, keep changes in WORKING TREE (default)
    git reset --hard  HEAD~1   undo commit AND DISCARD the changes  <-- destructive
RESETS

sub "git revert - the safe undo for shared history"
BAD=$(git rev-parse --short HEAD)
git revert --no-edit "$BAD" 2>&1 | head -2 | sed 's/^/  /'
lg 6
echo
echo "  revert creates a NEW commit that undoes an old one. History is preserved,"
echo "  so it is safe on a branch other people have pulled."
echo
echo "  RULE: reset rewrites history - only on your own unpushed commits."
echo "        revert adds history   - the correct tool for anything already pushed."

hr "7. STASH - park work in progress"
echo "print('half-finished')" >> app.py
sub "dirty working tree"
git status --short | sed 's/^/  /'
git stash push -qm "WIP on app.py"
sub "after git stash - tree is clean"
git status --short | sed 's/^/  /' ; echo "  (clean)"
git stash list | sed 's/^/  /'
sub "git stash pop - bring it back"
git stash pop 2>&1 | tail -3 | sed 's/^/  /'
git checkout -- app.py 2>/dev/null || true

hr "8. TAGS"
git tag -a v1.0.0 -m "First release"
git tag v1.0.1
git tag -n | sed 's/^/  /'
echo
echo "  -a makes an ANNOTATED tag: its own object with author, date and message."
echo "  A bare 'git tag x' is lightweight - just a pointer. Use annotated for releases."
echo "  Tags are NOT pushed by default: git push origin v1.0.0  (or --tags)"

hr "9. .gitignore"
cat > .gitignore <<'IGNORE'
*.log
__pycache__/
.env
node_modules/
IGNORE
touch debug.log .env
mkdir -p __pycache__ && touch __pycache__/app.pyc
sub "git status - the ignored files do not appear"
git status --short | sed 's/^/  /'
echo
echo "  debug.log, .env and __pycache__/ exist on disk but Git ignores them."
echo "  .gitignore only affects UNTRACKED files. A file already committed stays"
echo "  tracked forever until you run: git rm --cached <file>"

hr "10. REMOTES - how local history reaches GitHub"
git init -q --bare "$SANDBOX/origin.git"
git remote add origin "$SANDBOX/origin.git"
git add -A && git commit -qm "Add .gitignore"
sub "git remote -v"
git remote -v | sed 's/^/  /'
sub "git push -u origin main"
git push -u origin main 2>&1 | tail -3 | sed 's/^/  /'
sub "the bare remote now has the history"
git --git-dir="$SANDBOX/origin.git" log --oneline | head -5 | sed 's/^/  /'
echo
cat <<'REMOTES'
    git fetch    download remote commits, do NOT touch your working tree
    git pull     = fetch + merge   (git pull --rebase = fetch + rebase)
    git push     upload your commits
    git clone    copy a repo and set 'origin' automatically

    On GitHub the flow is:
      fork/branch -> commit -> push -> open a Pull Request -> review -> merge
REMOTES

hr "11. INSPECTION"
sub "git log --oneline --graph --all"
lg 10
sub "git show --stat HEAD"
git show --stat HEAD | head -8 | sed 's/^/  /'
sub "git diff HEAD~1 --stat"
git diff HEAD~1 --stat | sed 's/^/  /'
sub "git blame version.py"
git blame version.py 2>/dev/null | sed 's/^/  /'

hr "DONE"
echo "  sandbox $SANDBOX will now be removed."
