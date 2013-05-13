# == Class: eventlogging::mongo
#
# Provisions a MongoDB instance and an EventLogging subscriber that
# writes an event stream into that instance.
#
# === Parameters
#
# [*db_user*]
#   MongoDB user name.
#
# [*db_pass*]
#   MongoDB password.
#
# [*db_path*]
#   Path in the local filesystem where MongoDB's database files will
#   reside (default: '/srv/mongodb').
#
# [*socket_id*]
#   ZeroMQ socket identity. A short string unique to this subscriber
#   that the publisher uses to know which messages to replay from the
#   buffer in case of a disconnect. The default is '<hostname>-mongo'.
#
# [*pub_stream*]
#   URI of ZeroMQ publisher that is publishing an event stream. Default:
#   "tcp://localhost:8600".
#
# === Examples
#
#  class { 'eventlogging::mongo':
#    db_user => 'eventlogger',
#    db_pass => 'secret',
#  }
#
class eventlogging::mongo(
	$db_user,
	$db_pass,
	$db_path    = '/srv/mongodb',
	$socket_id  = "${::hostname}-mongo",
	$pub_stream = 'tcp://localhost:8600',
) {
	include eventlogging
	include eventlogging::supervisor

	package { 'python-pymongo':
		ensure => present,
	}

	class { '::mongodb':
		dbpath  => $db_path,
		bind_ip => false,
		auth    => true,
	}

	file { '/etc/supervisor/eventlogging.mongodb.conf':
		content => template('eventlogging/eventlogging.mongodb.conf.erb'),
		require => [ Package['supervisor'], Systemuser['eventlogging'] ],
		notify  => Service['supervisor'],
		mode    => '0644',
	}
}
