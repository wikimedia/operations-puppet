# Collector of analytic events
# See <https://wikitech.wikimedia.org/wiki/EventLogging>
class eventlogging {

	include rsync::server
	include eventlogging::ganglia
	include eventlogging::archive

	package { [
		'python-mysqldb',
		'python-pygments',
		'python-sqlalchemy',
		'python-zmq',
		'supervisor',
	]:
		ensure => latest,
	}

	systemuser { 'eventlogging':
		name => 'eventlogging',
	}

	git::clone { 'eventlogging':
		ensure    => latest,
		directory => '/var/eventlogging',
		origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/extensions/EventLogging.git',
		require   => Systemuser['eventlogging'],
		notify    => Exec['install-eventlogging'],
	}

	exec { 'install-eventlogging':
		command     => 'python setup.py install',
		cwd         => '/var/eventlogging/server',
		refreshonly => true,
	}

}
