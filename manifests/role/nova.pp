class role::nova::config {
	include role::nova::config::pmtpa,
		role::nova::config::eqiad

	$novaconfig = $site ? {
		"pmtpa" => $role::nova::config::pmtpa::novaconfig,
		"eqiad" => $role::nova::config::eqiad::novaconfig,
	}
}

class role::nova::config::common {
	include passwords::openstack::nova

	$commonnovaconfig = {
		db_name => "nova",
		db_user => "nova",
		db_pass => $passwords::openstack::nova::nova_db_pass,
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

class role::nova::config::pmtpa inherits role::nova::config::common {
	include role::keystone::config::pmtpa

	$keystoneconfig = $role::keystone::config::pmtpa::keystoneconfig
	$controller_hostname = $realm ? {
		"production" => "virt0.wikimedia.org",
		"labs" => "localhost",
	}


	$pmtpanovaconfig = {
		db_host => $controller_hostname,
		dhcp_domain => "pmtpa.wmflabs",
		glance_host => $controller_hostname,
		rabbit_host => $controller_hostname,
		cc_host => $controller_hostname,
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
			"production" => "10.4.0.0/21",
			"labs" => "192.168.0.0/21",
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
			"labs" => "10.4.0.0/21",
		},
		controller_hostname => $realm ? {
			"production" => "wikitech.wikimedia.org",
			"labs" => $fqdn,
		},
		ajax_proxy_url => $realm ? {
			"production" => "http://wikitech.wikimedia.org:8000",
			"labs" => "http://${hostname}.${domain}:8000",
		},
		ldap_host => $controller_hostname,
		puppet_host => $controller_hostname,
		puppet_db_host => $controller_hostname,
		live_migration_uri => "qemu://%s.pmtpa.wmnet/system?pkipath=/var/lib/nova",
		zone => "pmtpa",
		keystone_admin_token => $keystoneconfig["admin_token"],
		keystone_auth_host => $keystoneconfig["bind_ip"],
		keystone_auth_protocol => $keystoneconfig["auth_protocol"],
		keystone_auth_port => $keystoneconfig["auth_port"],
	}
	if ( $::hostname == "virt2" ) {
		$networkconfig = {
			network_flat_interface => $realm ? {
				"production" => "bond1.103",
				"labs" => "eth0.103",
			},
			network_flat_interface_name => $realm ? {
				"production" => "bond1",
				"labs" => "eth0",
			},
		}
		$novaconfig = merge( $pmtpanovaconfig, $commonnovaconfig, $networkconfig )
	} else {
		$novaconfig = merge( $pmtpanovaconfig, $commonnovaconfig )
	}
}

class role::nova::config::eqiad inherits role::nova::config::common {
	include role::keystone::config::eqiad

	$keystoneconfig = $role::keystone::config::eqiad::keystoneconfig
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
		network_flat_interface => $realm ? {
			"production" => "eth1.1118",
			"labs" => "eth0.1118",
		},
		network_flat_interface_name => $realm ? {
			"production" => "eth1",
			"labs" => "eth0",
		},
		network_flat_interface_vlan => "1118",
		flat_network_bridge => "br1118",
		network_public_interface => "eth0",
		network_host => $realm ? {
			"production" => "10.68.16.1",
			"labs" => "127.0.0.1",
		},
		api_host => $realm ? {
			"production" => "virt1005.eqiad.wmnet",
			"labs" => "localhost",
		},
		api_ip => $realm ? {
			"production" => "10.68.16.1",
			"labs" => "127.0.0.1",
		},
		fixed_range => $realm ? {
			"production" => "10.68.16.0/21",
			"labs" => "192.168.0.0/21",
		},
		dhcp_start => $realm ? {
			"production" => "10.68.16.4",
			"labs" => "192.168.0.4",
		},
		network_public_ip => $realm ? {
			"production" => "208.80.155.255",
			"labs" => "127.0.0.1",
		},
		dmz_cidr => $realm ? {
			"production" => "208.80.155.0/22,10.0.0.0/8",
			"labs" => "10.4.0.0/21",
		},
		controller_hostname => $realm ? {
			"production" => "wikitech.wikimedia.org",
			"labs" => $fqdn,
		},
		ajax_proxy_url => $realm ? {
			"production" => "http://wikitech.wikimedia.org:8000",
			"labs" => "http://${hostname}.${domain}:8000",
		},
		ldap_host => $controller_hostname,
		puppet_host => $controller_hostname,
		puppet_db_host => $controller_hostname,
		live_migration_uri => "qemu://%s.eqiad.wmnet/system?pkipath=/var/lib/nova",
		zone => "eqiad",
		keystone_admin_token => $keystoneconfig["admin_token"],
		keystone_auth_host => $keystoneconfig["bind_ip"],
		keystone_auth_protocol => $keystoneconfig["auth_protocol"],
		keystone_auth_port => $keystoneconfig["auth_port"],
	}
	$novaconfig = merge( $eqiadnovaconfig, $commonnovaconfig )
}

class role::nova::common {
	include role::nova::config
	$novaconfig = $role::nova::config::novaconfig

	include passwords::misc::scripts

	class { "openstack::common":
		openstack_version => $openstack_version,
		novaconfig => $novaconfig,
		instance_status_wiki_host => "wikitech.wikimedia.org",
		instance_status_wiki_domain => "labs",
		instance_status_wiki_page_prefix => "Nova_Resource:",
		instance_status_wiki_region => "pmtpa",
		instance_status_dns_domain => "pmtpa.wmflabs",
		instance_status_wiki_user => $passwords::misc::scripts::wikinotifier_user,
		instance_status_wiki_pass => $passwords::misc::scripts::wikinotifier_pass
	}
}

class role::nova::manager {
	include role::nova::config
	$novaconfig = $role::nova::config::novaconfig

	class { "openstack::openstack-manager":
		openstack_version => $openstack_version,
		novaconfig => $novaconfig,
		certificate => $realm ? {
			"production" => "star.wikimedia.org",
			"labs" => "star.wmflabs",
		}
	}
}

class role::nova::controller {
	include role::nova::config
	$novaconfig = $role::nova::config::novaconfig

	include role::keystone::config::pmtpa,
		role::keystone::config::eqiad,
		role::glance::config::pmtpa,
		role::glance::config::eqiad

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
	class { "openstack::queue-server": openstack_version => $openstack_version, novaconfig => $novaconfig }
	class { "openstack::iptables": }
	class { "openstack::database-server":
		openstack_version => $openstack_version,
		novaconfig => $novaconfig,
		glanceconfig => $glanceconfig,
		keystoneconfig => $keystoneconfig,
	}
	class { "role::keystone::server": }
	if $realm == "production" {
		class { "role::puppet::server::labs": }
	}
}

class role::nova::api {
	include role::nova::config
	$novaconfig = $role::nova::config::novaconfig

	include role::nova::common

	class { "openstack::api-service": openstack_version => $openstack_version, novaconfig => $novaconfig }
}

class role::nova::network::bonding {
	interface_aggregate { "bond1": orig_interface => "eth1", members => [ "eth1", "eth2", "eth3" ] }
}

class role::nova::network {
	include role::nova::config
	$novaconfig = $role::nova::config::novaconfig

	include role::nova::common

	if ($::site == "pmtpa") {
		require role::nova::network::bonding

		interface_ip { "openstack::network_service_public_dynamic_snat": interface => "lo", address => $site ? { "pmtpa" => "208.80.153.192", "eqiad" => "208.80.155.255" } }

		interface_tagged { "bond1.103":
			base_interface => "bond1",
			vlan_id => "103",
			method => "manual",
			up => 'ip link set $IFACE up',
			down => 'ip link set $IFACE down',
		}
	}

	class { "openstack::network-service": openstack_version => $openstack_version, novaconfig => $novaconfig }
}

class role::nova::wikiupdates {

    include base::mwclient

    if ($::lsbdistcodename == "lucid") {
		file { "/usr/local/lib/python2.6/dist-packages/wikinotifier.py":
			source => "puppet:///files/openstack/essex/nova/wikinotifier.py",
			mode => 0644,
			owner => root,
			group => root,
			require => package["python-mwclient"],
			notify => Service["nova-compute"]
		}
	} else {
		file { "/usr/local/lib/python2.7/dist-packages/wikinotifier.py":
			source => "puppet:///files/openstack/essex/nova/wikinotifier.py",
			mode => 0644,
			owner => root,
			group => root,
			require => package["python-mwclient"],
			notify => Service["nova-compute"]
		}
	}
}

class role::nova::compute {
	include role::nova::config
	$novaconfig = $role::nova::config::novaconfig

	include role::nova::wikiupdates,
 		role::nova::common

	interface_tagged { $novaconfig["network_flat_interface"]:
		base_interface => $novaconfig["network_flat_interface_name"],
		vlan_id => $novaconfig["network_flat_interface_vlan"],
		method => "manual",
		up => 'ip link set $IFACE up',
		down => 'ip link set $IFACE down',
	}

	class { "openstack::compute-service": openstack_version => $openstack_version, novaconfig => $novaconfig }

	if $realm == "labs" {
		include role::nova::api,
			role::nova::network
	}
}
