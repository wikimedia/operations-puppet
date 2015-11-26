class ldap::client::pam($ldapconfig) {
    package { 'libpam-ldapd':
        ensure => latest,
    }

    File {
        owner => 'root',
        group => 'root',
        mode  => '0444',
    }

    #
    # XXX: This forcicbly restores /etc/pam.d/sshd to the package's
    #      version and makes a backup of the local changes. (This
    #      uses the presence of that backup as a signal to not try
    #      again).
    #
    #      That whole thing is obviously cruddy and causes a restart
    #      of the sshd and so should almost certainly be removed as
    #      quickly as we can once we are convinced that no locally
    #      modified version remains
    #
    exec { 'restore-default-pamd-sshd':
        creates => '/etc/pam.d/sshd.orig',
        command => '/bin/mv /etc/pam.d/sshd /etc/pam.d/sshd.orig && ( sudo apt-get -o Dpkg::Options::="--force-confmiss" install --reinstall openssh-server || /bin/mv /etc/pam.d/sshd.orig /etc/pam.d/sshd'
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
