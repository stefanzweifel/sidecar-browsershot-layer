#!/bin/sh
set -e

. "$(dirname "$0")/config.sh"

parse_args "$@"

README_PATH="README.md"

if [ ! -f "$README_PATH" ]; then
    echo "Error: $README_PATH not found"
    exit 1
fi

echo "Fetching latest layer ARNs for stage: $STAGE"

# Create temp files
TMP_ARNS=$(mktemp)
TMP_README=$(mktemp)
trap 'rm -f "$TMP_ARNS" "$TMP_README"' EXIT

# Build the new ARN list and write to temp file
for REGION in $AWS_REGIONS; do
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

    echo "Found: $LAYER_ARN"
    echo "- \`${LAYER_ARN}\`" >> "$TMP_ARNS"
done

if [ ! -s "$TMP_ARNS" ]; then
    echo "Error: No ARNs found. Cannot update README."
    exit 1
fi

# Get the puppeteer-core version from the layer description
PUPPETEER_VERSION=$(aws lambda list-layer-versions \
    --region "us-east-1" \
    --layer-name "$LAYER_NAME" \
    --query 'LayerVersions[0].Description' \
    --output text \
    $AWS_PROFILE_ARG 2>/dev/null | sed -n 's/.*puppeteer-core v\([0-9.]*\).*/\1/p' || echo "")

# Use awk to replace the ARN section and puppeteer version
awk -v new_version="$PUPPETEER_VERSION" -v arns_file="$TMP_ARNS" '
BEGIN { in_arn_section = 0 }

# Update puppeteer-core version line
/^- `puppeteer-core`:/ && new_version != "" {
    print "- `puppeteer-core`: v" new_version
    next
}

# Detect start of ARN section
/^- `arn:aws:lambda:/ && !in_arn_section {
    in_arn_section = 1
    while ((getline line < arns_file) > 0) {
        print line
    }
    close(arns_file)
}

# Skip old ARN lines
in_arn_section && /^- `arn:aws:lambda:/ {
    next
}

# Detect end of ARN section (any line that is not an ARN)
in_arn_section && !/^- `arn:aws:lambda:/ {
    in_arn_section = 0
}

# Print all other lines
{ print }
' "$README_PATH" > "$TMP_README"

# Replace the original README
mv "$TMP_README" "$README_PATH"
trap 'rm -f "$TMP_ARNS"' EXIT

echo "README.md updated successfully"
