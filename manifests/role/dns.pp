class role::dns::ldap {
	if $site == "pmtpa" {
		# FIXME: turn these settings into a hash that can be included somewhere
		include openstack::nova_config

		class { "dns::auth-server":
			dns_auth_ipaddress => "208.80.152.32",
			dns_auth_soa_name => "labs-ns0.wikimedia.org",
			dns_auth_master => "labs-ns0.wikimedia.org",
			ldap_host => $openstack::nova_config::nova_ldap_host,
			ldap_base_dn => $openstack::nova_config::nova_ldap_base_dn,
			ldap_user_dn => $openstack::nova_config::nova_ldap_user_dn,
			ldap_user_pass => $openstack::nova_config::nova_ldap_user_pass
		}
	}
	if $site == "eqiad" {
		# FIXME: turn these settings into a hash that can be included somewhere
		include openstack::nova_config

		class { "dns::auth-server":
			dns_auth_ipaddress => "208.80.154.18",
			dns_auth_soa_name => "labs-ns1.wikimedia.org",
			dns_auth_master => "labs-ns0.wikimedia.org",
			ldap_host => "virt1000.wikimedia.org",
			ldap_base_dn => $openstack::nova_config::nova_ldap_base_dn,
			ldap_user_dn => $openstack::nova_config::nova_ldap_user_dn,
			ldap_user_pass => $openstack::nova_config::nova_ldap_user_pass
		}
	}
}
