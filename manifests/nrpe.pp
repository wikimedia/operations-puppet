# Definition: nrpe::check
#
# Installs a single NRPE check in /etc/nagios/nrpe.d/
#
# Arguments:
# - $title
#	Name of the check, referenced by monitor_service and Nagios check_command
#	e.g. check_varnishhtcpd
# - $command
#	Command run by NRPE, e.g. "/usr/lib/nagios/plugins/check_procs -c 1:1 -C varnishtcpd"
define nrpe::check($command) {
	Class[nrpe::packages] -> Nrpe::Check[$title]

	file { "/etc/nagios/nrpe.d/${title}.cfg":
		owner => root,
		group => root,
		mode => 0444,
		content => "command[${title}]=${command}\n",
		notify => Service["nagios-nrpe-server"]
	}
}

# Definition: nrpe::monitor_service
#
# Defines a Nagios check for a remote service over NRPE
#
# Also optionally installs a corresponding NRPE check file
# using nrpe::check
#
# Parameters
#    $description   - Service check description
#    $nrpe_command  - if defined, installs this NRPE command as check_${title}
#    $contact_group
#    $retries
#    $ensure        - Default: "present"
#
define nrpe::monitor_service(
	$description,
	$nrpe_command  = undef,
	$contact_group = "admins",
	$retries       = 3,
	$ensure        = "present")
{
	if $nrpe_command != undef {
		nrpe::check { "check_${title}":
			command => $nrpe_command,
			before => ::Monitor_service[$title]
		}
	}
	else {
		Nrpe::Check["check_${title}"] -> Nrpe::Monitor_service[$title]
	}

	::monitor_service{ $title:
		description   => $description,
		check_command => "nrpe_check!check_${title}",
		contact_group => $contact_group,
		retries       => $retries,
		ensure        => $ensure,
	}
}

class nrpe {
	include nrpe::packages
	include nrpe::service

	#Collect virtual NRPE nagios service checks
	Monitor_service <| tag == "nrpe" |>
}
class nrpe::packages {
	$nrpe_allowed_hosts = $::realm ? {
		"production" => "127.0.0.1,208.80.152.185,208.80.152.161,208.80.154.14",
		"labs" => "10.4.0.120"
	}

	package { [ "nagios-nrpe-server", "nagios-plugins", "nagios-plugins-basic", "nagios-plugins-extra", "nagios-plugins-standard", "libssl0.9.8" ]:
		ensure => present;
	}

	file { "/etc/nagios/nrpe_local.cfg":
		ensure => present,
		owner => root,
		group => root,
		mode => 0444,
		content => template("icinga/nrpe_local.cfg.erb"),
		require => Package[nagios-nrpe-server],
	}

	file { "/usr/lib/nagios/plugins/check_dpkg":
		ensure => present,
		owner => root,
		group => root,
		mode => 0555,
		source => "puppet:///files/icinga/check_dpkg",
	}

	# TBD: remove all that, completely unneeded
	package { [ "icinga-nrpe-server" ]:
		ensure => absent;
	}

	file {
		"/etc/icinga/":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;
		"/etc/icinga/nrpe.d":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;
		"/etc/init.d/nagios-nrpe-server":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/icinga/nagios-nrpe-server-init";
		"/etc/nagios/nrpe.cfg":
			owner => root,
			group => root,
			mode => 0644,
			source => "puppet:///files/icinga/nrpe.cfg";
	}
}

class nrpe::service {
	Class[nrpe::packages] -> Class[nrpe::service]

	service { nagios-nrpe-server:
		require => [ Package[nagios-nrpe-server], File["/etc/nagios/nrpe_local.cfg"], File["/usr/lib/nagios/plugins/check_dpkg"] ],
		subscribe => File["/etc/nagios/nrpe_local.cfg"],
		pattern => "/usr/sbin/nrpe",
		hasrestart => true,
		restart => "killall nrpe; sleep 2; /etc/init.d/nagios-nrpe-server start",
		ensure => running;
	}
}
