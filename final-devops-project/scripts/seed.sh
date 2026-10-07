#!/usr/bin/env bash
# seed.sh [BASE_URL] - report a few realistic items through the public API.
#   ./scripts/seed.sh http://localhost:3000            (compose)
#   ./scripts/seed.sh http://lostfound.local           (ingress, with /etc/hosts entry)
set -euo pipefail
BASE="${1:-http://localhost:3000}"
H=(-H 'content-type: application/json')
[ -n "${HOST_HEADER:-}" ] && H+=(-H "Host: $HOST_HEADER")

post() {
  curl -sf "${H[@]}" -X POST "$BASE/api/items" -d "$1" |
    python3 -c 'import json,sys; i=json.load(sys.stdin); print("  #%-3s %-5s %s" % (i["id"], i["kind"], i["title"]))'
}

echo "seeding $BASE"
post '{"kind":"lost","title":"Black leather wallet","description":"Library card inside, initials P.M.","category":"other","location":"Central Library, 2nd floor","contact":"pratyush@campus.test"}'
post '{"kind":"found","title":"Casio fx-991EX calculator","category":"electronics","location":"Exam Hall B","contact":"helpdesk@campus.test"}'
post '{"kind":"found","title":"Hostel room key (tag 214)","category":"keys","location":"Mess counter","contact":"helpdesk@campus.test"}'
post '{"kind":"lost","title":"Blue Milton water bottle","category":"bottle","location":"Basketball court","contact":"+91 90000 11111"}'
post '{"kind":"lost","title":"Student ID card","description":"Roll 24BCS10238","category":"id-card","location":"Auditorium","contact":"pratyush@campus.test"}'
post '{"kind":"found","title":"Grey hoodie with college logo","category":"clothing","location":"CS lab 3","contact":"helpdesk@campus.test"}'
# one claimed, one closed, so every status shows up
curl -sf "${H[@]}" -X PUT "$BASE/api/items/3" -d '{"status":"claimed"}' >/dev/null
curl -sf "${H[@]}" -X PUT "$BASE/api/items/4" -d '{"status":"closed"}'  >/dev/null
echo "stats: $(curl -sf "${H[@]}" "$BASE/api/stats")"
