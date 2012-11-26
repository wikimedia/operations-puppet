# wikidata.pp
# This file is a modified copy of mediawiki.pp. It will install a mediawiki with Wikibase extensions on labs.

# A one-step class for setting up a single-node MediaWiki install,
#  running from a Git tree.

# The following are defaults, the exact specifications are in the role definitions
class wikidata::singlenode( $keep_up_to_date = true,
							$install_repo = true,
							$install_client = true,
							$role_requires = ['"$IP/extensions/Diff/Diff.php"', '"$IP/extensions/DataValues/DataValues.php"', '"$IP/extensions/UniversalLanguageSelector/UniversalLanguageSelector.php"', '"$IP/extensions/Wikibase/lib/WikibaseLib.php"'],
							$role_config_lines = [ '$wgShowExceptionDetails = true' ]) {

	class { mediawiki::singlenode:
		keep_up_to_date => $keep_up_to_date,
		role_requires => $role_requires,
		role_config_lines => $role_config_lines
	}

# install either Wikibase repo or client to /srv/mediawiki/extensions

# get the Wikibase extensions and dependencies
	git::extension { "Diff":
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"]],
			ensure => $keep_up_to_date ? {
				true => latest,
				default => present
			},
	}

	git::extension { "DataValues":
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"]],
			ensure => $keep_up_to_date ? {
				true => latest,
				default => present
			},
	}

	git::extension { "UniversalLanguageSelector":
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"]],
			ensure => $keep_up_to_date ? {
				true => latest,
				default => present
			},
	}

	git::extension { "Wikibase":
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"], Git::Extension["Diff"], Git::Extension["DataValues"]],
		ensure => $keep_up_to_date ? {
				true => latest,
				default => present
			},
	}

	exec { "populateSitesTable":
			require => [Git::Extension["Wikibase"], File["/srv/mediawiki/LocalSettings.php"]],
			cwd => "/srv/mediawiki/extensions/Wikibase/lib/maintenance",
			command => "/usr/bin/php populateSitesTable.php",
			logoutput => "on_failure",
	}

	exec { "update-script":
			require => [Git::Extension["Wikibase"], Exec["populateSitesTable"]],
			cwd => "/srv/mediawiki",
			command => "/usr/bin/php maintenance/update.php --quick",
			logoutput => "on_failure",
	}

	exec { "localisation-cache":
			require => [Git::Extension["Wikibase"], Exec["populateSitesTable"], Exec["update-script"]],
			cwd => "/srv/mediawiki",
			command => "/usr/bin/php maintenance/rebuildLocalisationCache.php",
			logoutput => "on_failure",
	}

# Wikibase repo only:
	if $install_repo == true {
		exec { "populate_repo":
			require => [Git::Extension["Wikibase"], Exec["populateSitesTable"], Exec["update-script"]],
			cwd => "/srv/mediawiki/extensions/Wikibase/repo/maintenance",
			command => "/usr/bin/php importInterlang.php --verbose --ignore-errors simple simple-elements.csv",
			logoutput => "on_failure",
			}
	}

# Wikibase client only:
	if $install_client == true {
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
			command => "/usr/bin/php /srv/mediawiki/extensions/Wikibase/lib/maintenance/pollForChanges.php > /var/log/wikidata-replication.log",
			user => 'www-data',
			minute => '*/10',
		}
	}

# longterm stuff
	if $keep_up_to_date == true {
		exec { 'wikidata_update':
			require => [Git::Clone["mediawiki"],
				Git::Extension["Diff"],
				Git::Extension["DataValues"],
				Git::Extension["UniversalLanguageSelector"],
				Git::Extension["Wikibase"],
				File["/srv/mediawiki/LocalSettings.php"]],
			command => "/usr/bin/php /srv/mediawiki/maintenance/update.php --quick --conf '/srv/mediawiki/LocalSettings.php'",
			logoutput => "on_failure",
		}
	}
}

