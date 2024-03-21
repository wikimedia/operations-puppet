# SPDX-License-Identifier: Apache-2.0
class profile::ldap::client::labs(
    Optional[Array[String]] $restricted_to   = lookup('profile::ldap::client::labs::restricted_to',   {default_value => undef}),
    Optional[Array[String]] $restricted_from = lookup('profile::ldap::client::labs::restricted_from', {default_value => undef}),
) {
    include profile::ldap::client::utils

    unless $::realm == 'labs' {
        fail('profile::ldap::client::labs: only Cloud VPS VMs are supported')
    }

    # bypass pam_access restrictions for local commands
    security::access::config { 'labs-local':
        content  => "+:ALL:LOCAL\n",
        priority => 0,
    }

    # Cloud VPS instances default to allowing root and project
    # members only (members of the project-foo group).
    #
    # In addition, there are Hiera variables that can be set
    # via Horizon/ENC to alter that:
    #   $restricted_from
    #       limits the specified group or user from loggin in
    #       (used to prevent SREs from logging onto unsecured
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

    class { 'ldap::client::sssd':
        servers      => $profile::ldap::client::utils::ldapconfig['servernames'],
        base_dn      => $profile::ldap::client::utils::ldapconfig['basedn'],
        proxy_pass   => $profile::ldap::client::utils::ldapconfig['proxypass'],
        sudo_base_dn => $profile::ldap::client::utils::ldapconfig['sudobasedn'],
        page_size    => $profile::ldap::client::utils::ldapconfig['pagesize'],
        ca_file      => $profile::ldap::client::utils::ldapconfig['ca'],
    }

    # The ldap nss package recommends this package
    # and this package will reconfigure pam as well as add
    # its support
    # TODO: this was moved from ldap::client::includes, check
    # if it's still needed
    package { 'libpam-ldapd':
        ensure => absent,
    }
}
