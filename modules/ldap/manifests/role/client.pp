class ldap::role::client::labs($ldapincludes=['openldap', 'utils']) {
    include ldap::role::config::labs

    if ( $::realm == 'labs' ) {
        $includes = ['openldap', 'pam', 'nss', 'sudo', 'utils', 'access']

        # Cert for the old virt1000/virt0 ldap servers:
        include certificates::wmf_labs_ca

    } else {
        $includes = $ldapincludes
    }

    class{ 'ldap::client::includes':
        ldapincludes => $includes,
        ldapconfig   => $ldap::role::config::labs::ldapconfig,
    }
}
