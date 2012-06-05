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
		directory => "/srv/",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git";
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
		require => File['/var/www/srv'],
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

	exec { 'mediawiki_setup':
		require => [git::clone["mediawiki"],  File["/srv/mediawiki/orig"]],
		unless => "/usr/bin/test -e /srv/mediawiki/orig/LocalSettings.php",
		command => "/usr/bin/php /srv/mediawiki/maintenance/install.php testwiki admin --dbname testwiki --dbuser root --pass adminpassword --server $mwserver --scriptpath '/srv/mediawiki' --confpath '/srv/mediawiki/orig/'",
	}

        apache_site { '000_default': name => "000-default", ensure => absent }
        apache_site { 'controller': 
		require => apache_site['000_default'],
		name => "wiki",
		notify => Service["apache2"]
	}

	file { '/srv/mediawiki/LocalSettings.php':
		require => exec["mediawiki_setup"],
		content => template('mediawiki/labs-localsettings'),
		ensure => present,
	}
}
