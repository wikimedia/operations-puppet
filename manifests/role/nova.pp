class role::nova::config {
	include passwords::openstack::nova

	$commonnovaconfig = {
		db_name => "nova",
		db_user => "nova",
		db_pass => $passwords::openstack::nova::nova_db_pass,
		network_flat_interface => $realm ? {
			"production" => "eth1.103",
			"labs" => "eth0.103",
		},
		network_flat_interface_name => $realm ? {
			"production" => "eth1",
			"labs" => "eth0",
		},
		network_flat_interface_vlan => "103",
		flat_network_bridge => "br103",
		network_public_interface => "eth0",
		my_ip => $ipaddress_eth0,
		ldap_base_dn => "dc=wikimedia,dc=org",
		ldap_user_dn => "uid=novaadmin,ou=people,dc=wikimedia,dc=org",
		ldap_user_pass => $passwords::openstack::nova::nova_ldap_user_pass,
		ldap_proxyagent => "cn=proxyagent,ou=profile,dc=wikimedia,dc=org",
		ldap_proxyagent_pass => $passwords::openstack::nova::nova_ldap_proxyagent_pass,
		controller_mysql_root_pass => $passwords::openstack::nova::controller_mysql_root_pass,
		puppet_db_name => "puppet",
		puppet_db_user => "puppet",
		puppet_db_pass => $passwords::openstack::nova::nova_puppet_user_pass,
		zone => "nova",
		# By default, don't allow projects to allocate public IPs; this way we can
		# let users have network admin rights, for firewall rules and such, and can
		# give them public ips by increasing their quota
		quota_floating_ips => "0",
		libvirt_type => $realm ? {
			"production" => "kvm",
			"labs" => "qemu",
		},
	}
}

class role::nova::config::pmtpa inherits role::nova::config {
	include role::keystone::config::pmtpa

	$keystoneconfig = $role::keystone::config::pmtpa::keystoneconfig
	$controller_hostname = $realm ? {
		"production" => "virt1000.wikimedia.org",
		"labs" => "localhost",
	}


	$pmtpanovaconfig = {
		db_host => $controller_hostname,
		dhcp_domain => "pmtpa.wmflabs",
		glance_host => $controller_hostname,
		rabbit_host => $controller_hostname,
		cc_host => $controller_hostname,
		network_host => $realm ? {
			"production" => "10.4.0.1",
			"labs" => "127.0.0.1",
		},
		api_host => $realm ? {
			"production" => "virt2.pmtpa.wmnet",
			"labs" => "localhost",
		},
		api_ip => $realm ? {
			"production" => "10.4.0.1",
			"labs" => "127.0.0.1",
		},
		fixed_range => $realm ? {
			"production" => "10.4.0.0/24",
			"labs" => "192.168.0.0/24",
		},
		dhcp_start => $realm ? {
			"production" => "10.4.0.4",
			"labs" => "192.168.0.4",
		},
		network_public_ip => $realm ? {
			"production" => "208.80.153.192",
			"labs" => "127.0.0.1",
		},
		dmz_cidr => $realm ? {
			"production" => "208.80.153.0/22,10.0.0.0/8",
			"labs" => "10.4.0.0/24",
		},
		controller_hostname => $realm ? {
			"production" => "labsconsole.wikimedia.org",
			"labs" => $fqdn,
		},
		ajax_proxy_url => $realm ? {
			"production" => "http://labsconsole.wikimedia.org:8000",
			"labs" => "http://${hostname}.${domain}:8000",
		},
		ldap_host => $controller_hostname,
		puppet_host => "virt0.wikimedia.org",
		live_migration_uri => "qemu://%s.pmtpa.wmnet/system?pkipath=/var/lib/nova",
		keystone_admin_token => $keystoneconfig["admin_token"],
		keystone_auth_host => $keystoneconfig["bind_ip"],
		keystone_auth_protocol => $keystoneconfig["auth_protocol"],
		keystone_auth_port => $keystoneconfig["auth_port"],
	}
	$novaconfig = merge( $pmtpanovaconfig, $commonnovaconfig )
}

class role::nova::config::eqiad inherits role::nova::config {
	include role::keystone::config::eqiad

	$keystoneconfig = $role::keystone::config::pmtpa::keystoneconfig
	$controller_hostname = $realm ? {
		"production" => "virt1000.wikimedia.org",
		"labs" => "localhost",
	}

	$eqiadnovaconfig = {
		db_host => $controller_hostname,
		dhcp_domain => "eqiad.wmflabs",
		glance_host => $controller_hostname,
		rabbit_host => $controller_hostname,
		cc_host => $controller_hostname,
		network_host => $realm ? {
			"production" => "10.4.125.1",
			"labs" => "127.0.0.1",
		},
		api_host => $realm ? {
			"production" => "virt1002.pmtpa.wmnet",
			"labs" => "localhost",
		},
		api_ip => $realm ? {
			"production" => "10.4.125.1",
			"labs" => "127.0.0.1",
		},
		fixed_range => $realm ? {
			"production" => "10.4.125.0/24",
			"labs" => "192.168.0.0/24",
		},
		dhcp_start => $realm ? {
			"production" => "10.4.125.4",
			"labs" => "192.168.0.4",
		},
		network_public_ip => $realm ? {
			"production" => "208.80.153.193",
			"labs" => "127.0.0.1",
		},
		dmz_cidr => $realm ? {
			"production" => "208.80.153.0/22,10.0.0.0/8",
			"labs" => "10.4.0.0/24",
		},
		controller_hostname => $realm ? {
			"production" => "labsconsole.wikimedia.org",
			"labs" => $fqdn,
		},
		ajax_proxy_url => $realm ? {
			"production" => "http://labsconsole.wikimedia.org:8000",
			"labs" => "http://${hostname}.${domain}:8000",
		},
		ldap_host => $controller_hostname,
		puppet_host => "virt1000.wikimedia.org",
		live_migration_uri => "qemu://%s.eqiad.wmnet/system?pkipath=/var/lib/nova",
		keystone_admin_token => $keystoneconfig["admin_token"],
		keystone_auth_host => $keystoneconfig["bind_ip"],
		keystone_auth_protocol => $keystoneconfig["auth_protocol"],
		keystone_auth_port => $keystoneconfig["auth_port"],
	}
	$novaconfig = merge( $eqiadnovaconfig, $commonnovaconfig )
}

class role::nova::common {
	include role::nova::config::pmtpa,
		role::nova::config::eqiad

	$novaconfig = $site ? {
		"pmtpa" => $role::nova::config::pmtpa::novaconfig,
		"eqiad" => $role::nova::config::eqiad::novaconfig,
	}

	class { "openstack::common": openstack_version => $openstack_version, novaconfig => $novaconfig }
}

class role::nova::controller {
	include role::nova::config::pmtpa,
		role::nova::config::eqiad,
		role::keystone::config::pmtpa,
		role::keystone::config::eqiad,
		role::glance::config::pmtpa,
		role::glance::config::eqiad

	$novaconfig = $site ? {
		"pmtpa" => $role::nova::config::pmtpa::novaconfig,
		"eqiad" => $role::nova::config::eqiad::novaconfig,
	}
	$glanceconfig = $site ? {
		"pmtpa" => $role::glance::config::pmtpa::glanceconfig,
		"eqiad" => $role::glance::config::eqiad::glanceconfig,
	}
	$keystoneconfig = $site ? {
		"pmtpa" => $role::keystone::config::pmtpa::keystoneconfig,
		"eqiad" => $role::keystone::config::eqiad::keystoneconfig,
	}

	include role::nova::common

	class { "openstack::scheduler-service": openstack_version => $openstack_version, novaconfig => $novaconfig }
	class { "openstack::glance-service": openstack_version => $openstack_version, glanceconfig => $glanceconfig }
	class { "openstack::openstack-manager":
		openstack_version => $openstack_version,
		novaconfig => $novaconfig,
		certificate => $realm ? {
			"production" => "star.wikimedia.org",
			"labs" => "star.wmflabs",
		}
	}
	class { "openstack::queue-server": openstack_version => $openstack_version, novaconfig => $novaconfig }
	class { "openstack::iptables": }
	class { "openstack::database-server":
		openstack_version => $openstack_version,
		novaconfig => $novaconfig,
		glanceconfig => $glanceconfig,
		keystoneconfig => $keystoneconfig,
	}
	if $openstack_version == "essex" {
		class { "role::keystone::server": }
	}
	if $realm == "production" {
		class { "role::puppet::server::labs": }
	}
}

class role::nova::api {
	include role::nova::config::pmtpa,
		role::nova::config::eqiad

	include role::nova::common

	$novaconfig = $site ? {
		"pmtpa" => $role::nova::config::pmtpa::novaconfig,
		"eqiad" => $role::nova::config::eqiad::novaconfig,
	}
	class { "openstack::api-service": openstack_version => $openstack_version, novaconfig => $novaconfig }
}

class role::nova::network {
	include role::nova::config::pmtpa,
		role::nova::config::eqiad

	include role::nova::common

	$novaconfig = $site ? {
		"pmtpa" => $role::nova::config::pmtpa::novaconfig,
		"eqiad" => $role::nova::config::eqiad::novaconfig,
	}
	class { "openstack::network-service": openstack_version => $openstack_version, novaconfig => $novaconfig }
}

class role::nova::compute {
	include role::nova::config::pmtpa,
		role::nova::config::eqiad

	$novaconfig = $site ? {
		"pmtpa" => $role::nova::config::pmtpa::novaconfig,
		"eqiad" => $role::nova::config::eqiad::novaconfig,
	}

	include role::nova::common

	class { "openstack::compute-service": openstack_version => $openstack_version, novaconfig => $novaconfig }

	if $realm == "labs" {
		include role::nova::api,
			role::nova::network
	}
}
