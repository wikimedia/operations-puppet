# == Class: role::eventlogging
# This role configures an instance to act as the primary EventLogging
# log processor for the cluster. The setup is described in detail on
# <https://wikitech.wikimedia.org/wiki/EventLogging>.
#
# XXX(ori-l, 3-Jul-2013): Document this better.
#
class role::eventlogging {
	system_role { 'misc::log-collector':
		description => 'EventLogging log collector',
	}

	include eventlogging
	include eventlogging::monitor

	class { 'eventlogging::archive':
		destinations => [ 'stat1.wikimedia.org', 'stat1002.eqiad.wmnet' ],
	}

	class { 'mongodb':
		dbpath  => '/srv/mongodb',
		bind_ip => false,
		auth    => true,
	}

	require passwords::mongodb::eventlogging  # RT 5101
	$mongo_user = $passwords::mongodb::eventlogging::user
	$mongo_pass = $passwords::mongodb::eventlogging::password

	require passwords::mysql::eventlogging    # RT 4752
	$mysql_user = $passwords::mysql::eventlogging::user
	$mysql_pass = $passwords::mysql::eventlogging::password

	eventlogging::service::forwarder {
		'8421':
			ensure => present,
			count  => true;
		'8422':
			ensure => present;
	}

	eventlogging::service::processor {
		'server-side events':
			format => '%n EventLogging %j',
			input  => 'tcp://localhost:8421',
			output => 'tcp://*:8521';
		'client-side events':
			format => '%q %l %n %t %h',
			input  => 'tcp://localhost:8422',
			output => 'tcp://*:8522';
	}

	eventlogging::service::multiplexer { 'all events':
		inputs => [ 'tcp://127.0.0.1:8521', 'tcp://127.0.0.1:8522' ],
		output => 'tcp://*:8600',
	}

	eventlogging::service::consumer {
		'vanadium':
			input  => 'tcp://vanadium.eqiad.wmnet:8600',
			output => "mongodb://${mongo_user}:${mongo_pass}@vanadium.eqiad.wmnet:27017";
		'mysql-db1047':
			input  => 'tcp://vanadium.eqiad.wmnet:8600',
			output => "mysql://${mysql_user}:${mysql_pass}@db1047.eqiad.wmnet/log?charset=utf8";
		'server-side-events.log':
			input  => 'tcp://vanadium.eqiad.wmnet:8421',
			output => 'file:///var/log/eventlogging/server-side-events.log';
		'client-side-events.log':
			input  => 'tcp://vanadium.eqiad.wmnet:8422',
			output => 'file:///var/log/eventlogging/client-side-events.log';
		'all-events.log':
			input  => 'tcp://vanadium.eqiad.wmnet:8600',
			output => 'file:///var/log/eventlogging/all-events.log';
	}
}
