#!/bin/bash
set -e

echo "Starting 9Router v2 Container Setup..."

# 1. Pastikan direktori database ada di volume persisten /data
mkdir -p /data/db
chmod 777 /data /data/db

# 2. Siapkan Node.js module symlinks agar module resolution berjalan dengan benar
echo "Setting up Node.js module symlinks..."
mkdir -p /app/node_modules
mkdir -p /app/node_modules/@

# Symlink open-sse -> backend/open-sse
ln -sf /app/backend/open-sse /app/node_modules/open-sse

# Symlink @/lib -> backend/dist/lib
ln -sf /app/backend/dist/lib /app/node_modules/@/lib

# Verifikasi symlinks
echo "Verifying symlinks:"
ls -la /app/node_modules/open-sse
ls -la /app/node_modules/@/lib

# 3. Jalankan backend Express di background
echo "Starting Node.js Backend Server on port 3001..."
export PORT=3001
export DATA_DIR=/data
export NODE_ENV=production
cd /app
node backend/dist/server.js &

# 4. Jalankan Nginx di foreground sebagai proses utama
echo "Starting Nginx Reverse Proxy on port 80..."
exec nginx -g "daemon off;"
