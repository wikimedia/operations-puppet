/**
 * Configuration for parsoid-rt-testing testreduce client.js script
 * Use uprightdiff for image diffs
 */
'use strict';

if (typeof module === 'object') {
	module.exports = {
		server: {
			// The address of the master HTTP server (for getting titles and posting results) (no protocol)
			host: 'localhost',

			// The port where the server is running
			port: 8011
		},
		opts: {
			viewportWidth: 1920,
			viewportHeight: 1080,

			wiki: 'enwiki',
			title: 'Main_Page',
			filePrefix: null,
			quiet: true,
			outdir: '/srv/visualdiff/pngs', // Share with clients

			// HTML1 generator options
			html1: {
				name: 'php',
				dumpHTML: false,
				postprocessorScript: '/srv/visualdiff/lib/php_parser.postprocess.js',
				injectJQuery: false,
			},
			// HTML2 generator options
			html2: {
				name: 'parsoid',
				server: 'http://parsoid.svc.eqiad.wmnet:8000',
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
		},
	};
}
