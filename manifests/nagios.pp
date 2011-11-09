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
		target => "${nagios_config_dir}/puppet_checks.d/${host}.cfg",
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
			target => "${nagios_config_dir}/puppet_checks.d/${host}.cfg",
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
		fail("Parameter $host not defined!")
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
	# Remove the decommissioned hosts's file
	file { "${nagios_config_dir}/puppet_checks.d/${title}.cfg":
		ensure => absent
	}
}

# Class which implements the monitoring services on the monitor host
class nagios::monitor {
	class packages {
		# nagios3: nagios itself, depends: nagios3-core nagios3-cgi (nagios3-common)
		# nagios-plugins: the regular plugins as also installed on monitored hosts. depends: nagios-plugins-basic, nagios-plugins-standard
		# nagios-plugins-extra: plugins, but "extra functionality to be useful on a central nagios host"
		# nagios-images: images and icons for the web frontend

		package { [ 'nagios3', 'nagios-plugins', 'nagios-plugins-extra', 'nagios-images' ]:
			ensure => latest;
		}
	}

	class config {
		require nagios::monitor::packages

		include passwords::nagios::mysql
		$nagios_mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

		systemuser { nagios: name => "nagios", home => "/home/nagios", groups => [ "nagios", "dialout", "gammu" ] }

		file { "/etc/init.d/nagios":
			source => "puppet:///files/nagios/nagios-init",
			owner => root,
			group => root,
			mode => 0555;
		}
		
		# make sure the directory for individual service checks exists
		file { "/etc/nagios/puppet_checks.d":
			ensure => directory,
			owner => root,
			group => root,
			mode => 0755;
		}
		
		# Defaults
		File {
			owner => root,
			group => root,
			mode => 0444
		}
		
		file {
			"/etc/nagios/nagios.cfg":
				source => "puppet:///files/nagios/nagios.cfg",
				notify => Service[nagios];
			"/etc/nagios/special.cfg":
				source => "puppet:///files/nagios/special.cfg",
				notify => Service[nagios];
			"/etc/nagios/cgi.cfg":
				source => "puppet:///files/nagios/cgi.cfg",
				notify => Service[nagios];
			"/etc/nagios/htpasswd.users":
				source => "puppet:///private/nagios/htpasswd.users",
				notify => Service[nagios];
			"/etc/nagios/checkcommands.cfg":
				content => template("nagios/checkcommands.cfg.erb"),
				notify => Service[nagios];
			"/etc/nagios/contactgroups.cfg":
				source => "puppet:///files/nagios/contactgroups.cfg",
				notify => Service[nagios];
			"/etc/nagios/contacts.cfg":
				source => "puppet:///private/nagios/contacts.cfg",
				notify => Service[nagios];
			"/etc/nagios/migration.cfg":
				source => "puppet:///files/nagios/migration.cfg",
				notify => Service[nagios];
			"/etc/nagios/misccommands.cfg":
				source => "puppet:///files/nagios/misccommands.cfg",
				notify => Service[nagios];
			"/etc/nagios/resource.cfg":
				source => "puppet:///files/nagios/resource.cfg",
				notify => Service[nagios];
			"/etc/nagios/timeperiods.cfg":
				source => "puppet:///files/nagios/timeperiods.cfg",
				notify => Service[nagios];
		}	
	}

	class checks {
		require nagios::monitor::config,
			nagios::monitor::checkcommands
		
		# Collect exported resources
		Nagios_host <<| |>> {
			before => Class[decommission],
			notify => Service[nagios],
		}
		Nagios_hostextinfo <<| |>> {
			before => Class[decommission],
			notify => Service[nagios],
		}
		Nagios_service <<| |>> {
			before => Class[decommission],
			notify => Service[nagios],
		}

		# Collect all (virtual) resources
		Monitor_group <| |> {
			before => Class[decommission],
			notify => Service[nagios],
		}
		Monitor_host <| |> {
			before => Class[decommission],
			notify => Service[nagios],
		}
		Monitor_service <| tag != "nrpe" |> {
			before => Class[decommission],
			notify => Service[nagios],
		}
		
		include nagios::monitor::decommission
	}

	class decommission {
		require nagios::monitor::checks

		# Decommission servers
		decommission_monitor_host { $decommissioned_servers: }
	}

	class service {
		# Make sure all checks configuration has completed at this point,
		# and decommissioned hosts's configs have been removed
		require nagios::monitor::checks,
			nagios::monitor::decommission

		# Fix permissions on all individual service files
		exec { "fix nagios permissions":
			command => "/bin/chmod -R ugo+r /etc/nagios/puppet_hostgroups.cfg /etc/nagios/puppet_servicegroups.cfg /etc/nagios/puppet_checks.d/";
		}

		service { nagios:
			require => Exec["fix nagios permissions"],
			ensure => running;
		}
	}
	
	class traps {
		# snmp tarp stuff
		systemuser { snmptt: name => "snmptt", home => "/var/spool/snmptt", groups => [ "snmptt", "nagios" ] }

		package { [ "snmpd", "snmptt" ]: ensure => latest; }

		file {
			"/etc/snmp/snmptrapd.conf":
				source => "puppet:///files/snmp/snmptrapd.conf",
				owner => root,                                                                                                                                                 
				group => root,                                                                                                                                                 
				mode => 0400; 
			"/etc/snmp/snmptt.conf":
				source => "puppet:///files/snmp/snmptt.conf",
				owner => root,                                                                                                                                                 
				group => root,                                                                                                                                                 
				mode => 0444; 
		}
	}
	
	class checkcommands {
		# Stomp Perl module to monitor erzurumi (RT #703)

		package { "libnet-stomp-perl":
			ensure => latest;
		}
		
		# FIXME: move all nagios checkcommand scripts into a separate directory,
		# and manage them with one recursive file { }.

		file {
			"/usr/local/nagios/libexec/check_mysql-replication.pl":
				source => "puppet:///files/nagios/check_mysql-replication.pl",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/local/nagios/libexec/check_cert":
				owner => root,
				group => root,
				mode => 0555,
				source => "puppet:///files/nagios/check_cert";
			"/usr/local/nagios/libexec/check_all_memcached.php":
				source => "puppet:///files/nagios/check_all_memcached.php",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/local/nagios/libexec/check_bad_apaches":
				source => "puppet:///files/nagios/check_bad_apaches",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/local/nagios/libexec/check_job_queue":
				source => "puppet:///files/nagios/check_job_queue",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/local/nagios/libexec/check_longqueries":
				source => "puppet:///files/nagios/check_longqueries",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/local/nagios/libexec/check_MySQL.php":
				source => "puppet:///files/nagios/check_MySQL.php",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/local/nagios/libexec/check-ssl-cert":
				source => "puppet:///files/nagios/check-ssl-cert",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/local/nagios/libexec/check_stomp.pl":
				source => "puppet:///files/nagios/check_stomp.pl",
				owner => root,
				group => root,
				mode => 0555;
		}
		
		file { "/usr/local/nagios/libexec/eventhandlers/submit_check_result":
			source => "puppet:///files/nagios/submit_check_result",
			owner => root,                                                                                                                                                 
			group => root,                                                                                                                                                 
			mode => 0755; 
		}
	}
	
	include packages, config, checkcommands, traps, checks, service
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
			mode => 0444;
		"/etc/gammu-smsdrc":
			content => template("nagios/gammu-smsdrc.erb"),
			owner => root,
			mode => 0444;
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

	system_role { "nagios::nsca::daemon": description => "Nagios Service Checks Acceptor Daemon" }

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

		# temporarily remove the exec rule so that the ruleset is simply created
		# and we can inspect the file before allowing puppet to auto-load the rules
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
