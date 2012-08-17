class role::keystone::config {
	include passwords::openstack::keystone

	$commonkeystoneconfig = {
		db_name => "keystone",
		db_user => "keystone",
		db_pass => $passwords::openstack::keystone::keystone_db_pass,
		ldap_base_dn => "dc=wikimedia,dc=org",
		ldap_user_dn => "uid=novaadmin,ou=people,dc=wikimedia,dc=org",
		ldap_user_id_attribute => "uid",
		ldap_tenant_id_attribute => "cn",
		ldap_user_name_attribute => "uid",
		ldap_tenant_name_attribute => "cn",
		ldap_user_pass => $passwords::openstack::keystone::keystone_ldap_user_pass,
		ldap_proxyagent => "cn=proxyagent,ou=profile,dc=wikimedia,dc=org",
		ldap_proxyagent_pass => $passwords::openstack::keystone::keystone_ldap_proxyagent_pass,
		auth_protocol => "http",
		auth_port => "35357",
		admin_token => $passwords::openstack::keystone::keystone_admin_token,
	}
}
class role::keystone::config::pmtpa inherits role::keystone::config {
	$pmtpakeystoneconfig = {
		db_host => $realm ? {
			"production" => "virt0.wikimedia.org",
			"labs" => "localhost",
		},
		ldap_host => $realm ? {
			"production" => "virt0.wikimedia.org",
			"labs" => "localhost",
		},
		bind_ip => $realm ? {
			"production" => "208.80.152.32",
			"labs" => "127.0.0.1",
		},
	}
	$keystoneconfig = merge($pmtpakeystoneconfig, $commonkeystoneconfig)
}

class role::keystone::config::eqiad inherits role::keystone::config {
	$eqiadkeystoneconfig = {
		db_host => $realm ? {
			"production" => "virt1000.wikimedia.org",
			"labs" => "localhost",
		},
		ldap_host => $realm ? {
			"production" => "virt1000.wikimedia.org",
			"labs" => "localhost",
		},
		bind_ip => $realm ? {
			"production" => "208.80.154.18",
			"labs" => "127.0.0.1",
		},
	}
	$keystoneconfig = merge($eqiadkeystoneconfig, $commonkeystoneconfig)
}

class role::keystone::server {
	include role::keystone::config::pmtpa,
		role::keystone::config::eqiad

	$keystoneconfig = $site ? {
		"pmtpa" => $role::keystone::config::pmtpa::keystoneconfig,
		"eqiad" => $role::keystone::config::eqiad::keystoneconfig,
	}

	class { "openstack::keystone-service": openstack_version => $openstack_version, keystoneconfig => $keystoneconfig }
}
