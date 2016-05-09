class ldap::client(
    $ldapconfig,
    $use_sudo = false,
) {
    package { 'ldap-utils':
        ensure => latest,
    }

    file { '/etc/ldap/ldap.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ldap/open_ldap.erb'),
    }

    if $use_sudo {
        require ::sudo
        # sudo-ldap.conf has always been a duplicate of /etc/ldap/ldap.conf.
        #  Make it official.
        # FIXME: Figure out wtf the previous comment means
        file { '/etc/sudo-ldap.conf':
            ensure  => link,
            target  => '/etc/ldap/ldap.conf',
            require => File['/etc/ldap/ldap.conf'],
        }
    }
}

