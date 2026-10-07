# Stage 1: install the pinned dependencies and the wheel the Build job produced
FROM python:3.13-slim AS build
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1 PIP_ROOT_USER_ACTION=ignore
COPY requirements.txt /tmp/requirements.txt
COPY dist/*.whl /tmp/
RUN python -m venv /venv \
 && /venv/bin/pip install -r /tmp/requirements.txt \
 && /venv/bin/pip install --no-deps /tmp/*.whl \
 && /venv/bin/pip uninstall --yes pip

# Stage 2: runtime - no compilers, no build files, non-root
FROM python:3.13-slim
ARG GIT_SHA=dev
LABEL org.opencontainers.image.title="passguard" \
      org.opencontainers.image.source="https://github.com/bypratyush/devops-assignment" \
      org.opencontainers.image.revision="${GIT_SHA}"
ENV PATH=/venv/bin:$PATH PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 GIT_SHA=${GIT_SHA}
# No package manager at runtime: the base image's pip carries vendored copies of
# urllib3, msgpack and setuptools that Trivy flags HIGH, and the app never needs it
RUN python -m pip uninstall --yes --root-user-action=ignore pip \
 && groupadd --gid 10001 app && useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app
COPY --from=build /venv /venv
USER 10001
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD ["python", "-c", "import urllib.request,sys; sys.exit(urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=2).status != 200)"]
# /dev/shm for gunicorn's heartbeat files, so the root filesystem can be read-only in Kubernetes
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--worker-tmp-dir", "/dev/shm", "--access-logfile", "-", "passguard:create_app()"]
