class ldap::client::ldaplist {
    require ::ldap::supportlib

    file { '/usr/local/sbin/ldaplist':
        ensure => link,
        target => '/usr/local/bin/ldaplist',
    }

    file { '/usr/local/bin/ldaplist':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/ldap/scripts/ldaplist',
    }

}
