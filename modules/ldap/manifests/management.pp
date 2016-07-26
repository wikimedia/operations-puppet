# Bunch of utilities for managing LDAP users
class ldap::management(
    $server,
    $basedn,
    $user,
    $password,
) {
    require_package([
        'ldapvi',
    ])
  
    file { '/etc/ldapvi.conf':
        content => template('ldap/ldapvi.conf.erb'),
        mode    => '0440',
        owner   => 'root',
        group   => 'ldap-admins',
    }
}