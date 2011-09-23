class openstack::iptables-purges {

	require "iptables::tables"

	# The deny_all rule must always be purged, otherwise ACCEPTs can be placed below it
	iptables_purge_service{ "${hostname}_deny_all_mysql": service => "mysql" }
	iptables_purge_service{ "${hostname}_deny_all_ldap": service => "ldap" }
	iptables_purge_service{ "${hostname}_deny_all_ldap_backend": service => "ldap_backend" }
	iptables_purge_service{ "${hostname}_deny_all_ldaps": service => "ldaps" }
	iptables_purge_service{ "${hostname}_deny_all_ldaps_backend": service => "ldaps_backend" }
	iptables_purge_service{ "${hostname}_deny_all_ldap_admin_connector": service => "ldap_admin_connector" }
	iptables_purge_service{ "${hostname}_deny_all_puppetmaster": service => "puppetmaster" }
	iptables_purge_service{ "${hostname}_deny_all_glance_api": service => "glance_api" }
	iptables_purge_service{ "${hostname}_deny_all_glance_registry": service => "glance_registry" }
	iptables_purge_service{ "${hostname}_deny_all_beam1": service => "beam1" }
	iptables_purge_service{ "${hostname}_deny_all_beam2": service => "beam2" }
	iptables_purge_service{ "${hostname}_deny_all_epmd": service => "epmd" }

	# When removing or modifying a rule, place the old rule here, otherwise it won't
	# be purged, and will stay in the iptables forever
	iptables_purge_service{ "${hostname}_nova_ec2_api_private": service => "nova_ec2_api" }
	iptables_purge_service{ "${hostname}_nova_os_api_private": service => "nova_openstack_api" }
	iptables_purge_service{ "${hostname}_deny_all_nova_ec2_api": service => "nova_ec2_api" }
	iptables_purge_service{ "${hostname}_deny_all_nova_openstack_api": service => "nova_openstack_api" }

}

class openstack::iptables-accepts {

	require "openstack::iptables-purges"

	# Rememeber to place modified or removed rules into purges!
	iptables_add_service{ "${hostname}_lo_all": interface => "lo", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_localhost_all": source => "127.0.0.1", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_virt1_all": source => "208.80.153.131", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_spence_all": source => "208.80.152.161", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_mysql_nova": source => "10.4.16.0/24", service => "mysql", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_mysql_gerrit": source => "208.80.152.147", service => "mysql", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldap_private": source => "10.4.0.0/16", service => "ldap", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldaps_private": source => "10.4.0.0/16", service => "ldaps", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldap_backend_private": source => "10.4.0.0/16", service => "ldap_backend", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldaps_backend_private": source => "10.4.0.0/16", service => "ldaps_backend", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldap_floating": source => "208.80.153.192/28", service => "ldap", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldaps_floating": source => "208.80.153.192/28", service => "ldaps", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldap_backend_floating": source => "208.80.153.192/28", service => "ldap_backend", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldaps_backend_floating": source => "208.80.153.192/28", service => "ldaps_backend", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldap_gerrit": source => "208.80.152.147", service => "ldap", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldaps_gerrit": source => "208.80.152.147", service => "ldaps", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldap_backend_gerrit": source => "208.80.152.147", service => "ldap_backend", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldaps_backend_gerrit": source => "208.80.152.147", service => "ldaps_backend", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_ldap_admin_connector_nfs1": source => "10.0.0.244", service => "ldap_admin_connector", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_puppet_private": source => "10.4.0.0/16", service => "puppetmaster", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_glance_api_nova": source => "10.4.16.0/24", service => "glance_api", jump => "ACCEPT" }
	iptables_add_service{ "${hostname}_beam2_nova": source => "10.4.16.0/24", service => "beam2", jump => "ACCEPT" }

}

class openstack::iptables-drops {

	require "openstack::iptables-accepts"

	# Deny by default
	iptables_add_service{ "${hostname}_deny_all_mysql": service => "mysql", jump => "DROP" }
	iptables_add_service{ "${hostname}_deny_all_ldap": service => "ldap", jump => "DROP" }
	iptables_add_service{ "${hostname}_deny_all_ldap_backend": service => "ldap_backend", jump => "DROP" }
	iptables_add_service{ "${hostname}_deny_all_ldaps": service => "ldaps", jump => "DROP" }
	iptables_add_service{ "${hostname}_deny_all_ldaps_backend": service => "ldaps_backend", jump => "DROP" }
	iptables_add_service{ "${hostname}_deny_all_ldap_admin_connector": service => "ldap_admin_connector", jump => "DROP" }
	iptables_add_service{ "${hostname}_deny_all_puppetmaster": service => "puppetmaster", jump => "DROP" }
	iptables_add_service{ "${hostname}_deny_all_glance_api": service => "glance_api", jump => "DROP" }
	iptables_add_service{ "${hostname}_deny_all_glance_registry": service => "glance_registry", jump => "DROP" }
	iptables_add_service{ "${hostname}_deny_all_beam1": service => "beam1", jump => "DROP" }
	iptables_add_service{ "${hostname}_deny_all_beam2": service => "beam2", jump => "DROP" }
	iptables_add_service{ "${hostname}_deny_all_epmd": service => "epmd", jump => "DROP" }

}

class openstack::iptables  {

	# We use the following requirement chain:
	# iptables -> iptables::drops -> iptables::accepts -> iptables::accept-established -> iptables::purges
	#
	# This ensures proper ordering of the rules
	require "openstack::iptables-drops"

	# This exec should always occur last in the requirement chain.
	iptables_add_exec{ "${hostname}": service => "openstack" }

}

class openstack::common {

	include openstack::nova_config

	# Setup eth1 as tagged and created a tagged interface for VLAN 103
	interface_tagged { "eth1.103":
		base_interface => "eth1",
		vlan_id => "103",
		method => "manual";
	}

	# FIXME: third party repository
	apt::pparepo { "nova-core-release": repo_string => "nova-core/release", apt_key => "2A2356C9", dist => "lucid", ensure => "present" }

	package { [ "nova-common" ]:
		ensure => latest,
		require => Apt::Pparepo["nova-core-release"];
	}

	package { [ "unzip", "aoetools", "vblade-persist", "mysql-client", "python-mysqldb", "bridge-utils", "ebtables" ]:
		ensure => latest;
	}

	file {
		"/etc/nova/nova.conf":
			content => template("openstack/nova.conf.erb"),
			owner => root,
			group => root,
			mode => 0444,
			require => Package['nova-common'];
	}

}

class openstack::controller { 

	include openstack::common,
		openstack::scheduler-service,
		openstack::ajax-console-proxy-service,
		openstack::glance-service,
		openstack::openstack-manager,
		openstack::database-server,
		openstack::puppet-server,
		openstack::ldap-server,
		openstack::iptables

	package { [ "rabbitmq-server", "euca2ools" ]:
		ensure => latest;
	}

}

class openstack::compute {

	include openstack::common,
		openstack::compute-service,
		openstack::volume-service

	if $hostname == "virt2" {
		include openstack::network-service,
			openstack::api-service
	}

	file {
		"/etc/libvirt/qemu/networks/autostart/default.xml":
			ensure => absent;
	}

}

class openstack::puppet-server {

	# Only allow puppet access from the instances
	$puppet_passenger_allow_from = "10.4.0.0/24 10.4.16.3"

	include puppetmaster::passenger

}

class openstack::database-server {

	include openstack::nova_config,
		openstack::glance_config,
		gerrit::database-server

	package { "mysql-server":
		ensure => latest;
	}

	service { "mysql":
		enable => true,
		ensure => running;
	}

	exec {
		'set_root':
			onlyif => "/usr/bin/mysql -uroot --password=''",
			command => "/usr/bin/mysql -uroot --password='' mysql < /etc/nova/mysql.sql",
			require => [Package["mysql-client"],File["/etc/nova/mysql.sql"]],
			before => Exec['create_nova_db'];
		'create_nova_db_user':
			unless => "/usr/bin/mysql --defaults-file=/etc/nova/nova-user.cnf -e 'exit'",
			command => "/usr/bin/mysql -uroot < /etc/nova/nova-user.sql",
			require => [Package["mysql-client"],File["/etc/nova/nova-user.sql", "/etc/nova/nova-user.cnf", "/root/.my.cnf"]],
			before => Exec['sync_nova_db'];
		'create_nova_db':
			unless => "/usr/bin/mysql -uroot ${openstack::nova_config::nova_db_name} -e 'exit'",
			command => "/usr/bin/mysql -uroot -e \"create database ${openstack::nova_config::nova_db_name};\"",
			require => [Package["mysql-client"], File["/root/.my.cnf"]],
			before => Exec['create_nova_db_user'];
		'create_puppet_db_user':
			unless => "/usr/bin/mysql --defaults-file=/etc/puppet/puppet-user.cnf -e 'exit'",
			command => "/usr/bin/mysql -uroot < /etc/puppet/puppet-user.sql",
			require => [Package["mysql-client"],File["/etc/puppet/puppet-user.sql", "/etc/puppet/puppet-user.cnf", "/root/.my.cnf"]];
		'create_puppet_db':
			unless => "/usr/bin/mysql -uroot ${openstack::nova_config::puppet_db_name} -e 'exit'",
			command => "/usr/bin/mysql -uroot -e \"create database ${openstack::nova_config::puppet_db_name};\"",
			require => [Package["mysql-client"], File["/root/.my.cnf"]],
			before => Exec['create_puppet_db_user'];
		'sync_nova_db':
			unless => "/usr/bin/nova-manage db version | grep \"${openstack::nova_config::nova_db_version}\"",
			command => "/usr/bin/nova-manage db sync",
			require => Package["nova-common"];
		'create_glance_db_user':
			unless => "/usr/bin/mysql --defaults-file=/etc/glance/glance-user.cnf -e 'exit'",
			command => "/usr/bin/mysql -uroot < /etc/glance/glance-user.sql",
			require => [Package['mysql-client'], File["/etc/glance/glance-user.sql","/etc/glance/glance-user.cnf","/root/.my.cnf"]];
		'create_glance_db':
			unless => "/usr/bin/mysql -uroot ${openstack::glance_config::glance_db_name} -e 'exit'",
			command => "/usr/bin/mysql -uroot -e \"create database ${openstack::glance_config::glance_db_name};\"",
			require => [Package['mysql-client'], File["/root/.my.cnf"]],
			before => Exec['create_glance_db_user'];
	}

	file {
		"/root/.my.cnf":
			content => template("openstack/my.cnf.erb"),
			owner => root,
			group => root,
			mode => 0640;
		"/etc/nova/mysql.sql":
			content => template("openstack/mysql.sql.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["nova-common"];
		"/etc/nova/nova-user.sql":
			content => template("openstack/nova-user.sql.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["nova-common"];
		"/etc/nova/nova-user.cnf":
			content => template("openstack/nova-user.cnf.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["nova-common"];
		"/etc/puppet/puppet-user.sql":
			content => template("openstack/puppet-user.sql.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["puppetmaster"];
		"/etc/puppet/puppet-user.cnf":
			content => template("openstack/puppet-user.cnf.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["puppetmaster"];
		"/etc/glance/glance-user.sql":
			content => template("openstack/glance-user.sql.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["glance"];
		"/etc/glance/glance-user.cnf":
			content => template("openstack/glance-user.cnf.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["glance"];
	}

}

class openstack::ldap-server {

	include passwords::certs

	$ldap_user_dn = $openstack::nova_config::nova_ldap_user_dn
	$ldap_user_pass = $openstack::nova_config::nova_ldap_user_pass
	$ldap_certificate_location = "/var/opendj/instance"
	$ldap_cert_pass = $passwords::certs::certs_default_pass
	$ldap_base_dn = $openstack::nova_config::nova_ldap_base_dn
	$ldap_domain = $openstack::nova_config::nova_ldap_domain
	$ldap_proxyagent = $openstack::nova_config::nova_ldap_proxyagent
	$ldap_proxyagent_pass = $openstack::nova_config::nova_ldap_proxyagent_pass

	# Add a pkcs12 file to be used for start_tls, ldaps, and opendj's admin connector.
	# Add it into the instance location, and ensure opendj can read it.
	create_pkcs12{ "${ldap_certificate}.opendj": certname => "${ldap_certificate}", user => "opendj", group => "opendj", location => $ldap_certificate_location, password => $ldap_cert_pass }

	include openstack::nova_config,
		openstack::glance_config,
		ldap::server::schema::sudo,
		ldap::server::schema::ssh,
		ldap::server::schema::openstack,
		ldap::server::schema::puppet,
		ldap::client::wmf-test-cluster

	class { "ldap::server":
		ldap_certificate_location => $ldap_certificate_location,
		ldap_cert_pass => $ldap_cert_pass,
		ldap_base_dn => $ldap_base_dn;
	}

	monitor_service { "$hostname ldap cert": description => "Certificate expiration", check_command => "check_cert!virt1.wikimedia.org!636!Equifax_Secure_CA.pem", critical => "true" }

}

class openstack::openstack-manager {

	package { [ 'apache2', 'memcached', 'php5', 'php5-cli', 'php5-mysql', 'php5-ldap', 'php5-uuid', 'php5-curl', 'php5-memcache', 'php-apc' ]:
		ensure => latest;
	}

	file {
		"/etc/apache2/sites-available/labsconsole.wikimedia.org":
			require => [ Package[php5] ],
			mode => 644,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/labsconsole.wikimedia.org",
			ensure => present;
	}

	apache_site { controller: name => "labsconsole.wikimedia.org" }
	apache_module { rewrite: name => "rewrite" }

}

class openstack::scheduler-service {

	package {  "nova-scheduler":
		require => Apt::Pparepo["nova-core-release"],
		subscribe => File['/etc/nova/nova.conf'],
		ensure => latest;
	}

	service { "nova-scheduler":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'];
	}

}

class openstack::network-service {

	interface_ip { "openstack::network_service_public_dynamic_snat": interface => "lo", address => "208.80.153.192" }

	package {  [ "nova-network", "dnsmasq" ]:
		require => Apt::Pparepo["nova-core-release"],
		subscribe => File['/etc/nova/nova.conf'],
		ensure => latest;
	}

	service { "nova-network":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'];
	}

	# dnsmasq is run manually by nova-network, we don't want the service running
	service { "dnsmasq":
		enable => false,
		ensure => stopped;
	}

	# Enable IP forwarding
	include generic::sysctl::advanced-routing
}

class openstack::api-service {

	package {  [ "nova-api" ]:
		require => Apt::Pparepo["nova-core-release"],
		subscribe => File['/etc/nova/nova.conf'],
		ensure => latest;
	}

	service { "nova-api":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'];
	}

}

class openstack::ajax-console-proxy-service {

	package {  [ "nova-ajax-console-proxy" ]:
		require => Apt::Pparepo["nova-core-release"],
		subscribe => File['/etc/nova/nova.conf'],
		ensure => latest;
	}

	service { "nova-ajax-console-proxy":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'];
	}

}
class openstack::volume-service {

	package { [ "nova-volume" ]:
		require => Apt::Pparepo["nova-core-release"],
		subscribe => File['/etc/nova/nova.conf'],
		ensure => latest;
	}

	service { "nova-volume":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'];
	}

}

class openstack::compute-service {

	package { [ "nova-compute", "ajaxterm" ]:
		require => Apt::Pparepo["nova-core-release"],
		subscribe => File['/etc/nova/nova.conf'],
		ensure => latest;
	}

	service { "nova-compute":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'];
	}

	# ajaxterm is run manually by nova-compute; we don't want the service running
	service { "ajaxterm":
		enable => false,
		ensure => stopped;
	}

}

class openstack::glance-service {

	# FIXME: third party repository
	apt::pparepo { "glance-core-release": repo_string => "glance-core/release", apt_key => "2085FE8D", dist => "lucid", ensure => "present" }

	include openstack::glance_config

	package { [ "glance" ]:
		require => Apt::Pparepo["glance-core-release"],
		ensure => latest;
	}

	service { "glance-api":
		ensure => running;
	}

	service { "glance-registry":
		ensure => running;
	}

	file {
		"/etc/glance/glance.conf":
			content => template("openstack/glance.conf.erb"),
			owner => root,
			group => root,
			notify => Service["glance-api", "glance-registry"],
			require => Package["glance"],
			mode => 0444;
	}

}

class openstack::nova_config {

	include passwords::openstack::nova

	$nova_db_host = "virt1.wikimedia.org"
	$nova_db_name = "nova"
	$nova_db_user = "nova"
	$nova_db_pass = $passwords::openstack::nova::nova_db_pass
	$nova_glance_host = "virt1.wikimedia.org"
	$nova_rabbit_host = "virt1.wikimedia.org"
	$nova_cc_host = "virt1.wikimedia.org"
	$nova_network_host = "10.4.0.1"
	$nova_api_host = "virt2.wikimedia.org"
	$nova_api_ip = "10.4.0.1"
	$nova_network_flat_interface = "eth1.103"
	$nova_flat_network_bridge = "br103"
	$nova_fixed_range = "10.4.0.0/24"
	$nova_dhcp_start = "10.4.0.4"
	$nova_dhcp_domain = "pmtpa.labs.wmnet"
	$nova_network_public_interface = "eth0"
	$nova_my_ip = $ipaddress_eth0
	$nova_network_public_ip = "208.80.153.192"
	$nova_dmz_cidr = "10.4.0.0/8"
	$nova_ajax_proxy_url = "http://labsconsole.wikimedia.org:8000"
	$nova_ldap_host = "virt1.wikimedia.org"
	$nova_ldap_domain = "labs"
	$nova_ldap_base_dn = "dc=wikimedia,dc=org"
	$nova_ldap_user_dn = "uid=novaadmin,ou=people,dc=wikimedia,dc=org"
	$nova_ldap_user_pass = $passwords::openstack::nova::nova_ldap_user_pass
	$nova_ldap_proxyagent = "cn=proxyagent,ou=profile,dc=wikimedia,dc=org"
	$nova_ldap_proxyagent_pass = $passwords::openstack::nova::nova_ldap_proxyagent_pass
	$controller_mysql_root_pass = $passwords::openstack::nova::controller_mysql_root_pass
	# When doing upgrades, you'll want to up this to the new version
	$nova_db_version = "14"
	$nova_puppet_host = "virt1.wikimedia.org"
	$nova_puppet_db_name = "puppet"
	$nova_puppet_user = "puppet"
	$nova_puppet_user_pass = $passwords::openstack::nova::nova_puppet_user_pass
	$nova_zone = "pmtpa"

}

class openstack::glance_config {

	include passwords::openstack::glance

	$glance_db_host = "virt1.wikimedia.org"
	$glance_db_name = "glance"
	$glance_db_user = "glance"
	$glance_db_pass = $passwords::openstack::glance::glance_db_pass
	$glance_bind_ip = "208.80.153.131"

}
