class ldap::role::client::labs($ldapincludes=['openldap', 'utils']) {
    include ldap::role::config::labs,
        certificates::wmf_ca

    if ( $::realm == 'labs' ) {
        if( $::site == 'eqiad' ) {
            $includes = ['openldap', 'pam', 'nss', 'sudo', 'utils', 'access']
        } else {
            $includes = ['openldap', 'pam', 'nss', 'sudo', 'utils', 'autofs', 'access']
        }

        include certificates::wmf_labs_ca
    } else {
        $includes = $ldapincludes
    }

    class{ 'ldap::client::includes':
        ldapincludes => $includes,
        ldapconfig   => $ldap::role::config::labs::ldapconfig
    }
}

class ldap::role::client::corp {
    include ldap::role::config::corp,
        certificates::wmf_ca

    $ldapincludes = ['openldap', 'utils']

    class{ 'ldap::client::includes':
        ldapincludes => $ldapincludes,
        ldapconfig   => $ldap::role::config::corp::ldapconfig
    }
}

# TODO: Remove this when all references to it are gone from ldap.
class ldap::client::wmf-test-cluster {
    include ldap::role::client::labs
}
