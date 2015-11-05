class ldap::client::pam($ldapconfig) {
    package { 'libpam-ldapd':
        ensure => latest,
    }

    File {
        owner => 'root',
        group => 'root',
        mode  => '0444',
    }

    file { '/etc/pam.d/common-auth':
            source => 'puppet:///modules/ldap/common-auth',
    }

    file { '/etc/pam.d/sshd':
            source => 'puppet:///modules/ldap/sshd',
    }

    file { '/etc/pam.d/common-account':
            source => 'puppet:///modules/ldap/common-account',
    }

    file { '/etc/pam.d/common-password':
            source => 'puppet:///modules/ldap/common-password',
    }

    file { '/etc/pam.d/common-session':
            source => 'puppet:///modules/ldap/common-session',
    }

    file { '/etc/pam.d/common-session-noninteractive':
            source => 'puppet:///modules/ldap/common-session-noninteractive',
    }
}
