exports.handler = async (event) => {
    try {
        // Lambda starts Node with --no-experimental-require-module and
        // puppeteer-core is ESM-only, so require() fails. ESM resolution
        // also ignores NODE_PATH, so import the layer file by absolute path.
        await import('/opt/nodejs/node_modules/puppeteer-core/lib/puppeteer/puppeteer-core.js');
        const pkg = require('puppeteer-core/package.json');

        return {
            ok: true,
            puppeteerCoreVersion: pkg.version
        };
    } catch (e) {
        return {
            ok: false,
            error: e.message
        };
    }
};
