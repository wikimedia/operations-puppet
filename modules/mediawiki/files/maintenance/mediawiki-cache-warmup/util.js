var http = require( 'http' ),
	https = require( 'https' ),
	url = require( 'url' ),
	keepAliveAgents = {
		http: new http.Agent( { keepAlive: true } ),
		https: new https.Agent( { keepAlive: true } )
	};

/**
 * @param {string} url
 * @return {Promise}
 */
function fetchHttpsUrl( url ) {
	return new Promise( function ( resolve, reject ) {
		var req = https.get( url, function ( resp ) {
			var data = '';
			resp.on( 'data', function ( chunk ) {
				data += chunk;
			} );
			resp.on( 'end', function() {
				resolve( data );
			} );
		} );
		req.on( 'error', reject );
	} );
}

/**
 * @param {string|Object} options Node http.request() options.
 * @param {boolean} [options.keepAlive=false] Use a keepAlive agent.
 * @return {Promise}
 */
function fetchUrl( options ) {
	var request;
	if ( typeof options === 'string' ) {
		options = url.parse( options );
	}
	request = options.protocol === 'https:' ? https : http;
	if ( options.keepAlive ) {
		// http.request() requires the Agent to be for the same protocol
		options.agent = options.protocol === 'https:' ?
			keepAliveAgents.https : keepAliveAgents.http;
	}
	return new Promise( function ( resolve, reject ) {
		var req = request.get( options, function ( resp ) {
			// Discard data
			resp.resume();
			resp.on( 'end', function() {
				resolve();
			} );
		} );
		req.on( 'error', function ( err ) {
			reject( new Error( err + ' [for url ' + url.format( options ) + ']' ) );
		} );
	} );
}

/**
 * @return {Promise}
 */
function getSiteMatrix() {
	return fetchHttpsUrl( 'https://meta.wikimedia.org/w/api.php?format=json&action=sitematrix&smlangprop=site&smsiteprop=url|dbname' )
		.then( JSON.parse )
		.then( function ( data ) {
			var map = Object.create( null );
			for ( let key in data.sitematrix ) {
				if ( key === 'count' ) {
					continue;
				}
				let group = key === 'specials' ? data.sitematrix[ key ] : data.sitematrix[ key ].site;
				if ( group && group.length ) {
					for ( let i = 0; i < group.length; i++ ) {
						let wiki = group[ i ];
						if ( wiki.private === undefined &&
							wiki.closed === undefined &&
							// Exlude labswiki (wikitech) and labtestwiki
							wiki.nonglobal === undefined &&
							wiki.fishbowl === undefined
						) {
							map[ wiki.dbname ] = {
								dbname: wiki.dbname,
								url: wiki.url,
								host: url.parse( wiki.url ).host
							};
						}
					}
				}
			}
			return map;
		} );
}

function makeMobileHost( wiki ) {
	var pattern, parts,
		wgMobileUrlTemplate = {
			default: '%h0.m.%h1.%h2',
			foundationwiki: 'm.%h0.%h1',
			mediawikiwiki: 'm.%h1.%h2',
			sourceswiki: 'm.%h0.%h1',
			wikidatawiki: 'm.%h1.%h2',
			labswiki: false,
			labtestwiki: false,
			loginwiki: false
		};
	pattern = wgMobileUrlTemplate[ wiki.dbname ] !== undefined ?
		wgMobileUrlTemplate[ wiki.dbname ] :
		wgMobileUrlTemplate.default;
	if ( !pattern ) {
		return false;
	}
	parts = wiki.host.split( '.' );
	return pattern.replace( /%h([0-9])/g, function ( mAll, m1 ) {
		return parts[ m1 ] || '';
	} );
}

/**
 * @param {string[]} lines
 * @return {string[]}
 */
function reduceTxtLines( lines ) {
	return lines.reduce( function ( out, line ) {
		var text = line.trim();
		if ( text && text[ 0 ] !== '#' ) {
			// Line with placeholders like %hostname or %m-hostname
			out.push( text );
		}
		return out;
	}, [] );
}

/**
 * @param {string[]} urls
 * @return {Promise} List of strings
 */
function expandUrlList( urls ) {
	return getSiteMatrix().then( function ( wikis ) {
		return urls.reduce( function ( out, url ) {
			var dbname, mhost;
			// Ensure HTTP instead of HTTPS
			// url = url.replace( /^https:/, 'http:' );
			if ( url.indexOf( '%server' ) !== -1 ) {
				// If %server, insert one for each wiki
				for ( dbname in wikis ) {
					out.push( url.replace( /%server/g, wikis[ dbname ].host ) );
				}
			} else if ( url.indexOf( '%mobileServer' ) !== -1 ) {
				// If %mobileServer, insert one for each wiki, converted to mobile
				for ( dbname in wikis ) {
					mhost = makeMobileHost( wikis[ dbname ] );
					if ( mhost ) {
						out.push( url.replace( /%mobileServer/g, mhost ) );
					}
				}
			} else {
				out.push( url );
			}
			return out;
		}, [] );
	} );
}

/**
 * @param {Object} options
 * @param {number} options.globalConcurrency
 * @param {number} [options.groupConcurrency=globalConcurrency]
 * @param {Array} dataset Items to be passed to the handler.
 * @param {Function} handler
 * @return {Promise}
 */
function worker( options, dataset, handler ) {
	var queues,
		concurrency = {
			groups: Object.create( null ),
			global: 0
		},
		workStart = process.hrtime(),
		stats = {
			timing: {
				min: Infinity,
				max: -Infinity,
				avg: 0,
				// wall of shame, top 5
				wos: []
			},
			count: {
				min: Infinity,
				max: -Infinity,
				avg: 0,
				total: 0
			}
		};
	function expandDiff( diff ) {
		return diff[ 0 ] * 1e9 + diff[ 1 ]; // in nanoseconds
	}
	function writeStats( diff, task, group ) {
		var duration, oldTotal;
		duration = expandDiff( diff );
		oldTotal = stats.count.total;
		stats.timing.min = Math.min( stats.timing.min, duration );
		// Keep track of the slowest 5
		if ( duration > stats.timing.max ) {
			stats.timing.wos.push( { group, task, duration } );
			if ( stats.timing.wos.length > 5 ) {
				stats.timing.wos.shift();
			}
		}
		stats.timing.max = Math.max( stats.timing.max, duration );
		stats.timing.avg = ( ( stats.timing.avg * oldTotal ) + duration ) / ( oldTotal + 1 );
		stats.count.total++;
		stats.count.min = Math.min( stats.count.min, concurrency.global );
		stats.count.max = Math.max( stats.count.max, concurrency.global );
		stats.count.avg = ( ( stats.count.avg * oldTotal ) + concurrency.global ) / ( oldTotal + 1 );
	}
	if ( !options.groupConcurrency ) {
		options.groupConcurrency = options.globalConcurrency;
	}
	if ( Array.isArray( dataset ) ) {
		queues = { main: dataset };
	} else {
		queues = dataset;
	}
	return new Promise( function ( resolve, reject ) {
		function startTask( group, task ) {
			var ret, start;
			concurrency.global++;
			concurrency.groups[ group ]++;
			start = process.hrtime();
			ret = handler( task, group );
			Promise.resolve( ret )
				.then( function () {
					writeStats( process.hrtime( start ), task, group );
					concurrency.global--;
					concurrency.groups[ group ]--;
					handlePending();
				} )
				.catch( reject );
		}
		function handlePending() {
			for ( let group in queues ) {
				let tasks = queues[ group ];
				if ( !tasks.length ) {
					delete queues[ group ];
					continue;
				}
				if ( concurrency.groups[ group ] === undefined ) {
					concurrency.groups[ group ] = 0;
				}
				while ( concurrency.global < options.globalConcurrency &&
					concurrency.groups[ group ] < options.groupConcurrency &&
					tasks.length
				) {
					startTask( group, tasks.pop() );
				}
			}
			// Done?
			if ( !concurrency.global ) {
				stats.timing.total = expandDiff( process.hrtime( workStart ) );
				resolve( stats );
			}
		}
		handlePending();
	} );
}

// See https://bost.ocks.org/mike/shuffle/
function shuffle( array ) {
	var tmp, random,
		i = array.length;
	while ( i !== 0 ) {
		// Take one of the remaining elements
		random = Math.floor( Math.random() * i );
		i--;
		// And swap it with the current one
		tmp = array[ i ];
		array[ i ] = array[ random ];
		array[ random ] = tmp;
	}
	return array;
}

module.exports = {
	fetchUrl,
	getSiteMatrix,
	makeMobileHost,
	reduceTxtLines,
	expandUrlList,
	worker,
	shuffle
};
