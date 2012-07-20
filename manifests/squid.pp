# squid.pp

import "generic-definitions.pp"

# Main entry point simply.
class squid {
	require squid::commons
	if( $::realm == 'labs' ) {
		require squid::labs
	} else {
		require squid::production
	}
}

class squid::commons {
	# Make sure all your file are belong to root
	File {
		mode => 0444,
		owner => root,
		group => root
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
		# Fast C External redirect helper
		"/usr/local/bin/redirector":
			mode => 0555,
			source => "puppet:///files/squid/redirector",
			ensure => present;
	}

	class packages {
		package { ["squid", "squid-frontend"]:
			ensure => latest;
		}

		# Cleanup of old wikimedia-task-squid package
		package { "wikimedia-task-squid": ensure => purged }
	}
	require packages

	# Tune kernel settings
	include generic::sysctl::high-http-performance

}

# labs specific configuration
class squid::labs {
	# Nova mounts /dev/vdb on /mnt by default. We want to use that device
	# for coss usage.
	mount { "/mnt":
		name => '/mnt',
		ensure => absent;
	}

	# FIXME: Hack for arrays in LDAP - you suck puppet
	$squid_coss_disks = split(get_var('squid_coss_disks'), ',')

	# We need placeholders configured in puppet to satisfy redudancies
	file {
		"/etc/squid/squid.conf":
			ensure  => present;
		"/etc/squid/frontend.conf":
			ensure  => present;
	}

}

# production specific configuration
class squid::production {
	file {
		"/etc/squid/squid.conf":
			source => "puppet:///volatile/squid/squid.conf/${::fqdn}";
		"/etc/squid/frontend.conf":
			source => "puppet:///volatile/squid/frontend.conf/${::fqdn}";
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

	class services {

		squid_service { 'squid':
			requisites => Exec[setup-aufs-cachedirs]
		}
		squid_service { 'frontend':
			requisites => frontendsquiddefaultconfig
		}

		service {
			"squid":
				require => [ File["/etc/squid/squid.conf"], Exec[setup-aufs-cachedirs] ],
				subscribe => File["/etc/squid/squid.conf"],
				hasstatus => false,
				pattern => "/usr/sbin/squid ",
				enable => false,
				ensure => running;
			"squid-frontend":
				require => File[ ["/etc/squid/frontend.conf", frontendsquiddefaultconfig] ],
				subscribe => File[ ["/etc/squid/frontend.conf", frontendsquiddefaultconfig] ],
				hasstatus => false,
				pattern => "squid-frontend",
				enable => false,
				ensure => running;
		}
	}
	include services
}

define squid_service(
		$name=$title,
	  $conf="/etc/squid/${title}.conf",
		$requisites=File[$conf]
) {

	# Make sure to look for the correct process
	$process_name = $name ? {
		'squid' => '/usr/bin/squid',
		default => $name,
	}
	$service_name = $name ? {
		'squid' => squid,
		default => "squid-${name}",
	}

	service { $service_name:
			ensure    => running,
			enabled   => false,
			hasstatus => false,
			pattern   => $process_name,
			require   => [ $requisites, File[$conf] ],
			subscribe => $requisites;
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
