# nagios.pp

import "generic-definitions.pp"
import "decommissioning.pp"

$nagios_config_dir = "/etc/nagios"

$ganglia_url = "http://ganglia.wikimedia.org"

define monitor_host ($ip_address=$ipaddress, $group=$nagios_group, $ensure=present, $critical="false", $contact_group="admins") {
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
					default => $contact_group
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

define monitor_service ($description, $check_command, $host=$hostname, $retries=3, $group=$nagios_group, $ensure=present, $critical="false", $passive="false", $freshness=36000, $normal_check_interval=1, $retry_check_interval=1, $contact_group="admins") {
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
			normal_check_interval => $normal_check_interval,
			retry_check_interval => $retry_check_interval,
			check_period => "24x7",
	                notification_interval => 0,
			notification_period => "24x7",
			notification_options => "c,r,f",
			contact_groups => $critical ? {
						"true" => "admins,sms",
						default => $contact_group
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
			normal_check_interval => $normal_check_interval,
			retry_check_interval => $retry_check_interval,
			check_period => "24x7",
			notification_interval => $critical ? {
					"true" => 240,
					default => 0
					},
			notification_period => "24x7",
			notification_options => "c,r,f",
			contact_groups => $critical ? {
						"true" => "admins,sms",
						default => $contact_group
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

# Nagios/icinga configuration files

class nagios::configuration {

	#This variable declares the monitoring hosts
	#It is called master hosts as monitor_host is already
	#a service.

	$master_hosts = [ "neon.wikimedia.org", "spence.wikimedia.org" ]

	$icinga_config_dir = "/etc/icinga"
	$nagios_config_dir = "/etc/icinga"

}

# Class which implements the monitoring services on the monitor host
class nagios::monitor {

	require nrpe

	include passwords::nagios::mysql
	$nagios_mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

	# puppet_hosts.cfg must be first
	$puppet_files = [ "${nagios_config_dir}/puppet_hosts.cfg",
			  "${nagios_config_dir}/puppet_hostgroups.cfg",
			  "${nagios_config_dir}/puppet_hostextinfo.cfg",
			  "${nagios_config_dir}/puppet_servicegroups.cfg",
			  "${nagios_config_dir}/puppet_services.cfg" ]

	$static_files = [ "${nagios_config_dir}/nagios.cfg",
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

	# nagios3: nagios itself, depends: nagios3-core nagios3-cgi (nagios3-common)
	# nagios-images: images and icons for the web frontend

	package { [ 'nagios3', 'nagios-images' ]:
		ensure => latest;
	}

	service { nagios:
		require => File[$puppet_files],
		ensure => running,
		subscribe => [ File[$puppet_files],
			       File[$static_files],
			       File["/etc/nagios/puppet_checks.d"] ];
	}

	class snmp {

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

		# snmp tarp stuff
		systemuser { snmptt: name => "snmptt", home => "/var/spool/snmptt", groups => [ "snmptt", "nagios" ] }

		package { "snmpd":
			ensure => latest;
		}

		package { "snmptt":
			ensure => latest;
		}

	}

	class firewall {

		# deny access to port 5667 TCP (nsca) from external networks
		# deny service snmp-trap (port 162) for external networks

		class iptables-purges {

			require "iptables::tables"
			iptables_purge_service{  "deny_pub_snmptrap": service => "snmptrap" }
			iptables_purge_service{  "deny_pub_nsca": service => "nsca" }
		}

		class iptables-accepts {

			require "nagios::monitor::firewall::iptables-purges"

			iptables_add_service{ "lo_all": interface => "lo", service => "all", jump => "ACCEPT" }
			iptables_add_service{ "localhost_all": source => "127.0.0.1", service => "all", jump => "ACCEPT" }
			iptables_add_service{ "private_pmtpa_nolabs": source => "10.0.0.0/14", service => "all", jump => "ACCEPT" }
			iptables_add_service{ "private_esams": source => "10.21.0.0/24", service => "all", jump => "ACCEPT" }
			iptables_add_service{ "private_eqiad1": source => "10.64.0.0/19", service => "all", jump => "ACCEPT" }
			iptables_add_service{ "private_eqiad2": source => "10.65.0.0/20", service => "all", jump => "ACCEPT" }
			iptables_add_service{ "public_152": source => "208.80.152.0/24", service => "all", jump => "ACCEPT" }
			iptables_add_service{ "public_153": source => "208.80.153.128/26", service => "all", jump => "ACCEPT" }
			iptables_add_service{ "public_154": source => "208.80.154.0/24", service => "all", jump => "ACCEPT" }
			iptables_add_service{ "public_esams": source => "91.198.174.0/25", service => "all", jump => "ACCEPT" }
		}

		class iptables-drops {

			require "nagios::monitor::firewall::iptables-accepts"
			iptables_add_service{ "deny_pub_nsca": service => "nsca", jump => "DROP" }
			iptables_add_service{ "deny_pub_snmptrap": service => "snmptrap", jump => "DROP" }
		}

		class iptables {

			require "nagios::monitor::firewall::iptables-drops"
			iptables_add_exec{ "${hostname}_nsca": service => "nsca" }
			iptables_add_exec{ "${hostname}_snmptrap": service => "snmptrap" }
		}

		require "nagios::monitor::firewall::iptables"
	}

	# Stomp Perl module to monitor erzurumi (RT #703)

	package { "libnet-stomp-perl":
		ensure => latest;
	}

	# PHP CLI needed for check scripts
	package { [ "php5-cli", "php5-mysql" ]:
		ensure => latest;
	}

	# install the nagios Apache site
	file { "/etc/apache2/sites-available/nagios":
		ensure => present,
		owner => root,
		group => root,
		mode => 0444,
		source => "puppet:///files/apache/sites/nagios.wikimedia.org";
	}

	apache_site { nagios: name => "nagios" }

	# make sure the directory for individual service checks exists
	file { "/etc/nagios":
		ensure => directory,
		owner => root,
		group => root,
		mode => 0755;

		"/etc/nagios/puppet_checks.d":
		ensure => directory,
		owner => root,
		group => root,
		mode => 0755;
	}

	file { "/usr/local/nagios/libexec/eventhandlers/submit_check_result":
		source => "puppet:///files/nagios/submit_check_result",
		owner => root,
		group => root,
		mode => 0755;
	}

	# Fix permissions
	file { $puppet_files:
		mode => 0644,
		ensure => present;
	}

	# also fix permissions on all individual service files
	exec { "fix_nagios_perms":
		command => "/bin/chmod -R ugo+r /etc/nagios/puppet_checks.d",
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

	file { "/etc/nagios/cgi.cfg":
		source => "puppet:///files/nagios/cgi.cfg",
		owner => root,
		group => root,
		mode => 0644;
	}

	file { "/etc/nagios/nsca_payments.cfg":
		source => "puppet:///private/nagios/nsca_payments.cfg",
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

#FIXME - lcarr 2012/02/17
# nagios::monitor::newmonitor will augment/replace many nagios
# features and uses icinga exclusively
# However, these items may break the existing setup on spence
# DO NOT FOR ANY REASON put this class on spence

class nagios::monitor::newmonitor {

	require nagios::configuration,
		icinga::monitor

	class {"webserver::php5": ssl => "true";}

	include webserver::php5-gd,
		generic::apache::no-default-site,
		mysql,
		nrpe::new,
		nagios::monitor::jobqueue::new

	include passwords::nagios::mysql

	install_certificate{ "star.wikimedia.org": }

	# snmp tarp stuff
	systemuser { snmptt: name => "snmptt", home => "/var/spool/snmptt", groups => [ "snmptt", "icinga" ] }

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

	# PHP CLI needed for check scripts
	package { [ "php5-cli", "php5-mysql" ]:
		ensure => latest;
	}

	# install the icinga Apache site
	file { "/etc/apache2/sites-available/icinga.wikimedia.org":
			ensure => present,
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/apache/sites/icinga.wikimedia.org";
	}

	# remove icinga default config
	file { "/etc/icinga/apache2.conf":
			ensure => absent;

		"/etc/apache2/conf.d/icinga.conf":
			ensure => absent;
	}

	apache_site { icinga: name => "icinga.wikimedia.org" }

	# make sure the directory for individual service checks exists
	file {
		"/etc/icinga/puppet_checks.d":
			ensure => directory,
			owner => root,
			group => root,
			mode => 0755;

		"/etc/nagios":
			ensure => directory,
			owner => root,
			group => root,
			mode => 0755;

		"/etc/nagios/puppet_checks.d":
			ensure => directory,
			owner => root,
			group => root,
			mode => 0755;

		"/usr/lib/nagios":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;

		"/usr/lib/nagios/plugins":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;

		"/usr/lib/nagios/plugins/eventhandlers":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;

		"/usr/lib/nagios/plugins/eventhandlers/submit_check_result":
			source => "puppet:///files/nagios/submit_check_result",
			owner => root,
			group => root,
			mode => 0755;

		 "/etc/snmp/snmptrapd.conf":
			source => "puppet:///files/snmp/snmptrapd.conf",
			owner => root,
			group => root,
			mode => 0600;

		 "/etc/snmp/snmptt.conf":
			source => "puppet:///files/snmp/snmptt.conf",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/init.d/icinga":
			source => "puppet:///files/icinga/icinga-init",
			owner => root,
			group => root,
			mode => 0755;
	}

	# Fix permissions
	file { $icinga::monitor::puppet_files:
		mode => 0644,
		ensure => present;
	}

	# also fix permissions on all individual service files
	exec {
		"fix_nagios_perms":
		command => "/bin/chmod -R a+r /etc/nagios/puppet_checks.d";

		"fix_icinga_perms":
		command => "/bin/chmod -R a+r /etc/icinga/puppet_checks.d";
		}

	# Script to purge resources for non-existent hosts
	file { "/usr/local/sbin/purge-nagios-resources.py":
		source => "puppet:///files/nagios/purge-nagios-resources.py",
		owner => root,
		group => root,
		mode => 0755;
	}

	# Nagios plugin configuration files
	file {
		"/etc/nagios-plugins":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;

		"/etc/nagios-plugins/config":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;

		"/etc/nagios-plugins/config/apt.cfg":
			source => "puppet:///files/icinga/plugin-config/apt.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/breeze.cfg":
			source => "puppet:///files/icinga/plugin-config/breeze.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/dhcp.cfg":
			source => "puppet:///files/icinga/plugin-config/dhcp.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/disk-smb.cfg":
			source => "puppet:///files/icinga/plugin-config/disk-smb.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/disk.cfg":
			source => "puppet:///files/icinga/plugin-config/disk.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/dns.cfg":
			source => "puppet:///files/icinga/plugin-config/dns.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/dummy.cfg":
			source => "puppet:///files/icinga/plugin-config/dummy.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/flexlm.cfg":
			source => "puppet:///files/icinga/plugin-config/flexlm.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/ftp.cfg":
			source => "puppet:///files/icinga/plugin-config/ftp.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/hppjd.cfg":
			source => "puppet:///files/icinga/plugin-config/hppjd.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/http.cfg":
			source => "puppet:///files/icinga/plugin-config/http.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/ifstatus.cfg":
			source => "puppet:///files/icinga/plugin-config/ifstatus.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/ldap.cfg":
			source => "puppet:///files/icinga/plugin-config/ldap.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/load.cfg":
			source => "puppet:///files/icinga/plugin-config/load.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/mail.cfg":
			source => "puppet:///files/icinga/plugin-config/mail.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/mrtg.cfg":
			source => "puppet:///files/icinga/plugin-config/mrtg.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/mysql.cfg":
			source => "puppet:///files/icinga/plugin-config/mysql.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/netware.cfg":
			source => "puppet:///files/icinga/plugin-config/netware.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/news.cfg":
			source => "puppet:///files/icinga/plugin-config/news.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/nt.cfg":
			source => "puppet:///files/icinga/plugin-config/nt.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/ntp.cfg":
			source => "puppet:///files/icinga/plugin-config/ntp.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/pgsql.cfg":
			source => "puppet:///files/icinga/plugin-config/pgsql.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/ping.cfg":
			source => "puppet:///files/icinga/plugin-config/ping.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/procs.cfg":
			source => "puppet:///files/icinga/plugin-config/procs.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/radius.cfg":
			source => "puppet:///files/icinga/plugin-config/radius.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/real.cfg":
			source => "puppet:///files/icinga/plugin-config/real.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/rpc-nfs.cfg":
			source => "puppet:///files/icinga/plugin-config/rpc-nfs.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/snmp.cfg":
			source => "puppet:///files/icinga/plugin-config/snmp.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/ssh.cfg":
			source => "puppet:///files/icinga/plugin-config/ssh.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/tcp_udp.cfg":
			source => "puppet:///files/icinga/plugin-config/tcp_udp.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/telnet.cfg":
			source => "puppet:///files/icinga/plugin-config/telnet.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/users.cfg":
			source => "puppet:///files/icinga/plugin-config/users.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/nagios-plugins/config/vsz.cfg":
			source => "puppet:///files/icinga/plugin-config/vsz.cfg",
			owner => root,
			group => root,
			mode => 0644;
	}

	service { "icinga":
		require => File[$icinga::monitor::puppet_files],
		ensure => running,
		subscribe => [ File[$icinga::monitor::puppet_files],
			       File[$icinga::monitor::static_files],
			       File["/etc/icinga/puppet_checks.d"] ];
	}

	# Collect exported resources
	Nagios_host <<| |>> {
		notify => Service[icinga],
	}
	Nagios_hostextinfo <<| |>> {
		notify => Service[icinga],
	}
	Nagios_service <<| |>> {
		notify => Service[icinga],
	}

	# Collect all (virtual) resources
	Monitor_group <| |> {
		notify => Service[icinga],
	}
	Monitor_host <| |> {
		notify => Service[icinga],
	}
	Monitor_service <| tag != "nrpe" |> {
		notify => Service[icinga],
	}

	# Decommission servers
	decommission_monitor_host { $decommissioned_servers: }

	# this command is so long because puppet will not insert a list of files
	# separated by spaces

	exec { "purge_decommissioned":
		command => "/usr/local/sbin/purge-nagios-resources.py /etc/icinga/puppet_hosts.cfg /etc/icinga/puppet_hostgroups.cfg /etc/icinga/puppet_hostextinfo.cfg /etc/icinga/puppet_servicegroups.cfg /etc/icinga/puppet_services.cfg /etc/nagios/puppet_checks.d/* /etc/icinga/puppet_checks.d/*",
		timeout => 60;
	}

	# WMF custom service checks
	file {
		"/usr/lib/nagios/plugins/check_mysql-replication.pl":
			source => "puppet:///files/nagios/check_mysql-replication.pl",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/lib/nagios/plugins/check_cert":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/nagios/check_cert";
		"/usr/lib/nagios/plugins/check_all_memcached.php":
			source => "puppet:///files/nagios/check_all_memcached.php",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/lib/nagios/plugins/check_bad_apaches":
			source => "puppet:///files/nagios/check_bad_apaches",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/lib/nagios/plugins/check_longqueries":
			source => "puppet:///files/nagios/check_longqueries",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/lib/nagios/plugins/check_MySQL.php":
			source => "puppet:///files/nagios/check_MySQL.php",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/lib/nagios/plugins/check-ssl-cert":
			source => "puppet:///files/nagios/check-ssl-cert",
			owner => root,
			group => root,
			mode => 0755;
		"/usr/lib/nagios/plugins/check_stomp.pl":
			source => "puppet:///files/nagios/check_stomp.pl",
			owner => root,
			group => root,
			mode => 0755;
	}

}
class nagios::monitor::jobqueue {

	file {"/usr/local/nagios/libexec/check_job_queue":
		source => "puppet:///files/nagios/check_job_queue",
		owner => root,
		group => root,
		mode => 0755;
	}

	monitor_service { "check_job_queue":
		description => "check_job_queue",
		check_command => "check_job_queue",
		normal_check_interval => 15,
		retry_check_interval => 5,
		critical => "false"
	}

}

#this class is for the new icinga install
# DO NOT install this on spence
class nagios::monitor::jobqueue::new {

	file {"/usr/lib/nagios/plugins/check_job_queue":
		source => "puppet:///files/nagios/check_job_queue",
		owner => root,
		group => root,
		mode => 0755;
	}

	monitor_service { "check_job_queue":
		description => "check_job_queue",
		check_command => "check_job_queue",
		normal_check_interval => 15,
		retry_check_interval => 5,
		critical => "false"
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
		"/usr/local/sbin/page_all":
			source => "puppet:///files/nagios/page_all",
			owner => root,
			group => root,
			mode => 0550;
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
		command => "test -w /var/log/ganglia/ganglia_parser.log && /usr/sbin/ganglia_parser",
		user => nagios,
		ensure => present;
	}
	file { "/var/lib/ganglia/xmlcache":
		ensure => directory,
		mode => 0755,
		owner => nagios;
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
