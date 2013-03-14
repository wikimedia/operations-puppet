class role::puppet::server::labs {
	include role::nova::config
	$novaconfig = $role::nova::config::novaconfig

	$puppet_db_name = $novaconfig["puppet_db_name"]
	$puppet_db_user = $novaconfig["puppet_db_user"]
	$puppet_db_pass = $novaconfig["puppet_db_pass"]

	$ldapconfig = $role::ldap::config::labs::ldapconfig
	$basedn = $ldapconfig["basedn"]

	# Only allow puppet access from the instances
	$puppet_passenger_allow_from = $realm ? {
		"production" => [ "10.4.0.0/21", "10.68.16.0/21", "10.4.16.3", "10.64.20.8", "208.80.152.161", "208.80.154.14" ],
		"labs" => [ "192.168.0.0/21" ],
	}

	class { puppetmaster:
		server_name => $fqdn,
		allow_from => $puppet_passenger_allow_from,
		config => {
			'thin_storeconfigs' => false,
			#'dbadapter' => "mysql",
			#'dbuser' => $novaconfig["puppet_db_user"],
			#'dbpassword' => $novaconfig["puppet_db_pass"],
			#'dbserver' => $novaconfig["puppet_db_host"],
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
