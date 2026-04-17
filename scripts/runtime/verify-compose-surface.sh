#!/usr/bin/env sh
set -eu

PUBLIC_CONFIG="${TMPDIR:-/tmp}/iib-compose-public.yaml"
DEV_CONFIG="${TMPDIR:-/tmp}/iib-compose-dev.yaml"

docker compose config >"$PUBLIC_CONFIG"
docker compose -f compose.dev.yaml config >"$DEV_CONFIG"

grep -q 'image: ghcr.io/pbanddev/infinite-image-browser-docker:latest' "$PUBLIC_CONFIG"
grep -q 'build:' "$DEV_CONFIG"
