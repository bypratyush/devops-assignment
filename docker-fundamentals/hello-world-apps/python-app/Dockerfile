FROM python:3.13-slim

# No .pyc files in the image, and log lines reach `docker logs` immediately.
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

RUN useradd --uid 10001 --no-create-home appuser
USER appuser

EXPOSE 5000
# gunicorn, not `flask run`: the Flask dev server is single-threaded and
# prints a warning not to use it in production.
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--access-logfile", "-", "app:app"]
