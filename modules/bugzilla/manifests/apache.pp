# == Class: bugzilla::apache
#
# Configures Apache HTTP Server to serve Bugzilla.
#
class bugzilla::apache {
	# Enabling Apache's mod_headers and mod_expires makes it possible to
	# upgrade Bugzilla without requiring that all users clear their
	# browser cache.

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
