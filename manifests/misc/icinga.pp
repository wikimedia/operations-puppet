# misc/icinga.pp

import "../generic-definitions.pp"
import "../decommissioning.pp"
import "../nagios.pp"

class icinga::monitor {

	include
		icinga::monitor::packages,
		passwords::nagios::mysql,
		icinga::monitor::firewall,
		icinga::monitor::configuration::files,
		icinga::monitor::files::nagios-plugins,
		icinga::monitor::snmp,
		icinga::monitor::checkpaging,
		icinga::monitor::service,
		icinga::monitor::jobqueue,
		icinga::monitor::snmp,
		icinga::monitor::naggen,
		icinga::monitor::nsca::daemon,
		icinga::monitor::apache,
		icinga::monitor::files::misc,
		nagios::ganglia::monitor::enwiki,
		icinga::ganglia::ganglios,
		mysql,
		nrpe::new

	systemuser { icinga: name => "icinga", home => "/home/icinga", groups => [ "icinga", "dialout", "nagios" ] }

	Class['icinga::monitor::packages'] -> Class['icinga::monitor::configuration::files'] -> Class['icinga::monitor::service']

}

# Nagios/icinga configuration files

class icinga::monitor::configuration::variables {

	#This variable declares the monitoring hosts
	#It is called master hosts as monitor_host is already
	#a service.

	$master_hosts = [ "neon.wikimedia.org", "spence.wikimedia.org" ]

	$icinga_config_dir = "/etc/icinga"
	$nagios_config_dir = "/etc/nagios"

	# puppet_hosts.cfg must be first
	$puppet_files = [
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/puppet_hostgroups.cfg",
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/puppet_servicegroups.cfg"]

	$static_files = [
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/puppet_hostextinfo.cfg",
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/puppet_services.cfg",
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/icinga.cfg",
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/analytics.cfg", # TEMP.  This will be removed when analytics puppetization goes to production
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/cgi.cfg",
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/checkcommands.cfg",
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/contactgroups.cfg",
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/contacts.cfg",
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/misccommands.cfg",
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/resource.cfg",
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/timeperiods.cfg",
			  "${icinga::monitor::configuration::variables::icinga_config_dir}/htpasswd.users"]

}
class icinga::monitor::apache {
	class {"webserver::php5": ssl => "true";}

	include webserver::php5-gd

	file {
		"/usr/share/icinga/htdocs/images/logos/ubuntu.png":
			source => "puppet:///files/icinga/ubuntu.png",
			owner => root,
			group => root,
			mode => 0644;

		# install the icinga Apache site
		"/etc/apache2/sites-available/icinga.wikimedia.org":
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
	install_certificate{ "star.wikimedia.org": }

}

class icinga::monitor::checkpaging {

  require icinga::monitor::packages

	file {"/usr/lib/nagios/plugins/check_to_check_nagios_paging":
		source => "puppet:///files/nagios/check_to_check_nagios_paging",
		owner => root,
		group => root,
		mode => 0755;
	}
	monitor_service { "check_to_check_nagios_paging":
		description => "check_to_check_nagios_paging",
		check_command => "check_to_check_nagios_paging",
		normal_check_interval => 1,
		retry_check_interval => 1,
		contact_group => "pager_testing",
		critical => "false"
	}
}

class icinga::monitor::configuration::files {
	# For all files dealing with icinga configuration

  require icinga::monitor::packages
	require passwords::nagios::mysql

	$nagios_mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

  Class['icinga::monitor::configuration::variables'] -> Class['icinga::monitor::configuration::files']

	# Icinga configuration files

	file { "/etc/icinga/cgi.cfg":
			source => "puppet:///files/icinga/cgi.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/icinga.cfg":
			source => "puppet:///files/icinga/icinga.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/nsca_payments.cfg":
			source => "puppet:///private/nagios/nsca_payments.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/htpasswd.users":
			source => "puppet:///private/nagios/htpasswd.users",
			owner => root,
			group => root,
			mode => 0644;

		# TEMP: analytics eqiad cluster manual entries.
		# These will be removed from this manually managed file
		# once analytics puppetization goes to production.
		"/etc/icinga/analytics.cfg":
			content => template("nagios/analytics.cfg.erb"),
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/checkcommands.cfg":
			content => template("icinga/checkcommands.cfg.erb"),
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/contactgroups.cfg":
			source => "puppet:///files/nagios/contactgroups.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/contacts.cfg":
			source => "puppet:///private/nagios/contacts.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/misccommands.cfg":
			source => "puppet:///files/icinga/misccommands.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/resource.cfg":
			source => "puppet:///files/icinga/resource.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/icinga/timeperiods.cfg":
			source => "puppet:///files/nagios/timeperiods.cfg",
			owner => root,
			group => root,
			mode => 0644;

		"/etc/init.d/icinga":
			source => "puppet:///files/icinga/icinga-init",
			owner => root,
			group => root,
			mode => 0755;
	}
}

class icinga::monitor::files::misc {
# Required files and directories
# Must be loaded last

	file {
		"/etc/icinga/conf.d":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;

		"/etc/nagios":
			ensure => directory,
			owner => root,
			group => root,
			mode => 0755;

		"/var/cache/icinga":
			ensure => directory,
			owner => icinga,
			group => www-data,
			mode => 0775;

		"/var/lib/nagios/rw":
			ensure => directory,
			owner => icinga,
			group => nagios,
			mode => 0777;

		"/var/lib/icinga":
			ensure => directory,
			owner => icinga,
			group => www-data,
			mode => 0755;

		# Script to purge resources for non-existent hosts
		 "/usr/local/sbin/purge-nagios-resources.py":
			source => "puppet:///files/nagios/purge-nagios-resources.py",
			owner => root,
			group => root,
			mode => 0755;
	}

	# fix permissions on all individual service files
	exec {
		"fix_nagios_perms":
			command => "/bin/chmod -R a+r /etc/nagios";

		"fix_icinga_perms":
			command => "/bin/chmod -R a+r /etc/icinga";

		"fix_icinga_temp_files":
			command => "/bin/chown -R icinga /var/lib/icinga";

		"fix_nagios_plugins_files":
			command => "/bin/chmod -R a+w /var/lib/nagios";

		"fix_icinga_command_file":
			command => "/bin/chmod a+rw /var/lib/nagios/rw/nagios.cmd";
	}
}

class icinga::monitor::files::nagios-plugins {

  require icinga::monitor::packages

	file {
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
			source => "puppet:///files/icinga/submit_check_result",
			owner => root,
			group => root,
			mode => 0755;

		"/var/lib/nagios/rm":
			owner => icinga,
			group => nagios,
			mode => 0775,
			ensure => directory;

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
		"/usr/lib/nagios/plugins/check_solr":
			source => "puppet:///files/nagios/check_solr",
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
		"/usr/lib/nagios/plugins/check_nrpe":
			source => "puppet:///files/icinga/check_nrpe",
			owner => root,
			group => root,
			mode => 0755;
	}

	# some default configuration files conflict and should be removed

	file {
		"/etc/nagios-plugins/config/mailq.cfg":
			ensure => absent;
	}

}


class icinga::monitor::firewall {

	# deny access to port 5667 TCP (nsca) from external networks
	# deny service snmp-trap (port 162) for external networks

	class iptables-purges {

		require "iptables::tables"
		iptables_purge_service{  "deny_pub_snmptrap": service => "snmptrap" }
		iptables_purge_service{  "deny_pub_nsca": service => "nsca" }
	}

	class iptables-accepts {

		require "icinga::monitor::firewall::iptables-purges"

		iptables_add_service{ "lo_all": interface => "lo", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "localhost_all": source => "127.0.0.1", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "private_pmtpa_nolabs": source => "10.0.0.0/14", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "private_esams": source => "10.21.0.0/24", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "private_eqiad1": source => "10.64.0.0/17", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "private_eqiad2": source => "10.65.0.0/20", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "private_virt": source => "10.4.16.0/24", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "public_152": source => "208.80.152.0/24", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "public_153": source => "208.80.153.128/26", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "public_154": source => "208.80.154.0/24", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "public_fundraising": source => "208.80.155.0/27", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "public_esams": source => "91.198.174.0/25", service => "all", jump => "ACCEPT" }
	}

	class iptables-drops {

		require "icinga::monitor::firewall::iptables-accepts"
		iptables_add_service{ "deny_pub_nsca": service => "nsca", jump => "DROP" }
		iptables_add_service{ "deny_pub_snmptrap": service => "snmptrap", jump => "DROP" }
		iptables_add_service{ "TEMP_deny_smtp": service => "smtp", jump => "DROP" }
	}

	class iptables {

		require "icinga::monitor::firewall::iptables-drops"
		iptables_add_exec{ "${hostname}_nsca": service => "nsca" }
		iptables_add_exec{ "${hostname}_snmptrap": service => "snmptrap" }
	}

	require "icinga::monitor::firewall::iptables"
}

class icinga::monitor::jobqueue {
	include icinga::monitor::packages
	include applicationserver::packages

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

class icinga::monitor::naggen {

	# Naggen takes exported resources from hosts and creates nagios configuration files

  require icinga::monitor::packages

	file {
		"/etc/icinga/puppet_hosts.cfg":
			content => generate('/usr/local/bin/naggen', '--stdout', '--type', 'host'),
			backup => false,
			owner => root,
			group => root,
			mode => 0644;
		"/etc/icinga/puppet_services.cfg":
			content => generate('/usr/local/bin/naggen', '--stdout', '--type', 'service'),
			backup => false,
			owner => root,
			group => root,
			mode => 0644;
		"/etc/icinga/puppet_hostextinfo.cfg":
			content => generate('/usr/local/bin/naggen', '--stdout', '--type', 'hostextinfo'),
			backup => false,
			owner => root,
			group => root,
			mode => 0644;
	}

	# Fix permissions

	file { $icinga::monitor::configuration::variables::puppet_files:
		mode => 0644,
		ensure => present;
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
}

# NSCA - Nagios Service Check Acceptor
# package contains daemon and client script
class icinga::nsca {

	package { "nsca":
		ensure => latest;
	}

}

# NSCA - daemon config
class icinga::monitor::nsca::daemon {

	system_role { "icinga::nsca::daemon": description => "Nagios Service Checks Acceptor Daemon" }

	require icinga::nsca

	file { "/etc/nsca.cfg":
		source => "puppet:///private/icinga/nsca.cfg",
		owner => root,
		mode => 0400;
	}

	service { "nsca":
		ensure => running;
	}
}

class icinga::monitor::packages {

	# icinga: icinga itself
	# icinga-doc: files for the web-frontend

	package { [ 'icinga', 'icinga-doc' ]:
		ensure => latest;
	}

	# Stomp Perl module to monitor erzurumi (RT #703)
	package { "libnet-stomp-perl":
		ensure => latest;
	}
}

class icinga::monitor::service {

  require icinga::monitor::apache

	service { "icinga":
		ensure => running,
		hasstatus => false,
		subscribe => [ File[$icinga::monitor::configuration::variables::puppet_files],
			       File[$icinga::monitor::configuration::variables::static_files],
			       File["/etc/icinga/puppet_services.cfg"],
			       File["/etc/icinga/puppet_hostextinfo.cfg"],
			       File["/etc/icinga/puppet_hosts.cfg"]];
	}
}

class icinga::monitor::snmp {

	file { "/etc/snmp/snmptrapd.conf":
			source => "puppet:///files/snmp/snmptrapd.conf.icinga",
			owner => root,
			group => root,
			mode => 0600;
	       "/etc/snmp/snmptt.conf":
			source => "puppet:///files/snmp/snmptt.conf.icinga",
			owner => root,
			group => root,
			mode => 0644;
	       "/etc/init.d/snmptt":
			source => "puppet:///files/snmp/snmptt.init",
			owner => root,
			group => root,
			mode => 0755;
		"/etc/init.d/snmptrapd":
			source => "puppet:///files/snmp/snmptrapd.init",
			owner => root,
			group => root,
			mode => 0755;
		"/etc/init.d/snmpd":
			source => "puppet:///files/snmp/snmpd.init",
			owner => root,
			group => root,
			mode => 0755;
	}

	# snmp tarp stuff
	systemuser { snmptt: name => "snmptt", home => "/var/spool/snmptt", groups => [ "snmptt", "nagios" ] }

	package { "snmpd":
		ensure => latest;
	}

	package { "snmptt":
		ensure => latest;
	}

	service { snmptt:
		ensure => running,
		hasstatus => false,
		subscribe => [ File["/etc/snmp/snmptt.conf"],
			       File["/etc/init.d/snmptt"],
			       File["/etc/snmp/snmptrapd.conf"]];
	}

	service { snmptrapd:
		ensure => running,
		hasstatus => false,
		subscribe => File["/etc/init.d/snmptrapd"];
	}

	service { snmpd:
		ensure => running,
		hasstatus => false,
		subscribe => File["/etc/init.d/snmpd"];
	}

	# FIXME: smptt crashes periodically on precise
	cron { "restart_snmptt":
		command => "service snmptt restart",
		user => root,
		hour => [0, 4, 8, 12, 16, 20],
		minute => 7,
		ensure => present;
	} 

}

class icinga::ganglia::ganglios {
	include generic::mysql::packages::client,
		ganglia::collector

	package { "ganglios":
		ensure => latest;
	}
	cron { "ganglios-cron":
		command => "test -w /var/log/ganglia/ganglia_parser.log && /usr/sbin/ganglia_parser",
		user => icinga,
		minute => "*/2",
		ensure => present;
	}
	file { "/var/lib/ganglia/xmlcache":
		ensure => directory,
		mode => 0755,
		owner => icinga;
	}
}
