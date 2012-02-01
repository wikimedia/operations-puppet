# squid.pp

import "generic-definitions.pp"

# Virtual resources for the monitoring server
@monitor_group { "squids_pmtpa": description => "pmtpa text squids" }
@monitor_group { "squids_upload": description => "pmtpa upload squids" }
@monitor_group { "squids_text": description => "text squids" }
@monitor_group { "squids_esams_text": description => "esams text squids" }
@monitor_group { "squids_esams_upload": description => "esams upload squids" }
@monitor_group { "squids_eqiad_text": description => "eqiad text squids" }

class squid {

	if $realm == "labs" {
		# Hack for arrays in LDAP - you suck puppet
		$squid_coss_disks = split(get_var('squid_coss_disks'), ',')
	}

	# Resource definitions
	file {
		"frontendsquiddefaultconfig":
			name => "/etc/default/squid-frontend",
			owner => "root",
			group => "root",
			mode => 644,
			source => "puppet:///files/squid/squid-frontend";
		"/etc/logrotate.d/squid-frontend":
			source => "puppet:///files/logrotate/squid-frontend",
			owner => root,
			group => root,
			mode => 0644;	
		"squid-disk-permissions":
			path => "/etc/udev/rules.d/99-squid-disk-permissions.rules",
			owner => root,
			group => root,
			mode => 0644,
			content => template("squid/squid-disk-permissions.erb");
	}

	package { "wikimedia-task-squid":
		ensure => latest;
	}

	service {
		"squid-frontend":
			require => [ File[frontendsquiddefaultconfig], Package[wikimedia-task-squid] ],
			subscribe => File[frontendsquiddefaultconfig],
			hasstatus => false,
			pattern => "squid-frontend",
			ensure => running;
		"squid":
			require => [ Exec[setup-aufs-cachedirs], Package[wikimedia-task-squid] ],
			hasstatus => false,
			pattern => "/usr/sbin/squid ",
			ensure => running;
	}

	# Prepare aufs partition if necessary
	exec { setup-aufs-cachedirs:
		command => "/usr/sbin/setup-aufs-cachedirs",
		path => "/bin:/sbin:/usr/bin:/usr/sbin",
		require => [ File[squid-disk-permissions], Package[wikimedia-task-squid] ];
	}

	# Tune kernel settings
	include generic::sysctl::high-http-performance

	# Fast C External redirect helper 
	file { "/usr/local/bin/redirector":
		mode => 755,
		owner => root,
		group => root,
		source => "puppet:///files/squid/redirector",
		ensure => present;
	}

	# Monitoring
	monitor_service { "frontend http":
		description => "Frontend Squid HTTP",
		check_command => $nagios_group ? {
			/_upload$/ => 'check_http_upload',
			default => 'check_http'
		};
	}
	monitor_service { "backend http":
		description => "Backend Squid HTTP",
		check_command => $nagios_group ? {
			/_upload$/ => 'check_http_upload_on_port!3128',
			default => 'check_http_on_port!3128'
		};
	}
}


class squid::cachemgr {

	system_role { "squid::cachemgr": description => "Squid Cache Manager" }

	file { "/etc/squid/cachemgr.conf":
		source => "puppet:///files/squid/cachemgr.conf",
		owner => root,
		group => root,
		mode => 0444;
	}

	package { squid-cgi:ensure => latest }
}
