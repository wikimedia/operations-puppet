# == Define limn::instance
# Starts up a Limn Server instance.
#
# == Parameters:
# $port           - Listen port for Limn instance.  Default: 8081
# $environment    - Node environment.  Default: production
# $var_directory  - Limn instance var directory.  Default: /var/lib/limn/$name
# $log_file       - Limn instance log file.  Default: /var/log/lim/limn-$name.log
# $user           - Limn instance will run as this user.  Default: limn
# $group          - Limn instance will run in this group.  Default: limn
# $base_directory - Limn install base directory.  Default: /usr/lib/limn
# $ensure         - present|absent.  Default: present
#
define limn::instance (
	$port           = 8081,
	$environment    = "production",
	$var_directory  = "/var/lib/limn/${name}",
	$log_file       = "/var/log/limn/limn-${name}.log",
	$user           = "limn",
	$group          = "limn",
	$base_directory = "/usr/lib/limn",
	$ensure         = "present",
) {
	require limn

	file { $var_directory:
		owner  => $user,
		group  => $group,
		mode   => "0755",
		ensure => "directory",
	}

	# The upstart init conf will start server.co
	# logging to this file.
	file { $log_file:
		owner  => $user,
		group  => $group,
		mode   => "0755",
		ensure => "file",
	}

	# Install an upstart init file for this limn server instance.
	file { "/etc/init/limn-${name}.conf":
		content   => template("limn/limn.init.erb"),
		owner     => "root",
		group     => "root",
		mode      => "0644",
		ensure    => $ensure,
		require   => [File[$var_directory], File[$log_file]],
	}

	# Symlink an /etc/init.d script to upstart-job
	# for SysV compatibility.
	file { "/etc/init.d/limn-${name}":
		target  => "/lib/init/upstart-job",
		ensure  => $ensure ? {
			present   => "link",
			default   => "absent",
		},
		require => File["/etc/init/limn-${name}.conf"],
	}

	service { "limn-${name}":
		ensure     => $ensure ? {
			present   => "running",
			default   => "stopped",
		},
		provider   => "upstart",
		subscribe  => File["/etc/init/limn-${name}.conf"],
	}
}