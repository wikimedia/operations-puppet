<?php
require_once( "$IP/extensions/Diff/Diff.php" );
require_once( "$IP/extensions/DataValues/DataValues.php" );
require_once( "$IP/extensions/Wikibase/lib/WikibaseLib.php" );
require_once( "$IP/extensions/Wikibase/client/WikibaseClient.php" );
require_once( "$IP/extensions/DismissableSiteNotice/DismissableSiteNotice.php" );
require_once( "$IP/extensions/ParserFunctions/ParserFunctions.php" );

$wgShowExceptionDetails = true;

// experimental features
define( 'WB_EXPERIMENTAL_FEATURES', true );

$wgWBSettings['repoArticlePath'] = "/wiki/$1";
$wgWBSettings['repoScriptPath'] = "/w";

// The global site ID by which this wiki is known on the repo.
$wgWBSettings['siteGlobalID'] = "enwiki";
// Database name of the repository, for use by the pollForChanges script.
// This requires the given database name to be known to LBFactory, see
// $wgLBFactoryConf below.
$wgWBSettings['changesDatabase'] = "repo";
$wgWBSettings['repoDatabase'] = "repo";
$wgWBSettings['repoNamespaces'] = array( 'wikibase-item' => 'Item', 'wikibase-property' => 'Property' );

// Load Balancer
$wgLBFactoryConf = array( 'class' => 'LBFactory_Multi', 'serverTemplate' => array( 'dbname' => $wgDBname, 'user' => $wgDBuser, 'password' => $wgDBpassword, 'type' => 'mysql', 'flags' => DBO_DEFAULT | DBO_DEBUG, ), 'sectionLoads' => array( 'DEFAULT' => array( 'localhost' => 1, ), 'repo' => array( 'local1' => 1, ), ), 'sectionsByDB' => array( $wgDBname => 'DEFAULT', 'repo' => 'repo', ), 'hostsByName' => array( 'localhost' => '127.0.0.1:3306', 'local1' => '10.4.0.23:3306', ), 'masterTemplateOverrides' => array( 'fakeMaster' => true ), );

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
// MoodBar
$wgGroupPermissions['sysop']['moodbar-view'] = true;
