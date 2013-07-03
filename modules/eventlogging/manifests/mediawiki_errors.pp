# == Class: eventlogging::mediawiki_errors
#
# Monitors MediaWiki exceptions and fatals using Ganglia.
#
# === Parameters
#
# [*port*]
#   UDP port to listen on.
#
class eventlogging::mediawiki_errors($port = 8423) {

	file { '/usr/lib/ganglia/python_modules/mwerrors.py':
		ensure  => present,
		source  => 'puppet:///modules/eventlogging/mwerrors.py',
		require => [
			File['/usr/lib/ganglia/python_modules'],
			Package['python-zmq'],
		],
	}

	# FIXME(ori-l, 3-Jul-2013): We're no longer using supervisord.
	file { '/etc/supervisor/conf.d/mwerrors.conf':
		content => template('eventlogging/mwerrors.conf.erb'),
		require => [ Package['supervisor'], User['eventlogging'] ],
		notify  => Service['supervisor'],
		mode    => '0444',
	}

	file { '/etc/ganglia/conf.d/mwerrors.pyconf':
		ensure   => present,
		content  => template('eventlogging/mwerrors.pyconf.erb'),
		require  => [
			File['/etc/ganglia/conf.d'],
			File['/usr/lib/ganglia/python_modules/mwerrors.py'],
			File['/etc/supervisor/conf.d/mwerrors.conf'],
		],
		notify   => Service[gmond],
	}

}
