var fs = require( 'fs' ),
	http = require( 'http' ),
	path = require( 'path' ),
	url = require( 'url' ),

	util = require( './util' ),

	mode, urlList;

function usage() {
	console.log( '\nUsage: node ' + path.basename( process.argv[ 1 ] ) + ' [file] [mode]\n' );
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

if ( mode === 'clone' ) {
	// Mode: clone
	// This mode runs each of the listed urls on each of the servers.
	// This is meant for warming up APC caches on each app server.

	// TODO:
	// - Fetch list of servers
	//   Either from puppet, appserver from conftool-data/nodes/eqiad.yaml
	//   or, from confd, using:
	//   `sudo -i confctl --quiet select 'dc=codfw,cluster=appserver,service=apache2,pooled=yes' get`
	//   Return format:
	//     {"mw0000.codfw.wmnet": {"pooled": "yes", ..}, ..}
	//     {"mw0001.codfw.wmnet": {"pooled": "yes", ..}, ..}
	// - Clone url list once for each server, swap hostname,
	//   and add Host header. In format for util.worker().
	// - Configure groupConcurrency for util.worker().
	console.error( 'Mode "clone" not yet implemented.' );
	process.exit( 1 );
}

// Mode: spread or clone-debug
// This mode takes a list of urls and sends it to a cluster.
// This is meanta for warming up a shared service like Memcached or SQL.

// TODO: In mode 'spread', override host destination from the production
// wiki hostname, to e.g. text-lb.eqiad.wikimedia.org or text-lb.codfw.wikimedia.org.
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

	if ( mode === 'spread' ) {
		console.error( 'Mode "spread" not yet implemented.' );
		process.exit( 1 );
	}

	return util.worker(
		workerConfig,
		// Randomize order
		util.shuffle( urls ),
		function ( uri ) {
			var options = Object.assign(
				Object.create( baseOptions ),
				url.parse( uri )
			);
			console.log( `[${new Date().toISOString()}] Request ${uri}` );
			if ( mode === 'spread' ) {
				// FIXME: Doesn't work. Will route through codfw varnishes
				// but still goes to eqiad app servers.
				// setHostDestination( options, 'text-lb.codfw.wikimedia.org' );
			}
			return util.fetchUrl( options );
		}
	);
} ).then( function ( stats ) {
	console.log(
		`Statistics:
- timing: min = ${stats.timing.min / 1e9}s | max = ${stats.timing.max / 1e9}s | avg = ${stats.timing.avg / 1e9}s | total = ${Math.round( stats.timing.total / 1e9 )}s
- concurrency: min = ${stats.count.min} | max = ${stats.count.max} | avg = ${Math.round( stats.count.avg )}
`
	);
	console.log( 'Done!' );
} ).catch( function ( err ) {
	console.log( err );
	process.exit( 1 );
} );
