exports.handler = async (event) => {
    try {
        const puppeteer = require('puppeteer-core');
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
