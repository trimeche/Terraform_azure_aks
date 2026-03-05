# Stage 1 — Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY src/package.json ./
RUN npm install --omit=dev

# Stage 2 — Runtime
FROM node:20-alpine AS runtime
WORKDIR /app

# Copy deps + source BEFORE switching user
COPY --from=deps /app/node_modules ./node_modules
COPY src/ ./

# Fix permissions THEN switch to non-root
RUN chown -R node:node /app
USER node

EXPOSE 3000
ENV NODE_ENV=production
ENV PORT=3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -qO- http://localhost:3000/health/live || exit 1

CMD ["node", "index.js"]

