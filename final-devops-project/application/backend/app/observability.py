"""JSON logging and Prometheus metrics for the API."""

import json
import logging
import sys
import time
import uuid

from fastapi import Request
from prometheus_client import Counter, Gauge, Histogram

REQUESTS = Counter(
    "lostfound_http_requests_total",
    "HTTP requests handled by the API",
    ["method", "route", "status"],
)
LATENCY = Histogram(
    "lostfound_http_request_duration_seconds",
    "Request latency in seconds",
    ["method", "route"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5),
)
ITEMS_REPORTED = Counter(
    "lostfound_items_reported_total",
    "Items reported at the desk",
    ["kind"],
)
DB_UP = Gauge("lostfound_db_up", "1 if the last readiness check reached the database")


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        entry = {
            "ts": time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(record.created)),
            "level": record.levelname,
            "logger": record.name,
            "msg": record.getMessage(),
        }
        extra = getattr(record, "extra_fields", None)
        if extra:
            entry.update(extra)
        return json.dumps(entry)


def setup_logging(level: str) -> logging.Logger:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level)
    # uvicorn's own access log would duplicate ours
    logging.getLogger("uvicorn.access").disabled = True
    return logging.getLogger("lostfound")


def route_template(request: Request) -> str:
    # use the route pattern (/api/items/{item_id}) not the raw path, otherwise
    # every item id becomes a new label value and the metric cardinality explodes
    route = request.scope.get("route")
    return getattr(route, "path", "unmatched")


async def metrics_middleware(request: Request, call_next):
    start = time.perf_counter()
    request_id = request.headers.get("x-request-id", uuid.uuid4().hex[:12])
    status = 500
    try:
        response = await call_next(request)
        status = response.status_code
        response.headers["x-request-id"] = request_id
        return response
    finally:
        elapsed = time.perf_counter() - start
        route = route_template(request)
        if route not in ("/metrics", "/health", "/ready"):
            REQUESTS.labels(request.method, route, str(status)).inc()
            LATENCY.labels(request.method, route).observe(elapsed)
            logging.getLogger("lostfound.access").info(
                "request",
                extra={
                    "extra_fields": {
                        "request_id": request_id,
                        "method": request.method,
                        "path": request.url.path,
                        "status": status,
                        "duration_ms": round(elapsed * 1000, 2),
                    }
                },
            )
