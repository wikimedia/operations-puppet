# wikidata.pp
# This file depends on mediawiki.pp and will install a mediawiki with Wikibase extensions on labs.

# A one-step class for setting up a single-node MediaWiki install,
#  running from a Git tree.

# The following are defaults, the exact specifications are in the role definitions
class wikidata::singlenode( $install_path = "/srv/mediawiki",
							$database_name = "repo",
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

# install either Wikibase repo or client to ${install_path}/extensions

# enable profiling
	file { "${install_path}/StartProfiler.php":
		require => Exec["mediawiki_setup"],
		ensure => present,
		source => "puppet:///files/mediawiki/StartProfiler.php",
	}

# get the Wikibase extensions and dependencies
	git::clone { "Diff" :
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"]],
			directory => "${install_path}/extensions/Diff",
			branch => "master",
			ensure => $ensure,
			origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/Diff.git",
	}

	git::clone { "DataValues" :
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"]],
			directory => "${install_path}/extensions/DataValues",
			branch => "master",
			ensure => $ensure,
			origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/DataValues.git",
	}

	git::clone { "Wikibase" :
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"], Git::Clone["Diff"], Git::Clone["DataValues"]],
		directory => "${install_path}/extensions/Wikibase",
		branch => "master",
		ensure => $ensure,
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/Wikibase.git",
	}

# get more extensions for Wikidata test instances
	git::clone { "DismissableSiteNotice" :
		require => Git::Clone["mediawiki"],
		directory => "${install_path}/extensions/DismissableSiteNotice",
		branch => "master",
		ensure => $ensure,
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/DismissableSiteNotice.git",
	}

	git::clone { "ApiSandbox":
		require => Git::Clone["mediawiki"],
		directory => "${install_path}/extensions/ApiSandbox",
		branch => "master",
		ensure => $ensure,
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/ApiSandbox.git",
	}

	git::clone { "Moodbar":
		require => Git::Clone["mediawiki"],
		directory => "${install_path}/extensions/MoodBar",
		branch => "master",
		ensure => $ensure,
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/MoodBar.git",
	}

	git::clone { "OAI":
		require => Git::Clone["mediawiki"],
		directory => "${install_path}/extensions/OAI",
		branch => "master",
		ensure => $ensure,
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/OAI.git",
	}

	git::clone { "mwconfig":
		require => Git::Clone["mediawiki"],
		directory => "/srv/mediawiki-config",
		origin => "https://gerrit.wikimedia.org/r/p/operations/mediawiki-config.git",
	}

	git::clone { "SiteMatrix":
		require => Git::Clone["mediawiki"],
		directory => "${install_path}/extensions/SiteMatrix",
		branch => "master",
		ensure => $ensure,
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/SiteMatrix.git",
	}

	exec { "populateSitesTable":
			require => [Git::Clone["Wikibase"], File["${install_path}/LocalSettings.php"]],
			cwd => "${install_path}/extensions/Wikibase/lib/maintenance",
			command => "/usr/bin/php populateSitesTable.php",
			logoutput => "on_failure",
	}

	exec { "update-script":
			require => [Git::Clone["Wikibase"], Exec["populateSitesTable"]],
			cwd => "$install_path",
			command => "/usr/bin/php maintenance/update.php --quick",
			logoutput => "on_failure",
	}

	exec { "localisation-cache":
			require => [Git::Clone["Wikibase"], Exec["populateSitesTable"], Exec["update-script"]],
			cwd => "$install_path",
			command => "/usr/bin/php maintenance/rebuildLocalisationCache.php",
			timeout => "600",
			logoutput => "on_failure",
	}

# Wikibase repo only:
	if $install_repo == true {
		file { "${install_path}/repo_requires.php":
			require => Exec["mediawiki_setup"],
			ensure => present,
			content => template('mediawiki/wikidata-repo-role-requires.php'),
		}
		git::clone { "UniversalLanguageSelector" :
			require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"]],
				directory => "${install_path}/extensions/UniversalLanguageSelector",
				branch => "master",
				ensure => $ensure,
				origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/UniversalLanguageSelector.git",
		}
		file { "/etc/mysql/conf.d/wikidata.cnf":
			ensure => present,
			source => "puppet:///files/mediawiki/wikidata.cnf",
			notify => Service["mysql"],
		}
		exec { "repo_import_data":
			require => [Git::Clone["Wikibase"], Exec["populateSitesTable"], Exec["update-script"]],
			cwd => "${install_path}/extensions/Wikibase/repo/maintenance",
			command => "/usr/bin/php importInterlang.php --verbose --ignore-errors simple simple-elements.csv && /usr/bin/php importProperties.php --verbose en en-elements-properties.csv",
			logoutput => "on_failure",
		}
	}

# Wikibase client only:
	if $install_client == true {
		file { "${install_path}/client_requires.php":
			require => Exec["mediawiki_setup"],
			ensure => present,
			content => template('mediawiki/wikidata-client-role-requires.php'),
		}
		exec { "populate_interwiki":
			require => [Git::Clone["Wikibase"], Exec["update-script"]],
			cwd => "$install_path",
			command => "/usr/bin/php extensions/Wikibase/client/maintenance/populateInterwiki.php",
			logoutput => "on_failure",
		}

		exec { "SitesTable_client":
			require => Git::Clone["Wikibase"],
			cwd => "$install_path",
			command => "/usr/bin/php extensions/Wikibase/lib/maintenance/populateSitesTable.php",
			logoutput => "on_failure",
		}

		user { "www-data":
			ensure => present
		}
		file { "/etc/logrotate.d/wikidata-replication":
			ensure => present,
			source => "puppet:///files/logrotate/wikidata-replication",
			owner => 'root',
		}
		file { "/var/log/wikidata-replication.log":
			ensure => present,
			owner => 'www-data',
			group => 'www-data',
			mode => '0664',
		}
		cron {"pollForChanges":
			ensure => present,
			command => "/usr/bin/php ${install_path}/extensions/Wikibase/lib/maintenance/pollForChanges.php > /var/log/wikidata-replication.log",
			user => 'www-data',
			minute => '*/10',
		}
		git::clone { "ParserFunctions":
			require => Git::Clone["mediawiki"],
			directory => "${install_path}/extensions/ParserFunctions",
			branch => "master",
			ensure => $ensure,
			origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/ParserFunctions.git",
		}
		file { "${install_path}/simple-elements.xml":
			ensure => present,
			source => "puppet:///files/mediawiki/simple-elements.xml",
		}
		exec { "client_import_data":
			require => [Git::Clone["Wikibase"], File["${install_path}/simple-elements.xml"]],
			cwd => "$install_path",
			command => "/usr/bin/php maintenance/importDump.php simple-elements.xml",
			logoutput => "on_failure",
		}
	}

# longterm stuff
	if $ensure == 'latest' {
		exec { 'wikidata_update':
			require => [Git::Clone["mediawiki"],
				Git::Clone["Diff"],
				Git::Clone["DataValues"],
				Git::Clone["UniversalLanguageSelector"],
				Git::Clone["Wikibase"],
				File["${install_path}/LocalSettings.php"]],
			command => "/usr/bin/php ${install_path}/maintenance/update.php --quick --conf '${install_path}/LocalSettings.php'",
			logoutput => "on_failure",
		}
	}
}

