"""inventory - reserves stock. The 'gpu' lookup is slow on purpose, 'unicorn' is never in stock."""
import logging
import random
import time

from flask import Flask, jsonify, request
from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode

import telemetry

app = Flask(__name__)
tracer, log = telemetry.setup(app)
STOCK = {"book": 40, "lamp": 7, "gpu": 2, "unicorn": 0}


@app.get("/reserve/<item>")
def reserve(item):
    t0 = time.perf_counter()
    # the incoming W3C header that tied this request to the caller's trace
    telemetry.jlog(log, logging.INFO, "reserve requested", item=item,
                   traceparent=request.headers.get("traceparent"))

    with tracer.start_as_current_span("db.query") as span:
        span.set_attribute("db.system", "postgresql")
        span.set_attribute("db.statement", "SELECT qty FROM stock WHERE sku = $1 FOR UPDATE")
        # a missing index on the big 'gpu' partition - the kind of thing only a trace shows quickly
        time.sleep(0.6 if item == "gpu" else random.uniform(0.01, 0.03))
        qty = STOCK.get(item, 0)
        span.set_attribute("stock.qty", qty)

    if qty <= 0:
        # mark the server span as failed so Jaeger shows it red
        trace.get_current_span().set_status(Status(StatusCode.ERROR, "out of stock"))
        telemetry.jlog(log, logging.ERROR, "out of stock", item=item)
        telemetry.observe("/reserve", 409, time.perf_counter() - t0)
        return jsonify(error="out of stock", item=item), 409

    telemetry.jlog(log, logging.INFO, "reserved", item=item, remaining=qty - 1)
    telemetry.observe("/reserve", 200, time.perf_counter() - t0)
    return jsonify(reservation=f"R-{random.randint(10000, 99999)}", item=item)
