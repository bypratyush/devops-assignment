FROM node:20-alpine
WORKDIR /app
COPY server.js .
ENV PORT=3000 APP_NAME=node-app
EXPOSE 3000
# Run as a non-root user. Containers default to root, which is a real risk:
# a container escape then starts from root on the host.
USER node
CMD ["node", "server.js"]
