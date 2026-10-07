"""Hello World - Python (Flask) in a container, served by gunicorn."""
import platform
import socket
from importlib.metadata import version

from flask import Flask

app = Flask(__name__)

PAGE = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Hello World - Python</title>
  <style>
    body {{ font-family: system-ui, sans-serif; background: #f2f5fa; color: #1c2533; margin: 0; }}
    main {{ max-width: 640px; margin: 60px auto; padding: 32px 40px; background: #fff;
           border-top: 6px solid #3776ab; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,.08); }}
    h1 {{ margin: 0 0 8px; color: #3776ab; }}
    td {{ padding: 4px 16px 4px 0; }} td:first-child {{ color: #667; }}
    footer {{ margin-top: 24px; font-size: 14px; color: #556; }}
  </style>
</head>
<body>
  <main>
    <h1>Hello World from Python</h1>
    <p>A Flask app behind gunicorn, running inside a Docker container.</p>
    <table>
      <tr><td>Runtime</td><td>Python {python} / Flask {flask}</td></tr>
      <tr><td>Container hostname</td><td>{host}</td></tr>
      <tr><td>Platform</td><td>{system}/{machine}</td></tr>
    </table>
    <footer>Built by Pratyush Mohanty (Roll No. 24BCS10238)</footer>
  </main>
</body>
</html>"""


@app.get("/")
def index():
    return PAGE.format(
        python=platform.python_version(),
        flask=version("flask"),
        host=socket.gethostname(),
        system=platform.system(),
        machine=platform.machine(),
    )


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


if __name__ == "__main__":
    # Only for running outside Docker; the container uses gunicorn.
    app.run(host="0.0.0.0", port=5000)
