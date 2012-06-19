# misc/logging.pp
# any logging hosts

class udp2log {

	class logger( $log_file, $logging_instances={}, $has_monitoring = true ) {
		$logging_instances_keys = inline_template("<%= logging_instances.keys.join(',') %>") 
		$logging_instances_array = split($logging_instances_keys,',')

		include contacts::udp2log,
			udp2log::udp_filter
			
		if $has_monitoring == true {
			include udp2log::monitoring,
				udp2log::iptables
		}
			
		system_role { "udp2log::logger": description => "udp2log data collection server" }

		udp2log::instance { $logging_instances_array: }

		file {
			"/etc/udp2log":
				ensure => directory,
				owner => root,
				group => root,
				mode => 0775;
			"/etc/sysctl.d/99-big-rmem.conf":
				owner => "root",
				group => "root",
				mode => 0444,
				content => "net.core.rmem_max = 536870912";
		}
		
		# refresh sysctl when rmem_max file changes.
		exec { "rmem_max_sysctl_reload":
			command => "/sbin/sysctl -p /etc/sysctl.d/99-big-rmem.conf",
			subscribe => File["/etc/sysctl.d/99-big-rmem.conf"],
			refreshonly => true,
		}
		
		package { udplog:
			ensure => latest;
		}
	}

	define instance( $port = $logging_instances[$name]["port"],
					$has_logrotate = $logging_instances[$name]["has_logrotate"], 
					$multicast_listen = $logging_instances[$name]["multicast_listen"],
					$monitoring = $has_monitoring ) {

		file {
			"/etc/udp2log/${name}":
				require => Package[udplog],
				mode => 0444,
				owner => root,
				group => root,
				content => template("udp2log/filters.${name}.erb");
			"/etc/init.d/udp2log-${name}":
				mode => 0555,
				owner => root,
				group => root,
				content => template("udp2log/udp2log.init.erb");
		}

		if $has_logrotate == true {
			file {"/etc/logrotate.d/${name}-udp2log":
				mode => 0444,
				owner => root,
				group => root,
				source => "puppet:///files/logrotate/${name}-udp2log";
			}
		}

		if $monitoring == true {
			require udp2log::monitoring

			nrpe::monitor_service{ "udp2log_log_age-${name}": description => "udp2log log age for ${name}", nrpe_command => "/usr/lib/nagios/plugins/check_udp2log_log_age ${name}", contact_group => "admins,analytics" }
			nrpe::monitor_service{ "udp2log_procs-${name}": description => "udp2log processes for ${name}", nrpe_command => "/usr/lib/nagios/plugins/check_udp2log_procs ${name}", contact_group => "admins,analytics", retries => 10 }
		}

		service { "udp2log-${name}":
			require => Package[ udplog ],
			subscribe => File["/etc/udp2log/${name}" ],
			hasstatus => false,
			ensure => running;
		}
	}

	class utilities {
		file {
			"/usr/local/bin/demux.py":
				mode => 0544,
				owner => root,
				group => root,
				source => "puppet:///files/misc/demux.py";
			"/usr/local/bin/sqstat":
				mode => 0555,
				owner => root,
				group => root,
				source => "puppet:///files/udp2log/sqstat.pl"
		}
	}

	class udp_filter {
		package { udp-filter:
			ensure => latest;
		}
		package { udp-filters:
			ensure => absent;
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

		monitor_service { "packetloss": 
			description => "Packetloss_Average",
			check_command => "check_packet_loss_ave!4!8",
			contact_group => "admins,analytics",
			# ganglia-logtailer only runs every 5.
			# let's make nagios check every 2 minutes (to match ganglia_parser)
			# and retry 4 times (total 8 minutes) before
			# declaring a hard failure.
			normal_check_interval => 2,
			retry_check_interval => 2,
			retries => 4,
		}
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

