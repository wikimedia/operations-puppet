# application server required packages
class applicationserver::packages {

	package { [ "libapache2-mod-php5", "php5-cli", "php-pear", "php5-common", "php5-curl", "php5-mysql", "php5-xmlrpc",
			"php5", "php-wikidiff2", "php5-wmerrors", "php5-intl" ]:
		ensure => latest;
	}

	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "12.04") >= 0 {
		# On Precise, the 'php5' packages also provides the 'php5-fpm' which
		# install an unneeded fast CGI server.
		package { [ "php5-fpm" ]:
			ensure => absent;
		}
	}

	# Explicitly require the Wikimedia version of some packages
	generic::apt::pin-package{ [ "php-wikidiff2" ]: pin => "release o=Wikimedia" }
}