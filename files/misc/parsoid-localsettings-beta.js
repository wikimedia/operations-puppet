/*
 * THIS FILE IS MANAGED BY PUPPET
 * puppet:///files/misc/parsoid-localsettings-beta.js
 */

exports.setup = function( parsoidConfig ) {
	parsoidConfig.setInterwiki( 'commonswiki', 'http://commons.wikimedia.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'cswiki', 'http://cs.wikipedia.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'cswikibooks', 'http://cs.wikibooks.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'cswikinews', 'http://cs.wikinews.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'cswikisource', 'http://cs.wikisource.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'dewiki', 'http://de.wikipedia.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'dewikinews', 'http://de.wikinews.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'diqwiki', 'http://diq.wikipedia.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'enwiki', 'http://en.wikipedia.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'enwikibooks', 'http://en.wikibooks.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'enwikinews', 'http://en.wikinews.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'enwiktionary', 'http://en.wikitionary.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'frwiki', 'http://fr.wikipedia.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'hewiki', 'http://he.wikipedia.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'labs', 'http://deployment.wikimedia.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'simplewiki', 'http://simple.wikipedia.beta.wmflabs.org/w/api.php' );
	parsoidConfig.setInterwiki( 'trwiki', 'http://tr.wikipedia.beta.wmflabs.org/w/api.php' );

	// Use the PHP preprocessor to expand templates via the MW API (default true)
	parsoidConfig.usePHPPreProcessor = true;

	// Use selective serialization (default false)
	parsoidConfig.useSelser = true;

	// allow cross-domain requests to the API (default disallowed)
	//parsoidConfig.allowCORS = '*';
	//
	parsoidConfig.parsoidCacheURI = 'http://10.68.16.145/'; // deployment-parsoidcache01.eqiad.wmflabs

	// parsoidConfig.apiProxyURI = 'http://en.wikipedia.org';
};
