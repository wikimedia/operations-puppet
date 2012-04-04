class openstack::iptables-purges {

	require "iptables::tables"

	# The deny_all rule must always be purged, otherwise ACCEPTs can be placed below it
	iptables_purge_service{ "deny_all_mysql": service => "mysql" }
	iptables_purge_service{ "deny_all_memcached": service => "memcached" }
	iptables_purge_service{ "deny_all_ldap": service => "ldap" }
	iptables_purge_service{ "deny_all_ldap_backend": service => "ldap_backend" }
	iptables_purge_service{ "deny_all_ldaps": service => "ldaps" }
	iptables_purge_service{ "deny_all_ldaps_backend": service => "ldaps_backend" }
	iptables_purge_service{ "deny_all_ldap_admin_connector": service => "ldap_admin_connector" }
	iptables_purge_service{ "deny_all_puppetmaster": service => "puppetmaster" }
	iptables_purge_service{ "deny_all_glance_api": service => "glance_api" }
	iptables_purge_service{ "deny_all_glance_registry": service => "glance_registry" }
	iptables_purge_service{ "deny_all_beam1": service => "beam1" }
	iptables_purge_service{ "deny_all_beam2": service => "beam2" }
	iptables_purge_service{ "deny_all_epmd": service => "epmd" }

	# When removing or modifying a rule, place the old rule here, otherwise it won't
	# be purged, and will stay in the iptables forever
	iptables_purge_service{ "nova_ec2_api_private": service => "nova_ec2_api" }
	iptables_purge_service{ "nova_os_api_private": service => "nova_openstack_api" }
	iptables_purge_service{ "deny_all_nova_ec2_api": service => "nova_ec2_api" }
	iptables_purge_service{ "deny_all_nova_openstack_api": service => "nova_openstack_api" }

}

class openstack::iptables-accepts {

	require "openstack::iptables-purges"

	# Rememeber to place modified or removed rules into purges!
	iptables_add_service{ "lo_all": interface => "lo", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "localhost_all": source => "127.0.0.1", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "virt0_all": source => "208.80.153.135", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "spence_all": source => "208.80.152.161", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "neon_all": source => "208.80.154.14", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "mysql_nova": source => "10.4.16.0/24", service => "mysql", jump => "ACCEPT" }
	iptables_add_service{ "mysql_gerrit": source => "208.80.152.147", service => "mysql", jump => "ACCEPT" }
	iptables_add_service{ "ldap_private": source => "10.4.0.0/16", service => "ldap", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_private": source => "10.4.0.0/16", service => "ldaps", jump => "ACCEPT" }
	iptables_add_service{ "ldap_backend_private": source => "10.4.0.0/16", service => "ldap_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_backend_private": source => "10.4.0.0/16", service => "ldaps_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldap_floating": source => "208.80.153.192/28", service => "ldap", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_floating": source => "208.80.153.192/28", service => "ldaps", jump => "ACCEPT" }
	iptables_add_service{ "ldap_backend_floating": source => "208.80.153.192/28", service => "ldap_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_backend_floating": source => "208.80.153.192/28", service => "ldaps_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldap_gerrit": source => "208.80.152.147", service => "ldap", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_gerrit": source => "208.80.152.147", service => "ldaps", jump => "ACCEPT" }
	iptables_add_service{ "ldap_backend_gerrit": source => "208.80.152.147", service => "ldap_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_backend_gerrit": source => "208.80.152.147", service => "ldaps_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldap_gerrit_manganese": source => "208.80.154.152", service => "ldap", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_gerrit_manganese": source => "208.80.154.152", service => "ldaps", jump => "ACCEPT" }
	iptables_add_service{ "ldap_backend_gerrit_manganese": source => "208.80.154.152", service => "ldap_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_backend_gerrit_manganese": source => "208.80.154.152", service => "ldaps_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldap_jenkins": source => "208.80.154.135", service => "ldap", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_jenkins": source => "208.80.154.135", service => "ldaps", jump => "ACCEPT" }
	iptables_add_service{ "ldap_backend_jenkins": source => "208.80.154.135", service => "ldap_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_backend_jenkins": source => "208.80.154.135", service => "ldaps_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldap_admin_connector_nfs1": source => "10.0.0.244", service => "ldap_admin_connector", jump => "ACCEPT" }
	iptables_add_service{ "puppet_private": source => "10.4.0.0/16", service => "puppetmaster", jump => "ACCEPT" }
	iptables_add_service{ "glance_api_nova": source => "10.4.16.0/24", service => "glance_api", jump => "ACCEPT" }
	iptables_add_service{ "beam2_nova": source => "10.4.16.0/24", service => "beam2", jump => "ACCEPT" }

}

class openstack::iptables-drops {

	require "openstack::iptables-accepts"

	# Deny by default
	iptables_add_service{ "deny_all_mysql": service => "mysql", jump => "DROP" }
	iptables_add_service{ "deny_all_memcached": service => "memcached", jump => "DROP" }
	iptables_add_service{ "deny_all_ldap": service => "ldap", jump => "DROP" }
	iptables_add_service{ "deny_all_ldap_backend": service => "ldap_backend", jump => "DROP" }
	iptables_add_service{ "deny_all_ldaps": service => "ldaps", jump => "DROP" }
	iptables_add_service{ "deny_all_ldaps_backend": service => "ldaps_backend", jump => "DROP" }
	iptables_add_service{ "deny_all_ldap_admin_connector": service => "ldap_admin_connector", jump => "DROP" }
	iptables_add_service{ "deny_all_puppetmaster": service => "puppetmaster", jump => "DROP" }
	iptables_add_service{ "deny_all_glance_api": service => "glance_api", jump => "DROP" }
	iptables_add_service{ "deny_all_glance_registry": service => "glance_registry", jump => "DROP" }
	iptables_add_service{ "deny_all_beam1": service => "beam1", jump => "DROP" }
	iptables_add_service{ "deny_all_beam2": service => "beam2", jump => "DROP" }
	iptables_add_service{ "deny_all_epmd": service => "epmd", jump => "DROP" }

}

class openstack::iptables  {

	if $realm == "production" {
		# We use the following requirement chain:
		# iptables -> iptables::drops -> iptables::accepts -> iptables::accept-established -> iptables::purges
		#
		# This ensures proper ordering of the rules
		require "openstack::iptables-drops"

		# This exec should always occur last in the requirement chain.
		iptables_add_exec{ "${hostname}": service => "openstack" }
	}

	# Labs has security groups, and as such, doesn't need firewall rules

}

class openstack::common {

	include openstack::nova_config

	if $realm == "production" {
		# Setup eth1 as tagged and created a tagged interface for VLAN 103
		interface_tagged { "eth1.103":
			base_interface => "eth1",
			vlan_id => "103",
			method => "manual";
		}
	} elsif $realm == "labs" {
		# Setup eth1 as tagged and created a tagged interface for VLAN 103
		interface_tagged { "eth0.103":
			base_interface => "eth0",
			vlan_id => "103",
			method => "manual";
		}
	}

	# FIXME: third party repository
	apt::pparepo { "nova-core-release": repo_string => "nova-core/release", apt_key => "2A2356C9", dist => "lucid", ensure => "absent" }
	apt::pparepo { "nova-core-release-diablo": repo_string => "openstack-release/2011.3", apt_key => "3D1B4472", dist => "lucid", ensure => "present" }

	package { [ "nova-common" ]:
		ensure => latest,
		require => Apt::Pparepo["nova-core-release"];
	}

	package { [ "unzip", "aoetools", "vblade-persist", "python-mysqldb", "bridge-utils", "ebtables", "libmysqlclient16", "mysql-client", "mysql-common" ]:
		ensure => latest;
	}

	# For IPv6 support
	package { [ "python-netaddr", "radvd" ]:
		ensure => latest;
	}

	generic::apt::pin-package { [ "libmysqlclient16", "mysql-common" ]: }

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
		openstack::volume-service,
		openstack::gluster-service,
		openstack::gluster-client

	# tls is a PITA to enable in labs, let's find another way there.
	if ( $realm == "production" ) {
		install_certificate{ "${fqdn}": }
		install_additional_key{ "${fqdn}": key_loc => "/var/lib/nova", owner => "nova", group => "libvirtd", require => Package["nova-common"] }

		file {
			"/var/lib/nova/clientkey.pem":
				ensure => link,
				target => "/var/lib/nova/${fqdn}.key",
				require => Install_additional_key["${fqdn}"];
			"/var/lib/nova/clientcert.pem":
				ensure => link,
				target => "/etc/ssl/certs/${fqdn}.pem",
				require => Install_certificate["${fqdn}"];
			"/var/lib/nova/cacert.pem":
				ensure => link,
				target => "/etc/ssl/certs/wmf-ca.pem",
				require => Install_certificate["${fqdn}"];
			"/etc/libvirt/libvirtd.conf":
				notify => Service["libvirt-bin"],
				owner => "root",
				group => "root",
				mode => 0444,
				content => template("openstack/libvirtd.conf.erb"),
				require => Package["nova-common"];
			"/etc/default/libvirt-bin":
				notify => Service["libvirt-bin"],
				owner => "root",
				group => "root",
				mode => 0444,
				content => template("openstack/libvirt-bin.default.erb"),
				require => Package["nova-common"];
			"/etc/init/libvirt-bin.conf":
				notify => Service["libvirt-bin"],
				owner => "root",
				group => "root",
				mode => 0444,
				source => "puppet:///files/upstart/libvirt-bin.conf",
				require => Package["nova-common"];
		}
	}

	service { "libvirt-bin":
		ensure => running,
		enable => true,
		require => Package["nova-common"];
	}

	if $hostname == "virt2" or $realm == "labs" {
		include openstack::network-service,
			openstack::api-service
	}
	if $hostname =~ /^virt[3-4]$/ {
	}

	file {
		"/etc/libvirt/qemu/networks/autostart/default.xml":
			ensure => absent;
	}

}

class openstack::project-storage-cron {

	$ircecho_infile = "/var/lib/glustermanager/manage-volumes.log"
	$ircecho_nick = "labs-storage-wm"
	$ircecho_chans = "#wikimedia-labs"
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

	cron { "manage-volumes":
		command => '/usr/bin/python /usr/local/sbin/manage-volumes --logfile=/var/lib/glustermanager/manage-volumes.log',
		user => 'glustermanager',
		require => Systemuser["glustermanager"];
	}

}

class openstack::project-storage {

	include openstack::gluster-service

	$sudo_privs = [ 'ALL = NOPASSWD: /bin/mkdir -p /a/*',
			'ALL = NOPASSWD: /usr/sbin/gluster *' ]
	sudo_user { [ "glustermanager" ]: privileges => $sudo_privs, require => Systemuser["glustermanager"] }

	package { "python-paramiko":
		ensure => latest;
	}

	systemuser { "glustermanager": name => "glustermanager", home => "/var/lib/glustermanager", shell => "/bin/bash" }
	ssh_authorized_key {
		"glustermanager":
			ensure	=> present,
			user	=> "glustermanager",
			type	=> "ssh-rsa",
			key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAuE328+IMmMOoqFhti58rBBxkJy2u+sgxcKuJ4B5248f73YqfZ3RkEWvBGb3ce3VCptrrXJAMCw55HsMyhT8A7chBGLdjhPjol+3Vh2+mc6EkjW0xscX39gh1Fn1jVqrx+GMIuwid7zxGytaKyQ0vko4FP64wDbm1rfVc1jsLMQ+gdAG/KNGYtwjLMEQk8spydckAtkWg3YumMl7e4NQYpYlkTXgVIQiZGpslu5LxKBmXPPF4t2h17p+rNr9ZAVII4av8vRiyQa2/MaH4QZoGYGbkQXifbhBD438NlgZrvLANYuT78zPj4n1G061s7n9nmvVMH3W7QyXS8MpftLnegw==",
			require => Systemuser["glustermanager"];
	}
	file {
		"/var/lib/glustermanager/.ssh/id_rsa":
			owner => glustermanager,
			group => glustermanager,
			mode => 0600,
			source => "puppet:///private/gluster/glustermanager",
			require => Ssh_authorized_key["glustermanager"];
		"/var/run/glustermanager":
			ensure => directory,
			owner => glustermanager,
			group => glustermanager,
			mode => 0700,
			require => Systemuser["glustermanager"];
	}
}

class openstack::puppet-server {

	# Only allow puppet access from the instances
	$puppet_passenger_allow_from = $realm ? {
		"production" => [ "10.4.0.0/24", "10.4.16.3" ],
		"labs" => [ "192.168.0.0/24" ],
	}

	class { puppetmaster:
		server_name => $fqdn,
		allow_from => $puppet_passenger_allow_from,
		config => {
			'dbadapter' => "mysql",
			'dbuser' => $openstack::nova_config::nova_puppet_user,
			'dbpassword' => $openstack::nova_config::nova_puppet_user_pass,
			'dbserver' => $openstack::nova_config::nova_db_host,
			'node_terminus' => "ldap",
			'ldapserver' => $openstack::nova_config::nova_ldap_host,
			'ldapbase' => "ou=hosts,${openstack::nova_config::nova_ldap_base_dn}",
			'ldapstring' => "(&(objectclass=puppetClient)(associatedDomain=%s))",
			'ldapuser' => "cn=proxyagent,ou=profile,${openstack::nova_config::nova_ldap_base_dn}",
			'ldappassword' => $openstack::nova_config::nova_ldap_proxyagent_pass,
			'ldaptls' => true
		};
	}

}

class openstack::database-server {

	include openstack::nova_config,
		openstack::glance_config,
		gerrit::database-server

	generic::apt::pin-package { [ "mysql-server", "mysql-client" ]: }
	generic::apt::pin-package { "mysql-server-51": package => "mysql-server-5.1" }
	generic::apt::pin-package { "mysql-server-core-51": package => "mysql-server-core-5.1" }
	generic::apt::pin-package { "mysql-client-51": package => "mysql-client-5.1" }
	generic::apt::pin-package { "mysql-client-core-51": package => "mysql-client-core-5.1" }

	package { "mysql-server":
		ensure => latest;
	}

	service { "mysql":
		enable => true,
		require => Package["mysql-server"],
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

	if ( ! $controller_first_master ) {
		$controller_first_master = "false"
	}

	if ( $controller_first_master == "true" ) {
		exec {
			'sync_nova_db':
				unless => "/usr/bin/nova-manage db version | grep \"${openstack::nova_config::nova_db_version}\"",
				command => "/usr/bin/nova-manage db sync",
				require => Package["nova-common"];
		}
	} else {
		exec {
			# Don't sync if we aren't the first install
			'sync_nova_db':
				command => "/usr/bin/test true",
				require => Package["nova-common"];
		}
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
	create_pkcs12{ "${ldap_certificate}.opendj": certname => "${ldap_certificate}", user => "opendj", group => "opendj", location => $ldap_certificate_location, password => $ldap_cert_pass, require => Package["opendj"] }

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

	if $realm == "labs" {
		# server is on localhost
		file { "/var/opendj/.ldaprc":
			content => 'TLS_CHECKPEER   no
TLS_REQCERT     never
',
			mode => 0400,
			owner => root,
			group => root,
			require => Package["opendj"],
			before => Exec["start_opendj"];
		}
	}

	monitor_service { "$hostname ldap cert": description => "Certificate expiration", check_command => "check_cert!virt0.wikimedia.org!636!Equifax_Secure_CA.pem", critical => "true" }

}

class openstack::openstack-manager {

	include memcached,
		webserver::apache2,
		openstack::nova_config

	$nova_controller_hostname = $openstack::nova_config::nova_controller_hostname

	package { [ 'php5', 'php5-cli', 'php5-mysql', 'php5-ldap', 'php5-uuid', 'php5-curl', 'php5-memcache', 'php-apc', 'imagemagick' ]:
		ensure => latest;
	}

	file {
		"/etc/apache2/sites-available/${nova_controller_hostname}":
			require => [ Package[php5] ],
			mode => 0644,
			owner => root,
			group => root,
			content => template('apache/sites/labsconsole.wikimedia.org'),
			ensure => present;
	}

	apache_site { controller: name => "${nova_controller_hostname}" }
	apache_site { 000_default: name => "000-default", ensure => absent }
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
		subscribe => File['/etc/nova/nova.conf'],
		require => Package["nova-scheduler"];
	}

}

class openstack::network-service {

	if $realm == "production" {
		interface_ip { "openstack::network_service_public_dynamic_snat": interface => "lo", address => "208.80.153.192" }
	}

	package {  [ "nova-network", "dnsmasq" ]:
		require => Apt::Pparepo["nova-core-release"],
		subscribe => File['/etc/nova/nova.conf'],
		ensure => latest;
	}

	service { "nova-network":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'],
		require => Package["nova-network"];
	}

	# dnsmasq is run manually by nova-network, we don't want the service running
	service { "dnsmasq":
		enable => false,
		ensure => stopped,
		require => Package["dnsmasq"];
	}

	# Enable IP forwarding
	include generic::sysctl::advanced-routing,
		generic::sysctl::ipv6-disable-ra
}

class openstack::api-service {

	package {  [ "nova-api" ]:
		require => Apt::Pparepo["nova-core-release"],
		subscribe => File['/etc/nova/nova.conf'],
		ensure => latest;
	}

	service { "nova-api":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'],
		require => Package["nova-api"];
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
		subscribe => File['/etc/nova/nova.conf'],
		require => Package["nova-ajax-console-proxy"];
	}

}
class openstack::volume-service {

	package { [ "nova-volume" ]:
		#require => Apt::Pparepo["nova-core-release"],
		#subscribe => File['/etc/nova/nova.conf'],
		ensure => absent;
	}

	service { "nova-volume":
		ensure => stopped,
		subscribe => File['/etc/nova/nova.conf'],
		require => Package["nova-volume"];
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
		subscribe => File['/etc/nova/nova.conf'],
		require => Package["nova-compute"];
	}

	# ajaxterm is run manually by nova-compute; we don't want the service running
	service { "ajaxterm":
		enable => false,
		ensure => stopped,
		require => Package["ajaxterm"];
	}

}

class openstack::glance-service {

	# FIXME: third party repository
	apt::pparepo { "glance-core-release": repo_string => "glance-core/release", apt_key => "2085FE8D", dist => "lucid", ensure => "absent" }

	include openstack::glance_config

	package { [ "glance" ]:
		require => Apt::Pparepo["nova-core-release-diablo"],
		ensure => latest;
	}

	service { "glance-api":
		ensure => running,
		require => Package["glance"];
	}

	service { "glance-registry":
		ensure => running,
		require => Package["glance"];
	}

	file {
		"/etc/glance/glance-api.conf":
			content => template("openstack/glance-api.conf.erb"),
			owner => root,
			group => root,
			notify => Service["glance-api"],
			require => Package["glance"],
			mode => 0444;
		"/etc/glance/glance-registry.conf":
			content => template("openstack/glance-registry.conf.erb"),
			owner => root,
			group => root,
			notify => Service["glance-registry"],
			require => Package["glance"],
			mode => 0444;
	}

}

class openstack::gluster-service {

	include generic::gluster

	service { "glusterd":
		enable => true,
		ensure => running,
		require => [Package["glusterfs"], File["/etc/init.d/glusterd"], Upstart_job["glusterd"]];
	}

	# TODO: We need to replace the init script with an upstart job that'll ensure
	# the filesystem gets mounted after gluster is started.
	upstart_job{ "glusterd": require => Package["glusterfs"], install => "true" }

}

class openstack::gluster-client {

	include generic::gluster

	## mount the gluster volume for the instances
	mount { "/var/lib/nova/instances":
		device => "instancestorage.pmtpa.wmnet:/instances1",
		fstype => "glusterfs",
		name => "/var/lib/nova/instances",
		options => "defaults,_netdev=eth0,log-level=WARNING,log-file=/var/log/gluster.log",
		require => Package["glusterfs"],
		ensure => mounted;
	}

}

class openstack::nova_config {

	include passwords::openstack::nova

	$nova_db_host = $realm ? {
		"production" => "virt0.wikimedia.org",
		"labs" => "localhost",
	}
	$nova_db_name = "nova"
	$nova_db_user = "nova"
	$nova_db_pass = $passwords::openstack::nova::nova_db_pass
	$nova_glance_host = $realm ? {
		"production" => "virt0.wikimedia.org",
		"labs" => "localhost",
	}
	$nova_rabbit_host = $realm ? {
		"production" => "virt0.wikimedia.org",
		"labs" => "localhost",
	}
	$nova_cc_host = $realm ? {
		"production" => "virt0.wikimedia.org",
		"labs" => "localhost",
	}
	$nova_network_host = $realm ? {
		"production" => "10.4.0.1",
		"labs" => "127.0.0.1",
	}
	$nova_api_host = $realm ? {
		"production" => "virt2.pmtpa.wmnet",
		"labs" => "localhost",
	}
	$nova_api_ip = $realm ? {
		"production" => "10.4.0.1",
		"labs" => "127.0.0.1",
	}
	$nova_network_flat_interface = $realm ? {
		"production" => "eth1.103",
		"labs" => "eth0.103",
	}
	$nova_flat_network_bridge = "br103"
	$nova_fixed_range = $realm ? {
		"production" => "10.4.0.0/24",
		"labs" => "192.168.0.0/24",
	}
	$nova_dhcp_start = $realm ? {
		"production" => "10.4.0.4",
		"labs" => "192.168.0.4",
	}
	$nova_dhcp_domain = "pmtpa.wmflabs"
	$nova_network_public_interface = "eth0"
	$nova_my_ip = $ipaddress_eth0
	$nova_network_public_ip = $realm ? {
		"production" => "208.80.153.192",
		"labs" => "127.0.0.1",
	}
	$nova_dmz_cidr = $realm ? {
		"production" => "208.80.153.0/22,10.0.0.0/8",
		"labs" => "10.4.0.0/24",
	}
	$nova_controller_hostname = $realm ? {
		"production" => "labsconsole.wikimedia.org",
		"labs" => ${fqdn},
	}
	$nova_ajax_proxy_url = $realm ? {
		"production" => "http://labsconsole.wikimedia.org:8000",
		"labs" => "http://${hostname}.${domain}:8000",
	}
	$nova_ldap_host = $realm ? {
		"production" => "virt0.wikimedia.org",
		"labs" => "localhost",
	}
	$nova_ldap_domain = "labs"
	$nova_ldap_base_dn = "dc=wikimedia,dc=org"
	$nova_ldap_user_dn = "uid=novaadmin,ou=people,dc=wikimedia,dc=org"
	$nova_ldap_user_pass = $passwords::openstack::nova::nova_ldap_user_pass
	$nova_ldap_proxyagent = "cn=proxyagent,ou=profile,dc=wikimedia,dc=org"
	$nova_ldap_proxyagent_pass = $passwords::openstack::nova::nova_ldap_proxyagent_pass
	$controller_mysql_root_pass = $passwords::openstack::nova::controller_mysql_root_pass
	# When doing upgrades, you'll want to up this to the new version
	$nova_db_version = "46"
	$nova_puppet_host = "virt0.wikimedia.org"
	$nova_puppet_db_name = "puppet"
	$nova_puppet_user = "puppet"
	$nova_puppet_user_pass = $passwords::openstack::nova::nova_puppet_user_pass
	$nova_zone = "pmtpa"
	# By default, don't allow projects to allocate public IPs; this way we can
	# let users have network admin rights, for firewall rules and such, and can
	# give them public ips by increasing their quota
	$nova_quota_floating_ips = "0"
	$nova_libvirt_type = $realm ? {
		"production" => "kvm",
		"labs" => "qemu",
	}
	$nova_live_migration_uri = "qemu://%s.pmtpa.wmnet/system?pkipath=/var/lib/nova"

}

class openstack::glance_config {

	include passwords::openstack::glance

	$glance_db_host = $realm ? {
		"production" => "virt0.wikimedia.org",
		"labs" => "localhost",
	}
	$glance_db_name = "glance"
	$glance_db_user = "glance"
	$glance_db_pass = $passwords::openstack::glance::glance_db_pass
	$glance_bind_ip = $realm ? {
		"production" => "208.80.153.135",
		"labs" => "127.0.0.1",
	}

}
