class ldap::role::client::labs($ldapincludes=['openldap', 'utils']) {
    include ldap::role::config::labs

    if ( $::realm == 'labs' ) {
        $includes = ['openldap', 'pam', 'nss', 'sudo', 'utils']

        if ( $::restricted_from ) {
            security::access { 'labs-restrict-from':
                content  => "-:${restricted_from}:ALL\n",
                priority => '98',
            }
        }

        if ( $::restricted_to? ) {
            security::access { 'labs-restrict-to-group':
                content  => "-:ALL EXCEPT (${::restricted_to}) root:ALL\n",
                priority => '99',
            }
        } else {
            security::access { 'labs-restrict-to-project':
                content  => "-:ALL EXCEPT (${::projectgroup}) root:ALL\n",
                priority => '99',
            }
        }

    } else {
        $includes = $ldapincludes
    }

    class{ 'ldap::client::includes':
        ldapincludes => $includes,
        ldapconfig   => $ldap::role::config::labs::ldapconfig,
    }
}
