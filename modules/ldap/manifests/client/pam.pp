class ldap::client::pam($ldapconfig) {

    package { 'libpam-ldapd':
        ensure => present,
    }

    security::pam::config { 'wikimedia-labs-pam':
        source => 'puppet:///modules/ldap/wikimedia-labs-pam',
    }

    #
    # FIXME: This is needed transitionally until the
    # access.conf handling is changed to the security::access
    # scheme.
    #
    security::pam::config { 'wikimedia-pam-access':
        source => 'puppet:///modules/security/wikimedia-pam-access',
    }

    file { '/usr/local/sbin/cleanup-pam-config':
        ensure => present,
        source => 'puppet:///modules/ldap/cleanup-pam-config',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

}
