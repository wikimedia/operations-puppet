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
				// Talk to the existing Parsoid service.
				// No need to spin up our own private Parsoid service.
				parsoidURL: 'http://localhost:8142',
			},

			runTest: require('/usr/lib/parsoid/src/tests/testreduce/rtTestWrapper.js').runRoundTripTest,

			// Path of the git repo
			gitRepoPath: '/usr/lib/parsoid/src',
		};
	}
}());
