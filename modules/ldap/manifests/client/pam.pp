class ldap::client::pam($ldapconfig) {

    require_package('libpam-ldapd')

    File {
        owner => 'root',
        group => 'root',
        mode  => '0444',
    }

    exec { 'pam-auth-update':
        command     => '/usr/sbin/pam-auth-update --package',
        refreshonly => true,
        require     => Package['libpam-ldapd'],
    }

    file { '/usr/share/pam-configs/wikimedia-labs-pam':
        source => 'puppet:///modules/ldap/wikimedia-labs-pam',
        notify => Exec['pam-auth-update'],
    }

    file { '/usr/local/sbin/cleanup-pam-config':
        source => 'puppet:///modules/ldap/cleanup-pam-config',
        mode   => '0555',
    }

}
