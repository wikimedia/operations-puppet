# Collector of analytic events
# See <https://wikitech.wikimedia.org/wiki/EventLogging>
class eventlogging {

	class { 'eventlogging::ganglia': }
	class { 'eventlogging::archive': }

	package { [
		'python-mysqldb',
		'python-pygments',
		'python-sqlalchemy',
		'python-zmq',
		'supervisor'
	]:
		ensure => present,
	}

	systemuser { 'eventlogging':
		name => 'eventlogging',
	}

}
