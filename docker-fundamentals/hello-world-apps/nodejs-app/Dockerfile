FROM node:24-alpine

WORKDIR /app
ENV NODE_ENV=production PORT=3000

# Manifests first: the npm ci layer stays cached until the dependencies change,
# so editing server.js does not reinstall express on every build.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY server.js ./

# The official node image ships a non-root "node" user.
USER node
EXPOSE 3000
CMD ["node", "server.js"]
