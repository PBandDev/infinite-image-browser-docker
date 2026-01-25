#!/bin/sh
set -e

cd /app

sed -i 's/default_host = ".*"/default_host = "0.0.0.0"/' app.py

# Docker defaults (user can override via -e)
export PORT="${PORT:-8080}"
export EXTRA_PATHS="${EXTRA_PATHS:-/outputs}"
export IIB_CACHE_DIR="${IIB_CACHE_DIR:-/cache}"
export IIB_DB_PATH="${IIB_DB_PATH:-${IIB_CACHE_DIR}/iib.db}"
export IIB_ACCESS_CONTROL="${IIB_ACCESS_CONTROL:-enable}"
export IIB_DB_FILE_BACKUP_MAX="${IIB_DB_FILE_BACKUP_MAX:-0}"

echo "=== Infinite Image Browsing ==="
echo "PORT: $PORT"
echo "EXTRA_PATHS: $EXTRA_PATHS"
echo "IIB_DB_PATH: $IIB_DB_PATH"
echo "IIB_CACHE_DIR: $IIB_CACHE_DIR"
echo "EXTRA_OPTIONS: $EXTRA_OPTIONS"
echo "==============================="

exec python app.py \
    --port="$PORT" \
    --extra_paths="$EXTRA_PATHS" \
    --sd_webui_config="/config.json" \
    $EXTRA_OPTIONS
