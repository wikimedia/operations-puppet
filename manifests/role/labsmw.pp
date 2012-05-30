#include "labsmysql.pp"
#include "webserver.pp"
#include "generic-definitions.pp"


# A one-step class for setting up a single-node MediaWiki install,
#  running from a Git tree.
#
# (Totally unstable and unreliable, for the moment.)
class role::labs-mediawiki-install {

        require "role::labs-mysql-server",
		"webserver::php5-mysql",
		"webserver::php5"

	package { [ "imagemagick" ] :
		ensure => latest
	}

	git::clone { "core":
		directory => "/var/www",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git";
	}

	file { '/var/www/index.php':
                require => git::clone["core"],
		ensure => 'link',
		target => '/var/www/core/index.php',
	}
}
