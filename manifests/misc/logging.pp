# misc/logging.pp
# any logging hosts

class udp2log {

	class logger( $log_file, $has_aft="true" ) {

		include contacts::udp2log
		include udp2log::monitoring
		include udp2log::iptables
		if ( $udp2log::logger::has_aft == "true" ) {
			include udp2log::aft
		}

		system_role { "misc::mediawiki-logger": description => "MediaWiki log server" }

		package { udplog:
			ensure => latest;
		}
	
		file {
		## NOTE: this change will require a change to the init script on either locke or emery
		## to point it at the right place for the config file
			"/etc/udp2log/squid":
				require => Package[udplog],
				mode => 0444,
				owner => root,
				group => root,
				content => template("udp2log/squid.filters.$hostname.erb");
			"/etc/udp2log":
				require => Package[udplog],
				mode => 0444,
				owner => root,
				group => root,
				content => "flush pipe 1 python /usr/local/bin/demux.py\n";
			"/usr/local/bin/demux.py":
				mode => 0544,
				owner => root,
				group => root,
				source => "puppet:///files/misc/demux.py";
			"/etc/logrotate.d/mw-udp2log":
				source => "puppet:///files/logrotate/mw-udp2log",
				mode => 0444;
			"/etc/sysctl.d/99-big-rmem.conf":
				owner => "root",
				group => "root",
				mode => 0444,
				content => "
net.core.rmem_max = 536870912
";
		}

		service { udp2log:
			require => [ Package[udplog], File[ ["/etc/udp2log", "/usr/local/bin/demux.py"] ] ],
			subscribe => File["/etc/udp2log"],
			ensure => running;
		}
	}

	class aft {

		system_role { "misc::mediawiki-logger-aft": description => "MediaWiki log server aux process" }

		file {
			"/etc/init.d/udp2log-aft":
				mode => 0555,
				owner => root,
				group => root,
				source => "puppet:///files/udp2log/udp2log-aft";
			"/etc/logrotate.d/aft-udp2log":
				mode => 0444,
				source => "puppet:///files/logrotate/aft-udp2log";
		}

		service {
			"udp2log-aft":
				ensure => running,
				enable => true,
				require => File["/etc/init.d/udp2log-aft"];
		}
	}

	class monitoring {
		Class["udp2log::config"] -> Class["udp2log::monitoring"]

		include udp2log::iptables

		package { "ganglia-logtailer":
			ensure => latest;
		}

		file {
			"/etc/nagios/nrpe.d/nrpe_udp2log.cfg":
				require => Package[nagios-nrpe-server],
				mode => 0440,
				owner => root,
				group => nagios,
				source => "puppet:///files/nagios/nrpe_udp2log.cfg";
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
				command => "/usr/sbin/ganglia-logtailer --classname PacketLossLogtailer --log_file $log_file --mode cron",
				user => 'root',
				minute => '*/5';
		}

		monitor_service { "udp2log log age": description => "udp2log log age", check_command => "nrpe_check_udp2log_log_age" }
		monitor_service { "udp2log procs": description => "udp2log processes", check_command => "nrpe_check_udp2log_procs" }
		monitor_service { "packetloss": description => "Packetloss_Average", check_command => "check_packet_loss_ave!4!8" }
	}

	class iptables-purges {
		require "iptables::tables"
		# The deny rule must always be purged, otherwise ACCEPTs can be placed below it
		iptables_purge_service{ "udp2log_drop_udp": service => "udp" }
		# When removing or modifying a rule, place the old rule here, otherwise it won't
		# be purged, and will stay in the iptables forever
	}

	class iptables-accepts {
		require "udp2log::iptables-purges"
		# Rememeber to place modified or removed rules into purges!
		# common services for all hosts
		iptables_add_service{ "udp2log_accept_all_private": service => "all", source => "10.0.0.0/8", jump => "ACCEPT" }
		iptables_add_service{ "udp2log_accept_all_US": service => "all", source => "208.80.152.0/22", jump => "ACCEPT" }
		iptables_add_service{ "udp2log_accept_all_AMS": service => "all", source => "91.198.174.0/24", jump => "ACCEPT" }
		iptables_add_service{ "udp2log_accept_all_localhost": service => "all", source => "127.0.0.1/32", jump => "ACCEPT" }
	}

	class iptables-drops {
		require "udp2log::iptables-accepts"
		# Rememeber to place modified or removed rules into purges!
		iptables_add_service{ "udp2log_drop_udp": service => "udp", source => "0.0.0.0/0", jump => "DROP" }
	}

	class iptables  {
	# only allow UDP packets from our IP space into these machines to prevent malicious information injections

		# We use the following requirement chain:
		# iptables -> iptables-drops -> iptables-accepts -> iptables-purges
		#
		# This ensures proper ordering of the rules
		require "udp2log::iptables-drops"
		# This exec should always occur last in the requirement chain.
		## creating iptables rules but not enabling them to test.
		iptables_add_exec{ "udp2log": service => "udp2log" }
	}
}

class misc::syslog-server {
	system_role { "misc::syslog-server": description => "central syslog server" }

	package { syslog-ng:
		ensure => latest;
	}

	file {
		"/etc/syslog-ng/syslog-ng.conf":
			require => Package[syslog-ng],
			source => "puppet:///files/syslog-ng/syslog-ng.conf",
			mode => 0444;
		"/etc/logrotate.d/remote-logs":
			source => "puppet:///files/syslog-ng/remote-logs",
			mode => 0444;
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

	service { squid-logging-multicast-relay:
		require => Upstart_job[squid-logging-multicast-relay],
		ensure => running;
	}
}
