# role/dns.pp

class role::dns::ldap {
	if $site == "pmtpa" {
		interface_ip { "role::dns::ldap": interface => "eth0", address => "208.80.152.33" }

		# FIXME: turn these settings into a hash that can be included somewhere
		include openstack::nova_config

		class { "dns::auth-server::ldap":
			dns_auth_ipaddress => "208.80.152.33 208.80.152.32 208.80.153.135",
			dns_auth_query_address => "208.80.152.33",
			dns_auth_soa_name => "labs-ns0.wikimedia.org",
			ldap_host => $openstack::nova_config::nova_ldap_host,
			ldap_base_dn => $openstack::nova_config::nova_ldap_base_dn,
			ldap_user_dn => $openstack::nova_config::nova_ldap_user_dn,
			ldap_user_pass => $openstack::nova_config::nova_ldap_user_pass
		}
	}
	if $site == "eqiad" {
		interface_ip { "role::dns::ldap": interface => "eth0", address => "208.80.154.19" }

		# FIXME: turn these settings into a hash that can be included somewhere
		include openstack::nova_config

		class { "dns::auth-server::ldap":
			dns_auth_ipaddress => "208.80.154.19 208.80.154.18",
			dns_auth_query_address => "208.80.154.19",
			dns_auth_soa_name => "labs-ns1.wikimedia.org",
			ldap_host => "virt1000.wikimedia.org",
			ldap_base_dn => $openstack::nova_config::nova_ldap_base_dn,
			ldap_user_dn => $openstack::nova_config::nova_ldap_user_dn,
			ldap_user_pass => $openstack::nova_config::nova_ldap_user_pass
		}
	}
}

class role::dns::recursor {
	system_role { "role::dns::recursor": description => "Recursive DNS server" }
	
	include lvs::configuration

	class {
		"lvs::realserver":
			realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['dns_rec'][$::site];
		"::dns::recursor":
			require => Class["lvs::realserver"],
			listen_addresses => [ $::ipaddress, $::ipaddress6_eth0, $lvs::configuration::lvs_service_ips[$::realm]['dns_rec'][$::site] ];
	}
	
	::dns::recursor::monitor { [ $::ipaddress, $::ipaddress6_eth0 ]: }
}
