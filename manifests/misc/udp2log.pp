
# Class: udp2log
# 
# Includes packages and setup for misc::udp2log::instances.
# Make sure you include this class if you plan on using
# the misc::udp2log::instance define below.
#
# Parameters:
#    $monitor  - If true, monitoring scripts will be installed.  Default: true
class misc::udp2log($monitor  = true) {

	include 
		contacts::udp2log,
		misc::udp2log::udp_filter

	# include the monitoring scripts
	# required for monitoring udp2log instances
	if $monitor {
		include 
			misc::udp2log::monitoring,
			misc::udp2log::iptables
	}

	system_role { "udp2log::logger": description => "udp2log data collection server" }

	# make sure the udp2log filter config directory exists
	file { "/etc/udp2log":
		ensure => directory,
		owner  => root,
		group  => root,
		mode   => 0775
	}

	# set a large net rmem_max
	sysctl { "big-rmem":
		content       => "net.core.rmem_max = 536870912",
		number_prefix => "99",   # Only setting this for historical reasons.  This file already exists on some servers, and I dont' want to recreate the file.
	}

	# make sure the udplog package is installed
	package { udplog:
		ensure => latest;
	}
}


# Define: misc::udp2log::instance
#
# Sets up a udp2log daemon instance.
#
# Parameters:
#    $port             - Default 8420.
#    $log_directory    - Main location for log files.  Default: /var/log/udp2log
#    $packet_loss_log  - Path to packet-loss.log file.  Used for monitoring.  Default /var/log/udp2log/packet-loss.log
#    $logrotate        - If true, sets up a logrotate file for files in $log_directory. Default: true
#    $monitor          - If true, sets up Ganglia and Nagios monitoring of packet loss and filter process presence.  Default: true
#    $multicast        - If true, the udp2log instance will be started with the --multicast 233.58.59.1.  If you give a string, --mulitcast will be set to this string.  Default: false
#    $ensure           - Either 'stopped' or 'running'.   Default: 'running'
#
define misc::udp2log::instance(
	$port                = "8420",
	$log_directory       = "/var/log/udp2log",
	$packet_loss_log     = "/var/log/udp2log/packet-loss.log",
	$logrotate           = true,
	$monitor             = true,
	$multicast           = undef,
	$ensure              = "running")
{

	# This define requires that the udp2log class has
	# been included.  The udp2log class is parameterized,
	# so we don't want to use the require statement here
	# to make sure it is included.  This just sets
	# up the dependency.
	Class["misc::udp2log"] -> Misc::Udp2log::Instance[$title]

	file {
		# the udp2log instance's filter config file
		"/etc/udp2log/${name}":
			require => Package[udplog],
			mode    => 0444,
			owner   => root,
			group   => root,
			content => template("udp2log/filters.${name}.erb");
		# init service script for this udp2log instance
		"/etc/init.d/udp2log-${name}":
			mode    => 0555,
			owner   => root,
			group   => root,
			content => template("udp2log/udp2log.init.erb");
		# primary directory where log files will be stored.
		["${log_directory}", "${log_directory}/archive"]:
			mode    => 0755,
			owner   => root,
			group   => root,
			ensure  => directory
	}

	# if the logs in $log_directory should be rotated
	# then configure a logrotate.d script to do so.
	if $logrotate {
		file {"/etc/logrotate.d/udp2log-${name}":
			mode    => 0444,
			owner   => root,
			group   => root,
			content => template('udp2log/logrotate_udp2log.erb'),
		}
	}

	# TODO:  If $monitor is undef, then we should probably
	# ensure that monitoring doesn't happen, rather than
	# just not ensuring that it does.

	# If this udp2log instance should be monitored
	if $monitor {
		require misc::udp2log::monitoring

		# If this instance is stopped, 
		# then disable monitoring.
		$ensure_monitoring = $ensure ? {
			"stopped" => "absent",
			false     => "absent",
			default   => "present",
		}

		# Set up a cron to tail the packet loss log for this
		# instance into ganglia.
		cron { "ganglia-logtailer-udp2log-${name}":
			command => "/usr/sbin/ganglia-logtailer --classname PacketLossLogtailer --log_file ${packet_loss_log} --mode cron",
			user    => 'root',
			minute  => '*/5',
			ensure  => $ensure_monitoring,
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
			ensure                => $ensure_monitoring,
		}

		# Monitor the age of all of the logs defined in 
		# /etc/udp2log/$name
		nrpe::monitor_service { "udp2log_log_age-${name}":
			description   => "udp2log log age for ${name}",
			nrpe_command  => "/usr/lib/nagios/plugins/check_udp2log_log_age ${name}",
			contact_group => "admins,analytics",
			ensure        => $ensure_monitoring,
		}

		# Monitor that each filter defined in 
		# /etc/udp2log/$name is running
		nrpe::monitor_service { "udp2log_procs-${name}":
			description   => "udp2log processes for ${name}",
			nrpe_command  => "/usr/lib/nagios/plugins/check_udp2log_procs ${name}",
			contact_group => "admins,analytics",
			retries       => 10,
			ensure        => $ensure_monitoring,
		}
	}

	# ensure that this udp2log instance is running
	service { "udp2log-${name}":
		require   => Package["udplog"],
		subscribe => File["/etc/udp2log/${name}" ],
		hasstatus => false,
		ensure    => $ensure,
	}
}

class misc::udp2log::utilities {
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

class misc::udp2log::udp_filter {
	package { udp-filter:
		ensure => latest;
	}
	package { udp-filters:
		ensure => absent;
	}
}

# includes scripts and iptables rules
# needed for udp2log monitoring.
class misc::udp2log::monitoring {
	include misc::udp2log::iptables

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

class misc::udp2log::iptables_purges {
	require "iptables::tables"
	# The deny rule must always be purged, otherwise ACCEPTs can be placed below it
	iptables_purge_service{ "udp2log_drop_udp": service => "udp" }
	# When removing or modifying a rule, place the old rule here, otherwise it won't
	# be purged, and will stay in the iptables forever
}

class misc::udp2log::iptables_accepts {
	require "misc::udp2log::iptables_purges"
	# Rememeber to place modified or removed rules into purges!
	# common services for all hosts
	iptables_add_service{ "udp2log_accept_all_private": service => "all", source => "10.0.0.0/8", jump => "ACCEPT" }
	iptables_add_service{ "udp2log_accept_all_US": service => "all", source => "208.80.152.0/22", jump => "ACCEPT" }
	iptables_add_service{ "udp2log_accept_all_AMS": service => "all", source => "91.198.174.0/24", jump => "ACCEPT" }
	iptables_add_service{ "udp2log_accept_all_localhost": service => "all", source => "127.0.0.1/32", jump => "ACCEPT" }
}

class misc::udp2log::iptables_drops {
	require "misc::udp2log::iptables_accepts"
	# Rememeber to place modified or removed rules into purges!
	iptables_add_service{ "udp2log_drop_udp": service => "udp", source => "0.0.0.0/0", jump => "DROP" }
}

class misc::udp2log::iptables  {
# only allow UDP packets from our IP space into these machines to prevent malicious information injections

	# We use the following requirement chain:
	# iptables -> iptables-drops -> iptables-accepts -> iptables-purges
	#
	# This ensures proper ordering of the rules
	require "misc::udp2log::iptables_drops"
	# This exec should always occur last in the requirement chain.
	## creating iptables rules but not enabling them to test.
	iptables_add_exec{ "udp2log": service => "udp2log" }
}