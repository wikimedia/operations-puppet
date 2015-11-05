class ldap::client::includes($ldapincludes, $ldapconfig) {
    if 'openldap' in $ldapincludes {
        class { 'ldap::client::openldap':
            ldapconfig   => $ldapconfig,
            ldapincludes => $ldapincludes,
        }
    }

    if 'pam' in $ldapincludes {
        class { 'ldap::client::pam':
            ldapconfig => $ldapconfig
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
        class { 'ldap::client::nss':
            ldapconfig => $ldapconfig
        }
    }

    if 'sudo' in $ldapincludes {
        class { 'ldap::client::sudo':
            ldapconfig => $ldapconfig
        }
    }

    if 'utils' in $ldapincludes {
        class { 'ldap::client::utils':
            ldapconfig => $ldapconfig
        }
    }

    if 'access' in $ldapincludes {
        file { '/etc/security/access.conf':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('ldap/access.conf.erb'),
        }
    }
}
