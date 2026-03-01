#!/bin/sh
set -e

source "$(dirname "$0")/config.sh"

parse_args "$@"

# For canary, we only use the canary region
REGION="$CANARY_REGION"
CANARY_LAMBDA_NAME="${LAYER_NAME_BASE}-canary-${STAGE}"

echo "Deploying canary to $REGION (Stage: $STAGE)"

# 1. Publish test layer in canary region
# We use the publish-layer.sh script but restricted to the canary region
echo "Publishing layer to $REGION..."
AWS_REGIONS="$REGION" bin/publish-layer.sh "$@"

# Get the latest version number
LATEST_VERSION=$(aws lambda list-layer-versions \
    --region "$REGION" \
    --layer-name "$LAYER_NAME" \
    --query 'LayerVersions[0].Version' \
    --output text \
    $AWS_PROFILE_ARG)

LAYER_ARN=$(aws lambda list-layer-versions \
    --region "$REGION" \
    --layer-name "$LAYER_NAME" \
    --query 'LayerVersions[0].LayerVersionArn' \
    --output text \
    $AWS_PROFILE_ARG)

echo "Latest layer version: $LATEST_VERSION (ARN: $LAYER_ARN)"

# 2. Create/update canary Lambda
echo "Ensuring canary Lambda $CANARY_LAMBDA_NAME exists..."

# Create a temporary zip for the handler
TMP_ZIP=$(mktemp).zip
trap 'rm -f "$TMP_ZIP"' EXIT
cd "$(dirname "$0")/canary"
zip -q "$TMP_ZIP" handler.js
cd - > /dev/null

# IAM Role for Canary (simplified, usually pre-created or use a basic one)
# In CI/Automation, we might assume a role already exists or create one.
# For simplicity, we'll try to find or use a placeholder.
CANARY_ROLE_NAME="sidecar-browsershot-layer-canary-role"

# Check if role exists, if not, this might fail in some envs without enough permissions
ROLE_ARN=$(aws iam get-role --role-name "$CANARY_ROLE_NAME" --query 'Role.Arn' --output text $AWS_PROFILE_ARG 2>/dev/null || true)

if [ -z "$ROLE_ARN" ]; then
    echo "Warning: Role $CANARY_ROLE_NAME not found. Canary deployment might fail if Lambda doesn't exist."
    # In a real scenario, we'd create it here or expect it to exist.
    # For now, we'll assume it exists if we are in a configured environment.
fi

if aws lambda get-function --function-name "$CANARY_LAMBDA_NAME" --region "$REGION" $AWS_PROFILE_ARG >/dev/null 2>&1; then
    echo "Updating existing canary Lambda..."
    aws lambda update-function-code \
        --region "$REGION" \
        --function-name "$CANARY_LAMBDA_NAME" \
        --zip-file "fileb://$TMP_ZIP" \
        $AWS_PROFILE_ARG > /dev/null

    aws lambda update-function-configuration \
        --region "$REGION" \
        --function-name "$CANARY_LAMBDA_NAME" \
        --layers "$LAYER_ARN" \
        $AWS_PROFILE_ARG > /dev/null
else
    echo "Creating new canary Lambda..."
    if [ -z "$ROLE_ARN" ]; then
        echo "Error: Cannot create Lambda without a valid IAM role ARN ($CANARY_ROLE_NAME)."
        exit 1
    fi

    aws lambda create-function \
        --region "$REGION" \
        --function-name "$CANARY_LAMBDA_NAME" \
        --runtime nodejs18.x \
        --handler handler.handler \
        --role "$ROLE_ARN" \
        --zip-file "fileb://$TMP_ZIP" \
        --layers "$LAYER_ARN" \
        --timeout 30 \
        --memory-size 512 \
        $AWS_PROFILE_ARG > /dev/null
fi

echo "Canary Lambda $CANARY_LAMBDA_NAME deployed and configured."
