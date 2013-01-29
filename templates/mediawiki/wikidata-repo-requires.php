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
$wgWBSettings['entityNamespaces'][CONTENT_MODEL_WIKIBASE_ITEM] = NS_MAIN; // <=== Use main namespace for items!!!
$wgWBSettings['entityNamespaces'][CONTENT_MODEL_WIKIBASE_PROPERTY] = WB_NS_PROPERTY; // use custom namespace
$wgWBSettings['entityNamespaces'][CONTENT_MODEL_WIKIBASE_QUERY] = WB_NS_QUERY; // use custom namespace


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

