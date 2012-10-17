#include "labsmysql.pp"
#include "webserver.pp"
#include "generic-definitions.pp"


# A one-step class for setting up a single-node MediaWiki install,
#  running from a Git tree.
#
# (Totally unstable and unreliable, for the moment.)
class role::mediawiki-install::labs {

        require "role::labs-mysql-server",
		"webserver::php5-mysql",
		"webserver::php5"

	package { [ "imagemagick", "php-apc",  ] :
		ensure => latest
	}

	class { "memcached":
		memcached_ip => "127.0.0.1" }

	git::clone { "mediawiki":
		directory => "/srv/mediawiki",
		branch => "master",
		timeout => 1800,
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git";
	}

	git::clone { "nuke" :
		require => git::clone["mediawiki"],
		directory => "/srv/mediawiki/extensions/Nuke",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/Nuke.git";
	}

	git::clone { "SpamBlacklist" :
		require => git::clone["mediawiki"],
		directory => "/srv/mediawiki/extensions/SpamBlacklist",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/SpamBlacklist.git";
	}

	git::clone { "ConfirmEdit" :
		require => git::clone["mediawiki"],
		directory => "/srv/mediawiki/extensions/ConfirmEdit",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/ConfirmEdit.git";
	}

	file {
		"/etc/apache2/sites-available/wiki":
			mode => 644,
			owner => root,
			group => root,
			content => template('apache/sites/simplewiki.wmflabs.org'),
			ensure => present;
	}

	file { '/var/www/srv':
		ensure => 'directory';
	}

	file { '/var/www/srv/mediawiki':
		require => [File['/var/www/srv'], git::clone['mediawiki']],
		ensure => 'link',
		target => '/srv/mediawiki';
	}

	if $labs_mediawiki_hostname {
		$mwserver = "http://$labs_mediawiki_hostname"
	} else {
		$mwserver = "http://$hostname.pmtpa.wmflabs"
	}

	file { '/srv/mediawiki/orig':
		require => git::clone["mediawiki"],
		ensure => 'directory';
	}

        exec { 'password_gen':
		require => [git::clone["mediawiki"],  File["/srv/mediawiki/orig"]],
		creates => "/srv/mediawiki/orig/adminpass",
		command => "/usr/bin/openssl rand -base64 32 | tr -dc _A-Z-a-z-0-9 > /srv/mediawiki/orig/adminpass"
	}

	exec { 'mediawiki_setup':
		require => [git::clone["mediawiki"],  File["/srv/mediawiki/orig"], exec['password_gen']],
		creates => "/srv/mediawiki/orig/LocalSettings.php",
		command => "/usr/bin/php /srv/mediawiki/maintenance/install.php testwiki admin --dbname testwiki --dbuser root --passfile '/srv/mediawiki/orig/adminpass' --server $mwserver --scriptpath '/srv/mediawiki' --confpath '/srv/mediawiki/orig/'",
		logoutput => "on_failure",
	}

        apache_site { controller: name => "wiki" }
        apache_site { 000_default: name => "000-default", ensure => absent }

	exec { 'apache_restart':
		require => [Apache_site['controller'], Apache_site['000_default']],
		command => "/usr/sbin/service apache2 restart"
	}

	file { '/srv/mediawiki/LocalSettings.php':
		require => Exec["mediawiki_setup"],
		content => template('mediawiki/labs-localsettings'),
		ensure => present,
	}
}

class role::mediawiki-update::labs {
	require role::mediawiki-install::labs

	git::clone { "mediawiki-update":
		directory => "/srv/mediawiki",
		branch => "master",
		timeout => 1800,
		ensure => 'latest',
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git";
	}

	git::clone { "nuke-update" :
		require => git::clone["mediawiki-update"],
		directory => "/srv/mediawiki/extensions/Nuke",
		branch => "master",
		ensure => 'latest',
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/Nuke.git";
	}

	git::clone { "SpamBlacklist-update" :
		require => git::clone["mediawiki-update"],
		directory => "/srv/mediawiki/extensions/SpamBlacklist",
		branch => "master",
		ensure => 'latest',
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/SpamBlacklist.git";
	}

	git::clone { "ConfirmEdit-update" :
		require => git::clone["mediawiki-update"],
		directory => "/srv/mediawiki/extensions/ConfirmEdit",
		branch => "master",
		ensure => 'latest',
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/ConfirmEdit.git";
	}

	exec { 'mediawiki_update':
		require => [git::clone["mediawiki-update"], git::clone["nuke-update"], git::clone["SpamBlacklist-update"],
			git::clone["ConfirmEdit-update"], File["/srv/mediawiki/LocalSettings.php"]],
		command => "/usr/bin/php /srv/mediawiki/maintenance/update.php --quick --conf '/srv/mediawiki/LocalSettings.php'",
		logoutput => " ",
	}
}