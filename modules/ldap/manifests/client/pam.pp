class ldap::client::pam($ldapconfig) {

    package { 'libpam-ldapd':
        ensure => present,
    }

    security::pam::config { 'wikimedia-labs-pam':
        source => 'puppet:///modules/ldap/wikimedia-labs-pam',
    }

    file { '/usr/local/sbin/cleanup-pam-config':
        ensure => present,
        source => 'puppet:///modules/ldap/cleanup-pam-config',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

}
