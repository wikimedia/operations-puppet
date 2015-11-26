class ldap::client::pam($ldapconfig) {

    Package { 'libpam-ldapd':
        ensure => present,
    }

    exec { 'pam-auth-update':
        command     => '/usr/sbin/pam-auth-update --package',
        refreshonly => true,
        require     => Package['libpam-ldapd'],
    }

    file { '/usr/share/pam-configs/wikimedia-labs-pam':
        ensure => present,
        source => 'puppet:///modules/ldap/wikimedia-labs-pam',
        notify => Exec['pam-auth-update'],
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    file { '/usr/local/sbin/cleanup-pam-config':
        ensure => present,
        source => 'puppet:///modules/ldap/cleanup-pam-config',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

}
