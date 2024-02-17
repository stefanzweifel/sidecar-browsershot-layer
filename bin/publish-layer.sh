#!/usr/bin/sh

source "$(dirname "$0")/config.sh"

PROFILE=$1;

if [ -n "$PROFILE" ]
then
    echo "Using Profile ${PROFILE} to create Lambda layer.";
else
    echo "No Profile provided. Abort.";
    exit 1;
fi

# Extract exact dependency versions
PUPPETEER_CORE_VERSION=$(npm list --json | jq -r '.dependencies."puppeteer-core".version');

# Generate Layer description
LAYER_DESCRIPTION="puppeteer-core v$PUPPETEER_CORE_VERSION";

# Generate remote file name
REMOTE_FILE_NAME="sidecar-browsershot-layer__puppeteer-core-v${PUPPETEER_CORE_VERSION}.zip";
REMOTE_FILE_PATH="sidecar-browsershot-layer/${REMOTE_FILE_NAME}";

LOCAL_FILE_PATH="dist/${LOCAL_FILENAME}";

for REGION in $AWS_REGIONS; do
    BUCKET_NAME="$S3_BUCKET_NAME-$REGION";

    echo "Publish Layer in $REGION";

    # Uplaod ZIP to S3 Bucket
    aws configure set region $REGION;
    aws s3 cp $LOCAL_FILE_PATH s3://$BUCKET_NAME/$REMOTE_FILE_PATH --profile=$PROFILE;

    # Publish new Layer Version
    NEW_VERSION_NUMBER=$(aws lambda publish-layer-version \
        --region $REGION \
        --layer-name $LAYER_NAME \
        --description "$LAYER_DESCRIPTION" \
        --content "S3Bucket=${BUCKET_NAME},S3Key=${REMOTE_FILE_PATH}" \
        --compatible-runtimes nodejs \
        --compatible-architectures x86_64 \
        --output text \
        --query Version \
        --profile $PROFILE)

    # Update Layer Permission
    aws lambda add-layer-version-permission \
        --region $REGION \
        --layer-name $LAYER_NAME \
        --statement-id sid1 \
        --action lambda:GetLayerVersion \
        --principal '*' \
        --version-number $NEW_VERSION_NUMBER \
        --profile=$PROFILE
done
