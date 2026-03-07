#!/bin/sh

 . "$(dirname "$0")/config.sh"

parse_args "$@"

# For backward compatibility, if $1 was PROFILE and not starting with --
if [ -n "$PROFILE" ] && [ -z "$AWS_PROFILE_ARG" ]; then
    AWS_PROFILE_ARG="--profile $PROFILE"
fi

# Extract exact dependency versions from npm
PUPPETEER_CORE_VERSION=$(npm list --json | jq -r '.dependencies . "puppeteer-core".version');

# Define local file path early so we can verify it
LOCAL_FILE_PATH="dist/${LOCAL_FILENAME}";

# Verify the ZIP file contains the expected version
if [ -f "$LOCAL_FILE_PATH" ]; then
    TMP_VERIFY_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_VERIFY_DIR"' EXIT

    unzip -q "$LOCAL_FILE_PATH" -d "$TMP_VERIFY_DIR" 2>/dev/null || true

    ZIP_PUPPETEER_VERSION=$(NODE_PATH="$TMP_VERIFY_DIR/nodejs/node_modules" node -e '
        try {
            const pkg = require("puppeteer-core/package.json");
            console.log(pkg.version);
        } catch (e) {
            console.error("");
        }
    ' 2>/dev/null || echo "")

    if [ -z "$ZIP_PUPPETEER_VERSION" ]; then
        echo "Error: Could not detect puppeteer-core version inside $LOCAL_FILE_PATH"
        echo "Please rebuild the ZIP with: npm run build"
        exit 1
    fi

    if [ "$ZIP_PUPPETEER_VERSION" != "$PUPPETEER_CORE_VERSION" ]; then
        echo "Error: Version mismatch!"
        echo "  - npm list reports: $PUPPETEER_CORE_VERSION"
        echo "  - ZIP file contains: $ZIP_PUPPETEER_VERSION"
        echo "Please rebuild the ZIP with: npm run build"
        exit 1
    fi

    echo "Verified ZIP contains puppeteer-core v$ZIP_PUPPETEER_VERSION"
    rm -rf "$TMP_VERIFY_DIR"
    trap - EXIT
fi

# Generate Layer description
LAYER_DESCRIPTION="puppeteer-core v$PUPPETEER_CORE_VERSION";

# Generate remote file name
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "no-git")
REMOTE_FILE_NAME="puppeteer-core-v${PUPPETEER_CORE_VERSION}-${COMMIT_SHA}.zip";
REMOTE_FILE_PATH="${STAGE}/${REMOTE_FILE_NAME}";

if [ ! -f "$LOCAL_FILE_PATH" ]; then
    echo "Error: $LOCAL_FILE_PATH not found. Run 'npm run build' first."
    exit 1
fi

# Determine if layer should be public
if [ -z "$PUBLIC" ]; then
    if [ "$STAGE" = "prod" ]; then
        PUBLIC=true
    else
        PUBLIC=false
    fi
fi

for REGION in $AWS_REGIONS; do
    BUCKET_NAME="$S3_BUCKET_NAME-$REGION";

    echo "Publish Layer $LAYER_NAME in $REGION (Stage: $STAGE, Public: $PUBLIC)"

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would upload $LOCAL_FILE_PATH to s3://$BUCKET_NAME/$REMOTE_FILE_PATH"
        echo "[DRY RUN] Would publish layer $LAYER_NAME in $REGION"
        if [ "$PUBLIC" = true ]; then
            echo "[DRY RUN] Would make layer version public"
        fi
        continue
    fi

    # Upload ZIP to S3 Bucket
    aws s3 cp "$LOCAL_FILE_PATH" "s3://$BUCKET_NAME/$REMOTE_FILE_PATH" $AWS_PROFILE_ARG --region "$REGION";

    # Publish new Layer Version
    NEW_VERSION_NUMBER=$(aws lambda publish-layer-version \
        --region "$REGION" \
        --layer-name "$LAYER_NAME" \
        --description "$LAYER_DESCRIPTION" \
        --content "S3Bucket=${BUCKET_NAME},S3Key=${REMOTE_FILE_PATH}" \
        --compatible-runtimes nodejs \
        --compatible-architectures x86_64 \
        --output text \
        --query Version \
        $AWS_PROFILE_ARG)

    echo "Published version $NEW_VERSION_NUMBER in $REGION"

    # Update Layer Permission
    if [ "$PUBLIC" = true ]; then
        aws lambda add-layer-version-permission \
            --region "$REGION" \
            --layer-name "$LAYER_NAME" \
            --statement-id "public-access-${NEW_VERSION_NUMBER}" \
            --action lambda:GetLayerVersion \
            --principal '*' \
            --version-number "$NEW_VERSION_NUMBER" \
            $AWS_PROFILE_ARG \
            > /dev/null
        echo "Made version $NEW_VERSION_NUMBER public in $REGION"
    fi
done
