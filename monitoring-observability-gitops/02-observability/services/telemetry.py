"""Shared OpenTelemetry + logging + metrics setup for the two demo services.

One request should be findable in all three signals by the same trace_id:
  traces  -> exported over OTLP/HTTP to Jaeger
  logs    -> JSON lines on stdout that carry trace_id / span_id
  metrics -> a Prometheus histogram whose samples carry the trace_id as an exemplar
"""
import json
import logging
import os
import sys
import time

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_client import Histogram
from prometheus_client.exposition import choose_encoder

SERVICE = os.environ["SERVICE_NAME"]


def current_ids():
    ctx = trace.get_current_span().get_span_context()
    if not ctx.is_valid:
        return None, None
    return format(ctx.trace_id, "032x"), format(ctx.span_id, "016x")


class JsonFormatter(logging.Formatter):
    def format(self, record):
        trace_id, span_id = current_ids()
        line = {"ts": time.strftime("%H:%M:%S", time.gmtime(record.created)) + f".{int(record.msecs):03d}Z",
                "level": record.levelname, "service": SERVICE, "msg": record.getMessage(),
                "trace_id": trace_id, "span_id": span_id}
        line.update(getattr(record, "fields", {}))
        return json.dumps(line)


def setup(app):
    # traces: every Flask request and every outgoing `requests` call becomes a span,
    # and the W3C `traceparent` header is injected/extracted automatically
    provider = TracerProvider(resource=Resource.create({"service.name": SERVICE,
                                                        "service.version": "1.0.0"}))
    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))   # OTEL_EXPORTER_OTLP_ENDPOINT
    trace.set_tracer_provider(provider)
    FlaskInstrumentor().instrument_app(app, excluded_urls="metrics")
    RequestsInstrumentor().instrument()

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    log = logging.getLogger(SERVICE)
    log.handlers = [handler]
    log.setLevel(logging.INFO)
    log.propagate = False
    logging.getLogger("werkzeug").setLevel(logging.WARNING)

    @app.get("/metrics")
    def metrics():
        # OpenMetrics format is the one that can carry exemplars
        from flask import request
        from prometheus_client import REGISTRY
        encoder, content_type = choose_encoder(request.headers.get("Accept"))
        return encoder(REGISTRY), 200, {"Content-Type": content_type}

    return trace.get_tracer(SERVICE), log


def jlog(log, level, msg, **fields):
    log.log(level, msg, extra={"fields": fields})


REQUEST_SECONDS = Histogram("demo_request_duration_seconds", "Request latency",
                            ["service", "route", "status"],
                            buckets=(0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5))


def observe(route, status, seconds):
    trace_id, _ = current_ids()
    REQUEST_SECONDS.labels(SERVICE, route, str(status)).observe(
        seconds, exemplar={"trace_id": trace_id} if trace_id else None)
