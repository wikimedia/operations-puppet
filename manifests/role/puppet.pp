class role::puppet::server::labs {
	include role::ldap::config::labs,
		role::nova::config::pmtpa,
		role::nova::config::eqiad

	$novaconfig = $site ? {
		"pmtpa" => $role::nova::config::pmtpa::novaconfig,
		"eqiad" => $role::nova::config::eqiad::novaconfig,
	}
	$puppet_db_name = $novaconfig["puppet_db_name"]
	$puppet_db_user = $novaconfig["puppet_db_user"]
	$puppet_db_pass = $novaconfig["puppet_db_pass"]

	$ldapconfig = $role::ldap::config::labs::ldapconfig
	$basedn = $ldapconfig["basedn"]

	# Only allow puppet access from the instances
	$puppet_passenger_allow_from = $realm ? {
		"production" => [ "10.4.0.0/24", "10.4.125.0", "10.4.16.3" ],
		"labs" => [ "192.168.0.0/24" ],
	}

	class { puppetmaster:
		server_name => $fqdn,
		allow_from => $puppet_passenger_allow_from,
		config => {
			'ca' => "false",
			'ca_server' => "${fqdn}",
			'dbadapter' => "mysql",
			'dbuser' => $novaconfig["puppet_db_user"],
			'dbpassword' => $novaconfig["puppet_db_pass"],
			'dbserver' => $novaconfig["puppet_db_host"],
			'node_terminus' => "ldap",
			'ldapserver' => $ldapconfig["servernames"][0],
			'ldapbase' => "ou=hosts,${basedn}",
			'ldapstring' => "(&(objectclass=puppetClient)(associatedDomain=%s))",
			'ldapuser' => $ldapconfig["proxyagent"],
			'ldappassword' => $ldapconfig["proxypass"],
			'ldaptls' => true
		};
	}
}
