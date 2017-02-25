var fs = require( 'fs' ),
	http = require( 'http' ),
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
		' $ ' + arg.self + ' urls-server.txt clone appservers codfw\n'
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
 * @param {string[]} urlList
 * @param {Object} options
 * @param {number} [options.concurrency=50] Maximum concurrency
 * @param {string} [options.target=undefined] Custom destination host for HTTP request
 */
function doRequests( urlList, options ) {
	var targetStr = options.target || 'debug';
	util.expandUrlList( urlList ).then( function ( urls ) {
		var baseOptions, workerConfig;
		baseOptions = {
			agent: new http.Agent( { keepAlive: true } ),
			headers: {
				'User-Agent': 'node-wikimedia-warmup; Contact: Krinkle'
			}
		};
		workerConfig = {
			concurrency: options.concurrency || 50
		};

		if ( arg.mode === 'clone-debug' ) {
			baseOptions.headers[ 'X-Wikimedia-Debug' ] = '1';
		}

		return util.worker(
			workerConfig,
			// Randomize order
			util.shuffle( urls ),
			function ( uri ) {
				var reqOptions = createOptions( baseOptions, uri, options.target );
				console.log( `[${new Date().toISOString()}] Request ${uri} (${targetStr})` );
				return util.fetchUrl( reqOptions );
			}
		);
	} ).then( function ( stats ) {
		// TODO: manage this better in case we don't have just one download going on
		console.log(
			`Statistics for ${targetStr}:
	- timing: min = ${stats.timing.min / 1e9}s | max = ${stats.timing.max / 1e9}s | avg = ${stats.timing.avg / 1e9}s | total = ${Math.round( stats.timing.total / 1e9 )}s
	- concurrency: min = ${stats.count.min} | max = ${stats.count.max} | avg = ${Math.round( stats.count.avg )}
	`
		);
		console.log( 'Done!' );
		return true;
	} ).catch( function ( err ) {
		console.log( err );
		return false;
	} );
}

if ( arg.mode === 'clone' ) {
	let confctlCmd, confctlData, serverList;

	// This mode runs each of the listed urls on each of the servers.
	// This is meant for warming up APC caches on each app server.
	confctlCmd = 'confctl tags \'dc=' + arg.cloneDC + ',cluster=' + arg.cloneCluster + ',service=apache2\' --action get all';
	confctlData = JSON.parse( exec( confctlCmd ) );
	serverList = [];
	for ( let key in confctlData ) {
		if ( confctlData[ key ].pooled === 'yes' ) {
			serverList.push( key );
		}
	}

	for ( let server of serverList ) {
		// spawn the downloader for the single job
		console.log( 'Starting requests for server ' + server );
		doRequests( urlList, {
			target: server,
			concurrency: 300
		} );
	}
} else if ( arg.mode === 'spread' ) {
	doRequests( urlList, {
		target: arg.spreadTarget,
		concurrency: 500
	} );
} else {
	// mode: clone-debug
	doRequests( urlList, {
		concurrency: 50
	} );
}
