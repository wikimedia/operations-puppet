# https://racktables.wikimedia.org

## Please note that Racktables is a tarball extraction based installation
## into its web directory root.  This means that puppet cannot fully automate
## the installation at this time & the actual tarball must be downloaded from
## http://racktables.org/ and unzipped into /srv/org/wikimedia/racktables

class role::racktables {

	system_role { 'role::racktables': description => 'Racktables' }

	include standard,
	php5-gd,
	misc::racktables

	class {'webserver::php5': ssl => true; }

	install_certificate{ "${racktables_ssl_cert}" }


	# dependencies
	Class['webserver::php5'] -> apache_module['rewrite'] ->
	Install_certificate["${racktables_ssl_cert}"]

	# be flexible about labs vs. prod
	case $::realm {
		labs: {
			$racktables_host = "${instancename}.${domain}"
			$racktables_ssl_cert = '/etc/ssl/certs/star.wmflabs.pem'
			$racktables_ssl_key = '/etc/ssl/private/star.wmflabs.key'
			$racktables_ssl_cert = 'star.wmflabs.org'
		}
		production: {
			$racktables_host = 'racktables.wikimedia.org'
			$racktables_ssl_cert = '/etc/ssl/certs/star.wikimedia.org.pem'
			$racktables_ssl_key = '/etc/ssl/private/star.wikimedia.org.key'
			$racktables_ssl_cert = 'star.wikimedia.org'
		}
		default: {
			fail('unknown realm, should be labs or production')
		}
	}


	file {
		"/etc/apache2/sites-available/${racktables_host}":
		ensure  => present,
		mode    => '0444',
		owner   => 'root',
		group   => 'root',
		notify  => Service['apache2'],
		content => template('apache/sites/racktables.wikimedia.org.erb');
	}

	apache_site { 'racktables': name => "${racktables_host}" }
	apache_confd { 'namevirtualhost': install => true, name => 'namevirtualhost' }
	apache_module { 'rewrite': name => 'rewrite' }




}
