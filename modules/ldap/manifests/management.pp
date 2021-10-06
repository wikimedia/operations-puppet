# Bunch of utilities for managing LDAP users
# Note: We explicitly only use one server here, since we don't want to modify on both
# servers at the same time
class ldap::management(
    $server,
    $basedn,
    $user,
    $password,
) {
    ensure_packages([
        'ldapvi',
        'python3-yaml',
    ])

    apt::package_from_component { 'python3-ldap':
        component => 'component/python-ldap-bpo',
    }

    file { '/etc/ldapvi.conf':
        content => template('ldap/ldapvi.conf.erb'),
        mode    => '0440',
        owner   => 'root',
        group   => 'ldap-admins',
    }
    file {
        default:
            ensure => file,
            owner  => 'root',
            group  => 'ldap-admins',
            mode   => '0550';
        '/usr/local/bin/modify-ldap-user':
            content => file('ldap/modify-ldap-user');
        '/usr/local/bin/modify-ldap-group':
            content => file('ldap/modify-ldap-group');
        '/usr/local/bin/modify-mfa':
            content => file('ldap/scripts/modify-mfa.py');
    }
    file { '/usr/local/bin/rewrite-group-for-memberof':
        source => 'puppet:///modules/ldap/rewrite-group-for-memberof.py',
        mode   => '0554',
        owner  => 'root',
        group  => 'root',
    }
}
