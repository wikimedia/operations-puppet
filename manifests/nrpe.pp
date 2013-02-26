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

class nrpe::packages {
	$nrpe_allowed_hosts = $::realm ? {
		"production" => "127.0.0.1,208.80.152.185,208.80.152.161,208.80.154.14",
		"labs" => "10.4.0.120"
	}

	package { [ "nagios-nrpe-server", "nagios-plugins", "nagios-plugins-basic", "nagios-plugins-extra", "nagios-plugins-standard" ]:
		ensure => latest;
	}

	file {
		"/etc/nagios/nrpe.d":
			owner => root,
			group => root,
			mode => 0755,
			require => Package[nagios-nrpe-server],
			ensure => directory;
		"/etc/nagios/nrpe_local.cfg":
			require => Package[nagios-nrpe-server],
			owner => root,
			group => root,
			mode => 0444,
			notify => Service[nagios-nrpe-server],
			content => template("nagios/nrpe_local.cfg.erb");
		"/usr/lib/nagios/plugins/check_dpkg":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/nagios/check_dpkg";
		"/usr/lib/nagios/plugins/check_ram.sh":
			source => "puppet:///files/nagios/check_ram.sh",
			owner => root,
			group => root,
			mode => 0555;
	}
}

class nrpe::service {
	Class[nrpe::packages] -> Class[nrpe::service]
	
	service { nagios-nrpe-server:
		require => [ Package[nagios-nrpe-server], File["/etc/nagios/nrpe_local.cfg"], File["/usr/lib/nagios/plugins/check_dpkg"], File["/etc/init.d/nagios-nrpe-server"] ],
		subscribe => File["/etc/nagios/nrpe_local.cfg"],
		pattern => "/usr/sbin/nrpe",
		ensure => running;
	}

	file { "/etc/init.d/nagios-nrpe-server":
		owner => root,
		group => root,
		mode => 0555,
		source => "puppet:///files/nagios/nrpe-server-init";
	}

	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") >= 0 {
		file { "/etc/sudoers.d/nrpe":
			owner => root,
			group => root,
			mode => 0440,
			content => "
nagios	ALL = (root) NOPASSWD: /usr/bin/arcconf getconfig 1
nagios	ALL = (root) NOPASSWD: /usr/bin/check-raid.py
";
		}
	}
}

class nrpe {
	include nrpe::packages
	include nrpe::service

	# Collect virtual NRPE nagios service checks
	Monitor_service <| tag == "nrpe" |>
}

class nrpe::new {
	include nrpe::packagesnew
	include nrpe::servicenew

	#Collect virtual NRPE nagios service checks
}
class nrpe::packagesnew {
	$nrpe_allowed_hosts = $::realm ? {
		"production" => "127.0.0.1,208.80.152.185,208.80.152.161,208.80.154.14",
		"labs" => "10.4.0.34"
	}

	package { [ "nagios-nrpe-server", "nagios-plugins", "nagios-plugins-basic", "nagios-plugins-extra", "nagios-plugins-standard", "libssl0.9.8" ]:
		ensure => present;
	}

	package { [ "icinga-nrpe-server" ]:
		ensure => absent;
	}

	file {
		"/etc/icinga/nrpe.d":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;
		"/etc/icinga/nrpe_local.cfg":
			require => Package[nagios-nrpe-server],
			owner => root,
			group => root,
			mode => 0444,
			content => template("icinga/nrpe_local.cfg.erb");
		"/usr/lib/nagios/plugins/check_dpkg":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/nagios/check_dpkg";
		"/etc/init.d/nagios-nrpe-server":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/icinga/nagios-nrpe-server-init";
		"/etc/icinga/nrpe.cfg":
			owner => root,
			group => root,
			mode => 0644,
			source => "puppet:///files/icinga/nrpe.cfg";
	}
}

class nrpe::servicenew {
	Class[nrpe::packagesnew] -> Class[nrpe::servicenew]

	service { nagios-nrpe-server:
		require => [ Package[nagios-nrpe-server], File["/etc/icinga/nrpe_local.cfg"], File["/usr/lib/nagios/plugins/check_dpkg"] ],
		subscribe => File["/etc/icinga/nrpe_local.cfg"],
		pattern => "/usr/sbin/nrpe",
		ensure => running;
	}

	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		file { "/etc/sudoers.d/nrpe":
			owner => root,
			group => root,
			mode => 0440,
			content => "
nagios	ALL = (root) NOPASSWD: /usr/bin/arcconf getconfig 1
nagios	ALL = (root) NOPASSWD: /usr/bin/check-raid.py
icinga	ALL = (root) NOPASSWD: /usr/bin/arcconf getconfig 1
icinga	ALL = (root) NOPASSWD: /usr/bin/check-raid.py
";
		}
	}
}
