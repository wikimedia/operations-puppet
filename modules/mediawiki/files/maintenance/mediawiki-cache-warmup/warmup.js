var fs = require( 'fs' ),
	path = require( 'path' ),
	url = require( 'url' ),
	exec = require( 'child_process' ).execSync,
	util = require( './util' ),

	arg, urlList;

// Read cli arguments
arg = {
	self: path.basename( process.argv[ 0 ] ) + ' ' + path.basename( process.argv[ 1 ] ),
	file: process.argv[ 2 ],
	mode: process.argv[ 3 ],
	spreadTarget: process.argv[ 4 ] || 'appservers.svc.codfw.wmnet',
	cloneCluster: process.argv[ 4 ] || 'appserver',
	cloneDC: process.argv[ 5 ] || 'codfw'
};

function usage() {
	console.log( '\nUsage: ' + arg.self + ' FILE MODE [spread_target|clone_cluster] [clone_dc]\n' +
		' - file          Path to a text file containing a newline-separated list of urls. Entries may use %server or %mobileServer.\n' +
		' - mode          One of:\n' +
		'                  "spread": distribute urls via load-balancer\n' +
		'                  "clone": send each url to each server\n' +
		'                  "clone-debug": send urls to debug server\n' +
		'\nExamples:\n' +
		' $ ' + arg.self + ' urls-cluster.txt spread appservers.svc.codfw.wmnet\n' +
		' $ ' + arg.self + ' urls-server.txt clone-debug\n' +
		' $ ' + arg.self + ' urls-server.txt clone appserver codfw\n'
	);
}

// Required
if ( !arg.file || !arg.mode ) {
	usage();
	process.exit( 1 );
}

if ( ![ 'spread', 'clone', 'clone-debug' ].includes( arg.mode ) ) {
	console.error( 'Error: Invalid mode' );
	usage();
	process.exit( 1 );
}

urlList = util.reduceTxtLines( fs.readFileSync( process.argv[ 2 ] ).toString().split( '\n' ) );

function createOptions( base, uri, target ) {
	var urlObject = url.parse( uri ),
		options = {};
	Object.assign( options, base );
	if ( target ) {
		// We want to make our request to the target host, but set the correct HTTP headers
		// Please note this won't work outside of production if you want to target appservers
		// directly.
		options.headers.Host = urlObject.host;
		// No point in passing through nginx.
		if ( urlObject.protocol === 'https:' ) {
			options.headers[ 'X-Forwarded-Proto' ] = 'https';
			urlObject.protocol = 'http:';
		}
		urlObject.host = urlObject.hostname = target;
		urlObject.uri = url.format( urlObject );
	}
	Object.assign( options, urlObject );
	return options;
}

/**
 * @param {Array|Object} dataset Work load for util.worker()
 * @param {Object} options
 * @param {number} [options.globalConcurrency=50] Maximum concurrency
 * @param {number} [options.groupConcurrency=globalConcurrency]
 * @param {string} [options.target] Destination host for HTTP request.
 *  If set, will be used for all requests. Otherwise, falls back to the dataset group key
 *  (e.g. "clone" mode). If no group is used (or group is main/debug), then target is not
 *  overridden goes via canonical instead (e.g. "clone-debug" mode).
 * @return {Promise}
 */
function doRequests( dataset, options ) {
	var baseOptions, workerConfig;
	baseOptions = {
		headers: {
			'User-Agent': 'node-wikimedia-warmup; Contact: Krinkle'
		}
	};
	if ( arg.mode === 'clone-debug' ) {
		baseOptions.headers[ 'X-Wikimedia-Debug' ] = '1';
	}

	workerConfig = {
		globalConcurrency: options.globalConcurrency || 50,
		groupConcurrency: options.groupConcurrency
	};

	return util.worker(
		workerConfig,
		dataset,
		function ( uri, group ) {
			var target = options.target || ( group !== 'main' && group !== 'debug' ? group : null ),
				reqOptions = createOptions( baseOptions, uri, target );
			console.log( `[${new Date().toISOString()}] Request ${uri} (${group})` );
			return util.fetchUrl( reqOptions );
		}
	).then( function ( stats ) {
		console.log(
			`Statistics:
	- timing: min = ${stats.timing.min / 1e9}s | max = ${stats.timing.max / 1e9}s | avg = ${stats.timing.avg / 1e9}s | total = ${Math.round( stats.timing.total / 1e9 )}s
	- concurrency: min = ${stats.count.min} | max = ${stats.count.max} | avg = ${Math.round( stats.count.avg )}`
		);
		console.log( 'Slowest 5:\n' + stats.timing.wos.reverse().map( obj => {
			let duration = ( obj.duration / 1e9 ).toFixed( 3 );
			return ` - ${duration}s (${obj.group}) ${obj.task}`;
		} ).join( '\n' ) );
		console.log( 'Done!' );
	} ).catch( function ( err ) {
		console.log( err );
		process.exit( 1 );
	} );
}

util.expandUrlList( urlList ).then( function ( urlList ) {
	if ( arg.mode === 'clone' ) {
		let confctlCmd, confctlData, dataset;

		// This mode runs each of the listed urls on each of the servers.
		// This is meant for warming up APC caches on each app server.
		confctlCmd = 'confctl tags \'dc=' + arg.cloneDC + ',cluster=' + arg.cloneCluster + ',service=apache2\' --action get all';
		confctlData = JSON.parse( exec( confctlCmd ) );
		dataset = {};
		for ( let key in confctlData ) {
			if ( confctlData[ key ].pooled === 'yes' ) {
				// Randomize order. Must make a copy as otherwise, each group
				// will be working on the same list.
				dataset[ key ] = util.shuffle( urlList.slice() );
			}
		}
		console.log( '[clone] Sending ' + urlList.length + ' urls to ' + Object.keys( dataset ).length + ' servers.' );

		doRequests( dataset, {
			globalConcurrency: 2500,
			groupConcurrency: 150
		} );
	} else if ( arg.mode === 'spread' ) {
		console.log( '[spread] Sending ' + urlList.length + ' urls to the cluster.' );
		let dataset = {
			// Randomize order
			[ arg.spreadTarget ]: util.shuffle( urlList )
		};
		doRequests( dataset, {
			target: arg.spreadTarget,
			globalConcurrency: 1000
		} );
	} else {
		// mode: clone-debug
		let dataset = {
			// Randomize order
			debug: util.shuffle( urlList )
		};
		doRequests( dataset, {
			globalConcurrency: 100
		} );
	}
} );
