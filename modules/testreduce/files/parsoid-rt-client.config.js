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

				// FIXME: Weird! rt-testing code, for some reason, uses the Parsoid config too.
				// It is posting requests to Parsoid to run tests, so not sure why it needs the
				// config. Refactor that code to eliminate this dependency, if possible.
				parsoidConfig: '/srv/parsoid/src/tests/testreduce/parsoid-rt-client.rttest.localsettings.js',
			},

			runTest: require('/srv/parsoid/src/tests/testreduce/rtTestWrapper.js').runRoundTripTest,

			// Path of the git repo
			gitRepoPath: '/srv/parsoid/src',
		};
	}
}());
