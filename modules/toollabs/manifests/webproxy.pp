# tools-webproxy

class toollabs::webproxy {
	require webserver::apache
	require webserver::modproxy

	# The default webserver::site class does a lot of things which
	# are completely inapropriate for the current setup (inter alia,
	# it directives that are conflicting, an inapropriate docroot,
	# and presumes a logging scheme which is completely inapropriate).
	# We install a "proper" configuration file and symlink here instead.

        webserver::apache::module { "rewrite": require => Class["webserver::apache"] }

	file { "/etc/apache2/sites-enabled/000-default":
		ensure => absent,
	}

	file { "/etc/apache2/sites-enabled/100-webproxy":
		ensure => link,
		target => "/etc/apache2/sites-available/webproxy",
		before => File["/etc/apache2/sites-available/webproxy"],
		require => Package['apache2'],
	}

	file { "/etc/apache2/sites-available/webproxy":
		ensure => file,
		source => "puppet:///modules/toollabs/apache/webproxy",
		owner => root,
		group => root,
		mode  => 0755,
		require => Package['apache2'],
		notify => Service['apache2'],
	}
}

