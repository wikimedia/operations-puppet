# Collector of analytic events
# See <https://wikitech.wikimedia.org/wiki/EventLogging>
class eventlogging {

	class { 'eventlogging::supervisor': }
	class { 'eventlogging::analysis': }
	class { 'eventlogging::ganglia': }
	class { 'eventlogging::archive':
		destinations => [ 'stat1.wikimedia.org' ],
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
