# -----------------------------
# Builder stage
# -----------------------------
FROM node:20-slim AS builder
WORKDIR /app

# Copy root configuration files
COPY package.json package-lock.json nx.json tsconfig.base.json eslint.config.mjs ./

# Copy source code
COPY apps ./apps
COPY libs ./libs

# Install all dependencies
RUN npm ci

# Build the Next.js app (Nx handles output in apps/client/.next)
RUN npx nx build client

# -----------------------------
# Runner stage
# -----------------------------
FROM node:20-slim AS runner
WORKDIR /app

# Copy only what's needed for production
COPY package.json package-lock.json nx.json ./
RUN npm ci --omit=dev

# Copy Next.js build output and public assets
COPY --from=builder /app/apps/client/.next ./.next
COPY --from=builder /app/apps/client/public ./public
COPY --from=builder /app/apps/client/package.json ./package.json

# Copy shared libraries and node_modules
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/libs ./libs

# Environment and startup
ENV NODE_ENV=production
EXPOSE 3000

# Use Next.js built-in start command
CMD ["npx", "next", "start", "-p", "3000"]
