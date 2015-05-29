class ldap::role::client::labs($ldapincludes=['openldap', 'utils']) {
    include ldap::role::config::labs

    if ( $::realm == 'labs' ) {
        $includes = ['openldap', 'pam', 'nss', 'sudo', 'utils', 'access']
    } else {
        $includes = $ldapincludes
    }

    class{ 'ldap::client::includes':
        ldapincludes => $includes,
        ldapconfig   => $ldap::role::config::labs::ldapconfig,
    }
}
