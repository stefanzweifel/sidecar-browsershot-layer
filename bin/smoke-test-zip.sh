#!/bin/sh
set -e

. "$(dirname "$0")/config.sh"

LOCAL_FILE_PATH="dist/${LOCAL_FILENAME}"

if [ ! -f "$LOCAL_FILE_PATH" ]; then
    echo "Error: $LOCAL_FILE_PATH not found . "
    exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Unzipping $LOCAL_FILE_PATH to $TMP_DIR.. . "
unzip -q "$LOCAL_FILE_PATH" -d "$TMP_DIR"

echo "Checking if puppeteer-core can be required.. . "
# In the layer, node_modules is under nodejs/
NODE_PATH="$TMP_DIR/nodejs/node_modules"

DETECTED_VERSION=$(NODE_PATH="$NODE_PATH" ENTRY="$NODE_PATH/puppeteer-core/lib/puppeteer/puppeteer-core.js" node -e '
(async () => {
    try {
        await import(process.env.ENTRY);
        const pkg = require("puppeteer-core/package.json");
        console.log(pkg.version);
    } catch (e) {
        console.error("Failed to load puppeteer-core:", e.message);
        process.exit(1);
    }
})();
')

echo "Successfully required puppeteer-core version: $DETECTED_VERSION"
