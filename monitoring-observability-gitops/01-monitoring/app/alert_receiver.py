"""alert-receiver - stands in for Slack/PagerDuty/email.

Alertmanager POSTs its webhook payload here; we print one line per alert so
`docker compose logs alert-receiver` shows exactly what would have paged someone.
"""
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        for a in body.get("alerts", []):
            print(json.dumps({
                "notification": body.get("status"),          # firing | resolved
                "alertname": a["labels"].get("alertname"),
                "severity": a["labels"].get("severity"),
                "startsAt": a.get("startsAt"),
                "endsAt": a.get("endsAt") if a.get("status") == "resolved" else None,
                "summary": a.get("annotations", {}).get("summary"),
            }), flush=True)
        self.send_response(200)
        self.end_headers()

    def log_message(self, *args):      # keep stdout for the alerts only
        pass


if __name__ == "__main__":
    print("alert-receiver listening on :9000", flush=True)
    sys.stdout.flush()
    HTTPServer(("0.0.0.0", 9000), Handler).serve_forever()
