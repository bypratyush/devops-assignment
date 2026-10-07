# Frontend image: React (Vite) built with Node, served by unprivileged nginx.
# Build context = application/frontend
#   docker build -f docker/frontend.Dockerfile -t lostfound-frontend application/frontend

# ---- stage 1: build the static bundle ---------------------------------------
FROM node:22-alpine AS build
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm run build

# ---- stage 2: only the built files + nginx (no node, no node_modules) --------
FROM nginxinc/nginx-unprivileged:1.29-alpine
# The 1.29-alpine base lags behind Alpine's security fixes (Trivy found 42
# fixable HIGH CVEs in curl, openssl, libxml2, ...), so patch it at build time.
USER root
RUN apk upgrade --no-cache
# The official nginx entrypoint runs envsubst on /etc/nginx/templates/*.template
# at start-up, so the backend address is set at runtime with BACKEND_URL.
ENV BACKEND_URL=http://backend:8000
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /src/dist /usr/share/nginx/html
EXPOSE 8080
USER 101
