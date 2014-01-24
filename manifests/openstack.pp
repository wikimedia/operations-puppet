class openstack::firewall {
    $labs_private_net = '10.0.0.0/0'
	if ($::site == 'pmtpa') {
		$labs_nodes = '10.4.16.0/24'
		# virt1000
		$other_master = '208.80.154.18'
	} elsif ($::site == 'eqiad') {
		$labs_nodes = '10.68.20.0/24'
		# virt0
		$other_master = '208.80.152.32'
	}

	# LDAP
	ferm::rule { 'ldap_private_labs':
		rule => 'saddr (10.0.0.0/8 208.80.152.0/22) proto tcp dport (ldap ldaps) ACCEPT;',
	}
	ferm::rule { 'ldap_backend_private_labs':
		rule => 'saddr (10.0.0.0/8 208.80.152.0/22) proto tcp dport (1389 1636) ACCEPT;',
	}
	ferm::rule {' ldap_admin_replication':
		rule => "saddr (10.0.0.244 $other_master) proto tcp dport (4444 8989) ACCEPT;",
	}

	# internal services to Labs virt servers
	ferm::rule { 'keystone':
		rule => "saddr ($other_master $labs_nodes) proto tcp dport (5000 35357) ACCEPT;",
	}
	ferm::rule { 'mysql_nova':
		rule => "saddr $labs_nodes proto tcp dport (3306) ACCEPT;",
	}
	ferm::rule { 'beam_nova':
		rule => "saddr $labs_nodes proto tcp dport (5672 56918) ACCEPT;",
	}
	ferm::rule { 'glance_api_nova':
		rule => "saddr $labs_nodes proto tcp dport 9292 ACCEPT;",
	}

	# services provided to Labs instances
	ferm::rule { 'puppetmaster':
		rule => "saddr $labs_private_net proto tcp dport 8140 ACCEPT;",
	}
	ferm::rule { 'salt':
		rule => "saddr $labs_private_net proto tcp dport (4505 4506) ACCEPT;",
	}

	# allow amanda from tridge; will be dropped soon
	ferm::rule { 'amanda':
		rule => 'saddr 208.80.152.170 proto tcp dport 10080 ACCEPT;',
	}
}

class openstack::repo($openstack_version="folsom") {
	if ($::lsbdistcodename == 'precise') {
		apt::repository { 'ubuntucloud':
			uri        => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
			dist       => "precise-updates/${openstack_version}",
			components => 'main',
			keyfile    => 'puppet:///files/misc/ubuntu-cloud.key';
		}
	}
}

class openstack::common($openstack_version="folsom",
			$novaconfig,
			$instance_status_wiki_host,
			$instance_status_wiki_domain,
			$instance_status_wiki_page_prefix,
			$instance_status_wiki_region,
			$instance_status_dns_domain,
			$instance_status_wiki_user,
			$instance_status_wiki_pass) {
	if ! defined(Class["openstack::repo"]) {
		class { "openstack::repo": openstack_version => $openstack_version }
	}

	package { [ "nova-common", "python-keystone" ]:
		ensure => present,
		require => Class["openstack::repo"];
	}

	package { [ "unzip", "vblade-persist", "python-mysqldb", "bridge-utils", "ebtables", "mysql-common" ]:
		ensure => present,
		require => Class["openstack::repo"];
	}

	require mysql

	# For IPv6 support
	package { [ "python-netaddr", "radvd" ]:
		ensure => present,
		require => Class["openstack::repo"];
	}

	file {
		"/etc/nova/nova.conf":
			content => template("openstack/${$openstack_version}/nova/nova.conf.erb"),
			owner => nova,
			group => nogroup,
			mode => 0440,
			require => Package['nova-common'];
	}

	file {
		"/etc/nova/api-paste.ini":
			content => template("openstack/${$openstack_version}/nova/api-paste.ini.erb"),
			owner => nova,
			group => nogroup,
			mode => 0440,
			require => Package['nova-common'];
	}
}

class openstack::queue-server($openstack_version, $novaconfig) {
	if ! defined(Class["openstack::repo"]) {
		class { "openstack::repo": openstack_version => $openstack_version }
	}

	package { [ "rabbitmq-server" ]:
		ensure => present,
		require => Class["openstack::repo"];
	}
}

class openstack::project-storage-service {
	$ircecho_logs = { "/var/lib/glustermanager/manage-volumes.log" => "wikimedia-labs" }
	$ircecho_nick = "labs-storage-wm"
	$ircecho_server = "chat.freenode.net"

	include role::echoirc

	generic::upstart_job{ "manage-volumes":
		require => Package["glusterfs-server"],
		install => "true";
	}

	service { "manage-volumes":
		enable => true,
		ensure => running,
		require => Generic::Upstart_job["manage-volumes"];
	}
}

class openstack::project-nfs-storage-service {
	generic::upstart_job{ "manage-nfs-volumes":
		install => "true";
	}

	service { "manage-nfs-volumes":
		enable => true,
		ensure => running,
		require => Generic::Upstart_job["manage-nfs-volumes"];
	}

	$sudo_privs = [ 'ALL = NOPASSWD: /bin/mkdir -p /srv/*',
			'ALL = NOPASSWD: /bin/rmdir /srv/*',
			'ALL = NOPASSWD: /usr/local/sbin/sync-exports' ]
	sudo_user { [ "nfsmanager" ]: privileges => $sudo_privs, require => Generic::Systemuser["nfsmanager"] }
	generic::systemuser { "nfsmanager": name => "nfsmanager", home => "/var/lib/nfsmanager", shell => "/bin/bash" }
}

class openstack::project-storage {
	include gluster::service

	$sudo_privs = [ 'ALL = NOPASSWD: /bin/mkdir -p /a/*',
			'ALL = NOPASSWD: /bin/rmdir /a/*',
			'ALL = NOPASSWD: /usr/sbin/gluster *' ]
	sudo_user { [ "glustermanager" ]: privileges => $sudo_privs, require => Generic::Systemuser["glustermanager"] }

	package { "python-paramiko":
		ensure => present;
	}

	generic::systemuser { "glustermanager": name => "glustermanager", home => "/var/lib/glustermanager", shell => "/bin/bash" }
	ssh_authorized_key {
		"glustermanager":
			ensure	=> present,
			user	=> "glustermanager",
			type	=> "ssh-rsa",
			key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAuE328+IMmMOoqFhti58rBBxkJy2u+sgxcKuJ4B5248f73YqfZ3RkEWvBGb3ce3VCptrrXJAMCw55HsMyhT8A7chBGLdjhPjol+3Vh2+mc6EkjW0xscX39gh1Fn1jVqrx+GMIuwid7zxGytaKyQ0vko4FP64wDbm1rfVc1jsLMQ+gdAG/KNGYtwjLMEQk8spydckAtkWg3YumMl7e4NQYpYlkTXgVIQiZGpslu5LxKBmXPPF4t2h17p+rNr9ZAVII4av8vRiyQa2/MaH4QZoGYGbkQXifbhBD438NlgZrvLANYuT78zPj4n1G061s7n9nmvVMH3W7QyXS8MpftLnegw==",
			require => Generic::Systemuser["glustermanager"];
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
			require => Generic::Systemuser["glustermanager"];
	}
}

class openstack::database-server($openstack_version="folsom", $novaconfig, $keystoneconfig, $glanceconfig) {
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

	require mysql::server::package

	if !defined(Service['mysql']) {
		service { "mysql":		
			enable => true,		
			require => Class['mysql::server::package'],
			ensure => running;
		}
	}

	# TODO: This expects the services to be installed in the same location
	exec {
		'set_root':
			onlyif => "/usr/bin/mysql -uroot --password=''",
			command => "/usr/bin/mysql -uroot --password='' mysql < /etc/nova/mysql.sql",
			require => [Class['mysql'], File["/etc/nova/mysql.sql"]],
			before => Exec['create_nova_db'];
		'create_nova_db_user':
			unless => "/usr/bin/mysql --defaults-file=/etc/nova/nova-user.cnf -e 'exit'",
			command => "/usr/bin/mysql -uroot < /etc/nova/nova-user.sql",
			require => [Class['mysql'], File["/etc/nova/nova-user.sql", "/etc/nova/nova-user.cnf", "/root/.my.cnf"]];
		'create_nova_db':
			unless => "/usr/bin/mysql -uroot $nova_db_name -e 'exit'",
			command => "/usr/bin/mysql -uroot -e \"create database $nova_db_name;\"",
			require => [Class['mysql'], File["/root/.my.cnf"]],
			before => Exec['create_nova_db_user'];
		'create_puppet_db_user':
			unless => "/usr/bin/mysql --defaults-file=/etc/puppet/puppet-user.cnf -e 'exit'",
			command => "/usr/bin/mysql -uroot < /etc/puppet/puppet-user.sql",
			require => [Class['mysql'], File["/etc/puppet/puppet-user.sql", "/etc/puppet/puppet-user.cnf", "/root/.my.cnf"]];
		'create_puppet_db':
			unless => "/usr/bin/mysql -uroot $puppet_db_name -e 'exit'",
			command => "/usr/bin/mysql -uroot -e \"create database $puppet_db_name;\"",
			require => [Class['mysql'], File["/root/.my.cnf"]],
			before => Exec['create_puppet_db_user'];
		'create_glance_db_user':
			unless => "/usr/bin/mysql --defaults-file=/etc/glance/glance-user.cnf -e 'exit'",
			command => "/usr/bin/mysql -uroot < /etc/glance/glance-user.sql",
			require => [Class['mysql'], File["/etc/glance/glance-user.sql","/etc/glance/glance-user.cnf","/root/.my.cnf"]];
		'create_glance_db':
			unless => "/usr/bin/mysql -uroot $glance_db_name -e 'exit'",
			command => "/usr/bin/mysql -uroot -e \"create database $glance_db_name;\"",
			require => [Class['mysql'], File["/root/.my.cnf"]],
			before => Exec['create_glance_db_user'];
	}

	exec {
		'create_keystone_db_user':
			unless => "/usr/bin/mysql --defaults-file=/etc/keystone/keystone-user.cnf -e 'exit'",
			command => "/usr/bin/mysql -uroot < /etc/keystone/keystone-user.sql",
			require => [Class['mysql'], File["/etc/keystone/keystone-user.sql", "/etc/keystone/keystone-user.cnf", "/root/.my.cnf"]];
		'create_keystone_db':
			unless => "/usr/bin/mysql -uroot $keystone_db_name -e 'exit'",
			command => "/usr/bin/mysql -uroot -e \"create database $keystone_db_name;\"",
			require => [Class['mysql'], File["/root/.my.cnf"]],
			before => Exec['create_keystone_db_user'];
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

class openstack::openstack-manager($openstack_version="folsom", $novaconfig, $certificate) {
	require mediawiki::users::mwdeploy

	if !defined(Class["webserver::php5"]) {
		class {'webserver::php5': ssl => true; }
	}

	if !defined(Class["memcached"]) {
		class { "memcached":
			memcached_ip => "127.0.0.1",
			pin => true;
		}
	}

	$controller_hostname = $novaconfig["controller_hostname"]

	package { [ 'php5', 'php5-cli', 'php5-mysql', 'php5-ldap', 'php5-uuid', 'php5-curl', 'php-apc', 'php-luasandbox', 'imagemagick', 'librsvg2-bin' ]:
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
		"/var/www/robots.txt":
			ensure  => present,
			mode    => '0644',
			owner   => 'root',
			group   => 'root',
			content => template('openstack/labs-robots.txt.erb');
		"/a":
			mode => 755,
			owner => root,
			group => root,
			ensure => directory;
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

	include backup::host
	backup::set {'a-backup': }

	include nrpe
}

class openstack::scheduler-service($openstack_version="folsom", $novaconfig) {
	if ! defined(Class["openstack::repo"]) {
		class { "openstack::repo": openstack_version => $openstack_version }
	}

	package { "nova-scheduler":
		ensure => present,
		require => Class["openstack::repo"];
	}

	service { "nova-scheduler":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'],
		require => Package["nova-scheduler"];
	}
}

class openstack::network-service($openstack_version="folsom", $novaconfig) {
	if ! defined(Class["openstack::repo"]) {
		class { "openstack::repo": openstack_version => $openstack_version }
	}

	package {  [ "nova-network", "dnsmasq" ]:
		ensure => present,
		require => Class["openstack::repo"];
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

	sysctl::parameters { 'openstack':
		values => {
			# Turn off IP filter
			'net.ipv4.conf.default.rp_filter' => 0,
			'net.ipv4.conf.all.rp_filter'     => 0,

			# Enable IP forwarding
			'net.ipv4.ip_forward'             => 1,
			'net.ipv6.conf.all.forwarding'    => 1,

			# Disable RA
			'net.ipv6.conf.all.accept_ra'     => 0,
		},
	}
}

class openstack::api-service($openstack_version="folsom", $novaconfig) {
	if ! defined(Class["openstack::repo"]) {
		class { "openstack::repo": openstack_version => $openstack_version }
	}

	package {  [ "nova-api" ]:
		ensure => present,
		require => Class["openstack::repo"];
	}

	service { "nova-api":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'],
		require => Package["nova-api"];
	}
	file { "/etc/nova/policy.json":
		source => "puppet:///files/openstack/${openstack_version}/nova/policy.json",
		mode => 0644,
		owner => root,
		group => root,
		notify => Service["nova-api"],
		require => Package["nova-api"];
	}
}

class openstack::volume-service($openstack_version="folsom", $novaconfig) {
	if ! defined(Class["openstack::repo"]) {
		class { "openstack::repo": openstack_version => $openstack_version }
	}

	package { [ "nova-volume" ]:
		ensure => absent,
		require => Class["openstack::repo"];
	}

	#service { "nova-volume":
	#	ensure => stopped,
	#	subscribe => File['/etc/nova/nova.conf'],
	#	require => Package["nova-volume"];
	#}
}

class openstack::compute-service($openstack_version="folsom", $novaconfig) {
	if ! defined(Class["openstack::repo"]) {
		class { "openstack::repo": openstack_version => $openstack_version }
	}

	if ( $realm == "production" ) {
		$certname = "virt-star.${site}.wmnet"
		install_certificate{ "${certname}": }
		install_additional_key{ "${certname}": key_loc => "/var/lib/nova", owner => "nova", group => "libvirtd", require => Package["nova-common"] }

		file {
			"/var/lib/nova/clientkey.pem":
				ensure => link,
				target => "/var/lib/nova/${certname}.key",
				require => Install_additional_key["${certname}"];
			"/var/lib/nova/clientcert.pem":
				ensure => link,
				target => "/etc/ssl/certs/${certname}.pem",
				require => Install_certificate["${certname}"];
			"/var/lib/nova/cacert.pem":
				ensure => link,
				target => "/etc/ssl/certs/wmf-ca.pem",
				require => Install_certificate["${certname}"];
			"/var/lib/nova/.ssh":
				ensure => directory,
				owner => "nova",
				group => "nova",
				mode => 0700,
				require => Package["nova-common"];
			"/var/lib/nova/.ssh/id_rsa":
				source => "puppet:///private/ssh/nova/nova.key",
				owner => "nova",
				group => "nova",
				mode => 0600,
				require => File["/var/lib/nova/.ssh"];
			"/var/lib/nova/.ssh/authorized_keys":
				source => "puppet:///private/ssh/nova/nova.pub",
				owner => "nova",
				group => "nova",
				mode => 0600,
				require => File["/var/lib/nova/.ssh"];
			"/etc/libvirt/libvirtd.conf":
				notify => Service["libvirt-bin"],
				owner => "root",
				group => "root",
				mode => 0444,
				content => template("openstack/common/nova/libvirtd.conf.erb"),
				require => Package["nova-common"];
			"/etc/default/libvirt-bin":
				notify => Service["libvirt-bin"],
				owner => "root",
				group => "root",
				mode => 0444,
				content => template("openstack/common/nova/libvirt-bin.default.erb"),
				require => Package["nova-common"];
			"/etc/nova/nova-compute.conf":
				notify => Service["nova-compute"],
				owner => "root",
				group => "root",
				mode => 0444,
				content => template("openstack/common/nova/nova-compute.conf.erb"),
				require => Package["nova-common"];
		}
	}

	service { "libvirt-bin":
		ensure => running,
		enable => true,
		require => Package["nova-common"];
	}

	package { [ "nova-compute", "nova-compute-kvm" ]:
		ensure => present,
		require => Class["openstack::repo"];
	}

	# nova-compute adds the user with /bin/false, but resize, live migration, etc.
	# need the nova use to have a real shell, as it uses ssh.
	user { "nova":
		ensure => present,
		shell => "/bin/bash",
		require => Package["nova-common"];
	}

	service { "nova-compute":
		ensure => running,
		subscribe => File['/etc/nova/nova.conf'],
		require => Package["nova-compute"];
	}

	file {
		"/etc/libvirt/qemu/networks/autostart/default.xml":
			ensure => absent;
		# Live hack to use qcow2 ephemeral base images. Need to upstream
		# a config option for this in havana.
		"/usr/share/pyshared/nova/virt/libvirt/driver.py":
			source => "puppet:///files/openstack/${openstack_version}/nova/virt-libvirt-driver",
			notify => Service["nova-compute"],
			owner => "root",
			group => "root",
			mode => 0444,
			require => Package["nova-common"];
	}
}

class openstack::keystone-service($openstack_version="folsom", $keystoneconfig) {
	if ! defined(Class["openstack::repo"]) {
		class { "openstack::repo": openstack_version => $openstack_version }
	}

	package { [ "keystone" ]:
		ensure => present,
		require => Class["openstack::repo"];
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

class openstack::glance-service($openstack_version="folsom", $glanceconfig) {
	if ! defined(Class["openstack::repo"]) {
		class { "openstack::repo": openstack_version => $openstack_version }
	}

	package { [ "glance" ]:
		ensure => present,
		require => Class["openstack::repo"];
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
		# Keystone config was (thankfully) moved out of the paste config
		# So, past essex we don't need to change these.
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
