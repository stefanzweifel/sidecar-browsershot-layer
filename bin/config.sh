#!/bin/sh

# Set defaults
export STAGE="${STAGE:-prod}"
export AWS_PROFILE_ARG=""
export AWS_REGIONS="${AWS_REGIONS:-us-east-1 us-east-2 us-west-1 us-west-2 ca-central-1 eu-central-1 eu-west-1 eu-west-2 eu-west-3 eu-north-1 ap-northeast-1 ap-northeast-2 ap-southeast-1 ap-southeast-2 ap-south-1 sa-east-1}"
export CANARY_REGION="${CANARY_REGION:-us-east-1}"
export LAYER_NAME_BASE="sidecar-browsershot-layer"
export S3_BUCKET_BASE="wnx-sidecar-layers"
export LOCAL_FILENAME="sidecar-browsershot-layer.zip"

# Function to parse arguments
parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --stage)
                STAGE="$2"
                shift 2
                ;;
            --profile)
                AWS_PROFILE_ARG="--profile $2"
                shift 2
                ;;
            --regions)
                AWS_REGIONS="$2"
                shift 2
                ;;
            --canary-region)
                CANARY_REGION="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --public)
                PUBLIC="$2"
                shift 2
                ;;
            *)
                # For backward compatibility or extra positional args
                if [ -z "$PROFILE" ]; then
                    PROFILE="$1"
                    AWS_PROFILE_ARG="--profile $1"
                fi
                shift
                ;;
        esac
    done

    # Validate stage
    if [ "$STAGE" != "prod" ] && [ "$STAGE" != "test" ]; then
        echo "Error: --stage must be either 'prod' or 'test'."
        exit 1
    fi

    # Compute derived names
    if [ "$STAGE" = "test" ]; then
        export LAYER_NAME="${LAYER_NAME_BASE}-test"
        export S3_BUCKET_NAME="${S3_BUCKET_BASE}-test"
    else
        export LAYER_NAME="${LAYER_NAME_BASE}"
        export S3_BUCKET_NAME="${S3_BUCKET_BASE}"
    fi
}
