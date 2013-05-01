# misc/logging.pp
# any logging hosts

class misc::syslog-server($config="nfs") {
	system_role { "misc::syslog-server": description => "central syslog server ($config)" }

	package { syslog-ng:
		ensure => latest;
	}

	file { "/etc/syslog-ng/syslog-ng.conf":
		require => Package[syslog-ng],
		source => "puppet:///files/syslog-ng/syslog-ng.conf.${config}",
		mode => 0444;
	}
	
	# FIXME: handle properly
	if $config == "nfs" {
		file { "/etc/logrotate.d/remote-logs":
			source => "puppet:///files/syslog-ng/remote-logs",
			mode => 0444;
		"/home/wikipedia/syslog":
			owner => root,
			group => root,
			mode  => 0755;
		}
	}

	service { syslog-ng:
		require => [ Package[syslog-ng], File["/etc/syslog-ng/syslog-ng.conf"] ],
		subscribe => File["/etc/syslog-ng/syslog-ng.conf"],
		ensure => running;
	}
}




class misc::logging::socat {
	package { 'socat':
		ensure => 'installed',
	}
}


# == Define misc::logging::multicast-relay
# Sets up a UDP unicast to multicast relay process.
#
# == Parameters:
# $listen_port       - The port on which to accept UDP traffic for relay.
# $destination_ip
# $destination_port
# $multicast         - boolean.  Default false.  If true, the received traffic will be relayed to multicast group specified by $destination_ip and $destination_port.
define misc::logging::relay(
	$listen_port,
	$destination_ip,
	$destination_port,
	$multicast = false,
)
{
	require misc::logging::socat

	# Configure and start the upstart job for
	# luanching the socat multicast relay daemon.
	# Note: Not using upstart_job define here since
	# it doesn't support using ERb templates.

	if $multicast {
		$daemon_name = "${title}-multicast-relay"
	}
	else {
		$daemon_name = "${title}-unicast-relay"
	}

	# Create symlink
	file { "/etc/init.d/${daemon_name}":
		ensure => 'link',
		target => '/lib/init/upstart-job';
	}

	file { "/etc/init/${daemon_name}.conf":
		content => template('misc/logging-relay.upstart.conf.erb'),
	}

	service { "${daemon_name}":
		ensure    => running,
		require   => Package['socat'],
		subscribe => File["/etc/init/${daemon_name}.conf"],
		provider  => 'upstart',
	}
}


# NOTE:  This class is depcreated.
# It will be removed once oxygen is no longer using it.
class misc::squid-logging::multicast-relay {
	require misc::logging::socat

	system_role { "misc::squid-logging::multicast-relay": description => "Squid logging unicast to multicast relay" }

	upstart_job { "squid-logging-multicast-relay": install => "true" }

	service { squid-logging-multicast-relay:
		require => [ Package[socat], Upstart_job[squid-logging-multicast-relay] ],
		subscribe => Upstart_job[squid-logging-multicast-relay],
		ensure => running;
	}
}


# NOTE:  This class is deprecated.
# It will be removed once oxygen is no longer using it.
class misc::logging::vanadium-relay {
	require misc::logging::socat

	system_role { "misc::logging::vanadium-relay": description => "esams bits event logging to vanadium relay" }

	upstart_job { "event-logging-vanadium-relay": install => "true" }

	service { event-logging-vanadium-relay:
		require => [ Package[socat], Upstart_job[event-logging-vanadium-relay] ],
		subscribe => Upstart_job[event-logging-vanadium-relay],
		ensure => running;
	}
}
