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

class role::nova::pmtpa inherits role::nova {
	include role::keystone::config::pmtpa

	$pmtpanovaconfig = {
		db_host => $realm ? {
			"production" => "virt0.wikimedia.org",
			"labs" => "localhost",
		},
		dhcp_domain => "pmtpa.wmflabs",
		glance_host => $realm ? {
			"production" => "virt0.wikimedia.org",
			"labs" => "localhost",
		},
		rabbit_host => $realm ? {
			"production" => "virt0.wikimedia.org",
			"labs" => "localhost",
		},
		cc_host => $realm ? {
			"production" => "virt0.wikimedia.org",
			"labs" => "localhost",
		},
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
		ldap_host => $realm ? {
			"production" => "virt0.wikimedia.org",
			"labs" => "localhost",
		},
		puppet_host => "virt0.wikimedia.org",
		live_migration_uri => "qemu://%s.pmtpa.wmnet/system?pkipath=/var/lib/nova",
		keystone_admin_token => $role::keystone::config::pmtpa::admin_token,
		keystone_auth_host => $role::keystone::config::pmtpa::bind_ip,
		keystone_auth_protocol => $role::keystone::config::pmtpa::auth_protocol,
		keystone_auth_port => $role::keystone::config::pmtpa::auth_port,
	}
	$novaconfig = merge( $pmtpanovaconfig, $commonnovaconfig )
}

class role::nova::eqiad inherits role::nova {
	include role::keystone::config::eqiad

	$eqiadnovaconfig = {
		db_host => $realm ? {
			"production" => "virt1000.wikimedia.org",
			"labs" => "localhost",
		},
		dhcp_domain => "eqiad.wmflabs",
		glance_host => $realm ? {
			"production" => "virt1000.wikimedia.org",
			"labs" => "localhost",
		},
		rabbit_host => $realm ? {
			"production" => "virt1000.wikimedia.org",
			"labs" => "localhost",
		},
		cc_host => $realm ? {
			"production" => "virt1000.wikimedia.org",
			"labs" => "localhost",
		},
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
		ldap_host => $realm ? {
			"production" => "virt1000.wikimedia.org",
			"labs" => "localhost",
		},
		puppet_host => "virt1000.wikimedia.org",
		live_migration_uri => "qemu://%s.eqiad.wmnet/system?pkipath=/var/lib/nova",
		keystone_admin_token => $role::keystone::config::eqiad::admin_token,
		keystone_auth_host => $role::keystone::config::eqiad::bind_ip,
		keystone_auth_protocol => $role::keystone::config::eqiad::auth_protocol,
		keystone_auth_port => $role::keystone::config::eqiad::auth_port,
	}
	$novaconfig = merge( $eqiadnovaconfig, $commonnovaconfig )
}

class role::nova::controller {
	include role::nova::config::pmtpa,
		role::nova::config::eqiad,
		role::keystone::config::pmtpa,
		role::keystone::config::eqiad,
		role::glance::config::pmtpa,
		role::glance::config::eqiad

	$novaconfig = $cluster ? {
		"pmtpa" => role::nova::config::pmtpa::novaconfig,
		"eqiad" => role::nova::config::eqiad::novaconfig,
	}
	$glanceconfig = $cluster ? {
		"pmtpa" => role::glance::config::pmtpa::glanceconfig,
		"eqiad" => role::glance::config::eqiad::glanceconfig,
	}
	$keystoneconfig = $cluster ? {
		"pmtpa" => role::keystone::config::pmtpa::keystoneconfig,
		"eqiad" => role::keystone::config::eqiad::keystoneconfig,
	}

	class { "openstack::common": openstack_version => $openstack_version, novaconfig => $novaconfig }
	class { "openstack::scheduler-service": openstack_version => $openstack_version, novaconfig => $novaconfig }
	class { "openstack::glance-service": openstack_version => $openstack_version, novaconfig => $novaconfig }
	class { "openstack::openstack-manager": openstack_version => $openstack_version, novaconfig => $novaconfig }
	class { "openstack::queue-server": openstack_version => $openstack_version, novaconfig => $novaconfig }
	class { "openstack::iptables" }
	class { "openstack::database-server":
		openstack_version => $openstack_version,
		novaconfig => $novaconfig,
		glanceconfig => $glanceconfig,
		keystoneconfig => $keystoneconfig,
	}
	if $openstack_version == "essex" {
		class { "role::keystone::server": }

		class { "openstack::keystone-service": openstack_version => $openstack_version, keystoneconfig => $keystoneconfig }
	}
	class { "role::puppet::server::labs": }
}

class role::nova::compute {
	include role::nova::config::pmtpa,
		role::nova::config::eqiad

	$novaconfig = $cluster ? {
		"pmtpa" => role::nova::config::pmtpa::novaconfig,
		"eqiad" => role::nova::config::eqiad::novaconfig,
	}

	class { "openstack::common": openstack_version => $openstack_version, novaconfig => $novaconfig }
	class { "openstack::compute-service": openstack_version => $openstack_version, novaconfig => $novaconfig }

	if $realm == "labs" {
		class { "openstack::network-service": openstack_version => $openstack_version, novaconfig => $novaconfig }
		class { "openstack::api-service": openstack_version => $openstack_version, novaconfig => $novaconfig }
	}
}
