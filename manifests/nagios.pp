# nagios.pp

import "generic-definitions.pp"
import "decommissioning.pp"

$nagios_config_dir = "/etc/nagios"

$ganglia_url = "http://ganglia.wikimedia.org"

define monitor_host ($ip_address=$ipaddress, $group=$nagios_group, $ensure=present, $critical="false") {
	if ! $ip_address {
		fail("Parameter $ip_address not defined!")
	}

	# Export the nagios host instance
	@@nagios_host { $title:
		target => "${nagios_config_dir}/puppet_hosts.cfg",
		host_name => $title,
		address => $ip_address,
		hostgroups => $group ? {
			/.+/ => $group,
			default => undef
		},
		check_command => "check_ping!500,20%!2000,100%",
		check_period => "24x7",
		max_check_attempts => 2,
		contact_groups => $critical ? {
					"true" => "admins,sms",
					default => "admins"
				},
		notification_interval => 0,
		notification_period => "24x7",
		notification_options => "d,u,r,f",
		ensure => $ensure;
	}

	if $title == $hostname {
		$image = $operatingsystem ? {
			"Ubuntu"	=> "ubuntu",
			"Solaris" 	=> "sunlogo",
			default		=> "linux40"
		}

		# Couple it with some hostextinfo
		@@nagios_hostextinfo { $title:
			target => "${nagios_config_dir}/puppet_hostextinfo.cfg",
			host_name => $title,
			notes => $title,
			# Needs c= cluster parameter. Let's fix this cleanly with Puppet 2.6 hashes
			notes_url => "${ganglia_url}/?c=${ganglia::cname}&h=${fqdn}&m=&r=hour&s=descending&hc=4",
			icon_image => "${image}.png",
			vrml_image => "${image}.png",
			statusmap_image => "${image}.gd2",
			ensure => $ensure;
		}
	}
}

define monitor_service ($description, $check_command, $host=$hostname, $retries=3, $group=$nagios_group, $ensure=present, $critical="false", $passive="false", $freshness=36000) { 
        if ! $host {
                fail("Parametmer $host not defined!")
        }

	if $hostname in $decommissioned_servers {
		# Export the nagios service instance
		@@nagios_service { "$hostname $title":
			target => "${nagios_config_dir}/puppet_checks.d/${host}.cfg",
			host_name => $host,
			servicegroups => $group ? {
				/.+/ => $group,
				default => undef
			},
			service_description => $description,
			check_command => $check_command,
			max_check_attempts => $retries,
			normal_check_interval => 1,
			retry_check_interval => 1,
			check_period => "24x7",
	                notification_interval => 0,
			notification_period => "24x7",
			notification_options => "c,r,f",
			contact_groups => $critical ? {
						"true" => "admins,sms",
						default	=> "admins"
					},
			ensure => absent;
		}
	}
	else {
		# Export the nagios service instance
		@@nagios_service { "$hostname $title":
			target => "${nagios_config_dir}/puppet_checks.d/${host}.cfg",
			host_name => $host,
			servicegroups => $group ? {
				/.+/ => $group,
				default => undef
			},
			service_description => $description,
			check_command => $check_command,
			max_check_attempts => $retries,
			normal_check_interval => 1,
			retry_check_interval => 1,
			check_period => "24x7",
			notification_interval => $critical ? {
					"true" => 240,
					default => 0
					},
			notification_period => "24x7",
			notification_options => "c,r,f",
			contact_groups => $critical ? {
						"true" => "admins,sms",
						default	=> "admins"
					},
			passive_checks_enabled => 1,
			active_checks_enabled => $passive ? {
					"true" => 0,
					default => 1
					},
			is_volatile => $passive ? {
					"true" => 1,
					default => 0
					},
			check_freshness => $passive ? {
					"true" => 1,
					default => 0
					},
			freshness_threshold => $passive ? {
					"true" => $freshness,
					default => undef
					},
			ensure => $ensure;
		}
	}
}

define monitor_group ($description, $ensure=present) {
        # Nagios hostgroup instance
	nagios_hostgroup { $title:
		target => "${nagios_config_dir}/puppet_hostgroups.cfg",
		hostgroup_name => $title,
		alias => $description,
		ensure => $ensure;
        }

	# Nagios servicegroup instance
	nagios_servicegroup { $title:
		target => "${nagios_config_dir}/puppet_servicegroups.cfg",
		servicegroup_name => $title,
		alias => $description,
		ensure => $ensure;
	}
}

define decommission_monitor_host {
	if defined(Nagios_host[$title]) {
		# Override the existing resources
		Nagios_host <| title == $title |> {
			ensure => absent
		}
		Nagios_hostextinfo <| title == $title |> {
			ensure => absent
		}
	}
	else {
		# Resources don't exist in Puppet. Remove from Nagios config as well.
		nagios_host { $title:
			host_name => $title,
			ensure => absent;
		}

		nagios_hostextinfo { $title:
			host_name => $title,
			ensure => absent;
		}
	}
}

# Class which implements the monitoring services on the monitor host
class nagios::monitor {

	include passwords::nagios::mysql
	$nagios_mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

	# puppet_hosts.cfg must be first
	$puppet_files = [ "${nagios_config_dir}/puppet_hosts.cfg",
			  "${nagios_config_dir}/puppet_hostgroups.cfg",
			  "${nagios_config_dir}/puppet_hostextinfo.cfg",
			  "${nagios_config_dir}/puppet_servicegroups.cfg",
			  "${nagios_config_dir}/puppet_services.cfg" ]

	$static_files = [ "${nagios_config_dir}/nagios.cfg",
			  "${nagios_config_dir}/special.cfg",
			  "${nagios_config_dir}/cgi.cfg",
			  "${nagios_config_dir}/checkcommands.cfg",
			  "${nagios_config_dir}/contactgroups.cfg",
			  "${nagios_config_dir}/contacts.cfg",
			  "${nagios_config_dir}/migration.cfg",
			  "${nagios_config_dir}/misccommands.cfg",
			  "${nagios_config_dir}/resource.cfg",
			  "${nagios_config_dir}/timeperiods.cfg",
			  "${nagios_config_dir}/htpasswd.users"]

	systemuser { nagios: name => "nagios", home => "/home/nagios", groups => [ "nagios", "dialout", "gammu" ] }

	service { nagios:
		require => File[$puppet_files],
		ensure => running,
		subscribe => [ File[$puppet_files],
			       File[$static_files],
			       File["/etc/nagios/puppet_checks.d"] ];
	}

	# snmp tarp stuff
	systemuser { snmptt: name => "snmptt", home => "/var/spool/snmptt", groups => [ "snmptt", "nagios" ] }

	package { "snmpd":
		ensure => latest;
	}

	package { "snmptt":
		ensure => latest;
	}
	
	# Stomp Perl module to monitor erzurumi (RT #703)
	
	package { "libnet-stomp-perl":
		ensure => latest;
	}

	# make sure the directory for individual service checks exists
	file { "/etc/nagios/puppet_checks.d":
		ensure => directory,
		owner => root,
		group => root,
		recurse => true,
		mode => 0644;
	}

	file { "/usr/local/nagios/libexec/eventhandlers/submit_check_result":
		source => "puppet:///files/nagios/submit_check_result",
		owner => root,                                                                                                                                                 
                group => root,                                                                                                                                                 
                mode => 0755; 
	}

	file { "/etc/snmp/snmptrapd.conf":
		source => "puppet:///files/snmp/snmptrapd.conf",
		owner => root,                                                                                                                                                 
                group => root,                                                                                                                                                 
                mode => 0600; 
	}

	file { "/etc/snmp/snmptt.conf":
		source => "puppet:///files/snmp/snmptt.conf",
		owner => root,                                                                                                                                                 
                group => root,                                                                                                                                                 
                mode => 0644; 
	}

	# Fix permissions
	file { $puppet_files:
		mode => 0644,
		ensure => present;
	}
	
	# also fix permissions on all individual service files
	exec { "fix_nagios_perms":
		command => "/bin/chmod -R 644 /etc/nagios/puppet_checks.d",
		notify => Service["nagios"],
		refreshonly => "true";
	}

	# Script to purge resources for non-existent hosts
	file { "/usr/local/sbin/purge-nagios-resources.py":
		source => "puppet:///files/nagios/purge-nagios-resources.py",
		owner => root,
		group => root,
		mode => 0755;
	}

	file { "/etc/init.d/nagios":
		source => "puppet:///files/nagios/nagios-init",
		owner => root,
		group => root,
		mode => 0755;
	}

	file { "/etc/nagios/nagios.cfg":
		source => "puppet:///files/nagios/nagios.cfg",
		owner => root,
		group => root,
		mode => 0644;
	}

	file { "/etc/nagios/special.cfg":
		source => "puppet:///files/nagios/special.cfg",
		owner => root,
		group => root,
		mode => 0644;
	}

	file { "/etc/nagios/cgi.cfg":
		source => "puppet:///files/nagios/cgi.cfg",
		owner => root,
		group => root,
		mode => 0644;
	}

	file { "/etc/nagios/htpasswd.users":
		source => "puppet:///private/nagios/htpasswd.users",
		owner => root,
		group => root,
		mode => 0644;
	}

	file { "/etc/nagios/checkcommands.cfg":
		content => template("nagios/checkcommands.cfg.erb"),
		owner => root,
		group => root,
		mode => 0644;
	}

	file { "/etc/nagios/contactgroups.cfg":
		source => "puppet:///files/nagios/contactgroups.cfg",
		owner => root,
		group => root,
		mode => 0644;
	}

	file { "/etc/nagios/contacts.cfg":
		source => "puppet:///private/nagios/contacts.cfg",
		owner => root,
		group => root,
		mode => 0644;
	}

	file { "/etc/nagios/migration.cfg":
		source => "puppet:///files/nagios/migration.cfg",
		owner => root,
		group => root,
		mode => 0644;
	}

	file { "/etc/nagios/misccommands.cfg":
		source => "puppet:///files/nagios/misccommands.cfg",
		owner => root,
		group => root,
		mode => 0644;
	}

	file { "/etc/nagios/resource.cfg":
		source => "puppet:///files/nagios/resource.cfg",
		owner => root,
		group => root,
		mode => 0644;
	}

	file { "/etc/nagios/timeperiods.cfg":
		source => "puppet:///files/nagios/timeperiods.cfg",
		owner => root,
		group => root,
		mode => 0644;
	}

	# Collect exported resources
	Nagios_host <<| |>> {
		#before => Service[nagios],
		notify => Service[nagios],
	}
	Nagios_hostextinfo <<| |>> {
		notify => Service[nagios],
	}
	Nagios_service <<| |>> {
		notify => Service[nagios],
	}

        # Collect all (virtual) resources
	Monitor_group <| |> {
		notify => Service[nagios],
	}
	Monitor_host <| |> {
		notify => Service[nagios],
	}
	Monitor_service <| tag != "nrpe" |> {
		notify => Service[nagios],
	}

	# Decommission servers
	decommission_monitor_host { $decommissioned_servers: }

	file { "/usr/local/nagios/libexec/check_mysql-replication.pl":
			source => "puppet:///files/nagios/check_mysql-replication.pl",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/local/nagios/libexec/check_cert":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/nagios/check_cert";
		"/usr/local/nagios/libexec/check_all_memcached.php":
			source => "puppet:///files/nagios/check_all_memcached.php",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/local/nagios/libexec/check_bad_apaches":
			source => "puppet:///files/nagios/check_bad_apaches",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/local/nagios/libexec/check_job_queue":
			source => "puppet:///files/nagios/check_job_queue",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/local/nagios/libexec/check_longqueries":
			source => "puppet:///files/nagios/check_longqueries",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/local/nagios/libexec/check_MySQL.php":
			source => "puppet:///files/nagios/check_MySQL.php",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/local/nagios/libexec/check-ssl-cert":
			source => "puppet:///files/nagios/check-ssl-cert",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/local/nagios/libexec/check_stomp.pl":
			source => "puppet:///files/nagios/check_stomp.pl",
			owner => root,
			group => root,
			mode => 0755;
	}
}

class nagios::monitor::pager {

	#package { "gammu":
	#	ensure => latest;
	#}

	#package { "gammu-smsd":
	#	ensure => latest;
	#}

	include passwords::nagios::monitor

	$gammu_pin = $passwords::nagios::monitor::gammu_pin
	file {
		"/etc/gammurc":
			source => "puppet:///files/nagios/gammurc",
			owner => root,
			mode => 0644;
		"/etc/gammu-smsdrc":
			content => template("nagios/gammu-smsdrc.erb"),
			owner => root,
			mode => 0644;
	}

	systemuser { gammu: name => "gammu", home => "/nonexistent", groups => [ "gammu", "dialout" ] }

	service { gammu-smsd:
		require => [ Systemuser[gammu], File["/etc/gammurc"], File["/etc/gammu-smsdrc"] ],
		subscribe => [ File["/etc/gammurc"], File["/etc/gammu-smsdrc"] ],
		ensure => running;
	}
}
class nagios::ganglia::monitor::enwiki {

	include passwords::nagios::mysql
	$ganglia_mysql_enwiki_pass = $passwords::nagios::mysql::mysql_enwiki_pass
	$ganglia_mysql_enwiki_user = $passwords::nagios::mysql::mysql_enwiki_user
	cron {
		enwiki_jobqueue_length:
			command => "/usr/bin/gmetric --name='enwiki JobQueue length' --type=int32 --conf=/etc/ganglia/gmond.conf --value=$(mysql --batch --skip-column-names -u $ganglia_mysql_enwiki_user -p$ganglia_mysql_enwiki_pass -h db36.pmtpa.wmnet enwiki -e 'select count(*) from job') > /dev/null 2>&1",
			user => root,
			ensure => present;
	}
	# duplicating the above job to experiment with gmetric's host spoofing so as to
	#  gather these metrics in a fake host called "en.wikipedia.org"
	cron {
		enwiki_jobqueue_length_spoofed:
			command => "/usr/bin/gmetric --name='enwiki JobQueue length' --type=int32 --conf=/etc/ganglia/gmond.conf --spoof 'en.wikipedia.org:en.wikipedia.org' --value=$(mysql --batch --skip-column-names -u $ganglia_mysql_enwiki_user -p$ganglia_mysql_enwiki_pass -h db36.pmtpa.wmnet enwiki -e 'select count(*) from job') > /dev/null 2>&1",
			user => root,
			ensure => present;
	}
}

class nagios::ganglia::ganglios {
	package { "ganglios":
		ensure => latest;
	}
	cron { "ganglios-cron":
		command => "/usr/sbin/ganglia_parser",
		user => nagios,
		ensure => present;
	}
	file { "/var/lib/ganglia/xmlcache":
		ensure => directory,
		mode => 0755,
		owner => nagios;
	}
}

class nagios::bot {

        $ircecho_infile = "/var/log/nagios/irc.log"
        $ircecho_nick = "nagios-wm"
        $ircecho_chans = "#wikimedia-operations,#wikimedia-tech"
        $ircecho_server = "irc.freenode.net"

	package { "ircecho":
		ensure => latest;
	}

	service { "ircecho":
		require => Package[ircecho],
		ensure => running;
	}

	file {
		"/etc/default/ircecho":
			require => Package[ircecho],
			content => template('ircecho/default.erb'),
			owner => root,
			mode => 0755;
	}

}

# passive checks / NSCA

# package contains daemon and client script
class nagios::nsca {

	package { "nsca":
		ensure => latest;
	}

}
# NSCA - daemon
class nagios::nsca::daemon {

	require nagios::nsca

	file { "/etc/nsca.cfg":
		source => "puppet:///private/nagios/nsca.cfg",
		owner => root,
		mode => 0400;
	}


	service { "nsca":
		ensure => running;
	}


	# deny access to port 5667 TCP (nsca) from external networks

	class iptables-purges {

		require "iptables::tables"

		iptables_purge_service{  "deny_pub_nsca": service => "nsca" }
	}

	class iptables-accepts {

		require "nagios::nsca::daemon::iptables-purges"

		iptables_add_service{ "lo_all": interface => "lo", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "localhost_all": source => "127.0.0.1", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "private_all": source => "10.0.0.0/8", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "public_all": source => "208.80.154.128/26", service => "all", jump => "ACCEPT" }
	}

	class iptables-drops {

		require "nagios::nsca::daemon::iptables-accepts"

		iptables_add_service{ "deny_pub_nsca": service => "nsca", jump => "DROP" }
	}

	class iptables {

		require "nagios::nsca::daemon::iptables-drops"

		iptables_add_exec{ "${hostname}": service => "nsca" }
	}

	require "nagios::nsca::daemon::iptables"
}

# NSCA - client
class nagios::nsca::client {

	require nagios::nsca

	file { "/etc/send_nsca.cfg":
		source => "puppet:///private/nagios/send_nsca.cfg",
		owner => root,
		mode => 0400;
	}

	service { "nsca":
		ensure => stopped;
	}
}
