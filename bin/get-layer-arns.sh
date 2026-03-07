#!/bin/sh
set -e

. "$(dirname "$0")/config.sh"

parse_args "$@"

for REGION in $AWS_REGIONS; do
    # Get the latest layer version ARN
    LAYER_ARN=$(aws lambda list-layer-versions \
        --region "$REGION" \
        --layer-name "$LAYER_NAME" \
        --query 'LayerVersions[0].LayerVersionArn' \
        --output text \
        $AWS_PROFILE_ARG 2>/dev/null || echo "")

    if [ -z "$LAYER_ARN" ] || [ "$LAYER_ARN" = "None" ]; then
        echo "Warning: No layer found in $REGION" >&2
        continue
    fi

    echo "$LAYER_ARN"
done
