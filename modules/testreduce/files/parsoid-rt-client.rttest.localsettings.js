/*
 * This is a sample configuration file.
 *
 * Copy this file to localsettings.js and edit that file to fit your needs.
 *
 * Also see the file server.js for more information.
 */
'use strict';

exports.setup = function(parsoidConfig) {
	// The URL of your MediaWiki API endpoint.
	if (process.env.PARSOID_MOCKAPI_URL) {
		parsoidConfig.setMwApi({
			prefix: 'customwiki',
			domain: 'customwiki',
			uri: process.env.PARSOID_MOCKAPI_URL,
		});
	}

	// Use the API backends directly without hitting the text varnishes.
	// API requests are not cacheable anyway.
	parsoidConfig.defaultAPIProxyURI = 'http://10.2.2.22';

	// Turn on the batching API
	parsoidConfig.useBatchAPI = true;

	// Use selective serialization (default false)
	parsoidConfig.useSelser = true;

	// The URL of your LintBridge API endpoint
	//  parsoidConfig.linterAPI = 'http://lintbridge.wmflabs.org/add';

	// Set rtTestMode to true for round-trip testing
	parsoidConfig.rtTestMode = true;

	// Direct logs to logstash via bunyan and gelf-stream.
	var LOGSTASH_HOSTNAME = 'logstash1003.eqiad.wmnet';
	var LOGSTASH_PORT = 12201;
	parsoidConfig.loggerBackend = {
		name: ':Logger.bunyan/BunyanLogger',
		options: {
			// Replicate log to disk and to Logstash.
			// Use a parsoid-tests prefix to distinguish from
			// production parsoid logs.
			name: 'parsoid-tests',
			streams: [
				{
					stream: process.stdout,
					level: 'debug',
				},
				{
					type: 'raw',
					stream: require('gelf-stream').forBunyan(LOGSTASH_HOSTNAME, LOGSTASH_PORT),
					level: 'warn',
				},
			],
		},
	};

	// Set to true to enable Performance timing
	parsoidConfig.useDefaultPerformanceTimer = false;
	// Peformance timing options for testing
	parsoidConfig.performanceTimer = {
		count: function() {},
		timing: function() {},
	};

	// Sample verbose logs
	parsoidConfig.loggerSampling = [
		['warning/dsr/inconsistent', 5],
		['warning/empty/li', 20],
		['warning/empty/tr', 1],
		[/^warning\/empty\//, 5],
	];
};
