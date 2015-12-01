/**
 * asset-check.js
 *
 * This is a PhantomJS script. It connects to a page specified as a
 * command-line argument and prints a JSON object containing information
 * about the number of resources requested by the page and their size.
 *
 * Requires PhantomJS <http://phantomjs.org/>.
 *
 * Usage: phantomjs asset-check.js URL
 *
 * Optional arguments:
 *   --timeout=N       specifies timeout, in seconds.
 *   --ua=USER_AGENT   set this User-Agent header.
 *   --debug           enable verbose output and avoid minification.
 *
 * Copyright (C) 2013, Ori Livneh <ori@wikimedia.org>
 * Licensed under the terms of the GPL, version 2 or later.
 */
/*global phantom:false, console:false, require:false */
var system = require( 'system' ),
	webpage = require( 'webpage' ),
	options = {
		debug: false,
		timeout: 30,
		ua: null
	};

function usage() {
	console.error( 'Usage: phantomjs ' + system.args[ 0 ] +
		' URL [--timeout=N] [--ua=USER_AGENT_STRING] [--debug]'
	);
	phantom.exit( 1 );
}

function parseArgument( arg ) {
	var match;

	if ( arg === '-h' || arg === '--help' ) {
		usage();
		return;
	}

	if ( arg === '--debug' ) {
		options.debug = true;
		return;
	}

	match = /^--([^=]+)=(.*)/.exec( arg );
	if ( match ) {
		options[ match[1] ] = match[2];
	} else {
		options.url = arg;
	}
}

function countCssRules() {
	return Array.prototype.reduce.call( document.styleSheets, function ( total, styleSheet ) {
		return styleSheet.cssRules ? total + styleSheet.cssRules.length : total;
	}, 0 );
}

function checkAssets( url ) {
	var resourcesRequested = {},
		responseSizes = {},
		page = webpage.create(),
		payload = {
			javascript: { requests: 0, bytes: 0 },
			html: { requests: 0, bytes: 0 },
			css: {
				requests: 0,
				bytes: 0,
				rules: 0
			},
			image: { requests: 0, bytes: 0 },
			other: { requests: 0, bytes: 0 },
			cookies: {
				set: 0
			},
			combined: {
				requests: 0,
				bytes: 0,
				post: 0,
				redirects: 0,
				http200: 0,
				http304: 0,
				http4xx: 0,
				http5xx: 0,
				httpOther: 0,
				uncaughtException: 0
			},
			modules: {
				registered: 0,
				loading: 0,
				loaded: 0,
				ready: 0,
				error: 0,
				missing: 0,
				unregistered: 0
			}
		};

	// Set a custom Accept-Encoding header to prevent PhantomJS from setting
	// one which accepts gzip compression. Compression messes up our payload
	// size calculations. See https://github.com/ariya/phantomjs/issues/10930.
	page.customHeaders = { 'Accept-Encoding': 'identity' };

	if ( options.ua ) {
		page.settings.userAgent = options.ua;
	}

	page.onResourceRequested = function ( req ) {
		resourcesRequested[ req.id ] = {
			method: req.method,
			isDataUri: /^data:/.test( req.url )
		};
	};

	/**
	 * Analyze incoming resource
	 *
	 * Called two or more times for every requested resource (e.g. urls and
	 * resolved data uris). Once with stage="start", once with stage="end", and
	 * potentially zero or more times for individual chunks if the server
	 * sent data in multiple chunks.
	 *
	 * @param {Object} res
	 */
	page.onResourceReceived = function ( res ) {
		var match = /javascript|html|css|image/i.exec( res.contentType ) || [ 'other' ],
			type = match[0],
			req = resourcesRequested[ res.id ] || {},
			resource = payload[ type ];

		if ( res.bodySize ) {
			responseSizes[ res.id ] = ( responseSizes[ res.id ] || 0 ) + res.bodySize;
			return;
		}

		if ( res.stage === 'end' && !req.isDataUri ) {
			resource.requests++;
			payload.combined.requests++;

			resource.bytes = responseSizes[ res.id ];
			payload.combined.bytes += resource.bytes;

			if ( req.method === 'POST' ) {
				payload.combined.post++;
			}

			switch ( res.status ) {
				case 200: // OK
					payload.combined.http200++;
					break;
				case 301: // Moved Permanently
				case 302: // Found
				case 303: // See Other
					payload.combined.redirects++;
					break;
				case 304: // Not Modified
					payload.combined.http304++;
					break;
				case 403: // Forbidden
				case 404: // Not Found
					payload.combined.http4xx++;
					break;
				case 500: // Internal Server Error
				case 502: // Bad Gateway
				case 503: // Service Unavailable
				case 504: // Gateway Timeout
					payload.combined.http5xx++;
					break;
				default:
					payload.combined.httpOther++;
			}
		}
	};

	// Print network report
	page.onLoadFinished = function () {
		// The "page" is finished, but wait for asynchronously loaded modules
		// to finish as well.
		page.evaluate( function () {
			/*global mw */
			mw.hook( 'resourceloader.loadEnd' ).add( function () {
				window.callPhantom( 'mw-modules-ready' );
			} );
		} );
	};

	// Listens for calls to 'window.callPhantom' from the page
	page.onCallback = function ( data ) {
		if ( data !== 'mw-modules-ready' ) {
			return;
		}
		payload.cookies.set = page.cookies.length;
		payload.css.rules = page.evaluate( countCssRules );

		payload.modules = page.evaluate( function () {
			/*global mw */
			var states = {
				registered: 0,
				loading: 0,
				loaded: 0,
				ready: 0,
				error: 0,
				missing: 0,
				unregistered: 0
			};
			mw.loader.getModuleNames().forEach( function ( name ) {
			  var state = mw.loader.getState( name );
			  if ( states[ state ] !== undefined ) {
				states[ state ]++;
			  }
			} );
			return states;
		} );

		if ( options.debug ) {
			console.log( JSON.stringify( payload, null, '\t' ) );
		} else {
			console.log( JSON.stringify( payload ) );
		}
		phantom.exit( 0 );
	};

	page.onError = function () {
		// For example:
		// - Uncaught ReferenceError: jQuery not defined
		// - TypeError: 'undefined' is not a function (evaluating '$(document)')
		payload.combined.uncaughtException++;
	};

	// Abort if 30 seconds elapsed and the page hasn't finished loading
	setTimeout( function () {
		console.error( 'Timed out after ' + options.timeout + ' seconds.' );
		phantom.exit( 1 );
	}, ( options.timeout * 1000 ) );

	page.open( url );

	// Page is locked to the specified URL
	page.navigationLocked = true;
}

system.args.slice( 1 ).forEach( parseArgument );
if ( Object.keys( options ).sort().join(' ') !== 'debug timeout ua url' ) {
	usage();
} else {
	checkAssets( options.url );
}
