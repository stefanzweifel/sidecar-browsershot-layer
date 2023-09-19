#!/usr/bin/sh

source "$(dirname "$0")/config.sh"

PROFILE=$1;

for REGION in $AWS_REGIONS; do
    BUCKET_NAME="$S3_BUCKET_NAME-$REGION";

    aws configure set region $REGION;
    aws s3api create-bucket \
        --bucket=$BUCKET_NAME \
        --profile=$PROFILE \
        --region=$REGION \
        --create-bucket-configuration LocationConstraint=$REGION;
done
