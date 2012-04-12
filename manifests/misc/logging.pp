# misc/logging.pp
# any logging hosts

class udp2log {
	
	class logger( $log_file, $logging_instances=[] ) {

		include contacts::udp2log
		include udp2log::monitoring
		include udp2log::iptables

		system_role { "misc::mediawiki-logger": description => "MediaWiki log server" }
		
		udp2log::instance{ $logging_instances: }

		package { ["udplog", "udp-filter"]:
			ensure => latest;
		}
		package { udp-filters:
			ensure => absent;
		}

		file {
			## uuuhhhh... this is a directory now...
			#"/etc/udp2log":
			#	require => Package[udplog],
			#	mode => 0444,
			#	owner => root,
			#	group => root,
			#	content => "flush pipe 1 python /usr/local/bin/demux.py\n";
			"/usr/local/bin/demux.py":
				mode => 0544,
				owner => root,
				group => root,
				source => "puppet:///files/misc/demux.py";
			"/etc/sysctl.d/99-big-rmem.conf":
				owner => "root",
				group => "root",
				mode => 0444,
				content => "net.core.rmem_max = 536870912";
			"/usr/local/bin/sqstat":
				mode => 0555,
				owner => root,
				group => root,
				source => "puppet:///files/udp2log/sqstat.pl"
		}
		if "aft" in $logging_instances {
			file { "/etc/logrotate.d/aft-udp2log":
				mode => 0444,
				source => "puppet:///files/logrotate/aft-udp2log";
			}
		}
	}

	define instance( ) {
		file {
			"/etc/udp2log/${name}":
				require => Package[udplog],
				mode => 0444,
				owner => root,
				group => root,
				content => template("udp2log/filters.${name}");
			"/etc/init.d/udp2log-${name}":
				mode => 0555,
				owner => root,
				group => root,
				content => template("udp2log/udp2log.init.erb");
		}
		
		service { "udp2log_${name}":
			require => [ Package[udplog], File[ "/etc/udp2log/${name}", "/usr/local/bin/demux.py", "/etc/init.d/udp2log-${name}" ] ],
			subscribe => File["/etc/udp2log/${name}" ],
			#pattern => "/var/run/udp2log-${name}.pid",  ##should this be set? does it need to be?
			hasstatus => false,
			ensure => running;
		}
	}

	class monitoring {
		include udp2log::iptables

		package { "ganglia-logtailer":
			ensure => latest;
		}

		file {
			"/usr/lib/nagios/plugins/check_udp2log_log_age":
				mode => 0555,
				owner => root,
				group => root,
				source => "puppet:///files/nagios/check_udp2log_log_age";
			"/usr/lib/nagios/plugins/check_udp2log_procs":
				mode => 0555,
				owner => root,
				group => root,
				source => "puppet:///files/nagios/check_udp2log_procs";
			"PacketLossLogtailer.py":
				path => "/usr/share/ganglia-logtailer/PacketLossLogtailer.py",
				mode => 0444,
				owner => root,
				group => root,
				source => "puppet:///files/misc/PacketLossLogtailer.py";
		}

		cron {
			"ganglia-logtailer" :
				ensure => present,
				command => "/usr/sbin/ganglia-logtailer --classname PacketLossLogtailer --log_file $udp2log::logger::log_file --mode cron",
				user => 'root',
				minute => '*/5';
		}

		nrpe::monitor_service{ "udp2log_log_age": description => "udp2log log age", nrpe_command => "/usr/lib/nagios/plugins/check_udp2log_log_age" }
		nrpe::monitor_service{ "udp2log_procs": description => "udp2log processes", nrpe_command => "/usr/lib/nagios/plugins/check_udp2log_procs" }
		monitor_service { "packetloss": description => "Packetloss_Average", check_command => "check_packet_loss_ave!4!8" }
	}

	class iptables_purges {
		require "iptables::tables"
		# The deny rule must always be purged, otherwise ACCEPTs can be placed below it
		iptables_purge_service{ "udp2log_drop_udp": service => "udp" }
		# When removing or modifying a rule, place the old rule here, otherwise it won't
		# be purged, and will stay in the iptables forever
	}

	class iptables_accepts {
		require "udp2log::iptables_purges"
		# Rememeber to place modified or removed rules into purges!
		# common services for all hosts
		iptables_add_service{ "udp2log_accept_all_private": service => "all", source => "10.0.0.0/8", jump => "ACCEPT" }
		iptables_add_service{ "udp2log_accept_all_US": service => "all", source => "208.80.152.0/22", jump => "ACCEPT" }
		iptables_add_service{ "udp2log_accept_all_AMS": service => "all", source => "91.198.174.0/24", jump => "ACCEPT" }
		iptables_add_service{ "udp2log_accept_all_localhost": service => "all", source => "127.0.0.1/32", jump => "ACCEPT" }
	}

	class iptables_drops {
		require "udp2log::iptables_accepts"
		# Rememeber to place modified or removed rules into purges!
		iptables_add_service{ "udp2log_drop_udp": service => "udp", source => "0.0.0.0/0", jump => "DROP" }
	}

	class iptables  {
	# only allow UDP packets from our IP space into these machines to prevent malicious information injections

		# We use the following requirement chain:
		# iptables -> iptables-drops -> iptables-accepts -> iptables-purges
		#
		# This ensures proper ordering of the rules
		require "udp2log::iptables_drops"
		# This exec should always occur last in the requirement chain.
		## creating iptables rules but not enabling them to test.
		iptables_add_exec{ "udp2log": service => "udp2log" }
	}
}

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

