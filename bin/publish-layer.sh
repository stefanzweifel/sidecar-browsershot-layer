#!/bin/sh

source "$(dirname "$0")/config.sh"

parse_args "$@"

# For backward compatibility, if $1 was PROFILE and not starting with --
if [ -n "$PROFILE" ] && [ -z "$AWS_PROFILE_ARG" ]; then
    AWS_PROFILE_ARG="--profile $PROFILE"
fi

# Extract exact dependency versions
PUPPETEER_CORE_VERSION=$(npm list --json | jq -r '.dependencies."puppeteer-core".version');

# Generate Layer description
LAYER_DESCRIPTION="puppeteer-core v$PUPPETEER_CORE_VERSION";

# Generate remote file name
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "no-git")
REMOTE_FILE_NAME="puppeteer-core-v${PUPPETEER_CORE_VERSION}-${COMMIT_SHA}.zip";
REMOTE_FILE_PATH="${STAGE}/${REMOTE_FILE_NAME}";

LOCAL_FILE_PATH="dist/${LOCAL_FILENAME}";

if [ ! -f "$LOCAL_FILE_PATH" ]; then
    echo "Error: $LOCAL_FILE_PATH not found. Run bin/create-layer-zip.sh first."
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
