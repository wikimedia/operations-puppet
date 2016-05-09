class role::ldap::client::labs {
    include ldap::role::config::labs

    $ldapconfig = $ldap::role::config::labs::ldapconfig

    # Setup base ldap
    class { 'ldap::client':
        ldapconfig => $ldapconfig,
        use_sudo   => true,
    }

    # Setup PAM for Labs instances
    package { 'libpam-ldapd':
        ensure => present,
    }

    security::pam::config { 'wikimedia-labs-pam':
        source => 'puppet:///modules/ldap/wikimedia-labs-pam',
    }

    class { 'ldap::client::nss':
        ldapconfig => $ldapconfig
    }

    class { 'ldap::client::ldaplist':
        require => Class['ldap::client'],
    }

    class { 'ldap::client::ssh':
    }

    # bypass pam_access restrictions for local commands
    security::access::config { 'labs-local':
        content  => "+:ALL:LOCAL\n",
        priority => '00',
    }

    # Labs instance default to allowing root and project members
    # only (members of the project-foo group).
    #
    # In addition, there are variables that can be set on wikitech
    # to alter that:
    #   $restricted_from
    #       limits the specified group or user from loggin in
    #       (used to prevent opsen from logging onto unsecured
    #       bastions, for instance)
    #   $restricted_to
    #       replaces the default group allowed to login
    #       (project members) with an explicitly specified one.
    #
    if ( $::restricted_from ) {
        security::access::config { 'labs-restrict-from':
            content  => "-:${::restricted_from}:ALL\n",
            priority => '98',
        }
    }

    if ( $::restricted_to ) {
        security::access::config { 'labs-restrict-to-group':
            content  => "-:ALL EXCEPT (${::restricted_to}) root:ALL\n",
            priority => '99',
        }
    } else {
        security::access::config { 'labs-restrict-to-project':
            content  => "-:ALL EXCEPT (${::projectgroup}) root:ALL\n",
            priority => '99',
        }
    }
}
