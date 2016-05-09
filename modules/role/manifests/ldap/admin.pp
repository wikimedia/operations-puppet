class role::ldap::admin {
    # FIXME: Unravel this from the word 'labs'
    include ldap::role::config::labs

    $ldapconfig = $ldap::role::config::labs::ldapconfig

    # Setup base ldap credentials & config
    class { 'ldap::client':
        ldapconfig => $ldapconfig,
        use_sudo   => false,
    }

    class { '::ldap::client::admin':
        require => Class['::ldap::client'],
    }

    class { '::ldap::client::ldaplist':
        require => Class['::ldap::client'],
    }
}
