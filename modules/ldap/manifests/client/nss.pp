class ldap::client::nss(
    $ldapconfig = undef,
    $nsswitch_conf_source = 'puppet:///modules/ldap/nsswitch.conf',
) {
    package { [ 'libnss-ldapd',
                'nss-updatedb',
                'libnss-db',
                'nscd',
                'nslcd' ]:
        ensure => latest,
    }
    package { [ 'libnss-ldap' ]:
        ensure => purged,
    }

    service { 'nscd':
        ensure    => running,
        subscribe => File['/etc/ldap/ldap.conf'],
        require   => Package['nscd'],
    }

    service { 'nslcd':
        ensure  => running,
        subscribe => File['/etc/ldap/ldap.conf'],
        require => Package['nslcd'],
    }

    File {
        owner => 'root',
        group => 'root',
        mode  => '0444',
    }

    $nscd_conf = $::realm ? {
        'labs'  => 'puppet:///modules/ldap/nscd-labs.conf',
        default => 'puppet:///modules/ldap/nscd.conf',
    }

    file { '/etc/nscd.conf':
        require => Package['nscd'],
        notify  => Service['nscd'],
        source  => $nscd_conf,
    }

    file { '/etc/nsswitch.conf':
        notify => Service['nscd', 'nslcd'],
        source => $nsswitch_conf_source,
    }

    # Allow labs projects to give people custom shells
    $shell_override = hiera('user_login_shell', false)
    file { '/etc/ldap.conf':
        notify  => Service['nscd','nslcd'],
        require => File['/etc/nslcd.conf', '/etc/nscd.conf'],
        content => template('ldap/ldap.conf.erb'),
    }

    # So scripts don't have to parse the ldap.conf format
    $ldap_pw = $ldapconfig['basedn']
    $client_readable_config = {
        'servers'  => $ldapconfig['servernames'],
        'basedn'   => $ldapconfig['basedn'],
        'user' => "cn=proxyagent,ou=profile,${ldap_pw}",
        'password' => $ldapconfig['proxypass'],
    }

    file { '/etc/ldap.yaml':
        content => ordered_yaml($client_readable_config),
    }


    file { '/etc/nslcd.conf':
        require => Package['nslcd'],
        notify  => Service[nslcd],
        mode    => '0440',
        content => template('ldap/nslcd.conf.erb'),
    }
}

