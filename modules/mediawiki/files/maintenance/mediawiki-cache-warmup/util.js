var http = require( 'http' ),
	https = require( 'https' ),
	url = require( 'url' );

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
 * @param {string|Object} options
 * @return {Promise}
 */
function fetchUrl( options ) {
	var request;
	if ( typeof options === 'string' ) {
		options = url.parse( options );
	}
	request = options.protocol === 'https:' ? https : http;
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
			var map, key, group, i, wiki;
			map = Object.create( null );
			for ( key in data.sitematrix ) {
				if ( key === 'count' ) {
					continue;
				}
				group = key === 'specials' ? data.sitematrix[ key ] : data.sitematrix[ key ].site;
				if ( group && group.length ) {
					for ( i = 0; i < group.length; i++ ) {
						wiki = group[ i ];
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
 * @param {Object} options.concurrency
 * @param {Array} dataset Items to be passed to the handler.
 * @param {Function} handler
 * @return {Promise}
 */
function worker( options, dataset, handler ) {
	var tasks,
		concurrency = 0,
		workStart = process.hrtime(),
		stats = {
			timing: {
				min: Infinity,
				max: -Infinity,
				avg: 0
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
	function writeStats( diff ) {
		var duration, oldTotal;
		duration = expandDiff( diff );
		oldTotal = stats.count.total;
		stats.timing.min = Math.min( stats.timing.min, duration );
		stats.timing.max = Math.max( stats.timing.max, duration );
		stats.timing.avg = ( ( stats.timing.avg * oldTotal ) + duration ) / ( oldTotal + 1 );
		stats.count.total++;
		stats.count.min = Math.min( stats.count.min, concurrency );
		stats.count.max = Math.max( stats.count.max, concurrency );
		stats.count.avg = ( ( stats.count.avg * oldTotal ) + concurrency ) / ( oldTotal + 1 );
	}
	tasks = dataset.slice();
	return new Promise( function ( resolve, reject ) {
		function startTask( task ) {
			var ret, start;
			concurrency++;
			start = process.hrtime();
			ret = handler( task );
			Promise.resolve( ret )
				.then( function () {
					writeStats( process.hrtime( start ) );
					concurrency--;
					handlePending();
				} )
				.catch( reject );
		}
		function handlePending() {
			if ( !tasks.length && !concurrency ) {
				stats.timing.total = expandDiff( process.hrtime( workStart ) );
				resolve( stats );
				return;
			}
			while ( tasks.length && concurrency < options.concurrency ) {
				startTask( tasks.pop() );
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
