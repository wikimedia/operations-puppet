/**
 * Configuration for the visual diffing service.
 */
'use strict';

if (typeof module === 'object') {
    module.exports = {
        server: {
            host: 'localhost',
            port: 8002,
        },
        opts: {
            viewportWidth: 1920,
            viewportHeight: 1080,

            wiki: 'enwiki',
            title: 'Main_Page',
            filePrefix: null,
            outdir: null,

            html1: {
                name: 'php',
                dumpHTML: false,
                postprocessorScript: '/srv/visualdiff/lib/php_parser.postprocess.js',
                injectJQuery: false,
            },
            // HTML2 generator options
            html2: {
                name: 'parsoid',
                server: 'http://localhost:8000',
                dumpHTML: false,
                postprocessorScript: '/srv/visualdiff/lib/parsoid.postprocess.js',
                stylesYamlFile: '/srv/visualdiff/lib/parsoid.custom_styles.yaml',
                injectJQuery: true,
            },

            // Engine for image diffs, may be resemble or uprightdiff
            diffEngine: 'uprightdiff',

            // UprightDiff options
            uprightDiffSettings: {
                binary: '/usr/local/bin/uprightdiff'
            },
        }
    };
}
