#!/bin/sh
# Runs the canary handler against dist/<zip> inside the official AWS Lambda
# Node image. The image starts Node with the same flags as the real runtime.
# Requires Docker. Run `npm run build` first.
set -e

. "$(dirname "$0")/config.sh"

LOCAL_FILE_PATH="dist/${LOCAL_FILENAME}"
IMAGE="public.ecr.aws/lambda/nodejs:24"

if [ ! -f "$LOCAL_FILE_PATH" ]; then
    echo "Error: $LOCAL_FILE_PATH not found. Run 'npm run build' first."
    exit 1
fi

TMP_DIR=$(mktemp -d)
CONTAINER=""
cleanup() {
    [ -n "$CONTAINER" ] && docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

unzip -q "$LOCAL_FILE_PATH" -d "$TMP_DIR"
cp "$(dirname "$0")/canary/handler.js" "$TMP_DIR/handler.js"

CONTAINER=$(docker run -d -p 127.0.0.1::8080 \
    -v "$TMP_DIR/nodejs:/opt/nodejs:ro" \
    -v "$TMP_DIR/handler.js:/var/task/handler.js:ro" \
    "$IMAGE" handler.handler)

PORT=$(docker port "$CONTAINER" 8080/tcp | head -n1 | sed 's/.*://')

EXPECTED_VERSION=$(node -p "require('./node_modules/puppeteer-core/package.json').version")

RESULT=""
for _ in 1 2 3 4 5 6 7 8 9 10; do
    RESULT=$(curl -s -XPOST "http://localhost:$PORT/2015-03-31/functions/function/invocations" -d '{}') && [ -n "$RESULT" ] && break
    sleep 1
done

echo "Canary result: $RESULT"

if echo "$RESULT" | grep -q "\"ok\":true" && echo "$RESULT" | grep -q "\"puppeteerCoreVersion\":\"$EXPECTED_VERSION\""; then
    echo "Canary OK (puppeteer-core $EXPECTED_VERSION)"
else
    echo "Canary FAILED (expected puppeteer-core $EXPECTED_VERSION)"
    exit 1
fi
