"""shop - the front door. /checkout prices an item and reserves it in inventory."""
import logging
import os
import time

import requests
from flask import Flask, jsonify, request

import telemetry

app = Flask(__name__)
tracer, log = telemetry.setup(app)
INVENTORY = os.getenv("INVENTORY_URL", "http://inventory:8000")
PRICES = {"book": 499, "lamp": 1299, "gpu": 54999, "unicorn": 1}


@app.get("/checkout")
def checkout():
    t0 = time.perf_counter()
    item = request.args.get("item", "book")
    telemetry.jlog(log, logging.INFO, "checkout started", item=item)

    with tracer.start_as_current_span("price.calculate") as span:   # a manual span
        span.set_attribute("shop.item", item)
        time.sleep(0.015)
        price = PRICES.get(item, 0)

    r = requests.get(f"{INVENTORY}/reserve/{item}", timeout=5)      # auto-instrumented: child span + traceparent

    if r.status_code != 200:
        telemetry.jlog(log, logging.ERROR, "checkout failed", item=item,
                       inventory_status=r.status_code, reason=r.json().get("error"))
        status, body = 502, {"error": "could not reserve item", "item": item}
    else:
        telemetry.jlog(log, logging.INFO, "checkout complete", item=item, price=price)
        status, body = 200, {"item": item, "price": price, "reservation": r.json()["reservation"]}

    trace_id, _ = telemetry.current_ids()
    body["trace_id"] = trace_id           # handy for the demo: the client sees the id too
    telemetry.observe("/checkout", status, time.perf_counter() - t0)
    return jsonify(body), status
