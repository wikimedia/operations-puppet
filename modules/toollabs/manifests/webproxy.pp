# tools-webproxy

class toollabs::webproxy {
	require webserver::apache
	require webserver::modproxy

	# The default apache::vhost class does a lot of things which
	# are completely inapropriate for the current setup (inter alia,
	# it creates directories that are unused, and presumes a logging
	# scheme which is completely inapropriate).  We install a "proper"
	# configuration file and symlink here instead.

	file { "/etc/apache2/sites-enabled/100-webproxy":
		ensure => link,
		target => "/etc/apache2/sites-available/webproxy",
		require => [
			Package['httpd'],
			File["/etc/apache2/sites-available/webproxy"] ~> Service['httpd'],
		],
	}

	file { "/etc/apache2/sites-available/webproxy":
		ensure => file,
		source => "puppet:///modules/tools/apache/webproxy",
		owner => root,
		group => root,
		mode  => 0755,
		require => Package['httpd'],
	}
}

