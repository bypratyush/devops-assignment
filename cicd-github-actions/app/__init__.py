"""Grade calculator API - the application the Session 16 CI/CD pipeline builds and ships."""

import hmac
import os
import time

from flask import Flask, jsonify, request

from .grading import GradingError, grade_for, sgpa

__version__ = "1.2.0"


def create_app():
    app = Flask(__name__)
    started = time.monotonic()
    served = {"grade": 0, "sgpa": 0}

    @app.errorhandler(GradingError)
    def bad_input(err):
        return jsonify(error=str(err)), 400

    @app.get("/health")
    def health():
        return jsonify(status="ok")

    @app.get("/version")
    def version():
        # GIT_SHA is baked into the image at build time by the pipeline
        return jsonify(version=__version__, commit=os.environ.get("GIT_SHA", "dev"))

    @app.get("/api/grade")
    def grade():
        score = request.args.get("score")
        if score is None:
            raise GradingError("query parameter 'score' is required")
        letter, points = grade_for(score)
        served["grade"] += 1
        return jsonify(score=float(score), grade=letter, points=points)

    @app.post("/api/sgpa")
    def semester():
        body = request.get_json(silent=True) or {}
        result = sgpa(body.get("courses"))
        served["sgpa"] += 1
        return jsonify(result)

    @app.get("/api/admin/stats")
    def admin_stats():
        # The key comes from a GitHub Actions secret at deploy time, never from the repo
        expected = os.environ.get("ADMIN_API_KEY", "")
        if not expected:
            return jsonify(error="admin endpoint disabled (ADMIN_API_KEY not set)"), 503
        supplied = request.headers.get("X-API-Key", "")
        if not hmac.compare_digest(supplied, expected):
            return jsonify(error="invalid or missing X-API-Key"), 401
        return jsonify(
            uptime_seconds=round(time.monotonic() - started, 1),
            requests_served=served,
            pid=os.getpid(),
        )

    return app
