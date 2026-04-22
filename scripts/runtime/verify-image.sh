#!/usr/bin/env sh
set -eu

IMAGE_REF="${1:?usage: verify-image.sh <image-ref> [expected-tag]}"
EXPECTED_TAG="${2:-}"
CONTAINER_NAME="iib-verify-$$"
VERSION_FILE="$(mktemp)"
CONF_FILE="$(mktemp)"

for required_cmd in docker curl; do
  if ! command -v "$required_cmd" >/dev/null 2>&1; then
    echo "verification failed: require $required_cmd on the host" >&2
    exit 1
  fi
done

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
else
  echo "verification failed: require python3 or python on the host to parse JSON" >&2
  exit 1
fi

cleanup() {
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  rm -f "$VERSION_FILE" "$CONF_FILE"
}
trap cleanup EXIT INT TERM

docker run -d --rm \
  --name "$CONTAINER_NAME" \
  -p "127.0.0.1:${VERIFY_PORT:-}:8080" \
  "$IMAGE_REF" >/dev/null

PORT="$(docker port "$CONTAINER_NAME" 8080/tcp | head -n 1 | sed 's/.*://')"
if [ -z "$PORT" ]; then
  echo "verification failed: could not determine published local port for $CONTAINER_NAME" >&2
  exit 1
fi

ready=""
attempt=0
while [ "$attempt" -lt 60 ]; do
  if curl -fsS "http://127.0.0.1:${PORT}/infinite_image_browsing/version" >"$VERSION_FILE" 2>/dev/null; then
    ready="yes"
    break
  fi
  sleep 2
  attempt=$((attempt + 1))
done

if [ -z "$ready" ]; then
  echo "verification failed: timed out waiting for /infinite_image_browsing/version from $IMAGE_REF" >&2
  exit 1
fi

RUNTIME_HASH="$(
EXPECTED_TAG="$EXPECTED_TAG" "$PYTHON_BIN" - "$VERSION_FILE" <<'PY'
import json
import os
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())
if not data.get("hash"):
    raise SystemExit("verification failed: expected /version.hash to be non-empty")

expected_tag = os.environ.get("EXPECTED_TAG", "").strip()
if expected_tag and data.get("tag") != expected_tag:
    raise SystemExit(
        f"verification failed: expected tag {expected_tag!r}, got {data.get('tag')!r}"
    )
print(data["hash"])
PY
)"

set +e
SOURCE_HASH_OUTPUT="$(docker exec "$CONTAINER_NAME" sh -lc "git -C /app rev-parse HEAD" 2>&1)"
SOURCE_HASH_STATUS=$?
set -e

if [ "$SOURCE_HASH_STATUS" -ne 0 ]; then
  echo "verification failed: failed to read git HEAD for /app" >&2
  if [ -n "$SOURCE_HASH_OUTPUT" ]; then
    echo "$SOURCE_HASH_OUTPUT" >&2
  fi
  exit 1
fi

SOURCE_HASH="$(printf '%s' "$SOURCE_HASH_OUTPUT" | tr -d '\r\n')"
if [ -z "$SOURCE_HASH" ]; then
  echo "verification failed: expected git HEAD for /app to be non-empty" >&2
  exit 1
fi

if [ "$RUNTIME_HASH" != "$SOURCE_HASH" ]; then
  echo "verification failed: expected runtime hash $RUNTIME_HASH to match /app HEAD $SOURCE_HASH" >&2
  exit 1
fi

docker exec "$CONTAINER_NAME" sh -lc "cat /app/vue/src-tauri/tauri.conf.json" >"$CONF_FILE"
SOURCE_VERSION="$("$PYTHON_BIN" - "$CONF_FILE" <<'PY'
import json
import sys
from pathlib import Path

conf = json.loads(Path(sys.argv[1]).read_text())
print(conf["package"]["version"])
PY
)"

if [ -z "$SOURCE_VERSION" ]; then
  echo "verification failed: expected source version from tauri.conf.json to be non-empty" >&2
  exit 1
fi

NEEDLE="version:\"${SOURCE_VERSION}\""
set +e
JS_FILES_OUTPUT="$(docker exec "$CONTAINER_NAME" sh -lc "find /app/vue/dist/assets -type f -name '*.js'" 2>&1)"
JS_FILES_STATUS=$?
set -e

if [ "$JS_FILES_STATUS" -ne 0 ]; then
  echo "verification failed: failed to enumerate frontend JS assets under /app/vue/dist/assets" >&2
  if [ -n "$JS_FILES_OUTPUT" ]; then
    echo "$JS_FILES_OUTPUT" >&2
  fi
  exit 1
fi

if [ -z "$JS_FILES_OUTPUT" ]; then
  echo "verification failed: no frontend JS assets found under /app/vue/dist/assets" >&2
  exit 1
fi

MATCH_FOUND=""
OLD_IFS=$IFS
IFS='
'
for JS_FILE in $JS_FILES_OUTPUT; do
  set +e
  docker exec "$CONTAINER_NAME" sh -lc "grep -F -- '$NEEDLE' '$JS_FILE' >/dev/null" >/dev/null 2>&1
  GREP_STATUS=$?
  set -e

  case "$GREP_STATUS" in
    0)
      MATCH_FOUND="yes"
      break
      ;;
    1)
      ;;
    *)
      echo "verification failed: failed to scan frontend JS asset $JS_FILE" >&2
      exit 1
      ;;
  esac
done
IFS=$OLD_IFS

if [ -z "$MATCH_FOUND" ]; then
  echo "verification failed: expected frontend bundle to embed $NEEDLE" >&2
  exit 1
fi
