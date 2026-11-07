# Builds this fork from source (web interface + server) so Portainer can deploy it from Git.
# Usage: see compose.fork.yaml
FROM louislam/uptime-kuma:builder-go3 AS build_healthcheck

FROM louislam/uptime-kuma:base3 AS build
WORKDIR /app
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
COPY .npmrc package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build && \
    npm run precompile-server && \
    find server src -name '*.ts' -delete && \
    npm prune --omit=dev && \
    rm -rf node_modules/tsx node_modules/esbuild node_modules/@esbuild
COPY --from=build_healthcheck /app/extra/healthcheck /app/extra/healthcheck
RUN mkdir -p ./data && chown -R node:node /app

FROM louislam/uptime-kuma:base3 AS release
WORKDIR /app
ENV UPTIME_KUMA_IS_CONTAINER=1
ENV NODE_ENV=production
COPY --from=build /app /app
EXPOSE 3001
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=5 CMD extra/healthcheck
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "server/server.js"]
