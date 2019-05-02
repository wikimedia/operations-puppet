class ldap::client::sudoldap($ldapconfig) {
    # this is probably declared elsewhere, but let's be extra sure
    if ! defined(Class['Sudo::Sudoldap']) {
        class { 'sudo::sudoldap': }
    }

    # sudo-ldap.conf has always been a duplicate of /etc/ldap/ldap.conf.
    #  Make it official.
    file { '/etc/sudo-ldap.conf':
        ensure => link,
        target => '/etc/ldap/ldap.conf',
    }
}
