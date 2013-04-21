# Collector of analytic events
# See <https://wikitech.wikimedia.org/wiki/EventLogging>
class eventlogging( $archive_destinations = [] ) {

	class { 'eventlogging::supervisor': }
	class { 'eventlogging::analysis': }
	class { 'eventlogging::ganglia': }
	class { 'eventlogging::archive':
		destinations => $archive_destinations,
	}

	class { 'mongodb':
		dbpath  => '/srv/mongodb',
		bind_ip => false,
	}

	class { 'eventlogging::mediawiki_errors': }

	package { [
		'python-jsonschema',
		'python-mysqldb',
		'python-pygments',
		'python-pymongo',
		'python-sqlalchemy',
		'python-zmq',
	]:
		ensure => present,
	}

	systemuser { 'eventlogging':
		name => 'eventlogging',
	}

}
