import json, os, platform, socket
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("PORT", "5000"))
NAME = os.environ.get("APP_NAME", "python-app")

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps({
            "app": NAME,
            "hostname": socket.gethostname(),
            "platform": f"{platform.system()}/{platform.machine()}",
            "python": platform.python_version(),
            "path": self.path,
        }, indent=2).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        print(f"{self.address_string()} - {fmt % args}", flush=True)

print(f"{NAME} listening on :{PORT}", flush=True)
HTTPServer(("", PORT), Handler).serve_forever()
