#include "labsmysql.pp"
#include "webserver.pp"
#include "generic-definitions.pp"


class apachesetup {
	apache_module { rewrite: name => "rewrite" }
}

# A one-step class for setting up a single-node MediaWiki install,
#  running from a Git tree.
#
# (Totally unstable and unreliable, for the moment.)
class role::mediawiki-install::labs {

        require  "apachesetup",
		"role::labs-mysql-server",
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

        apache_site { controller: name => "wiki" }
        apache_site { 000_default: name => "000-default", ensure => absent }
}
