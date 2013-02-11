# wikidata.pp
# This file depends on mediawiki.pp and will install a mediawiki with Wikibase extensions on labs.

# A one-step class for setting up a single-node MediaWiki install,
#  running from a Git tree.

# The following are defaults, the exact specifications are in the role definitions
class wikidata::singlenode( $install_path = "/srv/mediawiki",
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

	class { mediawiki::singlenode:
		install_path => $install_path,
		database_name => $database_name,
		ensure => $ensure,
		role_requires => $role_requires,
		role_config_lines => $role_config_lines
	}


# Make mysql listen on all ports (That's o.k. in Labs)
	file { "/etc/mysql/conf.d/wikidata.cnf":
		ensure => present,
		source => "puppet:///files/mediawiki/wikidata.cnf",
		notify => Service["mysql"],
	}

# permissions for $wgCacheDir
	file { "/var/cache/mw-cache":
		ensure => directory,
		owner => "www-data",
		 group => "www-data",
		 mode => "0755",
	}

	file { "/var/cache/mw-cache/${database_name}":
		ensure => directory,
		owner => "www-data",
		group => "www-data",
		mode => "0755",
	}

# install either Wikibase repo or client to ${install_path}/extensions

# enable profiling
	file { "${install_path}/StartProfiler.php":
		require => Exec["mediawiki_setup"],
		ensure => present,
		source => "puppet:///files/mediawiki/StartProfiler.php",
	}

# permit www-data to write images
	file { "${install_path}/images":
		require => Git::Clone["mediawiki"],
		ensure => directory,
		owner => "www-data",
		group => "www-data",
		mode => 775;
	}

# get the dependencies for Wikibase extension
	mw-extension { [ "Diff", "DataValues" ]:
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"]],
	}

# get more extensions for Wikidata test instances
	mw-extension { [ "DismissableSiteNotice", "ApiSandbox", "OAI", "SiteMatrix" ]:
		require => Git::Clone["mediawiki"],
	}

	git::clone { "mwconfig":
		require => Git::Clone["mediawiki"],
		directory => "/srv/mediawiki-config",
		origin => "https://gerrit.wikimedia.org/r/p/operations/mediawiki-config.git",
	}

	file { "${install_path}/extensions/notitle.php":
		require => Git::Clone["mediawiki"],
		ensure => present,
		source => "puppet:///files/mediawiki/notitle.php",
	}

	exec { "populateSitesTable":
			require => [Mw-extension["Wikibase"], File["${install_path}/LocalSettings.php"]],
			cwd => "${install_path}/extensions/Wikibase/lib/maintenance",
			command => "/usr/bin/php populateSitesTable.php",
			logoutput => "on_failure",
	}

	exec { "update-script":
			require => [Mw-extension["Wikibase"], Exec["populateSitesTable"]],
			cwd => "$install_path",
			command => "/usr/bin/php maintenance/update.php --quick",
			logoutput => "on_failure",
	}

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
		file {"/tmp/wikidata-move-mainpage":
			ensure => present,
			source => "puppet:///files/mediawiki/wikidata-move-mainpage",
		}
		exec { "repo_move_mainpage":
			require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"], File["/tmp/wikidata-move-mainpage"]],
			cwd => "$install_path",
			command => "/usr/bin/php maintenance/moveBatch.php --conf ${install_path}/orig/LocalSettings.php /tmp/wikidata-move-mainpage",
			logoutput => "on_failure",
		}
		file { "${install_path}/wikidata-repo-mainpage.xml":
			require => Git::Clone["mediawiki"],
			ensure => present,
			source => "puppet:///files/mediawiki/wikidata-repo-mainpage.xml",
		}
		exec { "repo_import_mainpage":
			require => [File["${install_path}/wikidata-repo-mainpage.xml"], Exec["repo_move_mainpage"]],
			cwd => "$install_path",
			command => "/usr/bin/php maintenance/importDump.php wikidata-repo-mainpage.xml",
			logoutput => "on_failure",
		}

# get the extensions
		mw-extension { [ "Wikibase", "UniversalLanguageSelector" ]:
			require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"], Exec["repo_move_mainpage"], Mw-extension["Diff"], Mw-extension["DataValues"]],
		}
		file { "${install_path}/wikidata_repo_requires.php":
			require => [Exec["mediawiki_setup"], Exec["repo_move_mainpage"]],
			ensure => present,
			content => template('mediawiki/wikidata-repo-requires.php'),
		}
		file { "/srv/mediawiki/skins/common/images/Wikidata-logo-demorepo.png":
			require => Git::Clone["mediawiki"],
			ensure => present,
			source => "puppet:///files/mediawiki/Wikidata-logo-demorepo.png",
		}
		exec { "repo_import_data":
			require => [Mw-extension["Wikibase"], Exec["populateSitesTable"], Exec["update-script"]],
			cwd => "${install_path}/extensions/Wikibase/repo/maintenance",
			command => "/usr/bin/php importInterlang.php --verbose --ignore-errors simple simple-elements.csv && /usr/bin/php importProperties.php --verbose en en-elements-properties.csv",
			logoutput => "on_failure",
		}
		# propagation of changes from repo to client
		user { "www-data":
			ensure => present
		}
		file { "/var/log/dispatchChanges.log":
			ensure => present,
			owner => 'www-data',
			group => 'www-data',
			mode => '0664',
		}
		cron { "dispatchChanges":
			require => File["/var/log/dispatchChanges.log"],
			ensure => present,
			command => "/usr/bin/php ${install_path}/extensions/Wikibase/lib/maintenance/dispatchChanges.php --verbose --max-time 598 >> /var/log/dispatchChanges.log",
			user => "www-data",
			minute => "*/10",
		}
		file { "/etc/logrotate.d/wikidata-replication":
			ensure => present,
			source => "puppet:///files/logrotate/wikidata-replication",
			owner => 'root',
		}
	}

# Wikibase client only:
	if $install_client == true {
# get the extensions
		mw-extension { [ "Wikibase", "ParserFunctions" ]:
			require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"], Mw-extension["Diff"], Mw-extension["DataValues"]],
		}
		file { "${install_path}/wikidata_client_requires.php":
			require => Exec["mediawiki_setup"],
			ensure => present,
			content => template('mediawiki/wikidata-client-requires.php'),
		}
		file { "/srv/mediawiki/skins/common/images/Wikidata-logo-democlient.png":
			require => Git::Clone["mediawiki"],
			ensure => present,
			source => "puppet:///files/mediawiki/Wikidata-logo-democlient.png",
		}
		exec { "populate_interwiki":
			require => [Mw-extension["Wikibase"], Exec["update-script"]],
			cwd => "$install_path",
			command => "/usr/bin/php extensions/Wikibase/client/maintenance/populateInterwiki.php",
			logoutput => "on_failure",
		}

		exec { "SitesTable_client":
			require => Mw-extension["Wikibase"],
			cwd => "$install_path",
			command => "/usr/bin/php extensions/Wikibase/lib/maintenance/populateSitesTable.php",
			logoutput => "on_failure",
		}
		# receive repo's propagation of changes
		file { "/var/log/runJobs.log":
			ensure => present,
			owner => 'www-data',
			group => 'www-data',
			mode => '0664',
		}
		cron { "runJobs":
			require => File["/var/log/runJobs.log"],
			ensure => present,
			command => "/usr/bin/php ${install_path}/maintenance/runJobs.php >> /var/log/runJobs.log",
			user => "www-data",
			minute => "*/1",
		}
		file { "/etc/logrotate.d/wikidata-runJobs":
			ensure => present,
			source => "puppet:///files/logrotate/wikidata-runJobs",
			owner => 'root',
		}
		file { "${install_path}/simple-elements.xml":
			require => Git::Clone["mediawiki"],
			ensure => present,
			source => "puppet:///files/mediawiki/simple-elements.xml",
		}
		exec { "client_import_data":
			require => [Mw-extension["Wikibase"], File["${install_path}/simple-elements.xml"]],
			cwd => "$install_path",
			command => "/usr/bin/php maintenance/importDump.php simple-elements.xml",
			logoutput => "on_failure",
		}
	}

# longterm stuff
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
