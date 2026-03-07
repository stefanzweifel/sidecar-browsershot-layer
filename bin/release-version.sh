#!/bin/sh

PUPPETEER_VERSION=$(npm list puppeteer-core --json | jq -r '.dependencies["puppeteer-core"].version')
DEPLOY_DATE=$(date +%Y-%m-%d)
LAYER_VERSION="${PUPPETEER_VERSION}-${DEPLOY_DATE}"
echo "Layer Version: $LAYER_VERSION"
