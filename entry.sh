#!/bin/sh
set -e

cd /app

sed -i 's/default_host = ".*"/default_host = "0.0.0.0"/' app.py

# Install favicon (custom or default)
install_favicon() {
    # Determine which favicon to use
    if [ -f "/app/custom/favicon.svg" ]; then
        FAVICON_SRC="/app/custom/favicon.svg"
        echo "Using custom favicon from /app/custom/favicon.svg"
    else
        FAVICON_SRC="/app/default-favicon.svg"
        echo "Using default favicon"
    fi

    # Find the Vue dist folder (where static files are served from)
    VUE_DIST="/app/vue/dist"
    if [ -d "$VUE_DIST" ]; then
        cp "$FAVICON_SRC" "$VUE_DIST/favicon.svg"
        echo "Favicon installed to $VUE_DIST/favicon.svg"

        # Inject favicon link into index.html if not present
        if [ -f "$VUE_DIST/index.html" ]; then
            if ! grep -q 'rel="icon"' "$VUE_DIST/index.html"; then
                sed -i 's|<head>|<head><link rel="icon" type="image/svg+xml" href="/favicon.svg">|' "$VUE_DIST/index.html"
                echo "Favicon link injected into index.html"
            fi
        fi
    else
        echo "Warning: Vue dist folder not found at $VUE_DIST, favicon may not work"
    fi
}

install_favicon

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
