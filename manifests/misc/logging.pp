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
			mode  => 0755,
			# Logging is done in /home/wikipedia:
			require => File["/home/wikipedia"];
		}
	}

	service { syslog-ng:
		require => [ Package[syslog-ng], File["/etc/syslog-ng/syslog-ng.conf"] ],
		subscribe => File["/etc/syslog-ng/syslog-ng.conf"],
		ensure => running;
	}
}

class misc::squid-logging::multicast-relay {
	system_role { "misc::squid-logging::multicast-relay": description => "Squid logging unicast to multicast relay" }

	upstart_job { "squid-logging-multicast-relay": install => "true" }

	package { "socat": ensure => latest; }

	service { squid-logging-multicast-relay:
		require => [ Package[socat], Upstart_job[squid-logging-multicast-relay] ],
		subscribe => Upstart_job[squid-logging-multicast-relay],
		ensure => running;
	}
}

