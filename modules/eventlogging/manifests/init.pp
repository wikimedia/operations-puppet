# Collector of analytic events
# See <https://wikitech.wikimedia.org/wiki/EventLogging>
class eventlogging {

	class { 'eventlogging::ganglia': }
	class { 'eventlogging::archive': }

	$python_deps = [
		'python-mysqldb',
		'python-pygments',
		'python-sqlalchemy',
		'python-zmq'
	]

	package { $python_deps:
		ensure => latest,
		before => Exec['install-eventlogging'],
	}

	package { 'supervisor': ensure => latest }

	systemuser { 'eventlogging':
		name => 'eventlogging',
	}

	git::clone { 'eventlogging':
		ensure    => latest,
		directory => '/srv/eventlogging',
		origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/extensions/EventLogging.git',
		require   => Systemuser['eventlogging'],
		notify    => Exec['install-eventlogging'],
	}

	exec { 'install-eventlogging':
		command     => 'python setup.py install',
		cwd         => '/srv/eventlogging/server',
		refreshonly => true,
	}

}
