class ldap::client::pam($ldapconfig) {
    package { 'libpam-ldapd':
        ensure => latest,
    }

    File {
        owner => 'root',
        group => 'root',
        mode  => '0444',
    }

    exec { 'pam-auth-update':
        command     => '/usr/sbin/pam-auth-update --package --force',
        refreshonly => true,
        require     => Exec['restore-default-pamd-sshd'],
    }

    file { '/usr/share/pam-configs/wikimedia-labs-pam':
        source  => 'puppet:///modules/ldap/wikimedia-labs-pam',
        notify  => Exec['pam-auth-update'],
    }
}
