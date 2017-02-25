var fs = require( 'fs' ),
	http = require( 'http' ),
	path = require( 'path' ),
	url = require( 'url' ),
	exec = require('child_process').execSync,
	util = require( './util' ),

	mode, urlList;

function usage() {
	console.log( '\nUsage: node ' + path.basename( process.argv[ 1 ] ) + ' FILE MODE [spread_target|clone_cluster,clone_dc]\n' );
	console.log( ' - file \tPath to a text file containing newline-separated list of urls, may contain %server or %mobileServer.' );
	console.log( ' - mode \tOne of:\n   \t\t"spread": distribute urls via load-balancer\n   \t\t"clone": send each url to each server\n   \t\t"clone-debug": send urls to debug server' );
}

if ( !process.argv[ 2 ] || !process.argv[ 3 ] ) {
	usage();
	process.exit( 1 );
}

// Process cli arguments
mode = process.argv[ 3 ];
if ( mode !== 'spread' && mode !== 'clone' && mode !== 'clone-debug' ) {
	console.error( 'Error: Invalid mode' );
	usage();
	process.exit( 1 );
}

urlList = util.reduceTxtLines( fs.readFileSync( process.argv[ 2 ] ).toString().split( '\n' ) );

function createOptions(base, uri, target) {
	var options = {};
	Object.assign(options, base);
	var urlObject = url.parse(uri);
	if ( !target ) {
		// We want to make our request to the target host, but set the correct HTTP headers
		// Please note this won't work outside of production if you want to target appservers
		// directly.
		options.headers['Host'] = urlObject.host;
		// No point in passing through nginx.
		if (urlObject.protocol == 'https:') {
			options.headers['X-Forwarded-Proto'] = 'https';
			urlObject.protocol = 'http:';
		}
		urlObject.host = urlObject.hostname = target;
		urlObject.uri = url.format(urlObject);
	}
	Object.assign(options, urlObject);
	return options;
}

function doRequests( urlList, target ) {
	var targetStr = target || 'debug';
	util.expandUrlList( urlList ).then( function ( urls ) {
		var baseOptions, workerConfig;
		baseOptions = {
			agent: new http.Agent( { keepAlive: true } ),
			headers: {
				'User-Agent': 'node-wikimedia-warmup; Contact: Krinkle'
			}
		};
		workerConfig = {
			globalConcurrency: 500
		};

		if ( mode === 'clone-debug' ) {
			baseOptions.headers[ 'X-Wikimedia-Debug' ] = '1';
			workerConfig.globalConcurrency = 50;
		}

		return util.worker(
			workerConfig,
			// Randomize order
			util.shuffle( urls ),
			function ( uri ) {
				var options = createOptions( baseOptions, uri, target );
				console.log( `[${new Date().toISOString()}] Request ${uri} (${targetStr})` );
				return util.fetchUrl( options );
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



if ( mode === 'clone' ) {
	// Mode: clone
	var cluster = process.argv[4]? process.argv[4] : 'appserver';
	var dc = process.argv[5]? process.argv[5] : 'codfw';
	// This mode runs each of the listed urls on each of the servers.
	// This is meant for warming up APC caches on each app server.
	var confctlCmd = "confctl tags 'dc=" + dc + ',cluster=' + cluster + ",service=apache2' --action get all";
	var confctlData = JSON.parse( exec( confctlCmd ) );
	var serverList = [];
	for (var key in confctlData) {
			if ( confctlData[key].pooled === 'yes' ) {
				serverList.push(key);
			}
	}

	for (let server of serverList) {
		// spawn the downloader for the single job
		console.log('Starting requests for server ' + server);
		doRequests(urlList, server);
	}
} else if (mode === 'spread') {
	target = process.argv[4]? process.argv[4] : 'appservers.svc.codfw.wmnet';
	doRequests(urlList, target);
} else {
	// mode: clone-debug
	doRequests(urlList);
}
