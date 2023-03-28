# SPDX-License-Identifier: Apache-2.0
# @summary
#   Install and configure python3-bitu-ldap. This library is designed to make
#   interaction with LDAP from Python script easier. This profile provides a
#   default configuration which ensure that a users can automatically connect
#   and manage LDAP users and groups.
# @param ldap Hash containing LDAP connection info.
# @param group The group to use for sensitive files
#
class profile::ldap::bitu (
    Hash      $ldap = lookup('ldap'),
    String[0] $group = lookup('profile::ldap::bitu::group'),
) {
    if debian::codename::eq('buster') {
        apt::package_from_component { 'python3-ldap3':
        component => 'component/python3-ldap3',
        }
    }

    ensure_packages([
        'python3-bitu-ldap',
    ])

    $bitu_config = {
        uri      => ["ldaps://${ldap['rw-server']}:636"],
        username => $ldap['script_user_dn'],
        password => $ldap['script_user_pass'],
        groups   => {
            dn                => "${ldap['groups_cn']},${ldap['base-dn']}",
            auxiliary_classes => ['posixGroup'],
        },
        users    => {
            dn                => "${ldap['users_cn']},${ldap['base-dn']}",
            auxiliary_classes => ['posixAccount', 'wikimediaPerson'],
        },
    }

    file { '/etc/bitu/':
        ensure => directory,
        owner  => 'root',
        group  => $group,
        mode   => '0770',
    }

    file { '/etc/bitu/ldap.json':
        owner   => 'root',
        group   => $group,
        mode    => '0550',
        content => $bitu_config.to_json_pretty,
    }
}
