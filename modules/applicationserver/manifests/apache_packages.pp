class applicationserver::apache_packages {
	include applicationserver::packages

	package { "libapache2-mod-php5":
		ensure => "5.3.10-1ubuntu3.4+wmf1";
	}
}
