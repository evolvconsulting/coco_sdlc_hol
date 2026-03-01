# Build context: repo root (not apps/frontend/)
# SPCS requires linux/amd64 — never omit the --platform flag

FROM --platform=linux/amd64 node:20-alpine AS deps
WORKDIR /app

# Copy root workspace manifest and frontend manifests
COPY package.json package-lock.json* ./
COPY apps/frontend/package.json apps/frontend/package-lock.json* ./apps/frontend/

# Install only frontend production deps
RUN cd apps/frontend && npm ci --omit=dev

FROM --platform=linux/amd64 node:20-alpine AS builder
WORKDIR /app

# Copy deps from previous stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/apps/frontend/node_modules ./apps/frontend/node_modules

# Copy full source (respects .dockerignore)
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
RUN cd apps/frontend && npm run build

FROM --platform=linux/amd64 node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Standalone bundle (includes server.js and traced node_modules)
# Because outputFileTracingRoot is monorepo root, standalone preserves full path:
# server.js is at apps/frontend/server.js inside the standalone folder
COPY --from=builder --chown=nextjs:nodejs /app/apps/frontend/.next/standalone ./

# Static assets — standalone does NOT auto-include these
COPY --from=builder --chown=nextjs:nodejs /app/apps/frontend/.next/static ./apps/frontend/.next/static
COPY --from=builder --chown=nextjs:nodejs /app/apps/frontend/public ./apps/frontend/public

USER nextjs
EXPOSE 3000

# server.js path reflects monorepo structure in standalone output
CMD ["node", "apps/frontend/server.js"]
