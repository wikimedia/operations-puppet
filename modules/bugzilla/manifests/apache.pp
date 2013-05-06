# == Class: bugzilla::apache
#
# Configures Apache HTTP Server to serve Bugzilla.
#
class bugzilla::apache {
	# Enabling Apache's mod_headers and mod_expires makes it possible to
	# upgrade Bugzilla without requiring that all users clear their
	# browser cache.

	if !defined(Package['apache2']) {
		package { 'apache2':
			ensure => present,
		}
	}

	if !defined(Service['apache2']) {
		service { 'apache2':
			ensure     => running,
			provider   => 'init',
			require    => Package['apache2'],
			hasrestart => true,
		}
	}

	exec { 'a2enmod headers':
		unless  => 'apache2ctl -M 2>&1 | grep -q headers',
		path    => [ '/bin', '/usr/sbin' ],
		require => Package['apache2'],
		notify  => Service['apache2'],
	}

	exec { 'a2enmod expires':
		unless  => 'apache2ctl -M 2>&1 | grep -q expires',
		path    => [ '/bin', '/usr/sbin' ],
		require => Package['apache2'],
		notify  => Service['apache2'],
	}
}
