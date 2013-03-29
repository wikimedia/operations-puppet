# application server required packages
class applicationserver::packages {

	package { [ "php5-cli", "php-pear", "php5-common", "php5-curl", "php5-mysql", "php5-xmlrpc",
			"php5", "php5-intl" ]:
		ensure => latest;
	}
	package { [ "php-wikidiff2", "php5-wmerrors",  "php-luasandbox", "php5-redis",
			"php5-memcached", "libmemcached10", "php5-igbinary"  ]:
		ensure => latest;
	}
	# used by Score extension to render MIDI to Ogg Vorbis
	package { [ "lilypond" ]:
		ensure => latest;
	}

	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "12.04") >= 0 {
		# On Precise, the 'php5' packages also provides the 'php5-fpm' which
		# install an unneeded fast CGI server.
		package { [ "php5-fpm" ]:
			ensure => absent;
		}
	}
}
