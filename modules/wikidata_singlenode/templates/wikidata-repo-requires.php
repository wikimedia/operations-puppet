<?php
#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///templates/mediawiki/wikidata-client-role-requires.php
###
###  Changes to this file will be clobbered by Puppet.
###  If you need to hand-edit local settings, modify
###  the included orig/LocalSettings.php.
###
#####################################################################
// use the Wikidata logo
$wgLogo = "$wgStylePath/common/images/Wikidata-logo-demorepo.png";

// Cache
$wgCacheDirectory = "/var/cache/mw-cache/<%=database_name%>/";
$wgLocalisationCacheConf['manualRecache'] = true;

// Shared memory settings
$wgMainCacheType    = CACHE_MEMCACHED;
$wgMemCachedServers = array( "127.0.0.1:11000" );

// experimental features
define( 'WB_EXPERIMENTAL_FEATURES', <%=experimental%> );

require_once( "$IP/extensions/Diff/Diff.php" );
require_once( "$IP/extensions/DataValues/DataValues.php" );
require_once( "$IP/extensions/UniversalLanguageSelector/UniversalLanguageSelector.php" );
require_once( "$IP/extensions/Wikibase/lib/WikibaseLib.php" );
require_once( "$IP/extensions/Wikibase/repo/Wikibase.php" );
require_once( "$IP/extensions/DismissableSiteNotice/DismissableSiteNotice.php" );
require_once( "$IP/extensions/ApiSandbox/ApiSandbox.php" );
require_once( "$IP/extensions/OAI/OAIRepo.php" );
require_once( "$IP/extensions/notitle.php" );
require_once( "$IP/extensions/Babel/Babel.php" );

// Translate extension
require_once( "$IP/extensions/Translate/Translate.php" );
$wgGroupPermissions['translator']['translate'] = true;
# You can replace qqq with something more meaningful like info
$wgTranslateDocumentationLanguageCode = 'qqq';
# Add these too if you want to enable page translation
$wgGroupPermissions['sysop']['pagetranslation'] = true;
$wgEnablePageTranslation = true;

// AbuseFilter extension
require_once( "$IP/extensions/AbuseFilter/AbuseFilter.php" );
$wgGroupPermissions['sysop']['abusefilter-modify'] = true;
$wgGroupPermissions['*']['abusefilter-log-detail'] = true;
$wgGroupPermissions['*']['abusefilter-view'] = true;
$wgGroupPermissions['*']['abusefilter-log'] = true;
$wgGroupPermissions['sysop']['abusefilter-private'] = true;
$wgGroupPermissions['sysop']['abusefilter-modify-restricted'] = true;
$wgGroupPermissions['sysop']['abusefilter-revert'] = true;

// items in main namespace
$baseNs = 100;
// NOTE: do *not* define WB_NS_ITEM and WB_NS_ITEM_TALK when using a core namespace for items!
define( 'WB_NS_PROPERTY', $baseNs +2 );
define( 'WB_NS_PROPERTY_TALK', $baseNs +3 );
define( 'WB_NS_QUERY', $baseNs +4 );
define( 'WB_NS_QUERY_TALK', $baseNs +5 );

// You can set up an alias for the main namespace, if you like.
$wgNamespaceAliases['Item'] = NS_MAIN;
$wgNamespaceAliases['Item_talk'] = NS_TALK;

// No extra namespace for items, using a core namespace for that.
$wgExtraNamespaces[WB_NS_PROPERTY] = 'Property';
$wgExtraNamespaces[WB_NS_PROPERTY_TALK] = 'Property_talk';
$wgExtraNamespaces[WB_NS_QUERY] = 'Query';
$wgExtraNamespaces[WB_NS_QUERY_TALK] = 'Query_talk';

// Tell Wikibase which namespace to use for which kind of entity
$wgWBRepoSettings['entityNamespaces'][CONTENT_MODEL_WIKIBASE_ITEM] = NS_MAIN; // <=== Use main namespace for items!!!
$wgWBRepoSettings['entityNamespaces'][CONTENT_MODEL_WIKIBASE_PROPERTY] = WB_NS_PROPERTY; // use custom namespace
$wgWBRepoSettings['entityNamespaces'][CONTENT_MODEL_WIKIBASE_QUERY] = WB_NS_QUERY; // use custom namespace


$wgShowExceptionDetails = true;
$wgContentHandlerUseDB = true;

// Profiling
// Only record profiling info for pages that took longer than this
$wgProfileLimit = 0.1;
// Log sums from profiling into "profiling" table in db
$wgProfileToDatabase = true;
// If true, print a raw call tree instead of per-function report
$wgProfileCallTree = false;
// Should application server host be put into profiling table
$wgProfilePerHost = false;
// Detects non-matching wfProfileIn/wfProfileOut calls
$wgDebugProfiling = true;
// Output debug message on every wfProfileIn/wfProfileOut
$wgDebugFunctionEntry = 0;
// Lots of debugging output from SquidUpdate.php
$wgEnableProfileInfo = true;
// Debugging
$wgDebugToolbar = true;
$wgShowSQLErrors = true;
$wgShowDBErrorBacktrace = true;
$wgDevelopmentWarnings = true;
$wgEnableJavaScriptTest = true;

// config for extensions
// OAI
$oaiAgentRegex = '!.*!';
$oaiAuth = false;
$oaiAudit = false;

// SiteMatrix
$wgSiteMatrixFile = "$IP/../../mediawiki-config/langlist";
$wgSiteMatrixClosedSites = "$IP/../../mediawiki-config/closed.dblist";
$wgSiteMatrixPrivateSites = "$IP/../../mediawiki-config/private.dblist";
$wgSiteMatrixFishbowlSites = "$IP/../../mediawiki-config/fishbowl.dblist";

// propagation of changes
$wgWBSettings['localClientDatabases'] = array( 'enwiki' => 'client' );

// Load Balancer
$wgLBFactoryConf = array(
	// In order to seamlessly access a remote wiki, LBFactory_Multi must be used.
	'class' => 'LBFactory_Multi',

	// Connect to all databases using the same credentials.
	'serverTemplate' => array(
		'dbname' => $wgDBname,
		'user' => $wgDBuser,
		'password' => $wgDBpassword,
		'type' => 'mysql',
		'flags' => DBO_DEFAULT | DBO_DEBUG,
	),

	// Configure two sections, one for the repo and one for the client.
	// Each section contains only one server.
	'sectionLoads' => array(
		'DEFAULT' => array(
			'localhost' => 1,
		),
		'client' => array(
			'local1' => 1,
		),
	),

	// Map the wiki database names to sections. Database names must be unique,
	// i.e. may not exist in more than one section.
	'sectionsByDB' => array(
		$wgDBname => 'DEFAULT',
		'client' => 'client',
	),

	// Map host names to IP addresses to bypass DNS.
	// NOTE: Even if all sections run on the same MySQL server (typical for a test setup),
	// they must use different IP addresses, and MySQL must listen on all of them.
	// The easiest way to do this is to set bind-address = 0.0.0.0 in the MySQL
	// configuration. Beware that this makes MySQL listen on you ethernet port too.
	// Safer alternatives include setting up mysql-proxy or mysqld_multi.
	'hostsByName' => array(
		'localhost' => '127.0.0.1:3306',
		'local1' => '<%=client_ip%>',
	),

	// Set up as fake master, because there are no slaves.
	'masterTemplateOverrides' => array( 'fakeMaster' => true ),
);

// Let clients edit this wiki via CORS
// Allow all of wikimedia.de and all labs instances for the sake of simplicity
$wgCrossSiteAJAXdomains = array( '*.wikimedia.de', '*.instance-proxy.wmflabs.org' );
