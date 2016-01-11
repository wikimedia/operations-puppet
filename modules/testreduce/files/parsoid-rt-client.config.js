/**
 * Configuration for parsoid-rt-testing testreduce client.js script
 */
'use strict';

(function() {
	if (typeof module === 'object') {
		module.exports = {
			server: {
				// The address of the master HTTP server (for getting titles and posting results) (no protocol)
				host: 'localhost',

				// The port where the server is running
				port: 8002,
			},

			// A unique name for this client (optional) (URL-safe characters only)
			clientName: 'Parsoid RT testing client',

			opts: {
				// By default, use the same configuration as the testing Parsoid server.
				parsoidConfig: '/srv/testreduce/parsoid-rt-client.rttest.localsettings.js',

				// The parsoid API to use. If null, create our own server
				parsoidURL: null,
			},

			runTest: require('/usr/lib/parsoid/src/tests/testreduce/rtTestWrapper.js').runRoundTripTest,

			// Path of the git repo
			gitRepoPath: '/usr/lib/parsoid/src',
		};
	}
}());
