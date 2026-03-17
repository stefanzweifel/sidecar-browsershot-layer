# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AWS Lambda Layer packaging `puppeteer-core` for use with [sidecar-browsershot](https://github.com/stefanzweifel/sidecar-browsershot). The layer is a ZIP file containing `node_modules/puppeteer-core` in the Lambda-expected `nodejs/` directory structure. It is published to 16 AWS regions.

Works in combination with [shelfio/chrome-aws-lambda-layer](https://github.com/shelfio/chrome-aws-lambda-layer) to run Chromium on AWS Lambda.

## Commands

```shell
npm ci                # Install dependencies (use ci, not install, for reproducible builds)
npm run build         # Build the layer ZIP → dist/sidecar-browsershot-layer.zip
npm run smoke:test    # Verify the ZIP structure and that puppeteer-core can be required
```

### AWS deployment (requires aws CLI, jq, and configured AWS credentials)

```shell
bin/canary-deploy.sh --stage test --profile <profile>   # Deploy test layer + canary Lambda to us-east-1
bin/canary-invoke.sh --stage test --profile <profile>    # Invoke canary Lambda to verify layer works
bin/publish-layer.sh --stage prod --profile <profile>    # Publish layer to all 16 regions
bin/get-layer-arns.sh --stage prod --profile <profile>   # Fetch latest ARNs from AWS
bin/update-readme-arns.sh --stage prod --profile <profile>  # Update README ARN list
```

All `bin/` scripts accept `--stage <test|prod>`, `--profile <name>`, `--regions "<list>"`, `--canary-region <region>`, and `--dry-run`. Shared configuration lives in `bin/config.sh`.

## Architecture

- **`bin/config.sh`** — Shared configuration (regions, naming conventions, argument parsing) sourced by all other scripts.
- **`bin/create-layer-zip.sh`** — Build script: strips TypeScript types, `.d.ts` files, READMEs, and other unnecessary files from `node_modules`, then creates a compressed ZIP under `dist/` with the `nodejs/node_modules/` directory structure that Lambda expects.
- **`bin/smoke-test-zip.sh`** — Extracts the ZIP to a temp directory and verifies `puppeteer-core` can be `require()`'d.
- **`bin/canary/handler.js`** — Minimal Lambda handler that requires `puppeteer-core` and returns its version. Used by `canary-deploy.sh` and `canary-invoke.sh` to validate the layer in a real AWS environment.
- **`bin/publish-layer.sh`** — Uploads the ZIP to per-region S3 buckets, publishes as a Lambda layer version, and optionally makes it public.

## Release Process

Releases are triggered by pushing a git tag matching `v*`. The GitHub Actions release workflow (`release.yml`) runs:

1. **Build** — creates artifact, runs smoke test
2. **Canary test** — deploys to `test` namespace in `us-east-1`, invokes canary Lambda (requires "testing" environment approval)
3. **Production deploy** — publishes to all regions under `prod` namespace (requires "production" environment approval)
4. **Update README** — auto-commits updated ARNs to `main`

Version format for tags: `v<puppeteer-version>-<date>` (e.g., `v24.37.5-2026-03-07`). Use `bin/release-version.sh` to generate the version string.

## Key Constraints

- Node.js 22 / npm 10 (see `.nvmrc` and `package.json` engines)
- Lambda runtime: `nodejs22.x`, architecture: `x86_64`
- The sole production dependency is `puppeteer-core` — the entire purpose of this repo is to package it as a Lambda layer
- Layer naming: `sidecar-browsershot-layer` (prod) / `sidecar-browsershot-layer-test` (test)
- S3 buckets: `wnx-sidecar-layers-<region>` (prod) / `wnx-sidecar-layers-test-<region>` (test)
