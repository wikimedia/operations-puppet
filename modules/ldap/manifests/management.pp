# Bunch of utilities for managing LDAP users
# Note: We explicitly only use one server here, since we don't want to modify on both
# servers at the same time
class ldap::management(
    $server,
    $basedn,
    $user,
    $password,
) {
    require_package([
        'ldapvi',
        'python3-ldap3',
        'python3-yaml',
    ])

    file { '/etc/ldapvi.conf':
        content => template('ldap/ldapvi.conf.erb'),
        mode    => '0440',
        owner   => 'root',
        group   => 'ldap-admins',
    }

    file { '/usr/local/bin/modify-ldap-user':
        owner  => 'root',
        group  => 'ldap-admins',
        mode   => '0550',
        source => 'puppet:///modules/ldap/modify-ldap-user',
    }

    file { '/usr/local/bin/modify-ldap-group':
        owner  => 'root',
        group  => 'ldap-admins',
        mode   => '0550',
        source => 'puppet:///modules/ldap/modify-ldap-group',
    }

    file { '/usr/local/bin/rewrite-group-for-memberof':
        source => 'puppet:///modules/ldap/rewrite-group-for-memberof.py',
        mode   => '0554',
        owner  => 'root',
        group  => 'root',
    }
}
