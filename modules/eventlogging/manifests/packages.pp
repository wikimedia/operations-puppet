# == Class: eventlogging::packages
#
# This class configures EventLogging package dependencies.
#
class eventlogging::packages {
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
}
