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

     $yaml_config = {
        servers  => [$server],
        basedn   => $basedn,
        user     => $user,
        password => $password,
    }

    file { '/etc/ldap.scriptuser.yaml':
        content => ordered_yaml($yaml_config),
    }

    file { '/usr/local/bin/reset-ldap-password':
        source => 'puppet:///modules/ldap/reset-password',
        mode   => '0554',
        owner  => 'root',
        group  => 'root',
    }
}