# sidecar-browsershot-layer

An AWS Lambda Layer containing `puppeteer-core`; mainly used by [sidecar-browsershot](https://github.com/stefanzweifel/sidecar-browsershot), but feel free to use it in your projects as well.

The latest version of `sidecar-browsershot-layer` contains the following dependencies and their versions:

- `puppeteer-core`: v22.0.0

This layer works great in combination with [shelfio/chrome-aws-lambda-layer](https://github.com/shelfio/chrome-aws-lambda-layer) to run Chromium on AWS Lambda.

## Available Regions

We've deployed this layer to a number of AWS regions. Use the ARN that matches your region from the list below.

- `arn:aws:lambda:us-east-1:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:us-east-2:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:us-west-1:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:us-west-2:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:ca-central-1:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:eu-central-1:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:eu-west-1:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:eu-west-2:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:eu-west-3:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:eu-north-1:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:ap-northeast-1:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:ap-northeast-2:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:ap-southeast-1:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:ap-southeast-2:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:ap-south-1:821527532446:layer:sidecar-browsershot-layer:3`
- `arn:aws:lambda:sa-east-1:821527532446:layer:sidecar-browsershot-layer:3`

## Development
This repository holds bash scripts to help with the development and deployment of this layer. Most scripts require the [aws CLI](https://aws.amazon.com/cli/) to be installed and [jq](https://stedolan.github.io/jq/) for JSON parsing.

### Common Script Arguments
Most scripts in `bin/` accept the following arguments:
- `--stage <test|prod>`: Target namespace (default: `prod`). Affects layer and bucket names.
- `--profile <name>`: AWS CLI profile to use.
- `--regions "<list>"`: Space-separated list of regions.
- `--canary-region <region>`: Region used for canary testing (default: `us-east-1`).

### Creating new layer zip file
An AWS Layer is a ZIP file containing code. This layer contains a `node_modules` folder with `puppeteer-core`.

```shell
npm install
npm run build
```

### Local Smoke Test
Verify the generated ZIP structure and that `puppeteer-core` can be required.

```shell
npm run smoke:test
```

### AWS Canary Test
Deploy the layer to the `test` namespace in the canary region, then create and invoke a small Lambda function to verify it works in a real AWS environment.

```shell
# Deploy canary (publishes test layer and updates canary Lambda)
bin/canary-deploy.sh --stage test --profile your-profile

# Invoke canary and check results
bin/canary-invoke.sh --stage test --profile your-profile
```

### Publish new layer version
Publish the layer to all supported regions.

```shell
# Deploy to test namespace (private by default)
bin/publish-layer.sh --stage test --profile your-profile

# Deploy to prod namespace (public by default)
bin/publish-layer.sh --stage prod --profile your-profile
```

### Create Buckets for supported regions
Create AWS S3 buckets in the supported regions if they don't exist.

```shell
bin/create-buckets.sh --stage prod --profile your-profile
```

## CI/CD Workflow
This project uses GitHub Actions for automation.

### CI (Pull Requests / Push to main)
- Builds the layer ZIP.
- Runs the local smoke test.

### Release (Tags `v*`)
1. **Build**: Creates the production artifact.
2. **Test Canary**: Deploys the artifact to the `test` namespace in `us-east-1` and runs the canary invoke test.
3. **Production Deployment**: After manual approval in GitHub Environments (`production`), publishes the layer to all supported regions under the `prod` namespace.

#### Setup Requirements
- **AWS OIDC**: GitHub Actions should be configured to authenticate via OIDC.
- **Secrets**:
  - `AWS_ROLE_ARN`: The ARN of the IAM role for GitHub Actions to assume.
- **IAM Permissions**: The role needs permissions for S3 (PutObject), Lambda (PublishLayerVersion, AddLayerVersionPermission, Create/Update/Invoke Function), and IAM (GetRole).
- **Canary Role**: A role named `sidecar-browsershot-layer-canary-role` must exist for the canary Lambda function to use.

## Changelog

Please see [CHANGELOG](CHANGELOG.md) for more information on what has changed recently.

## Contributing

Please see [CONTRIBUTING](.github/CONTRIBUTING.md) for details.

## Security Vulnerabilities

Please review [our security policy](../../security/policy) on how to report security vulnerabilities.

## Credits

- [Stefan Zweifel](https://github.com/stefanzweifel)
- [All Contributors](../../contributors)

## License

The MIT License (MIT). Please see [License File](LICENSE.md) for more information.
