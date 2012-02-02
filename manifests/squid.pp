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
		# FIXME: Hack for arrays in LDAP - you suck puppet
		$squid_coss_disks = split(get_var('squid_coss_disks'), ',')
	}

	class packages {
		package { ["squid", "squid-frontend"]:
			ensure => latest;
		}

		# Cleanup of old wikimedia-task-squid package
		package { "wikimedia-task-squid": ensure => purged }
	}

	require packages

	File {
		mode => 0444,
		owner => root,
		group => root
	}
	file {
		"frontendsquiddefaultconfig":
			name => "/etc/default/squid-frontend",
			source => "puppet:///files/squid/squid-frontend";
		"/etc/logrotate.d/squid-frontend":
			source => "puppet:///files/logrotate/squid-frontend";
		"squid-disk-permissions":
			path => "/etc/udev/rules.d/99-squid-disk-permissions.rules",
			content => template("squid/squid-disk-permissions.erb");
	}

	service {
		"squid-frontend":
			require => File[frontendsquiddefaultconfig],
			subscribe => File[frontendsquiddefaultconfig],
			hasstatus => false,
			pattern => "squid-frontend",
			ensure => running;
		"squid":
			require => Exec[setup-aufs-cachedirs],
			hasstatus => false,
			pattern => "/usr/sbin/squid ",
			ensure => running;
	}

	class aufs {
		file {
			"/aufs":
				ensure => directory,
				mode => 0755;
			"/usr/local/sbin/setup-aufs-cachedirs":
				source => "puppet:///files/squid/setup-aufs-cachedirs",
				mode => 0555,
				owner => root,
				group => root;
		}

		# Prepare aufs partition if necessary
		exec { setup-aufs-cachedirs:
			require => File[ [squid-disk-permissions, "/aufs", "/usr/local/sbin/setup-aufs-cachedirs"] ],
			command => "/usr/local/sbin/setup-aufs-cachedirs";
		}
	}

	include aufs

	# Tune kernel settings
	include generic::sysctl::high-http-performance

	# Fast C External redirect helper 
	file { "/usr/local/bin/redirector":
		mode => 0555,
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
