#!/bin/sh

source "$(dirname "$0")/config.sh"

parse_args "$@"

for REGION in $AWS_REGIONS; do
    BUCKET_NAME="$S3_BUCKET_NAME-$REGION";

    echo "Ensuring S3 bucket $BUCKET_NAME exists in $REGION";

    # Check if bucket exists
    if aws s3api head-bucket --bucket "$BUCKET_NAME" $AWS_PROFILE_ARG --region "$REGION" 2>/dev/null; then
        echo "Bucket $BUCKET_NAME already exists and is accessible."
    else
        echo "Creating bucket $BUCKET_NAME in $REGION..."
        # Buckets in us-east-1 don't need LocationConstraint
        if [ "$REGION" = "us-east-1" ]; then
            aws s3api create-bucket \
                --bucket=$BUCKET_NAME \
                $AWS_PROFILE_ARG \
                --region=$REGION
        else
            aws s3api create-bucket \
                --bucket=$BUCKET_NAME \
                $AWS_PROFILE_ARG \
                --region=$REGION \
                --create-bucket-configuration LocationConstraint=$REGION
        fi
    fi
done
