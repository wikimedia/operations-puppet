#####  This file is obsolete; please direct your attention to labsmediawiki.pp instead.



#include "labsmysql.pp"
#include "webserver.pp"
#include "generic-definitions.pp"


class apachesetup {
	file { "/etc/apache2/httpd.conf":
		path => "/etc/apache2/httpd.conf",
		source => "puppet:///files/apache/rewrite.conf",
		ensure => present
	}

	apache_module { rewrite: name => "rewrite" }
}

# A one-step class for setting up a single-node MediaWiki install,
#  running from a Git tree.
#
# (Totally unstable and unreliable, for the moment.)
class role::labs-mediawiki-install {

        require "apachesetup",
		"role::labs-mysql-server",
		"webserver::php5-mysql",
		"webserver::php5"

	package { [ "imagemagick" ] :
		ensure => latest
	}

	git::clone { "wiki":
		directory => "/var/www",
		branch => "master",
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git";
	}
}
