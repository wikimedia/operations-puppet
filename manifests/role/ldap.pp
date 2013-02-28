class role::ldap::config::labs {
	include passwords::ldap::labs

	$basedn = "dc=wikimedia,dc=org"
	$servernames = $site ? {
		"pmtpa" => [ "virt0.wikimedia.org", "virt1000.wikimedia.org" ],
		"eqiad" => [ "virt1000.wikimedia.org", "virt0.wikimedia.org" ]
	}
	$sudobasedn = $realm ? {
		"labs" => "ou=sudoers,cn=${instanceproject},ou=projects,${basedn}",
		"production" => "ou=sudoers,${basedn}"
	}
	$ldapconfig = {
		"servernames" => $servernames,
		"basedn" => $basedn,
		"groups_rdn" => "ou=groups",
		"users_rdn" => "ou=people",
		"domain" => "wikimedia",
		"proxyagent" => "cn=proxyagent,ou=profile,${basedn}",
		"proxypass" => $passwords::ldap::labs::proxypass,
		"writer_dn" => "uid=novaadmin,ou=people,${basedn}",
		"writer_pass" => $passwords::ldap::labs::writerpass,
		"script_user_dn" => "cn=scriptuser,ou=profile,${basedn}",
		"script_user_pass" => $passwords::ldap::labs::script_user_pass,
		"user_id_attribute" => "uid",
		"tenant_id_attribute" => "cn",
		"ca" => "Equifax_Secure_CA.pem",
		"wikildapdomain" => "labs",
		"wikicontrollerapiurl" => "https://wikitech.wikimedia.org/w/api.php",
		"sudobasedn" => $sudobasedn,
		"pagesize" => "2000",
		"nss_min_uid" => "499",
	}
}

# TODO: kill this role at some point
class role::ldap::config::production {
	include passwords::ldap::production

	$basedn = "dc=wikimedia,dc=org"
	$servernames = $site ? {
		"pmtpa" => [ "nfs1.pmtpa.wmnet", "nfs2.pmtpa.wmnet" ],
		"eqiad" => [ "nfs2.pmtpa.wmnet", "nfs1.pmtpa.wmnet" ],
	}
	$sudobasedn = "ou=sudoers,${basedn}"
	$ldapconfig = {
		"servernames" => $servernames,
		"basedn" => $basedn,
		"groups_rdn" => "ou=groups",
		"users_rdn" => "ou=people",
		"domain" => "wikimedia",
		"proxyagent" => "cn=proxyagent,ou=profile,${basedn}",
		"proxypass" => $passwords::ldap::production::proxypass,
		"writer_dn" => "uid=novaadmin,ou=people,${basedn}",
		"writer_pass" => $passwords::ldap::production::writerpass,
		"script_user_dn" => "cn=scriptuser,ou=profile,${basedn}",
		"script_user_pass" => $passwords::ldap::labs::script_user_pass,
		"user_id_attribute" => "uid",
		"tenant_id_attribute" => "cn",
		"ca" => "wmf-ca.pem",
		"wikildapdomain" => "labs",
		"wikicontrollerapiurl" => "https://wikitech.wikimedia.org/w/api.php",
		"sudobasedn" => $sudobasedn,
		"pagesize" => "2000",
		"nss_min_uid" => "499",
	}
}

class role::ldap::config::corp {
	include passwords::ldap::corp

	$basedn = "dc=corp,dc=wikimedia,dc=org"
	$servernames = [ "sanger.wikimedia.org", "sfo-aaa1.corp.wikimedia.org" ]
	$sudobasedn = "ou=sudoers,${basedn}"
	$ldapconfig = {
		"servernames" => $servernames,
		"basedn" => $basedn,
		"groups_rdn" => "ou=groups",
		"users_rdn" => "ou=people",
		"domain" => "corp",
		"proxyagent" => "cn=proxyagent,ou=profile,${basedn}",
		"proxypass" => $passwords::ldap::corp::proxypass,
		"writer_dn" => "uid=novaadmin,ou=people,${basedn}",
		"writer_pass" => $passwords::ldap::corp::writerpass,
		"script_user" => "",
		"script_user_pass" => "",
		"user_id_attribute" => "uid",
		"tenant_id_attribute" => "cn",
		"ca" => "wmf-ca.pem",
		"sudobasedn" => $sudobasedn,
		"pagesize" => "1000",
		"nss_min_uid" => "499",
	}
}

class role::ldap::server::labs {
	include role::ldap::config::labs,
		passwords::certs,
		passwords::ldap::initial_setup

	$certificate_location = "/var/opendj/instance"
	$cert_pass = $passwords::certs::certs_default_pass
	$initial_password = $passwords::ldap::initial_setup::initial_password

	$base_dn = $role::ldap::config::labs::ldapconfig["basedn"]
	$domain = $role::ldap::config::labs::ldapconfig["domain"]
	$proxyagent = $role::ldap::config::labs::ldapconfig["proxyagent"]
	$proxypass = $role::ldap::config::labs::ldapconfig["proxypass"]

	$certificate = $realm ? {
		"production" => "star.wikimedia.org",
		"labs" => "star.wmflabs",
	}
	$ca_name = $realm ? {
		"production" => "Equifax_Secure_CA.pem",
		"labs"       => "wmf-labs.pem",
	}
	install_certificate{ $certificate: }
	# Add a pkcs12 file to be used for start_tls, ldaps, and opendj's admin connector.
	# Add it into the instance location, and ensure opendj can read it.
	create_pkcs12{ "${certificate}.opendj":
		certname => "${certificate}",
		user => "opendj",
		group => "opendj",
		location => $certificate_location,
		password => $cert_pass,
		require => Package["opendj"]
	}

	include ldap::server::schema::sudo,
		ldap::server::schema::ssh,
		ldap::server::schema::openstack,
		ldap::server::schema::puppet

	class { "ldap::server":
		certificate_location => $certificate_location,
		certificate => $certificate,
		cert_pass => $cert_pass,
		ca_name => $ca_name,
		base_dn => $base_dn,
		proxyagent => $proxyagent,
		proxyagent_pass => $proxypass,
		server_bind_ips => "127.0.0.1 $ipaddress_eth0",
		initial_password => $initial_password,
		first_master => false
	}

	if $realm == "labs" {
		# server is on localhost
		file { "/var/opendj/.ldaprc":
			content => 'TLS_CHECKPEER   no
TLS_REQCERT     never
',
			mode => 0400,
			owner => root,
			group => root,
			require => Package["opendj"],
			before => Exec["start_opendj"];
		}
	}
}

class role::ldap::server::production {
	include role::ldap::config::production,
		passwords::certs,
		passwords::ldap::initial_setup

	$certificate_location = "/var/opendj/instance"
	$cert_pass = $passwords::certs::certs_default_pass
	$initial_password = $passwords::ldap::initial_setup::initial_password

	$base_dn = $role::ldap::config::production::ldapconfig["basedn"]
	$domain = $role::ldap::config::production::ldapconfig["domain"]
	$proxyagent = $role::ldap::config::production::ldapconfig["proxyagent"]
	$proxypass = $role::ldap::config::production::ldapconfig["proxypass"]

	$certificate = "$hostname.pmtpa.wmnet"
	$ca_name = "wmf-ca.pem"
	install_certificate{ $certificate: }
	create_pkcs12{ "${certificate}.opendj":
		certname => "${certificate}",
		user => "opendj",
		group => "opendj",
		location => $certificate_location,
		password => $cert_pass
	} 

	include ldap::server::schema::sudo,
		ldap::server::schema::ssh,
		ldap::server::schema::openstack,
		ldap::server::schema::puppet

	class { "ldap::server":
		certificate_location => $certificate_location,
		certificate => $certificate,
		cert_pass => $cert_pass,
		ca_name => $ca_name,
		base_dn => $base_dn,
		proxyagent => $proxyagent,
		proxyagent_pass => $proxypass,
		server_bind_ips => "127.0.0.1 $ipaddress_eth0",
		initial_password => $initial_password,
		first_master => false
	}
}

class role::ldap::server::corp {
	include role::ldap::config::corp,
		passwords::certs,
		passwords::ldap::initial_setup

	$certificate_location = "/var/opendj/instance"
	$cert_pass = $passwords::certs::certs_default_pass
	$initial_password = $passwords::ldap::initial_setup::initial_password

	$base_dn = $role::ldap::config::corp::ldapconfig["basedn"]
	$domain = $role::ldap::config::corp::ldapconfig["domain"]
	$proxyagent = $role::ldap::config::corp::ldapconfig["proxyagent"]
	$proxypass = $role::ldap::config::corp::ldapconfig["proxypass"]

	$certificate = "${::fqdn}"
	$ca_name = "wmf-ca.pem"
	install_certificate{ $certificate: }
	create_pkcs12{ "${certificate}.opendj":
		certname => "${certificate}",
		user => "opendj",
		group => "opendj",
		location => $certificate_location,
		password => $cert_pass
	} 

	class { "ldap::server":
		certificate_location => $certificate_location,
		certificate => $certificate,
		cert_pass => $cert_pass,
		ca_name => $ca_name,
		base_dn => $base_dn,
		proxyagent => $proxyagent,
		proxyagent_pass => $proxypass,
		server_bind_ips => "127.0.0.1 $ipaddress_eth0",
		initial_password => $initial_password,
		first_master => false
	}
}

class role::ldap::client::labs($ldapincludes=['openldap', 'utils']) {
	include role::ldap::config::labs,
		certificates::wmf_ca

	if ( $realm == "labs" ) {
		$includes = ['openldap', 'pam', 'nss', 'sudo', 'utils', 'autofs', 'access']

		include certificates::wmf_labs_ca
	} else {
		$includes = $ldapincludes
	}
	
	class{ "ldap::client::includes":
		ldapincludes => $includes,
		ldapconfig => $role::ldap::config::labs::ldapconfig
	}
}

class role::ldap::client::corp {
	include role::ldap::config::corp,
		certificates::wmf_ca

	$ldapincludes = ['openldap', 'utils']
	
	class{ "ldap::client::includes":
		ldapincludes => $ldapincludes,
		ldapconfig => $role::ldap::config::corp::ldapconfig
	}
}

# TODO: Remove this when all references to it are gone from ldap.
class ldap::client::wmf-test-cluster {
	include role::ldap::client::labs
}
