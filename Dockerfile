# ==============================================================================
# Stage 1: Build Frontend (Vite + React)
# ==============================================================================
FROM node:22-bookworm-slim AS frontend-builder
WORKDIR /app

# Copy root workspace configurations
COPY package*.json ./
COPY frontend/package*.json ./frontend/

# Install frontend dependencies
RUN npm install --workspace=frontend

# Copy frontend source and build
COPY frontend/ ./frontend/
RUN npm run build --workspace=frontend

# ==============================================================================
# Stage 2: Build Backend (TypeScript)
# ==============================================================================
FROM node:22-bookworm-slim AS backend-builder
WORKDIR /app

# Copy root workspace configurations
COPY package*.json ./
COPY backend/package*.json ./backend/

# Install backend dependencies
RUN npm install --workspace=backend

# Copy backend source and compile
COPY backend/ ./backend/
RUN npm run build --workspace=backend

# ==============================================================================
# Stage 3: Runner (Nginx + Node.js + Python Camoufox)
# ==============================================================================
FROM node:22-bookworm-slim AS runner
WORKDIR /app

# Install system dependencies: Nginx, Python, and Firefox ESR (contains GUI libraries for Camoufox)
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    python3 \
    python3-pip \
    python3-venv \
    firefox-esr \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy package configurations for production install
COPY package*.json ./
COPY backend/package*.json ./backend/

# Install only production Node dependencies
RUN npm install --omit=dev --workspace=backend

# Copy compiled Frontend statically
COPY --from=frontend-builder /app/frontend/dist ./frontend/dist

# Copy compiled Backend JS, scripts, and automation assets
COPY --from=backend-builder /app/backend/dist ./backend/dist
COPY backend/open-sse ./backend/open-sse
COPY backend/src/automation ./backend/src/automation

# Setup Python Virtual Environment and pre-install Camoufox
RUN python3 -m venv /app/backend/.venv && \
    /app/backend/.venv/bin/pip install --no-cache-dir 'camoufox[geoip]' && \
    /app/backend/.venv/bin/python3 -m camoufox fetch

# Copy Custom Nginx configuration
COPY nginx.docker.conf /etc/nginx/nginx.conf

# Copy Entrypoint Startup script
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

# Environment variables
ENV PORT=3001
ENV DATA_DIR=/data
ENV NODE_ENV=production

# Expose Nginx Port
EXPOSE 80

# Execute entrypoint
ENTRYPOINT ["./entrypoint.sh"]
