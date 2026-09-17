#!/usr/bin/env bash
#
# sysinfo.sh - the session-3 assignment.
#
#   * print the current date
#   * print hostname and username
#   * capture process info into process.log
#   * take name / roll number / comment as input and print them
#   * use variables, create a file and a directory
#
# It prompts when run interactively, and falls back to defaults or arguments
# when run from a script or CI, so it is reproducible either way:
#
#   ./sysinfo.sh                          # prompts (or uses defaults if no TTY)
#   ./sysinfo.sh "Name" "Roll" "Comment"  # non-interactive
#   echo -e "Name\nRoll\nComment" | ./sysinfo.sh
set -euo pipefail

OUTDIR="sysinfo-output"
LOGFILE="$OUTDIR/process.log"
REPORT="$OUTDIR/report.txt"

# ---------------------------------------------------------------- variables --
# $(...) is command substitution: run the command, substitute its output.
current_date=$(date '+%Y-%m-%d %H:%M:%S %Z')
host_name=$(hostname)
user_name=$(whoami)
kernel=$(uname -sr)
uptime_str=$(uptime | sed 's/^ *//')

echo "=============================================="
echo " SYSTEM INFORMATION"
echo "=============================================="
echo "Current date : $current_date"
echo "Hostname     : $host_name"
echo "Username     : $user_name"
echo "Kernel       : $kernel"
echo "Uptime       : $uptime_str"

# -------------------------------------------------------------------- input --
# Precedence: command-line argument > piped stdin > interactive prompt > default.
read_field() {
  local prompt="$1" default="$2" argval="${3:-}"
  if [ -n "$argval" ]; then          # given as an argument
    printf '%s' "$argval"; return
  fi
  if [ -t 0 ]; then                  # a terminal is attached: ask
    local answer
    read -r -p "$prompt" answer
    printf '%s' "${answer:-$default}"
  else                               # piped or no TTY: read a line, else default
    local answer=""
    read -r answer || true
    printf '%s' "${answer:-$default}"
  fi
}

echo
echo "=============================================="
echo " STUDENT DETAILS"
echo "=============================================="
name=$(read_field      "Enter your name: "         "Pratyush Mohanty" "${1:-}")
roll_no=$(read_field   "Enter your roll number: "  "24BCS10238"       "${2:-}")
comment=$(read_field   "Enter your comment: "      "DevOps homework - session 3 shell scripting" "${3:-}")

echo
echo "My name is        : $name"
echo "My roll number is : $roll_no"
echo "My comment is     : $comment"

# --------------------------------------------------- create dir + log + file --
echo
echo "=============================================="
echo " FILES CREATED"
echo "=============================================="

# mkdir -p: create parents as needed, and do not fail if it already exists.
mkdir -p "$OUTDIR"
echo "created directory : $OUTDIR/"

# redirect the process list into a log file
ps -ef > "$LOGFILE" 2>/dev/null || ps aux > "$LOGFILE"
echo "wrote             : $LOGFILE ($(wc -l < "$LOGFILE" | tr -d ' ') lines)"

# a here-document writes a whole block to a file; "$VAR" still expands inside
cat > "$REPORT" <<REPORT_END
DevOps Homework - Session 3 (Shell Scripting)
=============================================
Name        : $name
Roll number : $roll_no
Comment     : $comment

Generated   : $current_date
Host        : $host_name
User        : $user_name
Kernel      : $kernel

Top 5 processes by memory:
$(ps -eo pid,comm,%mem --sort=-%mem 2>/dev/null | head -6 || echo "  (unavailable)")
REPORT_END
echo "wrote             : $REPORT ($(wc -l < "$REPORT" | tr -d ' ') lines)"

echo
echo "--- first 5 lines of $LOGFILE ---"
head -5 "$LOGFILE"

echo
echo "--- $REPORT ---"
cat "$REPORT"

echo
echo "Done."
