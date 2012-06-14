
# Class: udp2log
# 
# Includes packages and setup for udp2log::instances.
# Make sure you include this class if you plan on using
# the udp2log::instance define below.
#
# Parameters:
#    $should_monitor  - If true, monitoring scripts will be installed.  Default: true
class udp2log($should_monitor  = true) {

	include contacts::udp2log,
		udp2log::udp_filter
		
	# include the monitoring scripts
	# required for monitoring udp2log instances
	if $should_monitor {
		include 
			udp2log::monitoring,
			udp2log::iptables
	}
		
	system_role { "udp2log::logger": description => "udp2log data collection server" }

	file {
		"/etc/udp2log":
			ensure => directory,
			owner  => root,
			group  => root,
			mode   => 0775;
		"/etc/sysctl.d/99-big-rmem.conf":
			owner   => "root",
			group   => "root",
			mode    => 0444,
			content => "net.core.rmem_max = 536870912";
	}
	
	# refresh sysctl when rmem_max file changes.
	exec { "rmem_max_sysctl_reload":
		command     => "/sbin/sysctl -p /etc/sysctl.d/99-big-rmem.conf",
		subscribe   => File["/etc/sysctl.d/99-big-rmem.conf"],
		refreshonly => true,
	}
	
	package { udplog:
		ensure => latest;
	}
}


# Define: udp2log::instance
#
# Sets up a udp2log daemon instance.
#
# Parameters:
#    $port             - Default 8420.
#    $log_directory    - Main location for log files.  Default: /var/log/udp2log
#    $packet_loss_log  - Path to packet-loss.log file.  Used for monitoring.  Default /var/log/udp2log/packet-loss.log
#    $should_logrotate - If true, sets up a logrotate file for files in $log_directory. Default: true
#    $should_monitor   - If true, sets up Ganglia and Nagios monitoring of packet loss and filter process precense.  Default: true
#    $multicast_listen - If true, the udp2log instance will be started with the --multicast 233.58.59.1 flag.  Defaeult false.
define udp2log::instance( 
	$port                = "8420",
	$log_directory       = "/var/log/udp2log",
	$packet_loss_log     = "/var/log/udp2log/packet-loss.log",
	$should_logrotate    = true,
	$should_monitor      = true,
	$multicast_listen    = false) {

	require udp2log

	file {
		"/etc/udp2log/${name}":
			require => Package[udplog],
			mode    => 0444,
			owner   => root,
			group   => root,
			content => template("udp2log/filters.${name}.erb");
		"/etc/init.d/udp2log-${name}":
			mode    => 0555,
			owner   => root,
			group   => root,
			content => template("udp2log/udp2log.init.erb");
		["${log_directory}", "${log_directory}/archive"]:
			mode    => 0755,
			owner   => root,
			group   => root,
			ensure  => directory
	}

	# if the logs in $log_directory should be rotated
	# then configure a logrotate.d script to do so.
	if $should_logrotate {
		file {"/etc/logrotate.d/udp2log-${name}":
			mode    => 0444,
			owner   => root,
			group   => root,
			content => template('logrotate/udp2log.erb'),
		}
	}

	# If this udp2log instance should be monitored
	if $should_monitor {
		require udp2log::monitoring

		# Set up a cron to tail the packet loss log for this
		# instance into ganglia.
		cron {
			"ganglia-logtailer-udp2log-${name}" :
				ensure  => present,
				command => "/usr/sbin/ganglia-logtailer --classname PacketLossLogtailer --log_file ${packet_loss_log} --mode cron",
				user    => 'root',
				minute  => '*/5';
		}

		# Set up nagios monitoring of packet loss
		# for this udp2log instance.
		monitor_service { "udp2log-${name}-packetloss": 
			description           => "Packetloss_Average",
			check_command         => "check_packet_loss_ave!4!8",
			contact_group         => "admins,analytics",
			# ganglia-logtailer only runs every 5.
			# let's make nagios check every 2 minutes (to match ganglia_parser)
			# and retry 4 times (total 8 minutes) before
			# declaring a hard failure.
			normal_check_interval => 2,
			retry_check_interval  => 2,
			retries               => 4,
		}


		# Monitor the age of all of the logs defined in 
		# /etc/udp2log/$name
		nrpe::monitor_service{ "udp2log_log_age-${name}": 
			description   => "udp2log log age for ${name}", 
			nrpe_command  => "/usr/lib/nagios/plugins/check_udp2log_log_age ${name}", 
			contact_group => "admins,analytics" 
		}

		# Monitor that each filter defined in 
		# /etc/udp2log/$name is running
		nrpe::monitor_service{ "udp2log_procs-${name}": 
			description   => "udp2log processes for ${name}", 
			nrpe_command  => "/usr/lib/nagios/plugins/check_udp2log_procs ${name}", 
			contact_group => "admins,analytics", 
			retries       => 10 
		}
	}

	# ensure that this udp2log instance is running
	service { "udp2log-${name}":
		require   => Package["udplog"],
		subscribe => File["/etc/udp2log/${name}" ],
		hasstatus => false,
		ensure    => running;
	}
}

class udp2log::utilities {
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

class udp2log::udp_filter {
	package { udp-filter:
		ensure => latest;
	}
	package { udp-filters:
		ensure => absent;
	}
}

# includes scripts and iptables rules
# needed for udp2log monitoring.
class udp2log::monitoring {
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
}

class udp2log::iptables_purges {
	require "iptables::tables"
	# The deny rule must always be purged, otherwise ACCEPTs can be placed below it
	iptables_purge_service{ "udp2log_drop_udp": service => "udp" }
	# When removing or modifying a rule, place the old rule here, otherwise it won't
	# be purged, and will stay in the iptables forever
}

class udp2log::iptables_accepts {
	require "udp2log::iptables_purges"
	# Rememeber to place modified or removed rules into purges!
	# common services for all hosts
	iptables_add_service{ "udp2log_accept_all_private": service => "all", source => "10.0.0.0/8", jump => "ACCEPT" }
	iptables_add_service{ "udp2log_accept_all_US": service => "all", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "udp2log_accept_all_AMS": service => "all", source => "91.198.174.0/24", jump => "ACCEPT" }
	iptables_add_service{ "udp2log_accept_all_localhost": service => "all", source => "127.0.0.1/32", jump => "ACCEPT" }
}

class udp2log::iptables_drops {
	require "udp2log::iptables_accepts"
	# Rememeber to place modified or removed rules into purges!
	iptables_add_service{ "udp2log_drop_udp": service => "udp", source => "0.0.0.0/0", jump => "DROP" }
}

class udp2log::iptables  {
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