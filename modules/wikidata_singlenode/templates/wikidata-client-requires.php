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
require_once( "$IP/extensions/AbuseFilter/AbuseFilter.php" );
$wgGroupPermissions['sysop']['abusefilter-modify'] = true;
$wgGroupPermissions['*']['abusefilter-log-detail'] = true;
$wgGroupPermissions['*']['abusefilter-view'] = true;
$wgGroupPermissions['*']['abusefilter-log'] = true;
$wgGroupPermissions['sysop']['abusefilter-private'] = true;
$wgGroupPermissions['sysop']['abusefilter-modify-restricted'] = true;
$wgGroupPermissions['sysop']['abusefilter-revert'] = true;
require_once( "$IP/extensions/AntiBot/AntiBot.php" );
require_once( "$IP/extensions/AntiSpoof/AntiSpoof.php" );
require_once("$IP/extensions/APC/APC.php");
require_once( "$IP/extensions/ApiSandbox/ApiSandbox.php" );
require_once( "$IP/extensions/ArticleFeedback/ArticleFeedback.php" );
$wgArticleFeedbackv5Categories = array( 'Foo_bar', 'Baz' );
$wgArticleFeedbackv5DashboardCategory = 'Foo_bar';
$wgArticleFeedbackBlacklistv5Categories = array( 'Baz' );
$wgArticleFeedbackv5Namespaces = array( NS_MAIN, NS_HELP, NS_PROJECT );
$wgArticleFeedbackv5MaxCommentLength = 400;
require_once( "$IP/extensions/AssertEdit/AssertEdit.php" );
require_once( "$IP/extensions/Babel/Babel.php" );
require_once( "$IP/extensions/CategoryTree/CategoryTree.php" );
require_once( "$IP/extensions/CharInsert/CharInsert.php" );
require_once( "$IP/extensions/CheckUser/CheckUser.php" );
require_once( "$IP/extensions/Cite/Cite.php" );
require_once( "$IP/extensions/cldr/cldr.php" );
require_once( "$IP/extensions/ClickTracking/ClickTracking.php" );
require_once( "$IP/extensions/CodeEditor/CodeEditor.php" );
require_once( "$IP/extensions/Collection/Collection.php" );
require_once("$IP/extensions/ConfirmEdit/FancyCaptcha.php");
$wgCaptchaClass = 'SimpleCaptcha';
$wgGroupPermissions['*']['skipcaptcha'] = false;
$wgGroupPermissions['user']['skipcaptcha'] = false;
$wgGroupPermissions['autoconfirmed']['skipcaptcha'] = false;
$wgGroupPermissions['bot']['skipcaptcha'] = true; // registered bots
$wgGroupPermissions['sysop']['skipcaptcha'] = true;
$wgCaptchaTriggers['addurl'] = true;
$wgCaptchaTriggers['badlogin'] = true;
require_once( "$IP/extensions/EditPageTracking/EditPageTracking.php" );
require_once( "$IP/extensions/EmailCapture/EmailCapture.php" );
require_once( "$IP/extensions/ExpandTemplates/ExpandTemplates.php" );
require_once( "$IP/extensions/FeaturedFeeds/FeaturedFeeds.php" );
require_once( "$IP/extensions/FlaggedRevs/FlaggedRevs.php" );
require_once( "$IP/extensions/Gadgets/Gadgets.php" );
require_once( "$IP/extensions/GlobalUsage/GlobalUsage.php" );
require_once( "$IP/extensions/ImageMap/ImageMap.php" );
require_once( "$IP/extensions/InputBox/InputBox.php" );
require_once( "$IP/extensions/Interwiki/Interwiki.php" );
require_once( "$IP/extensions/LocalisationUpdate/LocalisationUpdate.php" );
require_once( "$IP/extensions/MarkAsHelpful/MarkAsHelpful.php" );
require_once( "$IP/extensions/Math/Math.php" );
require_once( "$IP/extensions/MobileFrontend/MobileFrontend.php" );
require_once( "$IP/extensions/MWSearch/MWSearch.php" );
require_once("$IP/extensions/notitle.php");
// OAI: turn off authentication for easier testing
// (This setting is not used in production)
require_once( "$IP/extensions/OAI/OAIRepo.php" );
$oaiAgentRegex = '!.*!';
$oaiAuth = false;
$oaiAudit = false;
require_once( "$IP/extensions/OpenSearchXml/OpenSearchXml.php" );
require_once("$IP/extensions/Oversight/HideRevision.php");
$wgGroupPermissions['oversight']['hiderevision'] = true;
$wgGroupPermissions['oversight']['oversight'] = true;
require_once( "$IP/extensions/PagedTiffHandler/PagedTiffHandler.php" );
require_once( "$IP/extensions/PageTriage/PageTriage.php" );
require_once( "$IP/extensions/ParserFunctions/ParserFunctions.php" );
require_once( "$IP/extensions/PdfHandler/PdfHandler.php" );
require_once( "$IP/extensions/Poem/Poem.php" );
require_once( "$IP/extensions/PoolCounter/PoolCounterClient.php" );
$wgPoolCounterConf = array(
		'Article::view' => array(
				'class' => 'PoolCounter_Client',
		),
);
require_once( "$IP/extensions/PostEdit/PostEdit.php" );
require_once( "$IP/extensions/CustomData/CustomData.php" );
require_once( "$IP/extensions/RelatedArticles/RelatedArticles.php" );
require_once( "$IP/extensions/RelatedSites/RelatedSites.php" );
require_once( "$IP/extensions/Renameuser/Renameuser.php" );
require_once( "$IP/extensions/Scribunto/Scribunto.php" );
$wgScribuntoDefaultEngine = 'luastandalone';
$wgScribuntoUseGeSHi = true;
$wgScribuntoUseCodeEditor = true;
require_once( "$IP/extensions/SecurePoll/SecurePoll.php" );
require_once( "$IP/extensions/SimpleAntiSpam/SimpleAntiSpam.php" );
require_once( "$IP/extensions/SiteMatrix/SiteMatrix.php" );
$wgSiteMatrixFile = "$IP/../../mediawiki-config/langlist";
$wgSiteMatrixClosedSites = "$IP/../../mediawiki-config/closed.dblist";
$wgSiteMatrixPrivateSites = "$IP/../../mediawiki-config/private.dblist";
$wgSiteMatrixFishbowlSites = "$IP/../../mediawiki-config/fishbowl.dblist";
require_once( "$IP/extensions/SpamBlacklist/SpamBlacklist.php" );
$wgEnableDnsBlacklist = true;
$wgDnsBlacklistUrls = array( 'xbl.spamhaus.org', 'opm.tornevall.org' );
require_once( "$IP/extensions/SwiftCloudFiles/SwiftCloudFiles.php" );
require_once( "$IP/extensions/SyntaxHighlight_GeSHi/SyntaxHighlight_GeSHi.php" );
require_once( "$IP/extensions/TemplateSandbox/TemplateSandbox.php" );
//require_once( "$IP/extensions/TitleBlacklist/TitleBlacklist.php" );
require_once( "$IP/extensions/TitleKey/TitleKey.php" );
require_once( "$IP/extensions/TorBlock/TorBlock.php" );
require_once( "$IP/extensions/UserDailyContribs/UserDailyContribs.php" );
require_once( "$IP/extensions/UserMerge/UserMerge.php" );
$wgGroupPermissions['sysop']['usermerge'] = true; 
$wgUserMergeProtectedGroups = array( 'sysop' );

require_once( "$IP/extensions/Vector/Vector.php" );
require_once( "$IP/extensions/WikiEditor/WikiEditor.php" );
require_once( "$IP/extensions/wikihiero/wikihiero.php" );
require_once( "$IP/extensions/WikiLove/WikiLove.php" );
require_once( "$IP/extensions/WikimediaMaintenance/WikimediaMaintenance.php" );
require_once( "$IP/extensions/WikimediaMessages/WikimediaMessages.php" );

// anti spam
$wgNamespaceProtection[NS_USER] = array( 'edit-user' );
$wgGroupPermissions['*']['edit-user'] = false;
$wgGroupPermissions['user']['edit-user'] = false;
$wgGroupPermissions['bot']['edit-user'] = false;
$wgNamespaceProtection[NS_USER_TALK] = array( 'edit-user-talk' );
$wgGroupPermissions['*']['edit-user-talk'] = false;
$wgGroupPermissions['user']['edit-user-talk'] = false;
$wgGroupPermissions['bot']['edit-user-talk'] = false;
