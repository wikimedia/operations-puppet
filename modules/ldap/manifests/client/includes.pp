class ldap::client::includes($ldapincludes, $ldapconfig) {
    if 'pam' in $ldapincludes {
        class { '::ldap::client::pam':
            ldapconfig => $ldapconfig,
        }
    } else {
        # The ldap nss package recommends this package
        # and this package will reconfigure pam as well as add
        # its support
        package { 'libpam-ldapd':
            ensure => absent,
        }
    }

    if 'nss' in $ldapincludes {
        class { '::ldap::client::nss':
            ldapconfig => $ldapconfig,
        }
    }

    if 'sssd' in $ldapincludes {
        class { '::ldap::client::sssd':
            ldapconfig   => $ldapconfig,
        }
    }

    if 'nosssd' in $ldapincludes {
        class { '::ldap::client::nosssd': }
    }
}
