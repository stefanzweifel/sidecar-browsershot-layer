#!/bin/sh

source "$(dirname "$0")/config.sh"

rm -rf "./dist/$LOCAL_FILENAME";

# Delete not used TypeScript Types
npx del-cli "./node_modules/**/@types/**" \
  "./node_modules/**/*.d.ts" \
  "./node_modules/**/.yarn-integrity" \
  "./node_modules/**/.bin" \
  "./node_modules/**/README.md" \
  "./node_modules/agent-base/src/*.ts" \
  "./**/.DS_Store"

# Define the target folder name
TARGET_FOLDER="nodejs"

# Remove previous folder
rm -rf "./dist/$TARGET_FOLDER"

# Create the target folder if it doesn't exist
mkdir -p "./dist/$TARGET_FOLDER"

# Copy node_modules files to nested folder
cp -R "./node_modules" "./dist/$TARGET_FOLDER/node_modules"

# Change the working directory to the parent directory of node_modules
cd "./dist/"

# Zip the contents of node_modules and place it inside the target folder
zip -r $LOCAL_FILENAME -9 "./$TARGET_FOLDER/node_modules/"

# Return to the original directory
cd -

# Delete temporary folder name
rm -rf "./dist/$TARGET_FOLDER"
