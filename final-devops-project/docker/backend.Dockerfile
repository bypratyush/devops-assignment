# Backend image: FastAPI + Alembic. Build context = application/backend
#   docker build -f docker/backend.Dockerfile -t lostfound-backend application/backend

# ---- stage 1: install dependencies into a virtualenv -------------------------
FROM python:3.13-slim AS deps
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
# pip is only needed to build the venv. Its vendored urllib3/msgpack/setuptools
# carried fixable HIGH CVEs (Trivy), so it does not go into the runtime image.
RUN pip install -r requirements.txt && pip uninstall -y pip

# ---- stage 2: runtime, no pip cache, no build tools, not root ----------------
FROM python:3.13-slim
ARG APP_VERSION=dev
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_VERSION=${APP_VERSION}
# same for the base image's own pip: nothing installs packages at runtime
RUN /usr/local/bin/python3 -m pip uninstall -y --root-user-action=ignore pip
RUN groupadd --gid 10001 app && useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app
WORKDIR /app
COPY --from=deps /opt/venv /opt/venv
COPY alembic.ini ./
COPY alembic ./alembic
COPY app ./app
COPY --chmod=755 entrypoint.sh ./
USER 10001
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request,sys; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2)" || exit 1
ENTRYPOINT ["./entrypoint.sh"]
