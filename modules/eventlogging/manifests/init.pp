# Collector of analytic events
# See <https://wikitech.wikimedia.org/wiki/EventLogging>
class eventlogging( $archive_destinations = [] ) {

	class { 'eventlogging::supervisor': }
	class { 'eventlogging::analysis': }
	class { 'eventlogging::ganglia': }
	class { 'eventlogging::archive':
		destinations => $archive_destinations,
	}

	package { [
		'python-jsonschema',
		'python-mysqldb',
		'python-pygments',
		'python-sqlalchemy',
		'python-zmq',
	]:
		ensure => present,
	}

	systemuser { 'eventlogging':
		name => 'eventlogging',
	}

}
