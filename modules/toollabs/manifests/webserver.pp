# tools-webserver-xx

class toollabs::webserver {
	require webserver::apache
	require toollabs::run_environ
	require gridengine::submit_host

	package { [
			'libapache2-mod-php5filter',
			'libapache2-mod-suphp']:
		ensure => latest,
	}

	# The default apache::vhost class does a lot of things which
	# are completely inapropriate for the current setup (inter alia,
	# it creates directories that are unused, and presumes a logging
	# scheme which is completely inapropriate).  We install a "proper"
	# configuration file and symlink here instead.

	file { "/etc/apache2/sites-enabled/100-webserver":
		ensure => link,
		target => "/etc/apache2/sites-available/webserver",
		require => [
			Package['httpd'],
			File["/etc/apache2/sites-available/webserver"] ~> Service['httpd'],
		],
	}

	file { "/etc/apache2/sites-available/webserver":
		ensure => file,
		source => "puppet:///modules/tools/apache/webserver",
		owner => root,
		group => root,
		mode  => 0755,
		require => Package['httpd'],
	}
}

