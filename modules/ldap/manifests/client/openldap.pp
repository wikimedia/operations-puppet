class ldap::client::openldap($ldapconfig, $ldapincludes) {
    package { 'ldap-utils':
        ensure => latest,
    }

    file { '/etc/ldap/ldap.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ldap/open_ldap.erb'),
    }
}

