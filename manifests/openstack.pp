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
	iptables_purge_service{ "deny_all_ldap_replication": service => "ldap_replication" }
	iptables_purge_service{ "deny_all_puppetmaster": service => "puppetmaster" }
	iptables_purge_service{ "deny_all_glance_api": service => "glance_api" }
	iptables_purge_service{ "deny_all_glance_registry": service => "glance_registry" }
	iptables_purge_service{ "deny_all_beam1": service => "beam1" }
	iptables_purge_service{ "deny_all_beam2": service => "beam2" }
	iptables_purge_service{ "deny_all_beam3": service => "beam3" }
	iptables_purge_service{ "deny_all_epmd": service => "epmd" }
	iptables_purge_service{ "deny_all_keystone_service": service => "keystone_service" }
	iptables_purge_service{ "deny_all_keystone_admin": service => "keystone_admin" }
	iptables_purge_service{ "deny_all_salt_publish": service => "salt_publish" }
	iptables_purge_service{ "deny_all_salt_ret": service => "salt_ret" }
	iptables_purge_service{ "deny_all_inetd": service => "inetd" }

	# When removing or modifying a rule, place the old rule here, otherwise it won't
	# be purged, and will stay in the iptables forever
}

class openstack::iptables-accepts {
	require "openstack::iptables-purges"

	# Rememeber to place modified or removed rules into purges!
	iptables_add_service{ "lo_all": interface => "lo", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "localhost_all": source => "127.0.0.1", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "virt0_all": source => "208.80.152.32", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "spence_all": source => "208.80.152.161", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "neon_all": source => "208.80.154.14", service => "all", jump => "ACCEPT" }
	iptables_add_service{ "ldap_private": source => "10.0.0.0/8", service => "ldap", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_private": source => "10.0.0.0/8", service => "ldaps", jump => "ACCEPT" }
	iptables_add_service{ "ldap_backend_private": source => "10.0.0.0/8", service => "ldap_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_backend_private": source => "10.0.0.0/8", service => "ldaps_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldap_public": source => "208.80.152.0/22", service => "ldap", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_public": source => "208.80.152.0/22", service => "ldaps", jump => "ACCEPT" }
	iptables_add_service{ "ldap_backend_public": source => "208.80.152.0/22", service => "ldap_backend", jump => "ACCEPT" }
	iptables_add_service{ "ldaps_backend_public": source => "208.80.152.0/22", service => "ldaps_backend", jump => "ACCEPT" }

	iptables_add_service{ "ldap_admin_connector_nfs1": source => "10.0.0.244", service => "ldap_admin_connector", jump => "ACCEPT" }
	iptables_add_service{ "ldap_admin_connector_virt0": source => "208.80.152.32", service => "ldap_admin_connector", jump => "ACCEPT" }
	iptables_add_service{ "ldap_admin_connector_virt1000": source => "208.80.154.18", service => "ldap_admin_connector", jump => "ACCEPT" }
	iptables_add_service{ "ldap_replication_nfs1": source => "10.0.0.244", service => "ldap_replication", jump => "ACCEPT" }
	iptables_add_service{ "ldap_replication_virt0": source => "208.80.152.32", service => "ldap_replication", jump => "ACCEPT" }
	iptables_add_service{ "ldap_replication_virt1000": source => "208.80.154.18", service => "ldap_replication", jump => "ACCEPT" }
	iptables_add_service{ "keystone_service_nova_virt0": source => "208.80.152.32", service => "keystone_service", jump => "ACCEPT" }
	iptables_add_service{ "keystone_admin_nova_virt0": source => "208.80.152.32", service => "keystone_admin", jump => "ACCEPT" }
	iptables_add_service{ "keystone_service_nova_virt1000": source => "208.80.154.18", service => "keystone_service", jump => "ACCEPT" }
	iptables_add_service{ "keystone_admin_nova_virt1000": source => "208.80.154.18", service => "keystone_admin", jump => "ACCEPT" }
	iptables_add_service{ "amanda": source => "208.80.152.170", service => "inetd", jump => "ACCEPT" }
	if ($site == "pmtpa") {
		iptables_add_service{ "puppet_private": source => "10.4.0.0/16", service => "puppetmaster", jump => "ACCEPT" }
		iptables_add_service{ "salt_publish_private": source => "10.4.0.0/16", service => "salt_publish", jump => "ACCEPT" }
		iptables_add_service{ "salt_ret_private": source => "10.4.0.0/16", service => "salt_ret", jump => "ACCEPT" }
		iptables_add_service{ "mysql_nova": source => "10.4.16.0/24", service => "mysql", jump => "ACCEPT" }
		iptables_add_service{ "glance_api_nova": source => "10.4.16.0/24", service => "glance_api", jump => "ACCEPT" }
		iptables_add_service{ "beam2_nova": source => "10.4.16.0/24", service => "beam2", jump => "ACCEPT" }
		iptables_add_service{ "beam3_nova": source => "10.4.16.0/24", service => "beam3", jump => "ACCEPT" }
		iptables_add_service{ "keystone_service_nova": source => "10.4.16.0/24", service => "keystone_service", jump => "ACCEPT" }
		iptables_add_service{ "keystone_admin_nova": source => "10.4.16.0/24", service => "keystone_admin", jump => "ACCEPT" }
	}
	if ($site == "eqiad") {
		iptables_add_service{ "puppet_private": source => "10.68.0.0/16", service => "puppetmaster", jump => "ACCEPT" }
		iptables_add_service{ "salt_publish_private": source => "10.68.0.0/16", service => "salt_publish", jump => "ACCEPT" }
		iptables_add_service{ "salt_ret_private": source => "10.68.0.0/16", service => "salt_ret", jump => "ACCEPT" }
		iptables_add_service{ "mysql_nova": source => "10.64.20.0/24", service => "mysql", jump => "ACCEPT" }
		iptables_add_service{ "glance_api_nova": source => "10.64.20.0/24", service => "glance_api", jump => "ACCEPT" }
		iptables_add_service{ "beam2_nova": source => "10.64.20.0/24", service => "beam2", jump => "ACCEPT" }
		iptables_add_service{ "beam3_nova": source => "10.64.20.0/24", service => "beam3", jump => "ACCEPT" }
		iptables_add_service{ "keystone_service_nova": source => "10.64.20.0/24", service => "keystone_service", jump => "ACCEPT" }
		iptables_add_service{ "keystone_admin_nova": source => "10.64.20.0/24", service => "keystone_admin", jump => "ACCEPT" }
	}
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
	iptables_add_service{ "deny_all_replication": service => "ldap_replication", jump => "DROP" }
	iptables_add_service{ "deny_all_puppetmaster": service => "puppetmaster", jump => "DROP" }
	iptables_add_service{ "deny_all_glance_api": service => "glance_api", jump => "DROP" }
	iptables_add_service{ "deny_all_glance_registry": service => "glance_registry", jump => "DROP" }
	iptables_add_service{ "deny_all_beam1": service => "beam1", jump => "DROP" }
	iptables_add_service{ "deny_all_beam2": service => "beam2", jump => "DROP" }
	iptables_add_service{ "deny_all_beam3": service => "beam3", jump => "DROP" }
	iptables_add_service{ "deny_all_epmd": service => "epmd", jump => "DROP" }
	iptables_add_service{ "deny_all_keystone_service": service => "keystone_service", jump => "DROP" }
	iptables_add_service{ "deny_all_keystone_admin": service => "keystone_admin", jump => "DROP" }
	iptables_add_service{ "deny_all_salt_publish": service => "salt_publish", jump => "DROP" }
	iptables_add_service{ "deny_all_salt_ret": service => "salt_ret", jump => "DROP" }
	iptables_add_service{ "deny_all_amanda": service => "inetd", jump => "DROP" }
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

class openstack::common($openstack_version="diablo",
			$novaconfig,
			$instance_status_wiki_host,
			$instance_status_wiki_domain,
			$instance_status_wiki_page_prefix,
			$instance_status_wiki_region,
			$instance_status_dns_domain,
			$instance_status_wiki_user,
			$instance_status_wiki_pass) {

	package { [ "nova-common", "python-keystone" ]:
		ensure => present;
	}

	package { [ "unzip", "vblade-persist", "python-mysqldb", "bridge-utils", "ebtables", "mysql-common" ]:
		ensure => present;
	}

	# For IPv6 support
	package { [ "python-netaddr", "radvd" ]:
		ensure => present;
	}

	file {
		"/etc/nova/nova.conf":
			content => template("openstack/${$openstack_version}/nova/nova.conf.erb"),
			owner => nova,
			group => nogroup,
			mode => 0440,
			require => Package['nova-common'];
	}

	if $openstack_version == "essex" {
		file {
			"/etc/nova/api-paste.ini":
				content => template("openstack/essex/nova/nova-api-paste.ini.erb"),
				owner => nova,
				group => nogroup,
				mode => 0440,
				require => Package['nova-common'];
		}
	}
}

class openstack::queue-server($openstack_version, $novaconfig) {
	package { [ "rabbitmq-server" ]:
		ensure => present;
	}
}

class openstack::project-storage-service {
	$ircecho_infile = "/var/lib/glustermanager/manage-volumes.log"
	$ircecho_nick = "labs-storage-wm"
	$ircecho_chans = "#wikimedia-labs"
	$ircecho_server = "irc.freenode.net"

	package { "ircecho":
		ensure => present;
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

	upstart_job{ "manage-volumes":
		require => Package["glusterfs-server"],
		install => "true";
	}

	service { "manage-volumes":
		enable => true,
		ensure => running,
		require => Upstart_job["manage-volumes"];
	}
}

class openstack::project-storage {
	include openstack::gluster-service

	$sudo_privs = [ 'ALL = NOPASSWD: /bin/mkdir -p /a/*',
			'ALL = NOPASSWD: /bin/rmdir /a/*',
			'ALL = NOPASSWD: /usr/sbin/gluster *' ]
	sudo_user { [ "glustermanager" ]: privileges => $sudo_privs, require => Systemuser["glustermanager"] }

	package { "python-paramiko":
		ensure => present;
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

class openstack::gluster-service {
	include generic::gluster-client,
		generic::gluster-server

	service { "glusterfs-server":
		enable => true,
		ensure => running,
		require => [Package["glusterfs-server"], File["/etc/init.d/glusterfs-server"], File["/etc/default/glusterd"], File["/etc/glusterfs/glusterd.vol"]];
	}
	file {
		"/etc/init.d/glusterfs-server":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/gluster/glusterfs-server",
			require => [Package["glusterfs-server"]];
		"/etc/default/glusterd":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/gluster/glusterd-default",
			require => [Package["glusterfs-server"]];
		"/etc/glusterfs/glusterd.vol":
			owner => root,
			group => root,
			mode => 0644,
			source => "puppet:///files/gluster/glusterd.vol",
			require => [Package["glusterfs-server"]];
		"/etc/init/glusterfs-server.conf":
			ensure => absent;
	}

}

class openstack::database-server($openstack_version="diablo", $novaconfig, $keystoneconfig, $glanceconfig) {
	$nova_db_name = $novaconfig["db_name"]
	$nova_db_user = $novaconfig["db_user"]
	$nova_db_pass = $novaconfig["db_pass"]
	$controller_mysql_root_pass = $novaconfig["controller_mysql_root_pass"]
	$puppet_db_name = $novaconfig["puppet_db_name"]
	$puppet_db_user = $novaconfig["puppet_db_user"]
	$puppet_db_pass = $novaconfig["puppet_db_pass"]
	$glance_db_name = $glanceconfig["db_name"]
	$glance_db_user = $glanceconfig["db_user"]
	$glance_db_pass = $glanceconfig["db_pass"]
	$keystone_db_name = $keystoneconfig["db_name"]
	$keystone_db_user = $keystoneconfig["db_user"]
	$keystone_db_pass = $keystoneconfig["db_pass"]

	require generic::mysql::packages::server

	# TODO: This expects the services to be installed in the same location
	exec {
		'set_root':
			onlyif => "/usr/bin/mysql -uroot --password=''",
			command => "/usr/bin/mysql -uroot --password='' mysql < /etc/nova/mysql.sql",
			require => File["/etc/nova/mysql.sql"],
			before => Exec['create_nova_db'];
		'create_nova_db_user':
			unless => "/usr/bin/mysql --defaults-file=/etc/nova/nova-user.cnf -e 'exit'",
			command => "/usr/bin/mysql -uroot < /etc/nova/nova-user.sql",
			require => File["/etc/nova/nova-user.sql", "/etc/nova/nova-user.cnf", "/root/.my.cnf"];
		'create_nova_db':
			unless => "/usr/bin/mysql -uroot $nova_db_name -e 'exit'",
			command => "/usr/bin/mysql -uroot -e \"create database $nova_db_name;\"",
			require => File["/root/.my.cnf"],
			before => Exec['create_nova_db_user'];
		'create_puppet_db_user':
			unless => "/usr/bin/mysql --defaults-file=/etc/puppet/puppet-user.cnf -e 'exit'",
			command => "/usr/bin/mysql -uroot < /etc/puppet/puppet-user.sql",
			require => File["/etc/puppet/puppet-user.sql", "/etc/puppet/puppet-user.cnf", "/root/.my.cnf"];
		'create_puppet_db':
			unless => "/usr/bin/mysql -uroot $puppet_db_name -e 'exit'",
			command => "/usr/bin/mysql -uroot -e \"create database $puppet_db_name;\"",
			require => File["/root/.my.cnf"],
			before => Exec['create_puppet_db_user'];
		'create_glance_db_user':
			unless => "/usr/bin/mysql --defaults-file=/etc/glance/glance-user.cnf -e 'exit'",
			command => "/usr/bin/mysql -uroot < /etc/glance/glance-user.sql",
			require => File["/etc/glance/glance-user.sql","/etc/glance/glance-user.cnf","/root/.my.cnf"];
		'create_glance_db':
			unless => "/usr/bin/mysql -uroot $glance_db_name -e 'exit'",
			command => "/usr/bin/mysql -uroot -e \"create database $glance_db_name;\"",
			require => File["/root/.my.cnf"],
			before => Exec['create_glance_db_user'];
	}

	if $openstack_version == "essex" {
		exec {
			'create_keystone_db_user':
				unless => "/usr/bin/mysql --defaults-file=/etc/keystone/keystone-user.cnf -e 'exit'",
				command => "/usr/bin/mysql -uroot < /etc/keystone/keystone-user.sql",
				require => File["/etc/keystone/keystone-user.sql", "/etc/keystone/keystone-user.cnf", "/root/.my.cnf"];
			'create_keystone_db':
				unless => "/usr/bin/mysql -uroot $keystone_db_name -e 'exit'",
				command => "/usr/bin/mysql -uroot -e \"create database $keystone_db_name;\"",
				require => File["/root/.my.cnf"],
				before => Exec['create_keystone_db_user'];
		}
	}

	file {
		"/root/.my.cnf":
			content => template("openstack/common/controller/my.cnf.erb"),
			owner => root,
			group => root,
			mode => 0640;
		"/etc/nova/mysql.sql":
			content => template("openstack/common/controller/mysql.sql.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["nova-common"];
		"/etc/nova/nova-user.sql":
			content => template("openstack/common/controller/nova-user.sql.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["nova-common"];
		"/etc/nova/nova-user.cnf":
			content => template("openstack/common/controller/nova-user.cnf.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["nova-common"];
		"/etc/puppet/puppet-user.sql":
			content => template("openstack/common/controller/puppet-user.sql.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["puppetmaster"];
		"/etc/puppet/puppet-user.cnf":
			content => template("openstack/common/controller/puppet-user.cnf.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["puppetmaster"];
		"/etc/glance/glance-user.sql":
			content => template("openstack/common/controller/glance-user.sql.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["glance"];
		"/etc/glance/glance-user.cnf":
			content => template("openstack/common/controller/glance-user.cnf.erb"),
			owner => root,
			group => root,
			mode => 0640,
			require => Package["glance"];
	}
	if $openstack_version == "essex" {
		file {
			"/etc/keystone/keystone-user.sql":
				content => template("openstack/common/controller/keystone-user.sql.erb"),
				owner => root,
				group => root,
				mode => 0640,
				require => Package["keystone"];
			"/etc/keystone/keystone-user.cnf":
				content => template("openstack/common/controller/keystone-user.cnf.erb"),
				owner => root,
				group => root,
				mode => 0640,
				require => Package["keystone"];
		}
	}
}

class openstack::openstack-manager($openstack_version="diablo", $novaconfig, $certificate) {
	require mediawiki::users::mwdeploy

    if !defined(Class["webserver::php5"]) {
		class {'webserver::php5': ssl => 'true'; }
	}

	if !defined(Class["memcached"]) {
		class { "memcached":
			pin => true;
		}
	}

	$controller_hostname = $novaconfig["controller_hostname"]

	package { [ 'php5', 'php5-cli', 'php5-ldap', 'php5-uuid', 'php5-curl', 'php-luasandbox' ]:
		ensure => present;
	}

	file {
		"/etc/apache2/sites-available/${controller_hostname}":
			require => [ Package[php5] ],
			mode => 0644,
			owner => root,
			group => root,
			content => template('apache/sites/wikitech.wikimedia.org.erb'),
			ensure => present;
		"/a/backup":
			mode => 755,
			owner => root,
			group => root,
			ensure => directory;
		"/usr/local/sbin/db-bak.sh":
			mode => 555,
			owner => root,
			group => root,
			source => "puppet:///files/openstack/db-bak.sh";
		"/usr/local/sbin/mw-files.sh":
			mode => 555,
			owner => root,
			group => root,
			source => "puppet:///files/openstack/mw-files.sh";
		"/usr/local/sbin/mw-xml.sh":
			mode => 555,
			owner => root,
			group => root,
			source => "puppet:///files/openstack/mw-xml.sh";
	}

	cron {
		"run-jobs":
			user => mwdeploy,
			command => 'cd /srv/org/wikimedia/controller/wikis/w; /usr/bin/php maintenance/runJobs.php > /dev/null 2>&1',
			ensure => present;
		"db-bak":
			user => root,
			hour => 1,
			minute => 0,
			command => '/usr/local/sbin/db-bak.sh > /dev/null 2>&1',
			require => File["/a/backup"],
			ensure => present;
		"mw-xml":
			user => root,
			hour => 1,
			minute => 30,
			command => '/usr/local/sbin/mw-xml.sh > /dev/null 2>&1',
			require => File["/a/backup"],
			ensure => present;
		"mw-files":
			user => root,
			hour => 2,
			minute => 0,
			command => '/usr/local/sbin/mw-files.sh > /dev/null 2>&1',
			require => File["/a/backup"],
			ensure => present;
		"backup-cleanup":
			user => root,
			hour => 3,
			minute => 0,
			command => 'find /a/backup -type f -mtime +7 -delete',
			require => File["/a/backup"],
			ensure => present;
	}


	apache_site { controller: name => "${controller_hostname}" }
	apache_module { rewrite: name => "rewrite" }
}

class openstack::scheduler-service($openstack_version="diablo", $novaconfig) {
	package { "nova-scheduler":
		ensure => present;
	}

	service { "nova-scheduler":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'],
		require => Package["nova-scheduler"];
	}
}

class openstack::network-service($openstack_version="diablo", $novaconfig) {
	package {  [ "nova-network", "dnsmasq" ]:
		ensure => present;
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

	if $openstack_version == "diablo" {
		file { "/usr/share/pyshared/nova/network/linux_net.py":
			source => "puppet:///files/openstack/diablo/nova/linux_net.py",
			mode => 0644,
			owner => root,
			group => root,
			notify => Service["nova-network"],
			require => Package["nova-network"];
		}
	}

	# Enable IP forwarding
	include generic::sysctl::advanced-routing,
		generic::sysctl::ipv6-disable-ra
}

class openstack::api-service($openstack_version="diablo", $novaconfig) {
	package {  [ "nova-api" ]:
		ensure => present;
	}

	service { "nova-api":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'],
		require => Package["nova-api"];
	}
	if $openstack_version == "essex" {
		file { "/etc/nova/policy.json":
			source => "puppet:///files/openstack/essex/nova/policy.json",
			mode => 0644,
			owner => root,
			group => root,
			notify => Service["nova-api"],
			require => Package["nova-api"];
		}
	}
}

class openstack::volume-service($openstack_version="diablo", $novaconfig) {
	package { [ "nova-volume" ]:
		ensure => absent;
	}

	#service { "nova-volume":
	#	ensure => stopped,
	#	subscribe => File['/etc/nova/nova.conf'],
	#	require => Package["nova-volume"];
	#}
}

class openstack::compute-service($openstack_version="diablo", $novaconfig) {
	# tls is a PITA to enable in labs, let's find another way there.
	# Disabling this for now, since we don't support live migration
	#if ( $realm == "production" ) {
	#	install_certificate{ "${fqdn}": }
	#	install_additional_key{ "${fqdn}": key_loc => "/var/lib/nova", owner => "nova", group => "libvirtd", require => Package["nova-common"] }

	#	file {
	#		"/var/lib/nova/clientkey.pem":
	#			ensure => link,
	#			target => "/var/lib/nova/${fqdn}.key",
	#			require => Install_additional_key["${fqdn}"];
	#		"/var/lib/nova/clientcert.pem":
	#			ensure => link,
	#			target => "/etc/ssl/certs/${fqdn}.pem",
	#			require => Install_certificate["${fqdn}"];
	#		"/var/lib/nova/cacert.pem":
	#			ensure => link,
	#			target => "/etc/ssl/certs/wmf-ca.pem",
	#			require => Install_certificate["${fqdn}"];
	#		"/etc/libvirt/libvirtd.conf":
	#			notify => Service["libvirt-bin"],
	#			owner => "root",
	#			group => "root",
	#			mode => 0444,
	#			content => template("openstack/common/nova/libvirtd.conf.erb"),
	#			require => Package["nova-common"];
	#		"/etc/default/libvirt-bin":
	#			notify => Service["libvirt-bin"],
	#			owner => "root",
	#			group => "root",
	#			mode => 0444,
	#			content => template("openstack/common/nova/libvirt-bin.default.erb"),
	#			require => Package["nova-common"];
	#		"/etc/init/libvirt-bin.conf":
	#			notify => Service["libvirt-bin"],
	#			owner => "root",
	#			group => "root",
	#			mode => 0444,
	#			source => "puppet:///files/upstart/libvirt-bin.conf",
	#			require => Package["nova-common"];
	#	}
	#}

	service { "libvirt-bin":
		ensure => running,
		enable => true,
		require => Package["nova-common"];
	}

	package { [ "nova-compute" ]:
		ensure => present;
	}

	if $openstack_version == "essex" {
		package { [ "nova-compute-kvm" ]:
			ensure => present;
		}
	}

	service { "nova-compute":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'],
		require => Package["nova-compute"];
	}

	if $openstack_version == "diablo" {
		file { "/usr/share/pyshared/nova/compute/api.py":
			source => "puppet:///files/openstack/diablo/nova/compute-api.py",
			mode => 0644,
			owner => root,
			group => root,
			notify => Service["nova-compute"],
			require => Package["nova-compute"];
		}
		file { "/usr/share/pyshared/nova/db/sqlalchemy/api.py":
			source => "puppet:///files/openstack/diablo/nova/sqlalchemy-api.py",
			mode => 0644,
			owner => root,
			group => root,
			notify => Service["nova-compute"],
			require => Package["nova-compute"];
		}
	}

	file {
		"/etc/libvirt/qemu/networks/autostart/default.xml":
			ensure => absent;
	}
}

class openstack::keystone-service($openstack_version="essex", $keystoneconfig) {
	package { [ "keystone" ]:
		ensure => present;
	}

	service { "keystone":
		ensure => running,
		subscribe => File['/etc/keystone/keystone.conf'],
		require => Package["keystone"];
	}

	file {
		"/etc/keystone/keystone.conf":
			content => template("openstack/${openstack_version}/keystone/keystone.conf.erb"),
			owner => keystone,
			group => keystone,
			notify => Service["keystone"],
			require => Package["keystone"],
			mode => 0440;
	}
}

class openstack::glance-service($openstack_version="diablo", $glanceconfig) {
	package { [ "glance" ]:
		ensure => present;
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
			content => template("openstack/${$openstack_version}/glance/glance-api.conf.erb"),
			owner => glance,
			group => nogroup,
			notify => Service["glance-api"],
			require => Package["glance"],
			mode => 0440;
		"/etc/glance/glance-registry.conf":
			content => template("openstack/${$openstack_version}/glance/glance-registry.conf.erb"),
			owner => glance,
			group => nogroup,
			notify => Service["glance-registry"],
			require => Package["glance"],
			mode => 0440;
	}
	if ($openstack_version == "essex") {
		file {
			"/etc/glance/glance-api-paste.ini":
				content => template("openstack/${$openstack_version}/glance/glance-api-paste.ini.erb"),
				owner => glance,
				group => glance,
				notify => Service["glance-api"],
				require => Package["glance"],
				mode => 0440;
			"/etc/glance/glance-registry-paste.ini":
				content => template("openstack/${$openstack_version}/glance/glance-registry-paste.ini.erb"),
				owner => glance,
				group => glance,
				notify => Service["glance-registry"],
				require => Package["glance"],
				mode => 0440;
		}
	}
}
