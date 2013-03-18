class applicationserver::apache_packages {
	include applicationserver::packages

	package { 'libapache2-mod-php5':
		ensure => present,
	}
}
