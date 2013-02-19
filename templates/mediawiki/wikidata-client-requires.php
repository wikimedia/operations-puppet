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

// overwrite the setting in orig/LocalSettings.php concerning pics from Commons
# InstantCommons allows wiki to use images from http://commons.wikimedia.org
$wgUseInstantCommons  = true;

// use the Wikidata logo
$wgLogo = "$wgStylePath/common/images/Wikidata-logo-democlient.png";

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
require_once( "$IP/extensions/Wikibase/lib/WikibaseLib.php" );
require_once( "$IP/extensions/Wikibase/client/WikibaseClient.php" );
require_once( "$IP/extensions/DismissableSiteNotice/DismissableSiteNotice.php" );
require_once( "$IP/extensions/ParserFunctions/ParserFunctions.php" );
require_once( "$IP/extensions/notitle.php" );

$wgShowExceptionDetails = true;

// information about the repo this client is connected to
$wgWBSettings['repoArticlePath'] = "/wiki/$1";
$wgWBSettings['repoScriptPath'] = "/w";

// The global site ID by which this wiki is known on the repo.
$wgWBSettings['siteGlobalID'] = "<%=siteGlobalID%>";
// Database name of the repository, for use by the pollForChanges script.
// This requires the given database name to be known to LBFactory, see
// $wgLBFactoryConf below.
$wgWBSettings['changesDatabase'] = "repo";
$wgWBSettings['repoDatabase'] = "repo";
$wgWBSettings['repoNamespaces'] = array( 'wikibase-item' => 'Item', 'wikibase-property' => 'Property' );

$wgWBSettings['repoUrl'] = "<%=repo_url%>";

//Load Balancer
$wgLBFactoryConf = array(
	'class' => 'LBFactory_Multi',
	'serverTemplate' => array(
		'dbname' => $wgDBname,
		'user' => $wgDBuser,
		'password' => $wgDBpassword,
		'type' => 'mysql',
		'flags' => DBO_DEFAULT | DBO_DEBUG,
	),
	'sectionLoads' => array(
		'DEFAULT' => array(
			'localhost' => 1,
		),
		'repo' => array(
			'local1' => 1,
		),
	),
	'sectionsByDB' => array(
		$wgDBname => 'DEFAULT',
		'repo' => 'repo',
	),
	'hostsByName' => array(
		'localhost' => '127.0.0.1:3306',
		'local1' => '<%=repo_ip%>:3306',
	),
	'masterTemplateOverrides' => array( 'fakeMaster' => true ),
);

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
error_reporting(E_ALL);
ini_set("display_errors", 1);
$wgDebugLogGroups['wikibase'] = "/tmp/devclient-wikibase.log";
$wgDebugLogGroups['WikibaseLangLinkHandler'] = "/tmp/devclient-LangLinkHandler.log";

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

