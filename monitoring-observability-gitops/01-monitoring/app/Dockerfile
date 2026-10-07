FROM python:3.13-slim

WORKDIR /app
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py alert_receiver.py ./

RUN useradd -r -m -u 10001 app
USER app
EXPOSE 8000
# one worker so the in-process metrics are not split between processes;
# threads let /stress/cpu run without blocking normal requests
CMD ["gunicorn", "-b", "0.0.0.0:8000", "-w", "1", "--threads", "8", "--log-level", "warning", "app:app"]
