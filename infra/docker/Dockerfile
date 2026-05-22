# syntax=docker/dockerfile:1.7
# Multi-stage build: Node для сборки Astro → Caddy для отдачи статики

# ============================================
# Stage 1: Build
# ============================================
FROM node:22-alpine AS builder

ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /repo

# Копируем только манифесты для кеша слоёв
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml* ./
COPY apps/flagship/package.json apps/flagship/
COPY packages/design-tokens/package.json packages/design-tokens/

RUN pnpm install --frozen-lockfile || pnpm install

# Копируем исходники
COPY packages/design-tokens packages/design-tokens
COPY apps/flagship apps/flagship

# Билдим токены, потом приложение
RUN pnpm --filter=@marshrut/design-tokens build
RUN pnpm --filter=@marshrut/flagship build

# ============================================
# Stage 2: Runtime — Caddy (PQC + auto HTTPS)
# ============================================
FROM caddy:2.8-alpine AS runtime

LABEL org.opencontainers.image.title="Marshrut Flagship"
LABEL org.opencontainers.image.description="Personal brand site for Andrei Moroz — marshrut.eu"
LABEL org.opencontainers.image.source="https://github.com/IDonRumata/marshrut-network"

# Статика Astro
COPY --from=builder /repo/apps/flagship/dist /srv/marshrut

# Caddyfile задаём через volume / env в compose, fallback есть в образе

EXPOSE 80 443 443/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1
