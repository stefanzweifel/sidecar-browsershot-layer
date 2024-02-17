# sidecar-browsershot-layer

An AWS Lambda Layer containing `puppeteer-core`; mainly used by [sidecar-browsershot](https://github.com/stefanzweifel/sidecar-browsershot), but feel free to use it in your projects as well.

The latest version of `sidecar-browsershot-layer` contains the following dependencies and their versions:

- `puppeteer-core`: v22.0.0

This layer works great in combination with [shelfio/chrome-aws-lambda-layer](https://github.com/shelfio/chrome-aws-lambda-layer) to run Chromium on AWS Lambda.

## Available Regions

We've deployed this layer to a number of AWS regions. Use the ARN that matches your region from the list below.

- `arn:aws:lambda:us-east-1:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:us-east-2:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:us-west-1:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:us-west-2:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:ca-central-1:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:eu-central-1:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:eu-west-1:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:eu-west-2:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:eu-west-3:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:eu-north-1:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:ap-northeast-1:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:ap-northeast-2:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:ap-southeast-1:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:ap-southeast-2:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:ap-south-1:821527532446:layer:sidecar-browsershot-layer:2`
- `arn:aws:lambda:sa-east-1:821527532446:layer:sidecar-browsershot-layer:2`

## Development
This repository holds some simple bash scripts to help with the development of this layer. Most script require the [aws CLI](https://aws.amazon.com/cli/) to be installed and configured.

### Creating new layer zip file
An AWS Layer is simply a ZIP file containing code. In this project the layer contains a `node_modules`-folder containing the required dependencies to run `puppeteer-core`.

Run the following commands in your terminal to install the dependencies and create the layer ZIP file.

```shell
npm install;
sh bin/create-layer-zip.sh;
```

A `dist/sidecar-browsershot-layer.zip` file should have been created.

### Publish new layer version
Run the following command to publish a new layer version to all supported regions using the provided AWS CLI profile.
The `dist/sidecar-browsershot-layer.zip`-file will be uploaded to S3 and used as a layer.

```shell
sh bin/publish-layer.sh <aws-cli-profile>
```

### Create Buckets for supported regions
Run the following command to create AWS S3 buckets in the supported regions.
(You probably only ever have to run this command if new regions should be added)

```shell
sh bin/create-buckets.sh <aws-cli-profile>
```

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
