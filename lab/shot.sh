#!/usr/bin/env bash
# shot.sh - capture a real terminal screenshot of a command and its output.
#
# Uses termshot (brew install termshot), which runs the command in a pseudo
# terminal and renders the ACTUAL output into a terminal-window PNG. These are
# genuine captures of commands that really ran, not mock-ups.
#
# termshot needs a TTY to size its pty, so it is run under script(1), which
# provides one even from a non-interactive shell.
#
#   ./lab/shot.sh <out.png> <command...>
#   WIDTH=160 ./lab/shot.sh shots/pods.png kubectl get pods -o wide
set -euo pipefail

OUT="$1"; shift
WIDTH="${WIDTH:-150}"
mkdir -p "$(dirname "$OUT")"

script -q /dev/null termshot --show-cmd --columns "$WIDTH" --filename "$OUT" -- "$@" >/dev/null 2>&1

if [ -f "$OUT" ]; then
  echo "  $(basename "$OUT")  ($(du -h "$OUT" | cut -f1 | tr -d ' '))"
else
  echo "  FAILED: $OUT" >&2
  exit 1
fi
