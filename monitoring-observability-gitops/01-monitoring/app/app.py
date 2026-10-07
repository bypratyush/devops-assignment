"""orders-api - a deliberately small service that is easy to watch.

It exposes:
  /api/orders        fake business endpoint (random latency, configurable error rate)
  /health            health check (503 when the app holds too much memory)
  /metrics           Prometheus metrics (request count, latency histogram, process CPU/RSS)
  /stress/cpu        spin one core for N seconds
  /stress/memory     hold N MB of RAM until /stress/release
  /admin/error-rate  change the share of /api/orders calls that fail

Every request is logged as one JSON line on stdout so the logs can be parsed
by Loki (or anything else) without regexes.
"""
import json
import logging
import os
import random
import sys
import threading
import time

from flask import Flask, g, jsonify, request
from prometheus_client import (CONTENT_TYPE_LATEST, Counter, Gauge, Histogram,
                               generate_latest)

SERVICE = os.getenv("SERVICE_NAME", "orders-api")
VERSION = os.getenv("APP_VERSION", "1.0.0")
HEALTH_MEMORY_LIMIT_MB = int(os.getenv("HEALTH_MEMORY_LIMIT_MB", "300"))
state = {"error_rate": float(os.getenv("ERROR_RATE", "0.02"))}
started = time.time()

# ---------------------------------------------------------------- metrics ----
REQUESTS = Counter("app_requests_total", "HTTP requests served",
                   ["method", "endpoint", "status"])
LATENCY = Histogram("app_request_duration_seconds", "Time spent serving a request",
                    ["endpoint"],
                    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5))
IN_FLIGHT = Gauge("app_requests_in_flight", "Requests being served right now")
HOG_BYTES = Gauge("app_memory_hog_bytes", "Bytes deliberately held by /stress/memory")
CPU_BURN = Gauge("app_cpu_burn_active", "1 while /stress/cpu is spinning a core")
ERROR_RATE = Gauge("app_configured_error_rate", "Share of /api/orders calls set to fail")
INFO = Gauge("app_build_info", "Build information", ["service", "version"])
INFO.labels(SERVICE, VERSION).set(1)
ERROR_RATE.set(state["error_rate"])


# ---------------------------------------------------------------- logging ----
class JsonFormatter(logging.Formatter):
    def format(self, record):
        line = {"ts": time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(record.created))
                      + f".{int(record.msecs):03d}Z",
                "level": record.levelname, "service": SERVICE, "msg": record.getMessage()}
        line.update(getattr(record, "extra_fields", {}))
        return json.dumps(line)


handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
log = logging.getLogger(SERVICE)
log.addHandler(handler)
log.setLevel(logging.INFO)
log.propagate = False
logging.getLogger("werkzeug").setLevel(logging.WARNING)


def jlog(level, msg, **fields):
    log.log(level, msg, extra={"extra_fields": fields})


app = Flask(__name__)
_hog = []          # memory held on purpose
_lock = threading.Lock()


@app.before_request
def _start():
    g.t0 = time.perf_counter()
    IN_FLIGHT.inc()


@app.after_request
def _record(resp):
    IN_FLIGHT.dec()
    if request.path == "/metrics":      # do not count the scrape itself
        return resp
    endpoint = request.url_rule.rule if request.url_rule else "unmatched"
    elapsed = time.perf_counter() - g.t0
    REQUESTS.labels(request.method, endpoint, str(resp.status_code)).inc()
    LATENCY.labels(endpoint).observe(elapsed)
    level = logging.ERROR if resp.status_code >= 500 else logging.INFO
    jlog(level, "request", method=request.method, path=request.path,
         status=resp.status_code, duration_ms=round(elapsed * 1000, 1),
         client=request.headers.get("User-Agent", "-").split("/")[0])
    return resp


# ------------------------------------------------------------- endpoints ----
@app.get("/")
def index():
    return jsonify(service=SERVICE, version=VERSION,
                   endpoints=["/api/orders", "/health", "/metrics", "/stress/cpu",
                              "/stress/memory", "/stress/release", "/admin/error-rate"])


@app.get("/api/orders")
def orders():
    # Mostly fast, with a slow tail - which is exactly what p95 is for.
    time.sleep(random.choice([0.02, 0.03, 0.04, 0.05, 0.06, 0.08, 0.12, 0.25]))
    if random.random() < state["error_rate"]:
        jlog(logging.ERROR, "order lookup failed", reason="inventory-db timeout")
        return jsonify(error="inventory-db timeout"), 500
    return jsonify(orders=[{"id": random.randint(1000, 9999), "status": "shipped"}])


@app.get("/health")
def health():
    held_mb = HOG_BYTES._value.get() / 1024 / 1024
    body = {"status": "ok", "service": SERVICE, "version": VERSION,
            "uptime_s": round(time.time() - started), "held_memory_mb": round(held_mb)}
    if held_mb > HEALTH_MEMORY_LIMIT_MB:
        body.update(status="degraded",
                    reason=f"holding {held_mb:.0f} MB > limit {HEALTH_MEMORY_LIMIT_MB} MB")
        return jsonify(body), 503
    return jsonify(body)


@app.get("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


def _burn(seconds):
    CPU_BURN.set(1)
    end = time.time() + seconds
    x = 0
    while time.time() < end:
        x = (x * 31 + 7) % 1000003       # pure CPU, no I/O
    CPU_BURN.set(0)
    jlog(logging.INFO, "cpu burn finished", seconds=seconds)


@app.get("/stress/cpu")
def stress_cpu():
    seconds = int(request.args.get("seconds", 60))
    threading.Thread(target=_burn, args=(seconds,), daemon=True).start()
    jlog(logging.WARNING, "cpu burn started", seconds=seconds)
    return jsonify(burning_for_s=seconds)


@app.get("/stress/memory")
def stress_memory():
    mb = int(request.args.get("mb", 100))
    with _lock:
        _hog.append(b"x" * (mb * 1024 * 1024))   # bytes are written, so RSS really grows
        total = sum(len(b) for b in _hog)
    HOG_BYTES.set(total)
    jlog(logging.WARNING, "memory allocated", added_mb=mb, held_mb=total // 1024 // 1024)
    return jsonify(held_mb=total // 1024 // 1024)


@app.get("/stress/release")
def stress_release():
    with _lock:
        _hog.clear()
    HOG_BYTES.set(0)
    jlog(logging.INFO, "memory released")
    return jsonify(held_mb=0)


@app.get("/admin/error-rate")
def error_rate():
    if "value" in request.args:
        state["error_rate"] = float(request.args["value"])
        ERROR_RATE.set(state["error_rate"])
        jlog(logging.WARNING, "error rate changed", error_rate=state["error_rate"])
    return jsonify(error_rate=state["error_rate"])


jlog(logging.INFO, "service started", version=VERSION, pid=os.getpid())
