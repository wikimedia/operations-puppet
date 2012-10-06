# role/dns.pp

class role::dns::ldap {
	include role::ldap::config::labs

	$ldapconfig = $role::ldap::config::labs::ldapconfig

	if $site == "pmtpa" {
		interface_ip { "role::dns::ldap": interface => "eth0", address => "208.80.152.33" }

		# FIXME: turn these settings into a hash that can be included somewhere
		class { "dns::auth-server::ldap":
			dns_auth_ipaddress => "208.80.152.33 208.80.152.32 208.80.153.135",
			dns_auth_query_address => "208.80.152.33",
			dns_auth_soa_name => "labs-ns0.wikimedia.org",
			ldap_hosts => $ldapconfig["servernames"],
			ldap_base_dn => $ldapconfig["basedn"],
			ldap_user_dn => $ldapconfig["proxyagent"],
			ldap_user_pass => $ldapconfig["proxypass"],
		}
	}
	if $site == "eqiad" {
		interface_ip { "role::dns::ldap": interface => "eth0", address => "208.80.154.19" }

		# FIXME: turn these settings into a hash that can be included somewhere
		class { "dns::auth-server::ldap":
			dns_auth_ipaddress => "208.80.154.19 208.80.154.18",
			dns_auth_query_address => "208.80.154.19",
			dns_auth_soa_name => "labs-ns1.wikimedia.org",
			ldap_hosts => $ldapconfig["servernames"],
			ldap_base_dn => $ldapconfig["basedn"],
			ldap_user_dn => $ldapconfig["proxyagent"],
			ldap_user_pass => $ldapconfig["proxypass"],
		}
	}
}

class role::dns::recursor {
	system_role { "role::dns::recursor": description => "Recursive DNS server" }
	
	include lvs::configuration, network::constants

	class {
		"lvs::realserver":
			realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['dns_rec'][$::site];
		"::dns::recursor":
			require => Class["lvs::realserver"],
			listen_addresses => [ $::ipaddress, $::ipaddress6_eth0, $lvs::configuration::lvs_service_ips[$::realm]['dns_rec'][$::site] ],
			allow_from => $network::constants::all_networks;
	}
	
	::dns::recursor::monitor { [ $::ipaddress, $::ipaddress6_eth0 ]: }
}
