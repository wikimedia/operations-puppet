# SPDX-License-Identifier: Apache-2.0
class profile::ldap::client::labs(
    Array[String]           $ldapincludes    = lookup('profile::ldap::client::labs::ldapincludes',    {default_value => ['openldap', 'utils']}),
    Optional[Array[String]] $restricted_to   = lookup('profile::ldap::client::labs::restricted_to',   {default_value => undef}),
    Optional[Array[String]] $restricted_from = lookup('profile::ldap::client::labs::restricted_from', {default_value => undef}),
){

    class { '::ldap::config::labs': }

    if $::realm == 'labs' {
        $includes = debian::codename() ? {
            'stretch' => ['openldap', 'pam', 'nss', 'sudoldap', 'utils', 'nosssd'],
            default   => ['openldap', 'utils', 'sssd'],
        }

        # bypass pam_access restrictions for local commands
        security::access::config { 'labs-local':
            content  => "+:ALL:LOCAL\n",
            priority => 0,
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
        if $restricted_from != undef {
            $restricted_from_formatted = $restricted_from.map |String $group| { "(${group})" }.join(' ')

            security::access::config { 'labs-restrict-from':
                content  => "-:${restricted_from_formatted}:ALL\n",
                priority => 98,
            }
        }

        if $restricted_to != undef {
            $restricted_to_formatted = $restricted_to.map |String $group| { "(${group})" }.join(' ')

            security::access::config { 'labs-restrict-to-group':
                content  => "-:ALL EXCEPT ${restricted_to_formatted} root:ALL\n",
                priority => 99,
            }
        } else {
            security::access::config { 'labs-restrict-to-project':
                content  => "-:ALL EXCEPT (${::projectgroup}) root:ALL\n",
                priority => 99,
            }
        }

    } else {
        $includes = $ldapincludes
    }

    class{ '::ldap::client::includes':
        ldapincludes => $includes,
        ldapconfig   => $ldap::config::labs::ldapconfig,
    }
}
