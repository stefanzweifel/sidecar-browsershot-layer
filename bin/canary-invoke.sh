#!/bin/sh
set -e

source "$(dirname "$0")/config.sh"

parse_args "$@"

REGION="$CANARY_REGION"
CANARY_LAMBDA_NAME="${LAYER_NAME_BASE}-canary-${STAGE}"

echo "Invoking canary Lambda $CANARY_LAMBDA_NAME in $REGION..."

RESPONSE_FILE=$(mktemp)
trap 'rm -f "$RESPONSE_FILE"' EXIT

# Extract expected puppeteer-core version
EXPECTED_VERSION=$(npm list --json | jq -r '.dependencies."puppeteer-core".version');

# Wait a bit to ensure layer is available (Lambda eventually consistency)
echo "Waiting for Lambda consistency..."
sleep 10

aws lambda invoke \
    --function-name "$CANARY_LAMBDA_NAME" \
    --region "$REGION" \
    --payload '{}' \
    --cli-binary-format raw-in-base64-out \
    $AWS_PROFILE_ARG \
    "$RESPONSE_FILE" > /dev/null

echo "Canary result:"
cat "$RESPONSE_FILE"
echo ""

OK=$(cat "$RESPONSE_FILE" | jq -r '.ok')
VERSION=$(cat "$RESPONSE_FILE" | jq -r '.puppeteerCoreVersion')

if [ "$OK" = "true" ] && [ "$VERSION" = "$EXPECTED_VERSION" ]; then
    echo "Canary SUCCESS: ok=true, version=$VERSION"
else
    echo "Canary FAILED: ok=$OK, version=$VERSION (expected $EXPECTED_VERSION)"
    exit 1
fi
