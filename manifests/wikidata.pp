# wikidata.pp
# This file is a modified copy of mediawiki.pp. It will install a mediawiki with Wikibase extensions on labs.

# A one-step class for setting up a single-node MediaWiki install,
#  running from a Git tree.
class wikidata::singlenode( $keep_up_to_date = true, $install_repo = true, $install_client = true) {
        require "role::labs-mysql-server",
		"webserver::php5-mysql",
		"webserver::php5"

	package { [ "imagemagick", "php-apc" ] :
		ensure => latest
	}

	# the following causes failures
	# class { "memcached":
	#	memcached_ip => "127.0.0.1" }

	git::clone { "mediawiki":
		directory => "/srv/mediawiki",
		branch => "master",
		timeout => 1800,
		depth => 1,
		ensure => $keep_up_to_date ? {
			true => latest,
			default => present
		},
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git",
	}

	git::clone { "nuke" :
		require => Git::Clone["mediawiki"],
		directory => "/srv/mediawiki/extensions/Nuke",
		branch => "master",
		ensure => $keep_up_to_date ? {
			true => latest,
			default => present
		},
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/Nuke.git",
	}

	git::clone { "SpamBlacklist" :
		require => Git::Clone["mediawiki"],
		directory => "/srv/mediawiki/extensions/SpamBlacklist",
		branch => "master",
		ensure => $keep_up_to_date ? {
			true => latest,
			default => present
		},
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/SpamBlacklist.git",
	}

	git::clone { "ConfirmEdit" :
		require => Git::Clone["mediawiki"],
		directory => "/srv/mediawiki/extensions/ConfirmEdit",
		branch => "master",
		ensure => $keep_up_to_date ? {
			true => latest,
			default => present
		},
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/ConfirmEdit.git",
	}

	file {
		"/etc/apache2/sites-available/wiki":
			mode => '644',
			owner => 'root',
			group => 'root',
			content => template('apache/sites/wikidata.wmflabs.org.erb'),
			ensure => present,
	}

	file { '/var/www/srv':
		ensure => 'directory',
	}

	file { '/var/www/srv/mediawiki':
		require => [File["/var/www/srv"], Git::Clone["mediawiki"]],
		ensure => 'link',
		target => '/srv/mediawiki',
	}

	if $labs_mediawiki_hostname {
		$mwserver = "http://$labs_mediawiki_hostname"
	} else {
		$mwserver = "http://$hostname.pmtpa.wmflabs"
	}

	file { '/srv/mediawiki/orig':
		require => Git::Clone["mediawiki"],
		ensure => 'directory',
	}

        exec { 'password_gen':
		require => [Git::Clone["mediawiki"],  File["/srv/mediawiki/orig"]],
		creates => "/srv/mediawiki/orig/adminpass",
		command => "/usr/bin/openssl rand -base64 32 | tr -dc _A-Z-a-z-0-9 > /srv/mediawiki/orig/adminpass"
	}
# install either Wikibase repo or client, so far either goes to /srv/mediawiki
	if $install_repo == true {
		exec { 'mediawiki_setup':
			require => [Git::Clone["mediawiki"], File["/srv/mediawiki/orig"], Exec['password_gen']],
			creates => "/srv/mediawiki/orig/LocalSettings.php",
			command => "/usr/bin/php /srv/mediawiki/maintenance/install.php Wikidata-repo admin --dbname wikidata_repo --dbuser root --passfile '/srv/mediawiki/orig/adminpass' --server $mwserver --scriptpath '/srv/mediawiki' --confpath '/srv/mediawiki/orig/'",
			logoutput => "on_failure",
		}
	} else {
		exec { 'mediawiki_setup':
			require => [Git::Clone["mediawiki"], File["/srv/mediawiki/orig"], Exec['password_gen']],
			creates => "/srv/mediawiki/orig/LocalSettings.php",
			command => "/usr/bin/php /srv/mediawiki/maintenance/install.php Wikidata-client admin --dbname wikidata_client --dbuser root --passfile '/srv/mediawiki/orig/adminpass' --server $mwserver --scriptpath '/srv/mediawiki' --confpath '/srv/mediawiki/orig/'",
			logoutput => "on_failure",
		}
	}

        apache_site { controller: name => "wiki" }
        apache_site { 000_default: name => "000-default", ensure => absent }

	apache_module { rewrite: name => "rewrite" }

	exec { 'apache_restart':
		require => [Apache_site['controller'], Apache_site['000_default']],
		command => "/usr/sbin/service apache2 restart"
	}
# include Wikibase extensions AFTER installing mediawiki
	git::clone { "Diff" :
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"]],
	        directory => "/srv/mediawiki/extensions/Diff",
	        branch => "master",
	        ensure => $keep_up_to_date ? {
				true => latest,
				default => present
			},
	        origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/Diff.git",
	}

	git::clone { "DataValues" :
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"]],
	        directory => "/srv/mediawiki/extensions/DataValues",
	        branch => "master",
	        ensure => $keep_up_to_date ? {
				true => latest,
				default => present
			},
	        origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/DataValues.git",
	}

	git::clone { "UniversalLanguageSelector" :
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"]],
	        directory => "/srv/mediawiki/extensions/UniversalLanguageSelector",
	        branch => "master",
	        ensure => $keep_up_to_date ? {
				true => latest,
				default => present
			},
	        origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/UniversalLanguageSelector.git",
	}

	git::clone { "Wikibase" :
		require => [Git::Clone["mediawiki"], Exec["mediawiki_setup"], Git::Clone["Diff"], Git::Clone["DataValues"]],
		directory => "/srv/mediawiki/extensions/Wikibase",
		branch => "master",
		ensure => $keep_up_to_date ? {
				true => latest,
				default => present
			},
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/Wikibase.git",
	}

	if $install_repo == true {
		file { '/srv/mediawiki/LocalSettings.php':
			require => Exec["mediawiki_setup"],
			content => template('mediawiki/wikibase-repo-localsettings'),
			ensure => present,
		}
	} else {
		file { '/srv/mediawiki/LocalSettings.php':
			require => Exec["mediawiki_setup"],
			content => template('mediawiki/wikibase-client-localsettings'),
			ensure => present,
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
# Controlling cron does not work, yet.
		cron {"pollForChanges":
			ensure => present,
			command => "/usr/bin/php /srv/mediawiki/extensions/Wikibase/lib/maintenance/pollForChanges.php > /var/log/wikidata-replication.log",
			user => 'www-data',
			minute => '*/10',
		}
	}

# longterm stuff
	if $keep_up_to_date == true {
		exec { 'mediawiki_update':
			require => [Git::Clone["mediawiki"],
				Git::Clone["nuke"],
				Git::Clone["SpamBlacklist"],
				Git::Clone["ConfirmEdit"],
				Git::Clone["Diff"],
				Git::Clone["DataValues"],
				Git::Clone["UniversalLanguageSelector"],
				Git::Clone["Wikibase"],
				File["/srv/mediawiki/LocalSettings.php"]],
			command => "/usr/bin/php /srv/mediawiki/maintenance/update.php --quick --conf '/srv/mediawiki/LocalSettings.php'",
			logoutput => "on_failure",
		}
	}

}

