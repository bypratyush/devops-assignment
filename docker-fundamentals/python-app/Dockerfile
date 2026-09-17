FROM python:3.12-alpine
WORKDIR /app
COPY app.py .
ENV PORT=5000 APP_NAME=python-app
EXPOSE 5000
RUN adduser -D -u 10001 appuser
USER appuser
CMD ["python", "app.py"]
