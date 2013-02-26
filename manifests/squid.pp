# squid.pp

import "generic-definitions.pp"

class squid {

	# Fast C External redirect helper
	require squid::redirector

	if $realm == "labs" {
		# Nova mounts /dev/vdb on /mnt by default. We want to use that device
		# for coss usage.
		mount { "/mnt":
			name => '/mnt',
			ensure => absent;
		}

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

	if( $::realm == 'production' ) {
		# We do not use the auto generated squid conf on labs but some hand
		# crafted one.  That is good enough for now until we switch to varnish
		file {
			"/etc/squid/squid.conf":
				source => "puppet:///volatile/squid/squid.conf/${::fqdn}";
			"/etc/squid/frontend.conf":
				source => "puppet:///volatile/squid/frontend.conf/${::fqdn}";
		}
	} else {
		# We need placeholders configured in puppet to satisfy redudancies
		file {
			"/etc/squid/squid.conf":
				ensure  => present;
			"/etc/squid/frontend.conf":
				ensure  => present;
		}
	}

	# Common files
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
			require => File[ ["/etc/squid/frontend.conf", frontendsquiddefaultconfig] ],
			subscribe => File[ ["/etc/squid/frontend.conf", frontendsquiddefaultconfig] ],
			hasstatus => false,
			restart => "/etc/init.d/squid-frontend reload",
			pattern => "squid-frontend",
			enable => false,
			ensure => running;
		"squid":
			require => [ File["/etc/squid/squid.conf"], Exec[setup-aufs-cachedirs] ],
			subscribe => File["/etc/squid/squid.conf"],
			hasstatus => false,
			restart => "/etc/init.d/squid reload",
			pattern => "/usr/sbin/squid ",
			enable => false,
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
			require => File[ [squid-disk-permissions, "/etc/squid/squid.conf", "/aufs", "/usr/local/sbin/setup-aufs-cachedirs"] ],
			command => "/usr/local/sbin/setup-aufs-cachedirs",
			path => "/bin:/usr/bin",
			onlyif => "egrep -q '^cache_dir[[:space:]]+aufs' /etc/squid/squid.conf"
		}
	}

	include aufs

	# Tune kernel settings
	include generic::sysctl::high-http-performance
}

class squid::redirector {

	# Top level domain name to use when redirecting URLs
	# MUST NOT have beginning or trailing dot.
	$squid_redirector_tld = $::realm ? {
		labs    => 'beta.wmflabs.org',
		default => 'org',
	}

	file {
		# Fast C External redirect helper
		"/usr/local/bin/redirector":
			mode => 0555,
			source => "puppet:///files/squid/redirector",
			ensure => present;
	}
	file {
		# ...and its configuration
		"/etc/squid/redirector.conf":
			mode => 0444,
			content => template('squid/redirector.conf.erb'),
			ensure => present;
	}

}

class squid::cachemgr {
	require role::cache::configuration

	system_role { "squid::cachemgr": description => "Squid Cache Manager" }

	file { "/etc/squid/cachemgr.conf":
		content => template("squid/cachemgr.conf.erb"),
		owner => root,
		group => root,
		mode => 0444;
	}

	package { squid-cgi:ensure => latest }
}
