# SPDX-License-Identifier: Apache-2.0
# @summary provisions the ldap connection config file and utilities to
#  interact with ldap (via the ldap-utils package)
# @param $labsldapconfig ldap configuration hash (TODO: convert to individual params)
class profile::ldap::client::utils (
    Hash[String[1], Any] $labsldapconfig = lookup('labsldapconfig'),
) {
    $basedn = 'dc=wikimedia,dc=org'

    # TODO: this is never used in production
    $sudobasedn = $::realm ? {
        'labs'       => "ou=sudoers,cn=${::wmcs_project},ou=projects,${basedn}",
        'production' => "ou=sudoers,${basedn}"
    }

    # This is directly used elsewhere, be careful when refactoring please.
    $ldapconfig = {
        'servernames'          => [ $labsldapconfig['hostname'] ],
        'basedn'               => $basedn,
        'groups_rdn'           => 'ou=groups',
        'users_rdn'            => 'ou=people',
        'domain'               => 'wikimedia',
        'proxyagent'           => "cn=proxyagent,ou=profile,${basedn}",
        'proxypass'            => $labsldapconfig['proxypass'],
        'script_user_dn'       => "cn=scriptuser,ou=profile,${basedn}",
        'script_user_pass'     => $labsldapconfig['script_user_pass'],
        'user_id_attribute'    => 'uid',
        'tenant_id_attribute'  => 'cn',
        'ca'                   => 'ca-certificates.crt',
        'sudobasedn'           => $sudobasedn,
        'pagesize'             => 2000,
        'nss_min_uid'          => '499',
    }

    class { 'ldap::client::config':
        servers    => $ldapconfig['servernames'],
        base_dn    => $ldapconfig['basedn'],
        proxy_pass => $ldapconfig['proxypass'],
    }

    ensure_packages(['ldap-utils'])
}
