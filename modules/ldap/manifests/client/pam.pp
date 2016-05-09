class ldap::client::pam($ldapconfig) {

    package { 'libpam-ldapd':
        ensure => present,
    }

    security::pam::config { 'wikimedia-labs-pam':
        source => 'puppet:///modules/ldap/wikimedia-labs-pam',
    }
}
