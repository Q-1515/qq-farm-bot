# Multi-stage Dockerfile for qq-farm-bot
# Builder stage - installs dependencies and builds both web and core
FROM node:18-bullseye-slim AS builder

WORKDIR /app

# Enable corepack to use the repo's pnpm version
RUN corepack enable

# copy workspace metadata first for efficient layer caching
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY core/package.json core/
COPY web/package.json web/

# Install pnpm version specified by packageManager and install dependencies
RUN corepack prepare pnpm@10.30.2 --activate && pnpm install --frozen-lockfile

# Copy the rest of the repo and build
COPY . .
RUN pnpm build

# Runtime image
FROM node:18-bullseye-slim
WORKDIR /app
ENV NODE_ENV=production

# Copy built app and node_modules from builder
COPY --from=builder /app /app

# Expose a port (adjust if your core server uses a different port)
EXPOSE 3000

# Start the core service
CMD ["pnpm", "-C", "core", "start"]
