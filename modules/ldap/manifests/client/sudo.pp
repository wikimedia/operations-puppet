class ldap::client::sudo($ldapconfig) {
    require ::sudo

    # sudo-ldap.conf has always been a duplicate of /etc/ldap/ldap.conf.
    #  Make it official.
    file { '/etc/sudo-ldap.conf':
        ensure => link,
        target => '/etc/ldap/ldap.conf',
    }
}

