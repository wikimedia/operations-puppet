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

	file { "/usr/local/bin/logsplitter":
		ensure => file,
		source => "puppet:///modules/toollabs/scripts/logsplitter",
		owner => root,
		group => root,
		mode  => 0755,
	}

	# The default webserver::site class does a lot of things which
	# are completely inapropriate for the current setup (inter alia,
	# it directives that are conflicting, an inapropriate docroot,
	# and presumes a logging scheme which is completely inapropriate).
	# We install a "proper" configuration file and symlink here instead.

        webserver::apache::module { "rewrite": require => Class["webserver::apache"] }
        webserver::apache::module { "php5filter": require => Class["webserver::apache"] }
        webserver::apache::module { "setenvif": require => Class["webserver::apache"] }

	file { "/etc/apache2/sites-enabled/000-default":
		ensure => absent,
	}

	file { "/etc/apache2/sites-enabled/100-webserver":
		ensure => link,
		target => "/etc/apache2/sites-available/webserver",
		before => File["/etc/apache2/sites-available/webserver"],
		require => Package['apache2'],
	}

	file { "/etc/apache2/sites-available/webserver":
		ensure => file,
		source => "puppet:///modules/toollabs/apache/webserver",
		owner => root,
		group => root,
		mode  => 0755,
		require => [
			Package['apache2'],
			File['/usr/local/bin/logsplitter']
		],
		notify => Service['apache2'],
	}
}

