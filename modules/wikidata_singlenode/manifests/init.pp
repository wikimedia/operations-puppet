# wikidata.pp
# This file depends on mediawiki.pp and will install a mediawiki with Wikibase extensions on labs.

# A one-step class for setting up a single-node MediaWiki install,
#  running from a Git tree.

# The following are defaults, the exact specifications are in the role definitions
class wikidata_singlenode( $install_path = "/srv/mediawiki",
							$database_name = "repo",
							$experimental = "true",
							$repo_ip = $wikidata_repo_ip,
							$repo_url = $wikidata_repo_url,
							$client_ip = $wikidata_client_ip,
							$siteGlobalID = $wikidata_client_siteGlobalID,
							$ensure = latest,
							$install_repo = true,
							$install_client = true,
							$role_requires = ['"$IP/extensions/Diff/Diff.php"', '"$IP/extensions/DataValues/DataValues.php"', '"$IP/extensions/Wikibase/lib/WikibaseLib.php"'],
							$role_config_lines = [ '$wgShowExceptionDetails = true' ]) {

	class { mediawiki_singlenode:
		install_path => $install_path,
		database_name => $database_name,
		ensure => $ensure,
		role_requires => $role_requires,
		role_config_lines => $role_config_lines
	}


# Make mysql listen on all ports (That's o.k. in Labs)
	file { "/etc/mysql/conf.d/wikidata.cnf":
		ensure => present,
		source => "puppet:///modules/wikidata_singlenode/wikidata.cnf",
		notify => Service["mysql"],
	}

# permissions for $wgCacheDir
# make sure the parent directory exists
	file { "/var/cache/mw-cache":
		ensure => directory,
		owner => "www-data",
		 group => "www-data",
		 mode => "0755",
	}
# create a directory for instance's cache named after db
	file { "/var/cache/mw-cache/${database_name}":
		ensure => directory,
		owner => "www-data",
		group => "www-data",
		mode => "0755",
	}

# The following are settings for all Wikidata instances (repo and client)

	# enable profiling
	file { "${install_path}/StartProfiler.php":
		require => Exec["mediawiki_setup"],
		ensure => present,
		source => "puppet:///modules/wikidata_singlenode/StartProfiler.php",
	}

	# permit www-data to write to image folder
	file { "${install_path}/images":
		require => Git::Clone["mediawiki"],
		ensure => directory,
		owner => "www-data",
		group => "www-data",
		mode => 775,
		recurse => true,
	}

	# get the dependencies for Wikibase extension after the successful installation of mediawiki core
	mw-extension { [ "Diff", "DataValues" ]:
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"]],
		install_path => $install_path,
	}

	# get more extensions for Wikidata test instances
	mw-extension { [ "DismissableSiteNotice", "ApiSandbox", "OAI", "SiteMatrix" ]:
		require => Git::Clone["mediawiki"],
		install_path => $install_path,
	}
	# get "mediawiki-config" for SiteMatrix extension
	git::clone { "mwconfig":
		require => Git::Clone["mediawiki"],
		directory => "/srv/mediawiki-config",
		origin => "https://gerrit.wikimedia.org/r/p/operations/mediawiki-config.git",
	}
	# copy notitle.php file to extensions folder
	file { "${install_path}/extensions/notitle.php":
		require => Git::Clone["mediawiki"],
		ensure => present,
		source => "puppet:///modules/wikidata_singlenode/notitle.php",
	}
	# run populateSitesTable
	exec { "populateSitesTable":
			require => [Mw-extension["Wikibase"], File["${install_path}/LocalSettings.php"]],
			cwd => "${install_path}/extensions/Wikibase/lib/maintenance",
			command => "/usr/bin/php populateSitesTable.php",
			logoutput => "on_failure",
	}
	# run the update script after having cloned Wikibase
	exec { "update-script":
			require => [Mw-extension["Wikibase"], Exec["populateSitesTable"]],
			cwd => "$install_path",
			command => "/usr/bin/php maintenance/update.php --quick",
			logoutput => "on_failure",
	}
	# rebuild the LocalisationCache
	exec { "localisation-cache":
			require => [Mw-extension["Wikibase"], Exec["populateSitesTable"], Exec["update-script"]],
			cwd => "$install_path",
			command => "/usr/bin/php maintenance/rebuildLocalisationCache.php",
			timeout => "600",
			logoutput => "on_failure",
	}

# Wikibase repo only:
	if $install_repo == true {
		# items are in main namespace, so main page has to be moved first
		# get the file you want to hand over to moveBatch.php
		file {"/tmp/wikidata-move-mainpage":
			ensure => present,
			source => "puppet:///modules/wikidata_singlenode/wikidata-move-mainpage",
		}
		# run moveBatch.php
		exec { "repo_move_mainpage":
			require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"], File["/tmp/wikidata-move-mainpage"]],
			cwd => "$install_path",
			command => "/usr/bin/php maintenance/moveBatch.php --conf ${install_path}/orig/LocalSettings.php /tmp/wikidata-move-mainpage",
			logoutput => "on_failure",
		}
		# get the file that contains our repo's main page
		file { "${install_path}/wikidata-repo-mainpage.xml":
			require => Git::Clone["mediawiki"],
			ensure => present,
			source => "puppet:///modules/wikidata_singlenode/wikidata-repo-mainpage.xml",
		}
		# import our repo's main page
		exec { "repo_import_mainpage":
			require => [File["${install_path}/wikidata-repo-mainpage.xml"], Exec["repo_move_mainpage"]],
			cwd => "$install_path",
			command => "/usr/bin/php maintenance/importDump.php wikidata-repo-mainpage.xml",
			logoutput => "on_failure",
		}

		# get the extensions
		# for repo get extensions Wikibase and ULS
		mw-extension { [ "Wikibase", "UniversalLanguageSelector", "Babel", "Translate", "AbuseFilter" ]:
			require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"], Exec["repo_move_mainpage"], Mw-extension["Diff"], Mw-extension["DataValues"]],
			install_path => $install_path,
		}
		# put a repo specific settings file to $install_path (required by LocalSettings.php)
		file { "${install_path}/wikidata_repo_requires.php":
			require => [Exec["mediawiki_setup"], Exec["repo_move_mainpage"]],
			ensure => present,
			content => template('wikidata_singlenode/wikidata-repo-requires.php'),
		}
		# logo file for demo repo
		file { "/srv/mediawiki/skins/common/images/Wikidata-logo-demorepo.png":
			require => Git::Clone["mediawiki"],
			ensure => present,
			source => "puppet:///modules/wikidata_singlenode/Wikidata-logo-demorepo.png",
		}
		# import items and properties for testing
		exec { "repo_import_data":
			require => [Mw-extension["Wikibase"], Exec["populateSitesTable"], Exec["update-script"]],
			cwd => "${install_path}/extensions/Wikibase/repo/maintenance",
			command => "/usr/bin/php importInterlang.php --verbose --ignore-errors simple simple-elements.csv && /usr/bin/php importProperties.php --verbose en en-elements-properties.csv",
			logoutput => "on_failure",
		}
		# propagation of changes from repo to client
		# dispatchChanges is run by user www-data, check if it exists
		user { "www-data":
			ensure => present
		}
		# create a log file for dispatchChanges that is writeable by www-data
		file { "/var/log/dispatchChanges.log":
			ensure => present,
			owner => 'www-data',
			group => 'www-data',
			mode => '0664',
		}
		# write a cronjob for dispatchChanges to www-data's crontab
		cron { "dispatchChanges":
			require => File["/var/log/dispatchChanges.log"],
			ensure => present,
			command => "/usr/bin/php ${install_path}/extensions/Wikibase/lib/maintenance/dispatchChanges.php --verbose --max-time 598 >> /var/log/dispatchChanges.log",
			user => "www-data",
			minute => "*/10",
		}
		# make sure this log rotates sometimes
		file { "/etc/logrotate.d/wikidata-replication":
			ensure => present,
			source => "puppet:///modules/wikidata_singlenode/wikidata-replication.logrotate",
			owner => 'root',
		}
	}

# Wikibase client only:
	if $install_client == true {
		# get the extensions
		# for client get extensions Wikibase and ParserFunctions (needed) and a bunch of other extensions that are on Wikipedias
		mw-extension { [ "Wikibase", "ParserFunctions", "AbuseFilter", "AntiBot", "AntiSpoof", "APC", "ArticleFeedback", "ArticleFeedbackv5", "AssertEdit", "Babel", "CategoryTree", "CharInsert", "CheckUser", "Cite", "cldr", "ClickTracking", "CodeEditor", "Collection", "CustomData", "Echo", "EditPageTracking", "EmailCapture", "ExpandTemplates", "FeaturedFeeds", "FlaggedRevs", "Gadgets", "GlobalUsage", "ImageMap", "InputBox", "Interwiki", "LocalisationUpdate", "MarkAsHelpful", "Math", "MobileFrontend", "MwEmbedSupport", "MWSearch", "NewUserMessage", "normal", "OATHAuth", "OpenSearchXml", "Oversight", "PagedTiffHandler", "PageTriage", "PdfHandler", "Poem", "PoolCounter", "PostEdit", "ReaderFeedback", "RelatedArticles", "RelatedSites", "Renameuser", "Scribunto", "SecurePoll", "SimpleAntiSpam", "SwiftCloudFiles", "SyntaxHighlight_GeSHi", "TemplateSandbox", "TitleKey", "TorBlock", "Translate", "UserDailyContribs", "UserMerge", "Vector", "WikiEditor", "wikihiero", "WikiLove", "WikimediaMaintenance", "WikimediaMessages" ]:
			require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"], Mw-extension["Diff"], Mw-extension["DataValues"]],
			install_path => $install_path,
		}
		# put a client specific settings file to $install_path (required by LocalSettings.php)
		file { "${install_path}/wikidata_client_requires.php":
			require => Exec["mediawiki_setup"],
			ensure => present,
			content => template('wikidata_singlenode/wikidata-client-requires.php'),
		}
		# logo file for demo client
		file { "/srv/mediawiki/skins/common/images/Wikidata-logo-democlient.png":
			require => Git::Clone["mediawiki"],
			ensure => present,
			source => "puppet:///modules/wikidata_singlenode/Wikidata-logo-democlient.png",
		}
		# run populateInterwiki
		exec { "populate_interwiki":
			require => [Mw-extension["Wikibase"], Exec["update-script"]],
			cwd => "$install_path",
			command => "/usr/bin/php extensions/Wikibase/client/maintenance/populateInterwiki.php",
			logoutput => "on_failure",
		}
		# run populateSitesTable
		exec { "SitesTable_client":
			require => Mw-extension["Wikibase"],
			cwd => "$install_path",
			command => "/usr/bin/php extensions/Wikibase/lib/maintenance/populateSitesTable.php",
			logoutput => "on_failure",
		}
		# receive repo's propagation of changes with runJobs
		# create a log file for runJobs that is writeable by www-data
		file { "/var/log/runJobs.log":
			ensure => present,
			owner => 'www-data',
			group => 'www-data',
			mode => '0664',
		}
		# write a cronjob for runJobs to www-data's crontab
		cron { "runJobs":
			require => File["/var/log/runJobs.log"],
			ensure => present,
			command => "/usr/bin/php ${install_path}/maintenance/runJobs.php >> /var/log/runJobs.log",
			user => "www-data",
			minute => "*/1",
		}
		# make sure this log rotates sometimes
		file { "/etc/logrotate.d/wikidata-runJobs":
			ensure => present,
			source => "puppet:///modules/wikidata_singlenode/wikidata-runJobs.logrotate",
			owner => 'root',
		}
		# get the dump with content for testing
		file { "${install_path}/simple-elements.xml":
			require => Git::Clone["mediawiki"],
			ensure => present,
			source => "puppet:///modules/wikidata_singlenode/simple-elements.xml",
		}
		# import content for testing
		exec { "client_import_data":
			require => [Mw-extension["Wikibase"], File["${install_path}/simple-elements.xml"]],
			cwd => "$install_path",
			command => "/usr/bin/php maintenance/importDump.php simple-elements.xml",
			logoutput => "on_failure",
		}
	}

# longterm stuff: "latest" option updates core and extensions from gerrit on every puppet run.
# This is not working for core right now, but unrelated to puppet.
	if $ensure == 'latest' {
		exec { 'wikidata_update':
			require => $install_repo ? {
				true => [Git::Clone["mediawiki"], Mw-extension["UniversalLanguageSelector"], Mw-extension["Diff"], Mw-extension["DataValues"], Mw-extension["Wikibase"], File["${install_path}/LocalSettings.php"]],
				default => [Git::Clone["mediawiki"], Mw-extension["Diff"], Mw-extension["DataValues"], Mw-extension["Wikibase"], File["${install_path}/LocalSettings.php"]],
			},
			command => "/usr/bin/php ${install_path}/maintenance/update.php --quick --conf '${install_path}/LocalSettings.php'",
			logoutput => "on_failure",
		}
	}
}
