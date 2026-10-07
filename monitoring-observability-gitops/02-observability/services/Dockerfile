FROM python:3.13-slim

WORKDIR /app
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY telemetry.py shop.py inventory.py ./

RUN useradd -r -m -u 10001 app
USER app
EXPOSE 8000
# which service runs is chosen by the compose `command`
CMD ["gunicorn", "-b", "0.0.0.0:8000", "-w", "1", "--threads", "4", "shop:app"]
