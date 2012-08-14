class role::glance::config {
	include passwords::openstack::glance

	$commonglanceconfig = {
		db_name => "glance",
		db_user => "glance",
		db_pass => $passwords::openstack::glance::glance_db_pass,
	}
}

class role::glance::config::pmtpa inherits role::glance::config {
	include role::keystone::config::pmtpa

	$pmtpaglanceconfig = {
		db_host => $realm ? {
			"production" => "virt0.wikimedia.org",
			"labs" => "localhost",
		},
		bind_ip => $realm ? {
			"production" => "208.80.152.32",
			"labs" => "127.0.0.1",
		},
		keystone_admin_token => $role::keystone::config::pmtpa::admin_token,
		keystone_auth_host => $role::keystone::config::pmtpa::bind_ip,
		keystone_auth_protocol => $role::keystone::config::pmtpa::auth_protocol,
		keystone_auth_port => $role::keystone::config::pmtpa::auth_port,
	}
	$glanceconfig = merge($pmtpaglanceconfig, $commonglanceconfig)
}

class role::glance::config::eqiad inherits role::glance::config {
	include role::keystone::config::eqiad

	$eqiadglanceconfig = {
		db_host => $realm ? {
			"production" => "virt0.wikimedia.org",
			"labs" => "localhost",
		},
		bind_ip => $realm ? {
			"production" => "208.80.154.18",
			"labs" => "127.0.0.1",
		},
		keystone_admin_token => $role::keystone::config::eqiad::admin_token,
		keystone_auth_host => $role::keystone::config::eqiad::bind_ip,
		keystone_auth_protocol => $role::keystone::config::eqiad::auth_protocol,
		keystone_auth_port => $role::keystone::config::eqiad::auth_port,
	}
	$glanceconfig = merge($eqiadglanceconfig, $commonglanceconfig)
}

class role::glance::server {
	include role::glance::config::pmtpa,
		role::glance::config::eqiad

	$glanceconfig = $cluster ? {
		"pmtpa" => $role::glance::config::pmtpa::glanceconfig,
		"eqiad" => $role::glance::config::eqiad::glanceconfig,
	}

	class { "openstack::glance-service": openstack_version => $openstack_version, glanceconfig => $glanceconfig }
}
