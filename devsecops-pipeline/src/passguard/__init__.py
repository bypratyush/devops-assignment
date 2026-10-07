"""PassGuard - a small password strength API, the app the Session 17 DevSecOps pipeline ships."""

import os

from flask import Flask, jsonify, render_template, request

from .strength import COMMON_PASSWORDS, PasswordError, assess, generate

__version__ = "1.0.0"

SECURITY_HEADERS = {
    "Content-Security-Policy": "default-src 'self'; frame-ancestors 'none'",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
}


def create_app():
    app = Flask(__name__)
    app.config["MAX_CONTENT_LENGTH"] = 4 * 1024  # a password check never needs more

    @app.after_request
    def harden(resp):
        resp.headers.update(SECURITY_HEADERS)
        if request.path.startswith("/api/"):
            resp.headers["Cache-Control"] = "no-store"  # responses relate to secrets
        return resp

    @app.errorhandler(PasswordError)
    def bad_input(err):
        return jsonify(error=str(err)), 400

    @app.get("/")
    def index():
        return render_template("index.html", version=__version__)

    @app.get("/healthz")
    def healthz():
        return jsonify(status="ok")

    @app.get("/readyz")
    def readyz():
        # ready only once the breached-password list is loaded
        ready = len(COMMON_PASSWORDS) > 0
        return jsonify(ready=ready), (200 if ready else 503)

    @app.get("/version")
    def version():
        return jsonify(version=__version__, commit=os.environ.get("GIT_SHA", "dev"))

    @app.post("/api/strength")
    def strength():
        body = request.get_json(silent=True) or {}
        return jsonify(assess(body.get("password")))

    @app.get("/api/generate")
    def generated():
        try:
            length = int(request.args.get("length", 16))
        except ValueError:
            raise PasswordError("length must be a whole number") from None
        password = generate(length)
        return jsonify(
            password=password, **{k: v for k, v in assess(password).items() if k != "feedback"}
        )

    return app
