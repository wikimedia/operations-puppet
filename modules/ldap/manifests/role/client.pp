class ldap::role::client::labs($ldapincludes=['openldap', 'utils']) {
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

class ldap::role::client::corp {
	include role::ldap::config::corp,
		certificates::wmf_ca

	$ldapincludes = ['openldap', 'utils']
	
	class{ "ldap::client::includes":
		ldapincludes => $ldapincludes,
		ldapconfig => $role::ldap::config::corp::ldapconfig
	}
}
