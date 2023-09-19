#!/bin/sh

# AWS Lambda Layer Name
export LAYER_NAME="sidecar-browsershot-layer";

# Base S3 Bucket Name
export S3_BUCKET_NAME="wnx-sidecar-layers";

# Supported AWS Regions
export AWS_REGIONS="us-east-1 us-east-2 us-west-1 us-west-2 ca-central-1 eu-central-1 eu-west-1 eu-west-2 eu-west-3 eu-north-1 ap-northeast-1 ap-northeast-2 ap-southeast-1 ap-southeast-2 ap-south-1 sa-east-1";

export LOCAL_FILENAME="sidecar-browsershot-layer.zip";
