#  Install Mediawiki from git and keep in sync with git trunk
class role::mediawiki-install-latest::labs {

	class { "mediawiki::singlenode":
		ensure => latest
	}
}

#  Install Mediawiki from git and then leave it alone.
class role::mediawiki-install::labs {

	class { "mediawiki::singlenode":
		ensure => present
	}
}

#  Install Wikidata repo (incl. MediaWiki) from git and keep in sync with git trunk
class role::wikidata-repo-latest::labs {

	class { "wikidata::singlenode":
		install_repo => true,
		install_client => false,
		database_name => "repo",
		ensure => latest,
		# all require_once lines here:
		role_requires => [
		'"$IP/extensions/Diff/Diff.php"',
		'"$IP/extensions/DataValues/DataValues.php"',
		'"$IP/extensions/UniversalLanguageSelector/UniversalLanguageSelector.php"',
		'"$IP/extensions/Wikibase/lib/WikibaseLib.php"',
		'"$IP/extensions/Wikibase/repo/Wikibase.php"',
		'"$IP/extensions/Wikibase/repo/ExampleSettings.php"',
		'"$IP/extensions/DismissableSiteNotice/DismissableSiteNotice.php"',
		'"$IP/extensions/APC/APC.php"',
		'"$IP/extensions/ApiSandbox/ApiSandbox.php"',
		'"$IP/extensions/MoodBar/MoodBar.php"',
		'"$IP/extensions/OAI/OAIRepo.php"'
		],
		# additional config lines
		role_config_lines => [
		'$wgShowExceptionDetails = true',
		'$wgContentHandlerUseDB = true',
		'// experimental features',
		'define( \'WB_EXPERIMENTAL_FEATURES\', true )',
		'//Profiling',
		'// Only record profiling info for pages that took longer than this',
		'$wgProfileLimit = 0.1',
		'// Log sums from profiling into "profiling" table in db',
		'$wgProfileToDatabase = true',
		'// If true, print a raw call tree instead of per-function report',
		'$wgProfileCallTree = false',
		'// Should application server host be put into profiling table',
		'$wgProfilePerHost = false',
		'// Detects non-matching wfProfileIn/wfProfileOut calls',
		'$wgDebugProfiling = true',
		'// Output debug message on every wfProfileIn/wfProfileOut',
		'$wgDebugFunctionEntry = 0',
		'// Lots of debugging output from SquidUpdate.php',
		'$wgEnableProfileInfo = true',
		'$wgSiteNotice = \'<div style="font-size: 90%; background: #FFCC33; padding: 1ex; border: #940 dotted; margin-top: 1ex; margin-bottom: 1ex; ">This is a demo system that shows the current development state of Wikidata.<br /> <strong>This is the bleeding edge.</strong><br /> Expect things to be broken. </div>\'',
		'//Debugging',
		'$wgDebugToolbar = true',
		'$wgShowSQLErrors = true',
		'$wgShowDBErrorBacktrace = true',
		'$wgDevelopmentWarnings = true',
		'$wgEnableJavaScriptTest = true',
		'// config for extensions',
		'// OAI',
		'$oaiAgentRegex = \'!.*!\'',
		'$oaiAuth = false',
		'$oaiAudit = false',
		'// SiteMatrix',
		'$wgSiteMatrixFile = "$IP/../../mediawiki-config/langlist"',
		'$wgSiteMatrixClosedSites = "$IP/../../mediawiki-config/closed.dblist"',
		'$wgSiteMatrixPrivateSites = "$IP/../../mediawiki-config/private.dblist"',
		'$wgSiteMatrixFishbowlSites = "$IP/../../mediawiki-config/fishbowl.dblist"',
		'// MoodBar',
		'$wgGroupPermissions[\'sysop\'][\'moodbar-view\'] = true'
		]
	}
}

#  Install Wikidata repo (incl. Mediawiki) from git and then leave it alone.
class role::wikidata-repo::labs {

	class { "wikidata::singlenode":
		install_repo => true,
		install_client => false,
		database_name => "repo",
		ensure => present,
		# all require_once lines here:
		role_requires => [
		'"$IP/extensions/Diff/Diff.php"',
		'"$IP/extensions/DataValues/DataValues.php"',
		'"$IP/extensions/UniversalLanguageSelector/UniversalLanguageSelector.php"',
		'"$IP/extensions/Wikibase/lib/WikibaseLib.php"',
		'"$IP/extensions/Wikibase/repo/Wikibase.php"',
		'"$IP/extensions/Wikibase/repo/ExampleSettings.php"',
		'"$IP/extensions/DismissableSiteNotice/DismissableSiteNotice.php"',
		'"$IP/extensions/APC/APC.php"',
		'"$IP/extensions/ApiSandbox/ApiSandbox.php"',
		'"$IP/extensions/MoodBar/MoodBar.php"',
		'"$IP/extensions/OAI/OAIRepo.php"'
		],
		# additional config lines
		role_config_lines => [
		'$wgShowExceptionDetails = true',
		'$wgContentHandlerUseDB = true',
		'// experimental features',
		'define( \'WB_EXPERIMENTAL_FEATURES\', true )',
		'//Profiling',
		'// Only record profiling info for pages that took longer than this',
		'$wgProfileLimit = 0.1',
		'// Log sums from profiling into "profiling" table in db',
		'$wgProfileToDatabase = true',
		'// If true, print a raw call tree instead of per-function report',
		'$wgProfileCallTree = false',
		'// Should application server host be put into profiling table',
		'$wgProfilePerHost = false',
		'// Detects non-matching wfProfileIn/wfProfileOut calls',
		'$wgDebugProfiling = true',
		'// Output debug message on every wfProfileIn/wfProfileOut',
		'$wgDebugFunctionEntry = 0',
		'// Lots of debugging output from SquidUpdate.php',
		'$wgEnableProfileInfo = true',
		'// DismissableSiteNotice',
		'$wgSiteNotice = \'<div style="font-size: 90%; background: #FFCC33; padding: 1ex; border: #940 dotted; margin-top: 1ex; margin-bottom: 1ex; ">This is a demo system that shows the current development state of Wikidata. It is going to evolve over the next few weeks. All data here can be deleted any time.<br>If you find bugs please report them in [https://bugzilla.wikimedia.org/enter_bug.cgi?product=MediaWiki%20extensions Bugzilla] for the Wikidata Client or Repo component. [https://meta.wikimedia.org/wiki/Wikidata/Development/Howto_Bugreport Here is how to submit a bug.] If you would like to discuss something or give input please use the [https://lists.wikimedia.org/mailman/listinfo/wikidata-l mailing list]. Thank you!</div>\'',
		'//Debugging',
		'$wgDebugToolbar = true',
		'$wgShowSQLErrors = true',
		'$wgShowDBErrorBacktrace = true',
		'$wgDevelopmentWarnings = true',
		'$wgEnableJavaScriptTest = true',
		'// config for extensions',
		'// OAI',
		'$oaiAgentRegex = \'!.*!\'',
		'$oaiAuth = false',
		'$oaiAudit = false',
		'// SiteMatrix',
		'$wgSiteMatrixFile = "$IP/../../mediawiki-config/langlist"',
		'$wgSiteMatrixClosedSites = "$IP/../../mediawiki-config/closed.dblist"',
		'$wgSiteMatrixPrivateSites = "$IP/../../mediawiki-config/private.dblist"',
		'$wgSiteMatrixFishbowlSites = "$IP/../../mediawiki-config/fishbowl.dblist"',
		'// MoodBar',
		'$wgGroupPermissions[\'sysop\'][\'moodbar-view\'] = true'
		]
	}
}

#  Install Wikidata client (incl. MediaWiki) from git and keep in sync with git trunk
class role::wikidata-client-latest::labs {

	class { "wikidata::singlenode":
		install_client => true,
		install_repo => false,
		database_name => "client",
		ensure => latest,
		install_path => "/srv/mediawiki",
		# all require_once lines here:
		role_requires => [
		'"$IP/extensions/Diff/Diff.php"',
		'"$IP/extensions/DataValues/DataValues.php"',
		'"$IP/extensions/Wikibase/lib/WikibaseLib.php"',
		'"$IP/extensions/Wikibase/client/WikibaseClient.php"',
		'"$IP/extensions/ParserFunctions/ParserFunctions.php"'
		],
		# additional config lines
		role_config_lines => [
		'define( \'WB_EXPERIMENTAL_FEATURES\', true )',
		'$wgShowExceptionDetails = true',
		'$wgWBSettings[\'repoUrl\'] = "//wikidata-test-repo.wikimedia.de"',
		'$wgWBSettings[\'repoArticlePath\'] = "/wiki/$1"',
		'$wgWBSettings[\'repoScriptPath\'] = "/w"',
		'// The global site ID by which this wiki is known on the repo.',
		'$wgWBSettings[\'siteGlobalID\'] = "enwiki"',
		'// Database name of the repository, for use by the pollForChanges script.',
		'// This requires the given database name to be known to LBFactory, see',
		'// $wgLBFactoryConf below.',
		'$wgWBSettings[\'changesDatabase\'] = "testrepo"',
		'$wgWBSettings[\'repoDatabase\'] = "testrepo"',
		'$wgWBSettings[\'repoNamespaces\'] = array( \'wikibase-item\' => \'Item\', \'wikibase-property\' => \'Property\' )',
		'// Load Balancer',
		'// still missing',
		'$wgSiteNotice = \'<div style="font-size: 90%; background: #FFCC33; padding: 1ex; border: #940 dotted; margin-top: 1ex; margin-bottom: 1ex; ">This is a demo system that shows the current development state of Wikidata.<br /> <strong>This is the bleeding edge.</strong><br /> Expect things to be broken. </div>\'',
		'// Profiling',
		'$wgProfileLimit = 0.1',
		'$wgProfileToDatabase = true',
		'$wgProfileCallTree = false',
		'$wgProfilePerHost = false',
		'$wgDebugProfiling = true',
		'$wgDebugFunctionEntry = 0',
		'$wgEnableProfileInfo = true',
		'$wgDebugToolbar = true',
		'error_reporting(E_ALL)',
		'ini_set("display_errors", 1)',
		'$wgDebugLogGroups[\'wikibase\'] = "/tmp/devclient-wikibase.log"',
		'$wgDebugLogGroups[\'Wikibase\LangLinkHandler\'] = "/tmp/devclient-LangLinkHandler.log"',
		'// MoodBar',
		'$wgGroupPermissions[\'sysop\'][\'moodbar-view\'] = true'
		]
	}
}

#  Install Wikidata client (incl. Mediawiki) from git and then leave it alone.
class role::wikidata-client::labs {

	class { "wikidata::singlenode":
		install_client => true,
		install_repo => false,
		database_name => "client",
		ensure => present,
		install_path => "/srv/mediawiki",
		# all require_once lines here:
		role_requires => [
		'"$IP/extensions/Diff/Diff.php"',
		'"$IP/extensions/DataValues/DataValues.php"',
		'"$IP/extensions/Wikibase/lib/WikibaseLib.php"',
		'"$IP/extensions/Wikibase/client/WikibaseClient.php"',
		'"$IP/extensions/ParserFunctions/ParserFunctions.php"'
		],
		# additional config lines
		role_config_lines => [
		'define( \'WB_EXPERIMENTAL_FEATURES\', true )',
		'$wgShowExceptionDetails = true',
		'$wgWBSettings[\'repoUrl\'] = "//wikidata-puppet-repoo.pmtpa.wmflabs"',
		'$wgWBSettings[\'repoArticlePath\'] = "/wiki/$1"',
		'$wgWBSettings[\'repoScriptPath\'] = "/w"',
		'// The global site ID by which this wiki is known on the repo.',
		'$wgWBSettings[\'siteGlobalID\'] = "enwiki"',
		'// Database name of the repository, for use by the pollForChanges script.',
		'// This requires the given database name to be known to LBFactory, see',
		'// $wgLBFactoryConf below.',
		'$wgWBSettings[\'changesDatabase\'] = "repo"',
		'$wgWBSettings[\'repoDatabase\'] = "repo"',
		'$wgWBSettings[\'repoNamespaces\'] = array( \'wikibase-item\' => \'Item\', \'wikibase-property\' => \'Property\' )',
		'// Load Balancer',
		'$wgLBFactoryConf = array( \'class\' => \'LBFactory_Multi\', \'serverTemplate\' => array( \'dbname\' => $wgDBname, \'user\' => $wgDBuser, \'password\' => $wgDBpassword, \'type\' => \'mysql\', \'flags\' => DBO_DEFAULT | DBO_DEBUG, ), \'sectionLoads\' => array( \'DEFAULT\' => array( \'localhost\' => 1, ), \'repo\' => array( \'local1\' => 1, ), ), \'sectionsByDB\' => array( $wgDBname => \'DEFAULT\', \'repo\' => \'repo\', ), \'hostsByName\' => array( \'localhost\' => \'127.0.0.1:3306\', \'local1\' => \'10.4.0.23:3306\', ), \'masterTemplateOverrides\' => array( \'fakeMaster\' => true ), )',
		'// DismissableSiteNotice',
		'$wgSiteNotice = \'<div style="font-size: 90%; background: #FFCC33; padding: 1ex; border: #940 dotted; margin-top: 1ex; margin-bottom: 1ex; ">This is a demo system that shows the current development state of Wikidata. It is going to evolve over the next few weeks. All data here can be deleted any time.<br>If you find bugs please report them in [https://bugzilla.wikimedia.org/enter_bug.cgi?product=MediaWiki%20extensions Bugzilla] for the Wikidata Client or Repo component. [https://meta.wikimedia.org/wiki/Wikidata/Development/Howto_Bugreport Here is how to submit a bug.] If you would like to discuss something or give input please use the [https://lists.wikimedia.org/mailman/listinfo/wikidata-l mailing list]. Thank you!</div>\'',
		'// Profiling',
		'$wgProfileLimit = 0.1',
		'$wgProfileToDatabase = true',
		'$wgProfileCallTree = false',
		'$wgProfilePerHost = false',
		'$wgDebugProfiling = true',
		'$wgDebugFunctionEntry = 0',
		'$wgEnableProfileInfo = true',
		'$wgDebugToolbar = true',
		'error_reporting(E_ALL)',
		'ini_set("display_errors", 1)',
		'$wgDebugLogGroups[\'wikibase\'] = "/tmp/devclient-wikibase.log"',
		'$wgDebugLogGroups[\'Wikibase\LangLinkHandler\'] = "/tmp/devclient-LangLinkHandler.log"',
		'// MoodBar',
		'$wgGroupPermissions[\'sysop\'][\'moodbar-view\'] = true'
		]
	}
}
