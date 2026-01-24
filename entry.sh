#!/bin/sh
set -e

cd /app

# Patch default_host to bind to all interfaces
sed -i 's/default_host = ".*"/default_host = "0.0.0.0"/' app.py

# Set defaults
PORT="${PORT:-8080}"
EXTRA_PATHS="${EXTRA_PATHS:-/outputs}"

echo "=== Infinite Image Browsing ==="
echo "PORT: $PORT"
echo "EXTRA_PATHS: $EXTRA_PATHS"
echo "EXTRA_OPTIONS: $EXTRA_OPTIONS"
echo "==============================="

# Configure environment
cat > .env << EOF
IIB_ACCESS_CONTROL=enable
IIB_DB_FILE_BACKUP_MAX=0
IIB_CACHE_DIR=/cache
EOF

exec python app.py \
    --port="$PORT" \
    --extra_paths="$EXTRA_PATHS" \
    --sd_webui_config="/config.json" \
    $EXTRA_OPTIONS
