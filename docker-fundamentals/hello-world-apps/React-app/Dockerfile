# ---------- stage 1: build the static bundle with node ----------
FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---------- stage 2: serve dist/ with nginx ----------
# No node, no node_modules, no source: only the compiled HTML/JS/CSS ships.
FROM nginx:1.30-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
