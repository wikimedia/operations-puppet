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

	file { "/etc/icinga/nrpe.d/${title}.cfg":
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
			source => "puppet:///files/icinga/check_dpkg";
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

class nrpe::service {
	include icinga::user

	Class[nrpe::packages] -> Class[nrpe::service]

	service { nagios-nrpe-server:
		require => [ Package[nagios-nrpe-server], File["/etc/icinga/nrpe_local.cfg"], File["/usr/lib/nagios/plugins/check_dpkg"] ],
		subscribe => File["/etc/icinga/nrpe_local.cfg"],
		pattern => "/usr/sbin/nrpe",
		hasrestart => true,
		restart => "killall nrpe; sleep 2; /etc/init.d/nagios-nrpe-server start",
		ensure => running;
	}
}

class nrpe::firewall {

  # deny access to NRPE  (5666/TCP) from external networks

  class iptables-purges {

    require 'iptables::tables'
    iptables_purge_service{  'deny_pub_nrpe': service => 'nrpe' }
  }

  class iptables-accepts {

    require 'nrpe::firewall::iptables-purges'

    iptables_add_service{ 'lo_all': interface => 'lo', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'localhost_all': source => '127.0.0.1', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'private_pmtpa_nolabs': source => '10.0.0.0/14', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'private_esams': source => '10.21.0.0/24', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'private_eqiad1': source => '10.64.0.0/17', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'private_eqiad2': source => '10.65.0.0/20', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'private_virt': source => '10.4.16.0/24', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'public_152': source => '208.80.152.0/24', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'public_153': source => '208.80.153.128/26', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'public_154': source => '208.80.154.0/24', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'public_fundraising': source => '208.80.155.0/27', service => 'all', jump => 'ACCEPT' }
    iptables_add_service{ 'public_esams': source => '91.198.174.0/25', service => 'all', jump => 'ACCEPT' }
  }

  class iptables-drops {

    require 'nrpe::firewall::iptables-accepts'
    iptables_add_service{ 'deny_pub_nrpe': service => 'nrpe', jump => 'DROP' }
  }

  class iptables {

    require 'nrpe::firewall::iptables-drops'
    iptables_add_exec{ "${hostname}_nrpe": service => 'nrpe' }
  }

  require 'nrpe::firewall::iptables'
}

