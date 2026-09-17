#!/usr/bin/env bash
# fundamentals.sh - the shell scripting building blocks, each one demonstrated.
set -u
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }

hr "1. VARIABLES AND QUOTING"
name="Pratyush"
count=5
echo "  plain          : \$name        -> $name"
echo "  braces         : \${name}_id   -> ${name}_id     (needed when text follows)"
echo "  command subst  : \$(date +%Y)  -> $(date +%Y)"
echo "  arithmetic     : \$((count*2)) -> $((count * 2))"
echo
single='no $name expansion here'
double="yes $name expansion here"
echo "  single quotes  : $single"
echo "  double quotes  : $double"
echo
echo "  ALWAYS quote variables. Unquoted \$var splits on spaces and globs:"
path="/tmp/my file.txt"
echo "    unquoted -> $(printf '%s\n' $path | wc -l | tr -d ' ') arguments (WRONG)"
echo "    quoted   -> $(printf '%s\n' "$path" | wc -l | tr -d ' ') argument  (right)"

hr "2. DEFAULTS AND PARAMETER EXPANSION"
unset maybe
echo "  \${maybe:-fallback}  -> ${maybe:-fallback}   (use fallback if unset)"
echo "  \${name:?required}   -> ${name:?required}    (error if unset)"
file="/var/log/syslog.1"
echo "  \${file##*/}         -> ${file##*/}          (basename)"
echo "  \${file%/*}          -> ${file%/*}           (dirname)"
echo "  \${file%.*}          -> ${file%.*}           (strip extension)"
echo "  \${#name}            -> ${#name}             (length)"

hr "3. CONDITIONALS"
num=42
if [ "$num" -gt 100 ]; then
  echo "  $num is greater than 100"
elif [ "$num" -gt 10 ]; then
  echo "  $num is between 11 and 100"
else
  echo "  $num is 10 or less"
fi
echo
echo "  numeric : -eq -ne -lt -le -gt -ge"
echo "  string  : =  !=  -z (empty)  -n (non-empty)"
echo "  files   : -f (file)  -d (dir)  -e (exists)  -r -w -x  -s (non-empty)"
echo
[ -f "$0" ]        && echo "  -f \"\$0\"           : this script is a file"
[ -d /etc ]        && echo "  -d /etc           : /etc is a directory"
[ ! -e /nope ]     && echo "  ! -e /nope        : /nope does not exist"
[ -z "${empty:-}" ] && echo "  -z \"\$empty\"       : empty variable detected"
echo
case "$(uname -s)" in
  Linux)  echo "  case: running on Linux" ;;
  Darwin) echo "  case: running on macOS" ;;
  *)      echo "  case: some other OS" ;;
esac

hr "4. LOOPS"
echo "  for over a list:"
for svc in nginx sshd cron; do printf "    service: %s\n" "$svc"; done
echo
echo "  for over a range:"
for i in $(seq 1 3); do printf "    i=%s squared=%s\n" "$i" "$((i * i))"; done
echo
echo "  while reading a file line by line (the correct idiom):"
printf 'alpha,1\nbeta,2\ngamma,3\n' > /tmp/loopdemo.csv
while IFS=, read -r word number; do
  printf "    word=%-6s number=%s\n" "$word" "$number"
done < /tmp/loopdemo.csv
rm -f /tmp/loopdemo.csv
echo
echo "  until:"
n=1
until [ "$n" -gt 3 ]; do printf "    n=%s\n" "$n"; n=$((n + 1)); done
echo
echo "  break exits the loop, continue skips to the next iteration."

hr "5. FUNCTIONS"
# functions return an EXIT STATUS (0 = success), not a value.
# To return data, echo it and capture with $( ).
greet() {
  local who="${1:-world}"     # 'local' keeps it out of the global scope
  echo "hello, $who"
}
is_even() {
  [ $(( $1 % 2 )) -eq 0 ]     # the test's exit status becomes the return value
}
echo "  greet Pratyush -> $(greet Pratyush)"
echo "  greet          -> $(greet)"
echo
for n in 4 7; do
  if is_even "$n"; then echo "  $n is even"; else echo "  $n is odd"; fi
done
echo
echo "  A function returns an EXIT STATUS, not a value."
echo "  To return data: echo it, and capture it with \$(func)."

hr "6. ARGUMENTS AND EXIT CODES"
echo "  \$0  script name   -> $0"
echo "  \$#  arg count     -> $#"
echo "  \$@  all args      -> ${*:-<none>}"
echo "  \$?  last status   -> (below)"
echo
true;  echo "  after 'true'  -> \$? = $?"
false || echo "  after 'false' -> \$? = 1 (caught with ||)"
echo
echo "  exit 0 = success, anything else = failure. Always exit non-zero on error,"
echo "  or the caller (make, CI, systemd) will think the script succeeded."

hr "7. ERROR HANDLING - the header every script should start with"
cat <<'EXPLAIN'
    set -euo pipefail

      -e           exit immediately if any command fails
      -u           error on use of an undefined variable (catches typos)
      -o pipefail  a pipeline fails if ANY stage fails, not just the last

    Without pipefail:  false | true   -> exit 0  (the failure is hidden)
    With pipefail:     false | true   -> exit 1

    trap 'echo "failed at line $LINENO"' ERR      # report where it broke
    trap 'rm -f "$tmpfile"' EXIT                  # always clean up
EXPLAIN
echo "  demonstrating pipefail:"
( set +o pipefail; false | true; echo "    without pipefail -> exit $?" )
( set -o pipefail; false | true; echo "    with pipefail    -> exit $?" )
echo
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT
echo "  created temp file $tmpfile - the EXIT trap will remove it automatically"

hr "8. A USEFUL PATTERN: argument parsing"
cat <<'EXPLAIN'
    while [ $# -gt 0 ]; do
      case "$1" in
        -v|--verbose) VERBOSE=1; shift ;;
        -f|--file)    FILE="$2"; shift 2 ;;
        -h|--help)    usage; exit 0 ;;
        *)            echo "unknown option: $1" >&2; exit 1 ;;
      esac
    done
EXPLAIN

hr "DONE"
